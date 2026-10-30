
// ---------------------------------------------------------------- rewrites
// A rewrite matches an operation, checks a side condition and builds a replacement. The
// side condition reads derived permissions and facts; it never restates what an
// operation does. Every attempt is logged as a decision, fired or not, with the reason.

class Rewrite {
  constructor(spec) { Object.assign(this, { name: 'rewrite', matchFn: () => true, whenFn: null, toFn: null }, spec); Object.freeze(this); }
  with(p) { return new Rewrite({ ...this, ...p }); }
  match(f) { return this.with({ matchFn: f }); }
  when(f) { return this.with({ whenFn: f }); }
  to(f) { return this.with({ toFn: f }); }
  yamlTag() { return `rewrite ${this.name}`; }
}
const rewrite = name => new Rewrite({ name });

// A small pattern language for match(): m.op('js.add').resultUnused()
function patternOf(sel = '*') {
  const tests = [s => sel === '*' || s.op.op === sel || (sel.endsWith('.*') && s.op.op.startsWith(sel.slice(0, -1)))];
  const p = {
    resultUnused: () => (tests.push(s => s.unused && !!s.op.result), p),   // an op with a result nobody uses
    noResult: () => (tests.push(s => !s.op.result), p),
    inLoop: () => (tests.push(s => s.inLoop), p),
    hasVariants: () => (tests.push(s => !!(s.def && s.def.narrow)), p),
    test: s => tests.every(f => f(s)),
  };
  return p;
}
const M = { op: patternOf };

function sitesOf(fn) {
  const uses = usesOf(fn), out = [];
  for (const b of fn.blocks) b.ops.forEach((o, i) => out.push({
    fn, block: b, index: i, op: o, id: `${fn.name}/${b.name}/${i}`, def: opRegistry[o.op],
    unused: !o.result || !(uses.get(o.result) || []).length,
  }));
  return out;
}

function siteContext(fn, facts, decisions) {
  return {
    facts,
    perm: (o, extra = {}) => derivePermissions(lookupOp(o.op).behaviour, extra),
    typeAt: (site, a) => facts.types.before(site.block.name, site.index, a),
    variantFor: site => {
      const d = site.def; if (!d || !d.narrow) return null;
      return d.narrow(site.op.args.map(a => facts.types.before(site.block.name, site.index, a)));
    },
    noWritesBetween: (resource, b, i, j) => b.ops.slice(i + 1, j).every(o => !lookupOp(o.op).behaviour.writes.has(resource)),
    decisions,
  };
}

function applyRewrite(fn, rw, facts, decisions) {
  let fired = 0;
  const ctx = siteContext(fn, facts, decisions);
  for (const site of sitesOf(fn).reverse()) {
    if (!site.block.ops.includes(site.op)) continue;
    const m = rw.matchFn(M, site);
    const hit = m === true || (m && m.test && m.test(site));
    if (!hit) continue;
    let ok = true, because = 'matched';
    if (rw.whenFn) {
      const r = rw.whenFn(site, ctx);
      ok = r === true || (r && r.ok === true);
      because = (r && r.because) || (ok ? 'side condition holds' : reasonFor(rw, site, ctx));
    }
    if (ok) {
      const action = rw.toFn(site, ctx);
      const done = performAction(fn, site, action);
      if (done) { fired++; decisions.push({ by: rw.name, at: site.id, op: site.op.op, fired: true, because: done === true ? because : done }); }
    } else decisions.push({ by: rw.name, at: site.id, op: site.op.op, fired: false, because });
  }
  return fired;
}

function reasonFor(rw, site, ctx) {
  const p = derivePermissions(site.def.behaviour, { identityObserved: !site.unused });
  if (/erase|dce|dead/.test(rw.name)) return `perm.erase = ${p.erase}: ${p.because.erase.join('; ')}`;
  if (/hoist/.test(rw.name)) return `perm.hoist = ${p.hoist}: ${p.because.hoist.join('; ')}`;
  return 'side condition does not hold';
}

// Actions a rewrite's to() returns.
const act = {
  erase: () => ({ kind: 'erase' }),
  replaceWith: operand => ({ kind: 'replace', operand }),
  replaceOp: (name, args) => ({ kind: 'replaceOp', name, args }),
};
function performAction(fn, site, a) {
  if (!a) return false;
  const i = site.block.ops.indexOf(site.op);
  if (i < 0) return false;
  if (a.kind === 'erase') { site.block.ops.splice(i, 1); return true; }
  if (a.kind === 'replace') {
    if (site.op.result) replaceUses(fn, site.op.result, a.operand);
    site.block.ops.splice(i, 1); return true;
  }
  if (a.kind === 'replaceOp') {
    if (site.op.op === a.name) return false;
    const before = site.op.op;
    site.op.op = a.name; if (a.args) site.op.args = a.args;
    return `${before} → ${a.name}`;
  }
  return false;
}

// ---- the standard rewrites

const PURE_FOLD = new Set(['num.add', 'num.sub', 'num.mul', 'num.div', 'num.mod', 'num.neg', 'num.lt', 'num.le', 'num.gt', 'num.ge', 'num.eq', 'num.ne',
  'i32.add', 'i32.sub', 'i32.mul', 'i32.lt', 'i32.eq', 'bool.not', 'bool.and', 'bool.or', 'core.copy', 'js.strict_eq', 'js.strict_ne', 'js.typeof', 'js.not', 'js.truthy', 'core.is_number', 'core.is_int32']);
const PRIMITIVE_FOLD = new Set(['js.add', 'js.sub', 'js.mul', 'js.div', 'js.mod', 'js.neg', 'js.lt', 'js.le', 'js.gt', 'js.ge']);
const foldMachine = () => new Machine(new Module([]), {});

const std = {
  constFold: rewrite('const-fold')
    .match((m, s) => s.op.result && s.op.args.length > 0 && s.op.args.every(isLit) && (PURE_FOLD.has(s.op.op) || PRIMITIVE_FOLD.has(s.op.op)))
    .when((s) => ({ ok: true, because: PRIMITIVE_FOLD.has(s.op.op) ? 'primitive literal operands: no user code can run' : 'pure operation on literals' }))
    .to(s => act.replaceWith(lit(lookupOp(s.op.op).step(foldMachine(), s.op.args.map(a => a.lit), s.op)))),
  eraseDead: rewrite('erase-dead-result')
    .match(m => m.op('*').resultUnused())
    .when((s, ctx) => {
      const p = ctx.perm(s.op, { identityObserved: false });
      return { ok: p.erase === true, because: `perm.erase = ${p.erase}: ${p.because.erase.join('; ')}` };
    })
    .to(() => act.erase()),
  naiveDce: rewrite('naive-dce')                    // unsound on purpose: no side condition
    .match(m => m.op('*').resultUnused())
    .to(() => act.erase()),
  narrow: rewrite('narrow-by-facts')
    .match(m => m.op('*').hasVariants())
    .when((s, ctx) => { const v = ctx.variantFor(s); return { ok: !!v, because: v ? `operand types ${s.op.args.map(a => ctx.typeAt(s, a)).join(', ')} select ${v}` : `operand types ${s.op.args.map(a => ctx.typeAt(s, a)).join(', ')} select no variant` }; })
    .to((s, ctx) => act.replaceOp(ctx.variantFor(s))),
  copyProp: rewrite('copy-propagation')
    .match((m, s) => s.op.op === 'core.copy')
    .to(s => act.replaceWith(s.op.args[0])),
  forwardCells: rewrite('forward-store-to-load')
    .match((m, s) => s.op.op === 'cell.load' && !isLit(s.op.args[0]))
    .when((s) => {
      const c = s.op.args[0], ops = s.block.ops;
      for (let j = s.index - 1; j >= 0; j--) {
        const o = ops[j];
        if ((o.op === 'cell.store' && o.args[0] === c) || (o.op === 'cell.new' && o.result === c && o.args.length)) return { ok: true, because: `stored at ${s.fn.name}/${s.block.name}/${j}; nothing writes cells in between`, value: o.op === 'cell.store' ? o.args[1] : o.args[0] };
        const b = lookupOp(o.op).behaviour;
        if (b.writes.has('cells')) return { ok: false, because: `${o.op} at ${s.fn.name}/${s.block.name}/${j} may write cells (${b})` };
      }
      return { ok: false, because: 'no store to this cell earlier in the block' };
    })
    .to((s) => {
      const c = s.op.args[0], ops = s.block.ops;
      for (let j = s.index - 1; j >= 0; j--) {
        const o = ops[j];
        if (o.op === 'cell.store' && o.args[0] === c) return act.replaceWith(o.args[1]);
        if (o.op === 'cell.new' && o.result === c) return act.replaceWith(o.args[0]);
      }
      return null;
    }),
};

// Block-level rewrites: constant branches and unreachable blocks.
function simplifyBranches(fn, decisions) {
  let n = 0;
  for (const b of fn.blocks) {
    if (b.term && b.term.kind === 'branch' && isLit(b.term.cond)) {
      const value = b.term.cond.lit, keep = value ? b.term.t : b.term.f;
      b.term = { kind: 'jump', to: keep }; n++;
      decisions.push({ by: 'simplify-branch', at: `${fn.name}/${b.name}/term`, fired: true, because: `condition is the literal ${litText(value)}; always goes to ${keep.block}` });
    }
  }
  return n;
}
function removeUnreachable(fn, decisions) {
  const dom = dominators(fn);
  const before = fn.blocks.length;
  const dropped = fn.blocks.filter(b => !dom.reachable.has(b.name)).map(b => b.name);
  fn.blocks = fn.blocks.filter(b => dom.reachable.has(b.name));
  for (const name of dropped) decisions.push({ by: 'remove-unreachable', at: `${fn.name}/${name}`, fired: true, because: 'no path from entry' });
  return before - fn.blocks.length;
}

function rewriteSet(...items) {
  const list = items.flat().flatMap(x => (x && x.items ? x.items : [x])).filter(Boolean);
  return {
    kind: 'rewrites', items: list, names: list.map(r => r.name || r),
    with: (...more) => rewriteSet(list, ...more),
    yamlTag: () => `rewrites (${list.map(r => r.name || r).join(', ')})`,
  };
}
const rewrites = (...items) => rewriteSet(...items);
rewrites.canonical = () => rewriteSet(std.copyProp, std.constFold, 'simplify-branch', 'remove-unreachable', std.eraseDead);
rewrites.standard = () => rewriteSet(std.copyProp, std.constFold, 'simplify-branch', 'remove-unreachable', std.narrow, std.forwardCells, std.eraseDead);
rewrites.none = () => rewriteSet();
Object.assign(rewrites, std);

// Run a set to a fixed point (bounded), recomputing type facts between rounds.
function runRewrites(fn, set, decisions = [], maxRounds = 8) {
  let rounds = 0, total = 0;
  for (; rounds < maxRounds; rounds++) {
    let changed = 0;
    for (const r of set.items) {
      if (r === 'simplify-branch') { changed += simplifyBranches(fn, decisions); continue; }
      if (r === 'remove-unreachable') { changed += removeUnreachable(fn, decisions); continue; }
      const facts = { types: solveTypes(fn) };
      changed += applyRewrite(fn, r, facts, decisions);
    }
    total += changed;
    if (!changed) break;
  }
  return { fired: total, rounds: rounds + 1 };
}

// ---------------------------------------------------------------- promote cells: building SSA
// The frontend gives every variable a cell. A cell that only this function reads and
// writes, never escapes, and is not stored in a block that can throw to a handler, can
// become SSA values: each store defines a new value, each load uses the current one, and
// where control flow merges (the iterated dominance frontier of the stores) a block
// parameter joins the incoming values. This is Cytron et al.'s algorithm with block
// parameters in place of phi nodes.

// A cell can become SSA values when only loads and stores in this function use it. One more
// condition comes from exceptions: a handler sees a variable's value at the operation that
// threw, which a block-level exceptional exit cannot pass when the cell is created or
// stored in a protected block. So such a cell stays a cell if any of its loads can run
// after that handler.
function promotableCells(fn) {
  const uses = usesOf(fn), out = [], reach = new Map();
  const reachable = from => {
    if (reach.has(from)) return reach.get(from);
    const seen = new Set([from]), work = [from];
    while (work.length) { const b = fn.block(work.pop()); if (!b) continue; for (const e of successors(fn, b)) if (!seen.has(e.block)) { seen.add(e.block); work.push(e.block); } }
    reach.set(from, seen); return seen;
  };
  const protectedBy = b => (b.onThrow && b.onThrow !== 'unwind' ? b.onThrow : null);
  for (const b of fn.blocks) for (const o of b.ops) {
    if (o.op !== 'cell.new' || !o.result) continue;
    const us = uses.get(o.result) || [];
    if (!us.every(u => !u.edge && !u.term && u.op && u.slot === 0 && (u.op.op === 'cell.load' || u.op.op === 'cell.store'))) continue;
    const handlers = new Set([protectedBy(b), ...us.filter(u => u.op.op === 'cell.store').map(u => protectedBy(u.block))].filter(Boolean));
    const loads = us.filter(u => u.op.op === 'cell.load').map(u => u.block.name);
    if ([...handlers].some(h => loads.some(l => reachable(h).has(l)))) continue;
    out.push(o.result);
  }
  return out;
}

function dominanceFrontiers(fn, idom) {
  const preds = predecessors(fn), df = new Map(fn.blocks.map(b => [b.name, new Set()]));
  for (const b of fn.blocks) {
    const ps = (preds.get(b.name) || []).map(p => p.from);
    if (ps.length < 2) continue;
    for (const p of ps) {
      let runner = p;
      while (runner && runner !== idom[b.name] && runner !== undefined) {
        df.get(runner).add(b.name);
        if (runner === fn.entry) break;
        runner = idom[runner];
      }
    }
  }
  return df;
}

function promoteCells(fn, decisions = []) {
  const cells = promotableCells(fn);
  if (!cells.length) return { promoted: [] };
  const dom = dominators(fn), idom = dom.idom, df = dominanceFrontiers(fn, idom);
  const children = new Map(fn.blocks.map(b => [b.name, []]));
  for (const b of fn.blocks) if (idom[b.name] && b.name !== fn.entry && children.has(idom[b.name])) children.get(idom[b.name]).push(b.name);
  const names = new Map(cells.map(c => [c, c.replace(/^c_?/, '') || c]));
  // Place block parameters at the iterated dominance frontier of each cell's stores.
  const placed = new Map();                       // block → [cell…] in parameter order
  for (const c of cells) {
    const defBlocks = new Set();
    for (const b of fn.blocks) for (const o of b.ops) if ((o.op === 'cell.store' && o.args[0] === c) || (o.op === 'cell.new' && o.result === c)) defBlocks.add(b.name);
    const work = [...defBlocks], has = new Set();
    while (work.length) {
      const x = work.pop();
      for (const y of df.get(x) || []) if (!has.has(y)) {
        has.add(y);
        if (!placed.has(y)) placed.set(y, []);
        placed.get(y).push(c);
        if (!defBlocks.has(y)) work.push(y);
      }
    }
  }
  const paramName = new Map();
  for (const [bname, cs] of placed) {
    const b = fn.block(bname);
    for (const c of cs) { const id = freshName(fn, names.get(c) + '_'); b.params.push({ id, type: t.any }); paramName.set(bname + '|' + c, id); }
  }
  // Rename along the dominator tree.
  const undef = lit(undefined);
  const visit = (bname, current) => {
    const b = fn.block(bname); current = new Map(current);
    for (const c of placed.get(bname) || []) current.set(c, paramName.get(bname + '|' + c));
    const kept = [];
    for (const o of b.ops) {
      if (o.op === 'cell.new' && cells.includes(o.result)) { current.set(o.result, o.args.length ? o.args[0] : undef); continue; }
      if (o.op === 'cell.store' && cells.includes(o.args[0])) { current.set(o.args[0], o.args[1]); continue; }
      if ((o.op === 'cell.load') && cells.includes(o.args[0])) { if (o.result) replaceUses(fn, o.result, current.get(o.args[0]) || undef); continue; }
      kept.push(o);
    }
    b.ops = kept;
    // Append the current values to every edge into a block with placed parameters.
    const append = (edge) => { for (const c of placed.get(edge.block) || []) edge.args.push(current.get(c) || undef); };
    const term = b.term;
    if (term) for (const key of ['to', 't', 'f', 'normal', 'exc']) if (term[key]) append(term[key]);
    if (b.onThrow && b.onThrow !== 'unwind') { b.throwArgs = b.throwArgs || []; for (const c of placed.get(b.onThrow) || []) b.throwArgs.push(current.get(c) || undef); }
    for (const k of children.get(bname) || []) visit(k, current);
  };
  visit(fn.entry, new Map());
  // Loads in blocks not dominated by the cell's definition read the initial value.
  for (const b of fn.blocks) b.ops = b.ops.filter(o => !(o.op === 'cell.load' && cells.includes(o.args[0]) && (o.result && replaceUses(fn, o.result, undef), true)));
  const removed = removeDeadParams(fn);
  for (const c of cells) decisions.push({ by: 'promote-cells', at: `${fn.name}/${c}`, fired: true, because: 'used only by loads and stores in this function' });
  return { promoted: cells, params: paramName.size, removedParams: removed };
}

// A block parameter is live if something other than an edge into a dead parameter uses it.
function removeDeadParams(fn) {
  const isParam = new Map();
  for (const b of fn.blocks) if (b !== fn.blocks[0]) b.params.forEach((p, i) => isParam.set(p.id, { block: b, index: i }));
  const live = new Set(), work = [];
  const mark = v => { if (isParam.has(v) && !live.has(v)) { live.add(v); work.push(v); } };
  // Real uses mark parameters live; an edge argument marks it live only through the target.
  forEachUse(fn, (v, at) => { if (!at.edge) mark(v); });
  const incoming = new Map();                     // param → operands flowing into it
  for (const b of fn.blocks) for (const e of successors(fn, b)) {
    const target = fn.block(e.block); if (!target) continue;
    const implicit = implicitCount(fn, b, e);
    e.args.forEach((a, i) => { const p = target.params[i + implicit]; if (p) { if (!incoming.has(p.id)) incoming.set(p.id, []); incoming.get(p.id).push(a); } });
    if (implicit && target.params[0]) mark(target.params[0].id);  // implicit parameters stay
  }
  while (work.length) for (const a of incoming.get(work.pop()) || []) if (!isLit(a)) mark(a);
  let removed = 0;
  for (const b of fn.blocks) {
    if (b === fn.blocks[0]) continue;
    const dead = b.params.map((p, i) => (!live.has(p.id) ? i : -1)).filter(i => i >= 0);
    if (!dead.length) continue;
    for (const src of fn.blocks) for (const e of realEdges(src)) {
      if (e.edge.block !== b.name) continue;
      const implicit = e.implicit;
      e.edge.args = e.edge.args.filter((_, i) => !dead.includes(i + implicit));
    }
    b.params = b.params.filter((_, i) => !dead.includes(i)); removed += dead.length;
  }
  return removed;
}

function realEdges(b) {                           // the edge objects themselves, for mutation
  const out = [], term = b.term;
  if (term) {
    if (term.kind === 'jump') out.push({ edge: term.to, implicit: 0 });
    if (term.kind === 'branch') out.push({ edge: term.t, implicit: 0 }, { edge: term.f, implicit: 0 });
    if (term.kind === 'invoke') { const d = opRegistry[term.op.op]; out.push({ edge: term.normal, implicit: d && d.results.length ? 1 : 0 }, { edge: term.exc, implicit: 1 }); }
  }
  if (b.onThrow && b.onThrow !== 'unwind') {
    const holder = { get block() { return b.onThrow; }, get args() { return b.throwArgs || []; }, set args(v) { b.throwArgs = v; } };
    out.push({ edge: holder, implicit: 1 });
  }
  return out;
}
