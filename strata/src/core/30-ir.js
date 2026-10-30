
// ---------------------------------------------------------------- the core IR
// A function is a list of blocks. A block has parameters, operations and exactly one
// terminator. Values enter a block only as arguments on an edge, so merges and
// loop-carried values are block parameters. A block may declare where an exception
// raised by one of its operations goes: a handler block, or `unwind` to the caller.

class Lit {
  constructor(value) { this.lit = value; Object.freeze(this); }
  toString() { return litText(this.lit); }
  toJSON() { return this.lit === undefined ? { undef: true } : (typeof this.lit === 'number' && !Number.isFinite(this.lit) || Object.is(this.lit, -0)) ? { num: litText(this.lit) } : { lit: this.lit }; }
}
const lit = v => (v instanceof Lit ? v : new Lit(v));
const isLit = x => x instanceof Lit;
function litText(v) {
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return Object.is(v, -0) ? '-0' : String(v);
  if (typeof v === 'string') return JSON.stringify(v);
  return String(v);
}
const operandText = a => (isLit(a) ? a.toString() : String(a));
const operandFromJSON = a => (typeof a === 'string' ? a : a.undef ? lit(undefined) : a.num !== undefined ? lit(Number(a.num)) : lit(a.lit));

class Fn {
  constructor({ name, params = [], result = t.any, blocks = [], meta = {} }) {
    this.name = name; this.params = params; this.result = result; this.blocks = blocks; this.meta = meta;
    this.kind = 'fn';
  }
  get entry() { return this.blocks[0] ? this.blocks[0].name : null; }
  block(name) { return this.blocks.find(b => b.name === name) || null; }
  clone() { return fnFromJSON(fnToJSON(this)); }
  hash() { return hashString(stable(fnToJSON(this))); }
  values() {
    const out = this.params.map(p => p.id);
    for (const b of this.blocks) {
      for (const p of b.params) out.push(p.id);
      for (const o of b.ops) if (o.result) out.push(o.result);
    }
    return out;
  }
  edit(fn) { const copy = this.clone(); fn(editor(copy)); return copy; }
  toString() { return printFn(this); }
  yamlTag() { return `fn ${this.name} (${this.blocks.length} blocks)`; }
  toJSON() { return fnToJSON(this); }
}

class Module {
  constructor(functions = [], meta = {}) {
    this.kind = 'module'; this.functions = new Map(functions.map(f => [f.name, f])); this.meta = meta;
    // Each function knows its module, so a direct call's result can take the callee's declared type.
    for (const f of functions) Object.defineProperty(f, 'module', { value: this, configurable: true, writable: true, enumerable: false });
    this.main = meta.main || (functions[0] && functions[0].name) || null;
  }
  fn(name) { return this.functions.get(name) || null; }
  names() { return [...this.functions.keys()]; }
  clone() { return new Module([...this.functions.values()].map(f => f.clone()), { ...this.meta }); }
  hash() { return hashString(this.names().map(n => this.fn(n).hash()).join(',')); }
  toString() { return [...this.functions.values()].map(printFn).join('\n'); }
  yamlTag() { return `module (${this.functions.size} functions)`; }
}

const termEdges = term => {
  if (!term) return [];
  switch (term.kind) {
    case 'jump': return [{ ...term.to, kind: 'jump' }];
    case 'branch': return [{ ...term.t, kind: 'true' }, { ...term.f, kind: 'false' }];
    case 'invoke': return [{ ...term.normal, kind: 'normal' }, { ...term.exc, kind: 'throw' }];
    default: return [];
  }
};

function successors(fn, b) {
  const out = termEdges(b.term);
  if (b.onThrow && b.onThrow !== 'unwind') out.push({ block: b.onThrow, args: b.throwArgs || [], kind: 'handler' });
  return out;
}

function predecessors(fn) {
  const preds = new Map(fn.blocks.map(b => [b.name, []]));
  for (const b of fn.blocks) for (const e of successors(fn, b)) if (preds.has(e.block)) preds.get(e.block).push({ from: b.name, ...e });
  return preds;
}

// Every place a value is used: op operands, terminator operands, edge arguments.
function forEachUse(fn, visit) {
  for (const b of fn.blocks) {
    (b.throwArgs || []).forEach(a => { if (!isLit(a)) visit(a, { block: b, index: -1, head: true, edge: { block: b.onThrow, args: b.throwArgs, kind: 'handler' } }); });
    b.ops.forEach((o, i) => o.args.forEach((a, j) => { if (!isLit(a)) visit(a, { block: b, index: i, op: o, slot: j }); }));
    const term = b.term; if (!term) continue;
    const at = { block: b, index: b.ops.length, term: true };
    if (term.kind === 'branch' && !isLit(term.cond)) visit(term.cond, at);
    if ((term.kind === 'return' || term.kind === 'throw') && !isLit(term.value)) visit(term.value, at);
    if (term.kind === 'invoke') term.op.args.forEach(a => { if (!isLit(a)) visit(a, { ...at, op: term.op }); });
    for (const e of termEdges(term)) e.args.forEach(a => { if (!isLit(a)) visit(a, { ...at, edge: e }); });
  }
}

function usesOf(fn) {
  const uses = new Map();
  forEachUse(fn, (v, at) => { if (!uses.has(v)) uses.set(v, []); uses.get(v).push(at); });
  return uses;
}

function replaceUses(fn, from, to) {               // substitute an operand everywhere
  const sub = a => (a === from ? to : a);
  for (const b of fn.blocks) {
    if (b.throwArgs) b.throwArgs = b.throwArgs.map(sub);
    for (const o of b.ops) o.args = o.args.map(sub);
    const term = b.term; if (!term) continue;
    if (term.kind === 'branch') term.cond = sub(term.cond);
    if (term.kind === 'return' || term.kind === 'throw') term.value = sub(term.value);
    if (term.kind === 'invoke') term.op.args = term.op.args.map(sub);
    for (const key of ['to', 't', 'f', 'normal', 'exc']) if (term[key]) term[key].args = term[key].args.map(sub);
  }
}

function freshName(fn, base = 'v') {
  const taken = new Set(fn.values());
  for (const b of fn.blocks) taken.add(b.name);
  let i = 1; while (taken.has(base + i)) i++;
  return base + i;
}

// The defining site of every value: a function parameter, a block parameter, an op.
function definitions(fn) {
  const defs = new Map();
  for (const p of fn.params) defs.set(p.id, { kind: 'param', block: fn.entry, type: p.type });
  for (const b of fn.blocks) {
    for (const p of b.params) defs.set(p.id, { kind: 'block-param', block: b.name, type: p.type });
    b.ops.forEach((o, i) => { if (o.result) defs.set(o.result, { kind: 'op', block: b.name, index: i, op: o }); });
  }
  return defs;
}

// ---------------------------------------------------------------- building functions

function makeOp(name, args, attrs = {}, result = null) {
  return { op: name, args, result, attrs: { ...attrs } };
}

function fnBuilder(name, paramTypes, resultType, body) {
  const params = Object.entries(paramTypes || {}).map(([id, ty]) => ({ id, type: typeOf(ty) }));
  const fn = new Fn({ name, params, result: typeOf(resultType || t.any) });
  let counter = 0;
  const taken = new Set(params.map(p => p.id));
  const fresh = () => { let id; do { id = 'v' + (++counter); } while (taken.has(id)); taken.add(id); return id; };
  const cursorFor = block => {
    const $ = {
      op(opName, ...args) {
        let attrs = {};
        if (args.length && args[0] && typeof args[0] === 'object' && !isLit(args[0]) && !Array.isArray(args[0])) attrs = args.shift();
        const def = lookupOp(opName);
        const id = def.results.length ? fresh() : null;
        block.ops.push(makeOp(opName, args.map(asOperand), attrs, id));
        return id;
      },
      call(callee, ...args) { return $.op('core.call', { callee }, ...args); },
      closure(callee, ...caps) { return $.op('js.closure', { callee }, ...caps); },
      const: v => lit(v),
      jump(edge) { block.term = { kind: 'jump', to: edge }; },
      branch(cond, te, fe) { block.term = { kind: 'branch', cond: asOperand(cond), t: te, f: fe }; },
      ret(v = lit(undefined)) { block.term = { kind: 'return', value: asOperand(v) }; },
      throw(v) { block.term = { kind: 'throw', value: asOperand(v) }; },
      unreachable() { block.term = { kind: 'unreachable' }; },
      invoke(opName, args, { normal, throw: exc, attrs = {} }) {
        block.term = { kind: 'invoke', op: makeOp(opName, args.map(asOperand), attrs, null), normal, exc };
      },
    };
    return $;
  };
  const f = {
    params: Object.fromEntries(params.map(p => [p.id, p.id])),
    to: (blockName, ...args) => ({ block: blockName, args: args.map(asOperand) }),
    entry(cb, opts = {}) { return f.block('entry', {}, cb, opts); },
    block(bname, ps, cb, opts = {}) {
      const bparams = Object.entries(ps || {}).map(([want, ty]) => {
        // Block parameters live in one SSA namespace, so a repeated name is freshened (i, i1, i2…).
        let id = want, k = 0; while (taken.has(id)) id = want + (++k);
        taken.add(id); return { id, type: typeOf(ty), as: want };
      });
      const block = { name: bname, params: bparams, ops: [], term: null, onThrow: opts.onThrow || null, throwArgs: (opts.throwArgs || []).map(asOperand) };
      fn.blocks.push(block);
      cb(cursorFor(block), Object.fromEntries(bparams.map(p => [p.as, p.id])));
      for (const p of bparams) delete p.as;
      return bname;
    },
  };
  body(f, f.params);
  const entryIndex = fn.blocks.findIndex(b => b.name === 'entry');
  if (entryIndex > 0) fn.blocks.unshift(fn.blocks.splice(entryIndex, 1)[0]);
  return fn;
}

const asOperand = a => (isLit(a) || typeof a === 'string' ? a : lit(a));
const typeOf = ty => (ty instanceof Type ? ty : t.parse(ty));

function editor(fn) {
  return {
    fn,
    retarget(blockName, { whenTrue, whenFalse, to } = {}) {
      const b = fn.block(blockName);
      if (b.term.kind === 'branch') { if (whenTrue) b.term.t.block = whenTrue; if (whenFalse) b.term.f.block = whenFalse; }
      else if (b.term.kind === 'jump' && to) b.term.to.block = to;
    },
    removeOp(blockName, index) { fn.block(blockName).ops.splice(index, 1); },
    insertOp(blockName, index, opName, args, attrs = {}) {
      const id = lookupOp(opName).results.length ? freshName(fn) : null;
      fn.block(blockName).ops.splice(index, 0, makeOp(opName, args.map(asOperand), attrs, id));
      return id;
    },
  };
}

// ---------------------------------------------------------------- text form

function opText(o) {
  const d = opRegistry[o.op];
  const attrNames = d ? d.attrs : [];
  let head = o.op;
  const extra = Object.entries(o.attrs || {}).filter(([k]) => k !== 'callee' && attrNames.includes(k));
  if (extra.length) head += '[' + extra.map(([k, v]) => (attrNames[0] === k ? String(v) : `${k}=${v}`)).join(', ') + ']';
  const args = o.args.map(operandText);
  if (o.attrs && o.attrs.callee) args.unshift('@' + o.attrs.callee);
  return `${head}(${args.join(', ')})`;
}
const edgeText = e => `${e.block}(${e.args.map(operandText).join(', ')})`;

function termText(term) {
  if (!term) return '<no terminator>';
  switch (term.kind) {
    case 'jump': return `jump ${edgeText(term.to)}`;
    case 'branch': return `branch ${operandText(term.cond)}, ${edgeText(term.t)}, ${edgeText(term.f)}`;
    case 'return': return `return ${operandText(term.value)}`;
    case 'throw': return `throw ${operandText(term.value)}`;
    case 'unreachable': return 'unreachable';
    case 'invoke': return `invoke ${opText(term.op)} normal ${edgeText(term.normal)} throw ${edgeText(term.exc)}`;
    default: return '?';
  }
}

function blockHeader(b, isEntry) {
  const ps = b.params.length || !isEntry ? `(${b.params.map(p => `${p.id}: ${p.type}`).join(', ')})` : '';
  const args = b.throwArgs && b.throwArgs.length ? `(${b.throwArgs.map(operandText).join(', ')})` : '';
  const handler = b.onThrow ? (b.onThrow === 'unwind' ? ' throws unwind' : ` throws to ${b.onThrow}${args}`) : '';
  return `${b.name}${ps}${handler}:`;
}

function printFn(fn, { annotate } = {}) {
  const lines = [`fn ${fn.name}(${fn.params.map(p => `${p.id}: ${p.type}`).join(', ')}) -> ${fn.result} {`];
  fn.blocks.forEach((b, bi) => {
    lines.push(blockHeader(b, bi === 0));
    b.ops.forEach((o, i) => {
      let line = '  ' + (o.result ? `${o.result} = ` : '') + opText(o);
      const note = annotate && annotate(b, i, o);
      if (note) line = line.padEnd(44) + ' ; ' + note;
      lines.push(line);
    });
    let tl = '  ' + termText(b.term);
    const tnote = annotate && annotate(b, 'term', b.term);
    if (tnote) tl = tl.padEnd(44) + ' ; ' + tnote;
    lines.push(tl);
  });
  lines.push('}');
  return lines.join('\n');
}

// The parser accepts what printFn writes, plus comments after ; or //.
function tokenizeArgs(text) {
  const out = []; let cur = '', depth = 0, quote = null;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quote) { cur += c; if (c === '\\') { cur += text[++i]; continue; } if (c === quote) quote = null; continue; }
    if (c === '"') { quote = c; cur += c; continue; }
    if (c === '(' || c === '[') depth++;
    if (c === ')' || c === ']') depth--;
    if (c === ',' && depth === 0) { out.push(cur.trim()); cur = ''; continue; }
    cur += c;
  }
  if (cur.trim()) out.push(cur.trim());
  return out;
}

function parseOperand(tok, where) {
  if (/^-?\d/.test(tok) || tok === 'NaN' || tok === 'Infinity' || tok === '-Infinity' || tok === '-0') {
    const v = tok === '-0' ? -0 : Number(tok);
    if (Number.isNaN(v) && tok !== 'NaN') throw new StrataError(`bad number ${tok} ${where}`);
    return lit(v);
  }
  if (tok.startsWith('"')) return lit(JSON.parse(tok));
  if (tok === 'true' || tok === 'false') return lit(tok === 'true');
  if (tok === 'null') return lit(null);
  if (tok === 'undefined') return lit(undefined);
  if (/^[A-Za-z_$][\w$.']*$/.test(tok)) return tok;
  throw new StrataError(`cannot read operand "${tok}" ${where}`);
}

function parseOpCall(text, where) {
  const m = /^([a-z_][\w.]*)(?:\[([^\]]*)\])?\((.*)\)$/.exec(text.trim());
  if (!m) throw new StrataError(`cannot read operation "${text}" ${where}`);
  const [, name, attrText, argText] = m;
  const d = opRegistry[name];
  const attrs = {};
  if (attrText) attrText.split(',').map(s => s.trim()).filter(Boolean).forEach((part, i) => {
    const kv = part.split('=');
    if (kv.length === 2) attrs[kv[0].trim()] = kv[1].trim();
    else attrs[(d && d.attrs[i]) || 'kind'] = part;
  });
  const args = [];
  for (const tok of tokenizeArgs(argText)) {
    if (tok.startsWith('@')) attrs.callee = tok.slice(1);
    else args.push(parseOperand(tok, where));
  }
  return makeOp(name, args, attrs);
}

function parseEdge(text, where) {
  const m = /^([A-Za-z_][\w.]*)(?:\((.*)\))?$/.exec(text.trim());
  if (!m) throw new StrataError(`cannot read edge "${text}" ${where}`);
  return { block: m[1], args: m[2] ? tokenizeArgs(m[2]).map(a => parseOperand(a, where)) : [] };
}

function parseParams(text, where) {
  if (!text || !text.trim()) return [];
  return tokenizeArgs(text).map(p => {
    const [id, ty] = p.split(':').map(s => s.trim());
    return { id, type: ty ? t.parse(ty) : t.any };
  });
}

function stripComment(line) {
  let quote = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"' && line[i - 1] !== '\\') quote = !quote;
    if (!quote && (c === ';' || (c === '/' && line[i + 1] === '/'))) return line.slice(0, i);
  }
  return line;
}

function parseIR(text) {
  const fns = []; let fn = null, block = null;
  const lines = text.split('\n');
  lines.forEach((raw, n) => {
    const where = `(line ${n + 1})`;
    const line = stripComment(raw).trim();
    if (!line) return;
    let m;
    if ((m = /^fn\s+([A-Za-z_$][\w$.]*)\s*\((.*)\)\s*(?:->\s*([\w|]+))?\s*\{$/.exec(line))) {
      fn = new Fn({ name: m[1], params: parseParams(m[2], where), result: m[3] ? t.parse(m[3]) : t.any });
      fns.push(fn); block = null; return;
    }
    if (line === '}') { fn = null; block = null; return; }
    if (!fn) throw new StrataError(`text outside a function ${where}`);
    if ((m = /^([A-Za-z_][\w.]*)(?:\(([^)]*)\))?(?:\s+throws\s+(?:to\s+)?([\w.]+)(?:\((.*)\))?)?:$/.exec(line))) {
      block = { name: m[1], params: parseParams(m[2], where), ops: [], term: null, onThrow: m[3] || null, throwArgs: m[4] ? tokenizeArgs(m[4]).map(a => parseOperand(a, where)) : [], line: n + 1 };
      fn.blocks.push(block); return;
    }
    if (!block) throw new StrataError(`operation before any block ${where}`);
    if (block.term) throw new StrataError(`block ${block.name} continues after its terminator ${where}`, { rule: 'terminator' });
    if ((m = /^jump\s+(.*)$/.exec(line))) { block.term = { kind: 'jump', to: parseEdge(m[1], where) }; return; }
    if ((m = /^branch\s+(.*)$/.exec(line))) {
      const parts = tokenizeArgs(m[1]);
      if (parts.length !== 3) throw new StrataError(`branch needs a condition and two edges ${where}`);
      block.term = { kind: 'branch', cond: parseOperand(parts[0], where), t: parseEdge(parts[1], where), f: parseEdge(parts[2], where) }; return;
    }
    if ((m = /^return(?:\s+(.*))?$/.exec(line))) { block.term = { kind: 'return', value: m[1] ? parseOperand(m[1].trim(), where) : lit(undefined) }; return; }
    if ((m = /^throw\s+(.*)$/.exec(line))) { block.term = { kind: 'throw', value: parseOperand(m[1].trim(), where) }; return; }
    if (line === 'unreachable') { block.term = { kind: 'unreachable' }; return; }
    if ((m = /^invoke\s+(.*\))\s+normal\s+(\S+(?:\(.*?\))?)\s+throw\s+(\S+(?:\(.*\))?)$/.exec(line))) {
      block.term = { kind: 'invoke', op: parseOpCall(m[1], where), normal: parseEdge(m[2], where), exc: parseEdge(m[3], where) }; return;
    }
    if ((m = /^(?:([A-Za-z_$][\w$.']*)\s*=\s*)?(.+)$/.exec(line))) {
      const o = parseOpCall(m[2], where); o.result = m[1] || null; o.line = n + 1;
      block.ops.push(o); return;
    }
    throw new StrataError(`cannot read "${line}" ${where}`);
  });
  return fns.length === 1 ? fns[0] : new Module(fns);
}

// ---------------------------------------------------------------- JSON form

function fnToJSON(fn) {
  const edge = e => ({ block: e.block, args: e.args.map(a => (isLit(a) ? a.toJSON() : a)) });
  const opJ = o => ({ op: o.op, args: o.args.map(a => (isLit(a) ? a.toJSON() : a)), result: o.result, attrs: o.attrs });
  return {
    name: fn.name, params: fn.params.map(p => ({ id: p.id, type: String(p.type) })), result: String(fn.result), meta: fn.meta,
    blocks: fn.blocks.map(b => {
      const term = b.term && { ...b.term };
      if (term) {
        for (const k of ['to', 't', 'f', 'normal', 'exc']) if (term[k]) term[k] = edge(term[k]);
        if (term.cond !== undefined) term.cond = isLit(term.cond) ? term.cond.toJSON() : term.cond;
        if (term.value !== undefined) term.value = isLit(term.value) ? term.value.toJSON() : term.value;
        if (term.op) term.op = opJ(term.op);
      }
      return { name: b.name, params: b.params.map(p => ({ id: p.id, type: String(p.type) })), onThrow: b.onThrow, throwArgs: (b.throwArgs || []).map(a => (isLit(a) ? a.toJSON() : a)), ops: b.ops.map(opJ), term };
    }),
  };
}

function fnFromJSON(j) {
  const edge = e => ({ block: e.block, args: e.args.map(operandFromJSON) });
  const opF = o => ({ op: o.op, args: o.args.map(operandFromJSON), result: o.result, attrs: { ...(o.attrs || {}) } });
  return new Fn({
    name: j.name, params: j.params.map(p => ({ id: p.id, type: t.parse(p.type) })), result: t.parse(j.result), meta: { ...(j.meta || {}) },
    blocks: j.blocks.map(b => {
      const term = b.term && { ...b.term };
      if (term) {
        for (const k of ['to', 't', 'f', 'normal', 'exc']) if (term[k]) term[k] = edge(term[k]);
        if (term.cond !== undefined) term.cond = operandFromJSON(term.cond);
        if (term.value !== undefined) term.value = operandFromJSON(term.value);
        if (term.op) term.op = opF(term.op);
      }
      return { name: b.name, params: b.params.map(p => ({ id: p.id, type: t.parse(p.type) })), onThrow: b.onThrow || null, throwArgs: (b.throwArgs || []).map(operandFromJSON), ops: b.ops.map(opF), term };
    }),
  });
}

// ---------------------------------------------------------------- dominators
// Cooper, Harvey and Kennedy's iterative algorithm over the reverse postorder. A block
// with a handler is split in two nodes: its head (parameters) and its body (operations),
// and the exceptional edge leaves from the head, because a throw can happen before any
// of the block's operations has defined its value.

function dominators(fn) {
  const nodes = [], succ = new Map();
  const add = (n) => { if (!succ.has(n)) { succ.set(n, []); nodes.push(n); } };
  for (const b of fn.blocks) { add(b.name); add(b.name + '#body'); }
  for (const b of fn.blocks) {
    succ.get(b.name).push(b.name + '#body');
    for (const e of termEdges(b.term)) if (fn.block(e.block)) succ.get(b.name + '#body').push(e.block);
    if (b.onThrow && b.onThrow !== 'unwind' && fn.block(b.onThrow)) succ.get(b.name).push(b.onThrow);
  }
  const order = [], seen = new Set();
  const visit = n => { seen.add(n); for (const s of succ.get(n)) if (!seen.has(s)) visit(s); order.push(n); };
  if (fn.entry) visit(fn.entry);
  const rpo = order.reverse(), index = new Map(rpo.map((n, i) => [n, i]));
  const preds = new Map(rpo.map(n => [n, []]));
  for (const n of rpo) for (const s of succ.get(n)) if (preds.has(s)) preds.get(s).push(n);
  const idom = new Map([[fn.entry, fn.entry]]);
  const intersect = (a, b) => {
    while (a !== b) {
      while (index.get(a) > index.get(b)) a = idom.get(a);
      while (index.get(b) > index.get(a)) b = idom.get(b);
    }
    return a;
  };
  let changed = true, rounds = 0;
  while (changed) {
    changed = false; rounds++;
    for (const n of rpo.slice(1)) {
      const ps = preds.get(n).filter(p => idom.has(p));
      if (!ps.length) continue;
      let d = ps[0];
      for (const p of ps.slice(1)) d = intersect(p, d);
      if (idom.get(n) !== d) { idom.set(n, d); changed = true; }
    }
  }
  const reachable = new Set(rpo);
  const dominates = (a, b) => {                   // node a dominates node b
    if (!reachable.has(b)) return true;
    let x = b;
    while (true) { if (x === a) return true; const up = idom.get(x); if (up === x || up === undefined) return x === a; x = up; }
  };
  const blockIdom = {};
  for (const b of fn.blocks) {
    if (!reachable.has(b.name) || b.name === fn.entry) continue;
    const up = idom.get(b.name);
    blockIdom[b.name] = up ? up.replace('#body', '') : null;
  }
  return { idom: blockIdom, dominates, reachable: new Set(fn.blocks.filter(b => reachable.has(b.name)).map(b => b.name)), rounds, nodeIdom: idom };
}

// ---------------------------------------------------------------- the verifier
// Five rules, each reported as data naming the rule and the place.

function staticType(fn, defs, a) {
  if (isLit(a)) return t.ofValue(a.lit);
  const d = defs.get(a);
  if (!d) return t.top;
  if (d.kind !== 'op') return d.type;
  const def = opRegistry[d.op.op];
  return def ? def.typeOf(d.op.args.map(x => staticType(fn, defs, x)), d.op, fn) : t.top;
}

function verify(target, opts = {}) {
  const fns = target instanceof Module ? [...target.functions.values()] : [target];
  const diags = [];
  for (const fn of fns) verifyFn(fn, diags, target instanceof Module ? target : null, opts);
  return { ok: !diags.some(d => d.severity === 'error'), diagnostics: diags };
}

function verifyFn(fn, diags, module, opts) {
  const err = (rule, message, at = {}, severity = 'error') => diags.push({ severity, kind: 'verify', rule, message, at: { fn: fn.name, ...at } });
  if (!fn.blocks.length) { err('entry', `${fn.name} has no blocks`); return; }
  const names = new Set();
  for (const b of fn.blocks) {
    if (names.has(b.name)) err('block-name', `block ${b.name} is defined twice`, { block: b.name });
    names.add(b.name);
  }
  // Rule 1: one definition per value.
  const seen = new Map();
  const define = (id, where) => {
    if (seen.has(id)) err('single-definition', `${id} is defined twice (${seen.get(id)} and ${where})`, { value: id });
    seen.set(id, where);
  };
  fn.params.forEach(p => define(p.id, 'parameter'));
  for (const b of fn.blocks) {
    b.params.forEach(p => define(p.id, `${b.name} parameter`));
    b.ops.forEach((o, i) => { if (o.result) define(o.result, `${b.name}/${i}`); });
  }
  const defs = definitions(fn);
  const dom = dominators(fn);
  for (const b of fn.blocks) {
    // Rule 5: exactly one terminator; known targets.
    if (!b.term) err('terminator', `block ${b.name} has no terminator`, { block: b.name });
    for (const e of termEdges(b.term)) if (!fn.block(e.block)) err('unknown-block', `${b.name} jumps to unknown block ${e.block}`, { block: b.name });
    if (b.onThrow && b.onThrow !== 'unwind' && !fn.block(b.onThrow)) err('unknown-block', `${b.name} throws to unknown block ${b.onThrow}`, { block: b.name });
    // Operations: known, right arity; Rule 3: may-throw needs an exit.
    const checkOp = (o, at, inInvoke) => {
      const d = opRegistry[o.op];
      if (!d) { err('unknown-op', `unknown operation ${o.op}`, at); return; }
      if (!d.variadic && o.args.length !== d.operands.length) err('arity', `${o.op} takes ${d.operands.length} operands, got ${o.args.length}`, at);
      if (d.mayThrow && !inInvoke && !b.onThrow) err('may-throw-without-exit', `${o.op} may throw but ${b.name} has no exceptional exit; use invoke or declare "throws to <block>" or "throws unwind"`, at);
      if ((o.op === 'js.closure' || o.op === 'core.call') && module && !module.fn(o.attrs.callee)) err('unknown-callee', `${o.op} names @${o.attrs.callee}, which is not in the module`, at);
    };
    b.ops.forEach((o, i) => checkOp(o, { block: b.name, op: `${fn.name}/${b.name}/${i}` }, false));
    if (b.term && b.term.kind === 'invoke') checkOp(b.term.op, { block: b.name, op: `${fn.name}/${b.name}/term` }, true);
    // Rule 2: edge arity and types (the implicit first argument of invoke and handler edges).
    for (const e of successors(fn, b)) {
      const target = fn.block(e.block); if (!target) continue;
      let implicit = 0;
      if (e.kind === 'throw' || e.kind === 'handler') implicit = 1;
      if (e.kind === 'normal') implicit = (opRegistry[b.term.op.op] && opRegistry[b.term.op.op].results.length) ? 1 : 0;
      const expected = target.params.length - implicit;
      if (e.args.length !== expected) {
        err('edge-arity', `edge ${b.name}→${e.block} passes ${e.args.length} argument${e.args.length === 1 ? '' : 's'}; ${e.block} expects ${Math.max(expected, 0)}${implicit ? ` after the implicit ${e.kind === 'normal' ? 'result' : 'thrown value'}` : ''}`, { block: b.name, edge: `${b.name}→${e.block}` });
        continue;
      }
      e.args.forEach((a, k) => {
        const p = target.params[k + implicit];
        const at = staticType(fn, defs, a);
        if (!at.le(p.type)) err('edge-type', `edge ${b.name}→${e.block} passes ${operandText(a)}: ${at} to ${p.id}: ${p.type}`, { block: b.name, edge: `${b.name}→${e.block}` });
      });
    }
  }
  // Rule 2 continued: every use is dominated by its definition.
  forEachUse(fn, (v, at) => {
    const d = defs.get(v);
    const where = { block: at.block.name, op: `${fn.name}/${at.block.name}/${at.term ? 'term' : at.index}` };
    if (!d) { err('undefined-value', `${v} is used in ${at.block.name} but never defined`, where); return; }
    if (d.kind === 'param') return;
    const useNode = at.head ? at.block.name : at.block.name + '#body';
    if (d.kind === 'block-param') {
      if (!dom.dominates(d.block, useNode)) err('dominance', `${v} (a parameter of ${d.block}) does not dominate its use in ${at.block.name}`, where);
      return;
    }
    if (d.block === at.block.name) {
      if (at.head || d.index >= at.index) err('dominance', `${v} is used in ${at.block.name} before it is defined`, where);
      return;
    }
    if (!dom.dominates(d.block + '#body', useNode)) {
      const path = counterPath(fn, d.block, at.block.name);
      err('dominance', `${v} is defined in ${d.block} but used in ${at.block.name}, which ${d.block} does not dominate${path ? ` (path ${path.join(' → ')})` : ''}`, where);
    }
  });
  // Unreachable blocks are reported, not silently dropped.
  for (const b of fn.blocks) if (!dom.reachable.has(b.name)) err('unreachable', `block ${b.name} is unreachable`, { block: b.name }, 'warning');
  if (opts.facts && opts.facts.stale) for (const s of opts.facts.stale) err('stale-fact', s.message, s.at || {});
}

function counterPath(fn, avoid, to) {                // a path from entry to `to` that skips `avoid`
  const prev = new Map([[fn.entry, null]]), queue = [fn.entry];
  if (fn.entry === avoid) return null;
  while (queue.length) {
    const n = queue.shift();
    if (n === to) { const path = []; for (let x = n; x; x = prev.get(x)) path.unshift(x); return path; }
    for (const e of successors(fn, fn.block(n))) if (e.block !== avoid && !prev.has(e.block) && fn.block(e.block)) { prev.set(e.block, n); queue.push(e.block); }
  }
  return null;
}
