
// ---------------------------------------------------------------- lattices
// A lattice supplies a bottom, a join and an order. A monotone transfer function over a
// lattice of finite height reaches a fixed point; one solver serves every analysis.

const lattice = {
  powerset(opts = {}) {
    return {
      name: 'powerset', universe: opts.universe,
      bottom: () => new Set(),
      join: (a, b) => { const out = new Set(a); for (const x of b) out.add(x); return out; },
      le: (a, b) => [...a].every(x => b.has(x)),
      eq: (a, b) => a.size === b.size && [...a].every(x => b.has(x)),
      height: () => (opts.universe ? [...opts.universe].length : Infinity),
      show: a => [...a].sort(),
      sample: (r, universe) => new Set([...universe].filter(() => r.chance(0.5))),
    };
  },
  flat(values = []) {
    const BOT = { flat: 'bottom' }, TOP = { flat: 'top' };
    return {
      name: 'flat', BOT, TOP, values,
      bottom: () => BOT,
      join: (a, b) => (a === BOT ? b : b === BOT ? a : Object.is(a, b) ? a : TOP),
      le: (a, b) => a === BOT || b === TOP || Object.is(a, b),
      eq: (a, b) => Object.is(a, b),
      height: () => 2, show: a => (a === BOT ? '⊥' : a === TOP ? '⊤' : a),
    };
  },
  map(inner) {
    return {
      name: `map(${inner.name})`, inner,
      bottom: () => new Map(),
      join: (a, b) => { const out = new Map(a); for (const [k, v] of b) out.set(k, out.has(k) ? inner.join(out.get(k), v) : v); return out; },
      le: (a, b) => [...a].every(([k, v]) => b.has(k) ? inner.le(v, b.get(k)) : inner.le(v, inner.bottom())),
      eq: (a, b) => a.size === b.size && [...a].every(([k, v]) => b.has(k) && inner.eq(v, b.get(k))),
      height: n => n * inner.height(), show: a => Object.fromEntries([...a].map(([k, v]) => [k, inner.show(v)])),
    };
  },
  types() {
    return {
      name: 'types', bottom: () => t.bottom, join: (a, b) => a.join(b), le: (a, b) => a.le(b), eq: (a, b) => a.eq(b),
      height: () => KINDS.length, show: a => a.toString(),
    };
  },
  product(...ls) {
    return {
      name: `product(${ls.map(l => l.name).join(', ')})`, parts: ls,
      bottom: () => ls.map(l => l.bottom()),
      join: (a, b) => ls.map((l, i) => l.join(a[i], b[i])),
      le: (a, b) => ls.every((l, i) => l.le(a[i], b[i])),
      eq: (a, b) => ls.every((l, i) => l.eq(a[i], b[i])),
      height: n => ls.reduce((h, l) => h + l.height(n), 0), show: a => ls.map((l, i) => l.show(a[i])),
    };
  },
  interval() {
    return {
      name: 'interval', infinite: true,
      bottom: () => null,
      join: (a, b) => (!a ? b : !b ? a : [Math.min(a[0], b[0]), Math.max(a[1], b[1])]),
      le: (a, b) => !a || (b && b[0] <= a[0] && a[1] <= b[1]),
      eq: (a, b) => (!a && !b) || (a && b && a[0] === b[0] && a[1] === b[1]),
      height: () => Infinity, show: a => (a ? `[${a[0]}, ${a[1]}]` : '⊥'),
    };
  },
};

const widen = {
  thresholds: steps => (prev, next) => {
    if (!prev || !next) return next;
    const lo = next[0] < prev[0] ? Math.max(...[-Infinity, ...steps].filter(s => s <= next[0])) : prev[0];
    const hi = next[1] > prev[1] ? Math.min(...[...steps, Infinity].filter(s => s >= next[1])) : prev[1];
    return [lo, hi];
  },
};

// ---------------------------------------------------------------- analyses as values

class Analysis {
  constructor(spec) { Object.assign(this, { name: 'analysis', direction: 'forward', exceptional: 'include', ...spec }); Object.freeze(this); }
  with(patch) { return new Analysis({ ...this, ...patch }); }
  lattice(l) { return this.with({ lat: l }); }
  forward() { return this.with({ direction: 'forward' }); }
  backward() { return this.with({ direction: 'backward' }); }
  transfer(f) { return this.with({ opTransfer: f, blockTransfer: null }); }
  block(f) { return this.with({ blockTransfer: f }); }
  edge(f) { return this.with({ edgeRule: f }); }
  widen(w) { return this.with({ widener: w }); }
  init(f) { return this.with({ boundary: f }); }
  yamlTag() { return `analysis ${this.name} (${this.direction})`; }
}
const analysisBuilder = name => new Analysis({ name });

// The edge rule for backward analyses over block parameters: a live parameter of the
// target makes the argument passed on this edge live; the implicit first parameter of an
// invoke or handler edge is defined by the edge itself.
const edgeRules = {
  substituteBlockArgs: () => (fn, from, e, x) => {
    const target = fn.block(e.block), implicit = implicitCount(fn, from, e);
    const out = new Set();
    for (const v of x) {
      const pi = target.params.findIndex(p => p.id === v);
      if (pi < 0) out.add(v);
      else if (pi >= implicit) { const a = e.args[pi - implicit]; if (a !== undefined && !isLit(a)) out.add(a); }
    }
    return out;
  },
  ignoreBlockArgs: () => (fn, from, e, x) => {
    const target = fn.block(e.block), names = new Set(target.params.map(p => p.id));
    return new Set([...x].filter(v => !names.has(v)));
  },
};

function implicitCount(fn, from, e) {
  if (e.kind === 'throw' || e.kind === 'handler') return 1;
  if (e.kind === 'normal') { const d = opRegistry[from.term.op.op]; return d && d.results.length ? 1 : 0; }
  return 0;
}

const operandsOf = o => o.args.filter(a => !isLit(a));
const termOperands = term => {
  const out = [];
  if (term.kind === 'branch') out.push(term.cond);
  if (term.kind === 'return' || term.kind === 'throw') out.push(term.value);
  if (term.kind === 'invoke') out.push(...term.op.args);
  return out.filter(a => !isLit(a));
};

// Liveness, block by block. Within a block, a may-throw operation with a handler makes
// everything the handler needs live across it, because the throw can come from there.
function livenessBlock(fn, b, liveOut, liveInOf, edgeRule, record) {
  let live = new Set(liveOut);
  const handler = b.onThrow && b.onThrow !== 'unwind' ? fn.block(b.onThrow) : null;
  const handlerLive = handler ? edgeRule(fn, b, { block: handler.name, args: b.throwArgs || [], kind: 'handler' }, liveInOf(handler.name)) : new Set();
  for (const a of termOperands(b.term)) live.add(a);
  if (record) record(`${fn.name}/${b.name}/term`, new Set([...liveOut]));
  for (let i = b.ops.length - 1; i >= 0; i--) {
    const o = b.ops[i];
    const d = opRegistry[o.op];
    if (o.result) live.delete(o.result);
    if (handler && d && d.mayThrow) for (const v of handlerLive) live.add(v);
    if (record) record(`${fn.name}/${b.name}/${i}`, new Set(live));
    for (const a of operandsOf(o)) live.add(a);
  }
  if (handler) for (const v of handlerLive) live.add(v);    // the handler's arguments are read at the head
  return live;
}

const analyses = {
  liveness: new Analysis({ name: 'liveness', direction: 'backward', lat: lattice.powerset(), edgeRule: edgeRules.substituteBlockArgs(), special: 'liveness' }),
  safepoints: new Analysis({ name: 'safepoints', direction: 'forward', lat: lattice.flat([false, true]), special: 'safepoints' }),
  typeFacts: new Analysis({ name: 'types', direction: 'forward', lat: lattice.map(lattice.types()), special: 'types' }),
  dominators: new Analysis({ name: 'dominators', special: 'dominators' }),
};
analyses.types = analyses.typeFacts;
analyses.product = (...as) => new Analysis({ name: as.map(a => a.name).join(' × '), parts: as, special: 'product' });

// ---------------------------------------------------------------- the solver
// A worklist over blocks. Each visit applies the block transfer; when a block's state
// changes, its neighbours in the direction of the analysis are queued again. The
// history of every visit is kept so the workbench can replay the iteration.

function solve(analysis, target, opts = {}) {
  if (target && target.kind === 'graph') return solveGraph(analysis, target, opts);
  const fn = target;
  if (analysis.special === 'product') {
    const parts = analysis.parts.map(a => solve(a, fn, opts));
    return { kind: 'facts', analysis: analysis.name, parts, iterations: Math.max(...parts.map(p => p.iterations)), ...Object.assign({}, ...parts.map(p => p.exports || {})), liveAcross: parts[0].liveAcross };
  }
  if (analysis.special === 'safepoints') return solveSafepoints(fn);
  if (analysis.special === 'dominators') { const d = dominators(fn); return { kind: 'facts', analysis: 'dominators', idom: d.idom, iterations: d.rounds, exports: { idom: d.idom } }; }
  if (analysis.special === 'types') return solveTypes(fn, opts);
  if (analysis.special === 'liveness' || analysis.direction === 'backward') return solveBackward(analysis, fn, opts);
  return solveForward(analysis, fn, opts);
}

function solveBackward(analysis, fn, opts = {}) {
  const lat = analysis.lat, rule = analysis.edgeRule || edgeRules.substituteBlockArgs();
  const IN = new Map(fn.blocks.map(b => [b.name, lat.bottom()])), OUT = new Map(fn.blocks.map(b => [b.name, lat.bottom()]));
  const preds = predecessors(fn), steps = [];
  const work = [...fn.blocks].reverse().map(b => b.name), queued = new Set(work);
  const budget = opts.budget ? opts.budget.n : Infinity, t0 = now();
  let visits = 0;
  while (work.length) {
    if (now() - t0 > budget) return budgetFallback(fn, analysis);
    const name = work.shift(); queued.delete(name); visits++;
    const b = fn.block(name);
    let out = lat.bottom();
    for (const e of termEdges(b.term)) if (fn.block(e.block)) out = lat.join(out, rule(fn, b, e, IN.get(e.block)));
    const inn = analysis.special === 'liveness' || !analysis.opTransfer
      ? livenessBlock(fn, b, out, n => IN.get(n), rule)
      : b.ops.slice().reverse().reduce((x, o) => analysis.opTransfer(o, x, { fn, block: b }), out);
    const changed = !lat.eq(inn, IN.get(name)) || !lat.eq(out, OUT.get(name));
    steps.push({ i: visits, block: name, before: { in: lat.show(IN.get(name)), out: lat.show(OUT.get(name)) }, after: { in: lat.show(inn), out: lat.show(out) }, changed });
    IN.set(name, inn); OUT.set(name, out);
    if (changed) {
      for (const p of preds.get(name) || []) if (!queued.has(p.from)) { work.push(p.from); queued.add(p.from); }
    }
  }
  // Live-across sets per operation: what is needed after it, excluding its own result.
  const across = {};
  for (const b of fn.blocks) livenessBlock(fn, b, OUT.get(b.name), n => IN.get(n), rule, (id, s) => { across[id] = [...s].sort(); });
  const show = m => Object.fromEntries([...m].map(([k, v]) => [k, lat.show(v)]));
  return {
    kind: 'facts', analysis: analysis.name, in: show(IN), out: show(OUT), across, steps, iterations: visits,
    liveAcross: id => across[id] || [],
    explain: (v, site) => explainLive(fn, v, site, across),
    of: v => ({ liveAt: Object.keys(across).filter(k => across[k].includes(v)) }),
    exports: { live: { in: show(IN), out: show(OUT), across } },
  };
}

function explainLive(fn, v, site, across) {
  const uses = usesOf(fn).get(v) || [];
  if (!(across[site] || []).includes(v)) return `${v} is not live across ${site}`;
  const u = uses[0];
  return u ? `${v} is live across ${site} because ${u.block.name} uses it later${u.edge ? ' as an argument to ' + u.edge.block : ''}` : `${v} is live across ${site}`;
}

function budgetFallback(fn, analysis) {
  const all = fn.values(), across = {};
  for (const b of fn.blocks) { b.ops.forEach((o, i) => { across[`${fn.name}/${b.name}/${i}`] = all; }); across[`${fn.name}/${b.name}/term`] = all; }
  return { kind: 'facts', analysis: analysis.name, status: 'budget-exhausted', result: 'fallback: every value live at every point (sound, imprecise)', across, liveAcross: id => across[id] || [], iterations: 0, steps: [] };
}

function solveForward(analysis, fn, opts = {}) {
  const lat = analysis.lat;
  const IN = new Map(fn.blocks.map(b => [b.name, lat.bottom()])), OUT = new Map(fn.blocks.map(b => [b.name, lat.bottom()]));
  if (analysis.boundary) IN.set(fn.entry, analysis.boundary(fn));
  const preds = predecessors(fn), steps = [];
  const work = fn.blocks.map(b => b.name), queued = new Set(work);
  let visits = 0;
  while (work.length) {
    const name = work.shift(); queued.delete(name); visits++;
    if (visits > 100000) throw new StrataError(`${analysis.name} did not converge; the lattice needs a widening`);
    const b = fn.block(name);
    let inn = name === fn.entry && analysis.boundary ? analysis.boundary(fn) : lat.bottom();
    for (const p of preds.get(name) || []) inn = lat.join(inn, analysis.edgeRule ? analysis.edgeRule(fn, fn.block(p.from), p, OUT.get(p.from)) : OUT.get(p.from));
    if (analysis.widener && visits > fn.blocks.length) inn = analysis.widener(IN.get(name), inn);
    const out = b.ops.reduce((x, o) => (analysis.opTransfer ? analysis.opTransfer(o, x, { fn, block: b }) : x), inn);
    const changed = !lat.eq(out, OUT.get(name)) || !lat.eq(inn, IN.get(name));
    steps.push({ i: visits, block: name, before: { in: lat.show(IN.get(name)), out: lat.show(OUT.get(name)) }, after: { in: lat.show(inn), out: lat.show(out) }, changed });
    IN.set(name, inn); OUT.set(name, out);
    if (changed) for (const e of successors(fn, b)) if (fn.block(e.block) && !queued.has(e.block)) { work.push(e.block); queued.add(e.block); }
  }
  const show = m => Object.fromEntries([...m].map(([k, v]) => [k, lat.show(v)]));
  return { kind: 'facts', analysis: analysis.name, in: show(IN), out: show(OUT), steps, iterations: visits, of: v => ({ in: show(IN), out: show(OUT) }) };
}

function solveSafepoints(fn) {
  const list = [];
  for (const b of fn.blocks) {
    b.ops.forEach((o, i) => { const d = opRegistry[o.op]; if (d && d.mayCollect) list.push(`${fn.name}/${b.name}/${i}`); });
    if (b.term && b.term.kind === 'invoke') { const d = opRegistry[b.term.op.op]; if (d && d.mayCollect) list.push(`${fn.name}/${b.name}/term`); }
  }
  return { kind: 'facts', analysis: 'safepoints', safepoints: list, iterations: 1, steps: [], exports: { safepoints: list } };
}

// Type facts, forward over a map from values to types. A branch on a type test refines
// the tested value on each edge, so a block reached only when x is a number knows it.
const TYPE_TESTS = { number: t.number, string: t.string, boolean: t.boolean, undefined: t.undefined, object: t.object.join(t.null), function: t.function };

function refinementOf(fn, defs, cond) {
  if (isLit(cond)) return null;
  const d = defs.get(cond);
  if (!d || d.kind !== 'op') return null;
  const o = d.op;
  if (o.op === 'core.is_number' && !isLit(o.args[0])) return { value: o.args[0], type: t.number };
  if (o.op === 'core.is_int32' && !isLit(o.args[0])) return { value: o.args[0], type: t.int32, onlyTrue: true };
  if (o.op === 'js.strict_eq' || o.op === 'num.eq') {
    const [a, b] = o.args;
    const ty = x => { if (isLit(x)) return null; const dx = defs.get(x); return dx && dx.kind === 'op' && dx.op.op === 'js.typeof' ? dx.op.args[0] : null; };
    for (const [subject, text] of [[ty(a), b], [ty(b), a]]) if (subject && !isLit(subject) && isLit(text) && TYPE_TESTS[text.lit]) return { value: subject, type: TYPE_TESTS[text.lit] };
  }
  if (o.op === 'js.truthy' || o.op === 'core.copy') return refinementOf(fn, defs, o.args[0]);
  return null;
}

function solveTypes(fn, opts = {}) {
  const defs = definitions(fn), lat = lattice.map(lattice.types());
  const typeIn = (state, a) => (isLit(a) ? t.ofValue(a.lit) : state.has(a) ? state.get(a) : t.bottom);
  const boundary = () => new Map(fn.params.map(p => [p.id, p.type]));
  const IN = new Map(fn.blocks.map(b => [b.name, new Map()])), OUT = new Map(fn.blocks.map(b => [b.name, new Map()]));
  const preds = predecessors(fn), steps = [];
  const edgeState = (from, e, state) => {
    const target = fn.block(e.block), out = new Map(state);
    const implicit = implicitCount(fn, from, e);
    if (implicit) {
      const p = target.params[0];
      if (e.kind === 'normal') { const o = from.term.op; out.set(p.id, opRegistry[o.op].typeOf(o.args.map(a => typeIn(state, a)), o, fn).meet(p.type)); }
      else out.set(p.id, p.type);
    }
    e.args.forEach((a, i) => { const p = target.params[i + implicit]; if (p) out.set(p.id, typeIn(state, a).meet(p.type)); });
    if (from.term && from.term.kind === 'branch' && (e.kind === 'true' || e.kind === 'false')) {
      const r = refinementOf(fn, defs, from.term.cond);
      if (r && state.has(r.value)) {
        const cur = out.get(r.value) || state.get(r.value);
        if (e.kind === 'true') out.set(r.value, cur.meet(r.type));
        else if (!r.onlyTrue) out.set(r.value, cur.minus(r.type));
      }
    }
    return out;
  };
  const work = fn.blocks.map(b => b.name), queued = new Set(work);
  let visits = 0;
  while (work.length) {
    const name = work.shift(); queued.delete(name); visits++;
    if (visits > 20000) break;
    const b = fn.block(name);
    let inn = name === fn.entry ? boundary() : new Map();
    for (const p of preds.get(name) || []) {
      const from = fn.block(p.from);
      if (p.kind === 'handler') inn = lat.join(inn, edgeState(from, p, IN.get(p.from)));
      else inn = lat.join(inn, edgeState(from, p, OUT.get(p.from)));
    }
    let state = new Map(inn);
    for (const o of b.ops) if (o.result) {
      const d = opRegistry[o.op];
      state.set(o.result, d ? d.typeOf(o.args.map(a => typeIn(state, a)), o, fn) : t.top);
    }
    const changed = !lat.eq(state, OUT.get(name)) || !lat.eq(inn, IN.get(name));
    steps.push({ i: visits, block: name, before: { in: lat.show(IN.get(name)), out: lat.show(OUT.get(name)) }, after: { in: lat.show(inn), out: lat.show(state) }, changed });
    IN.set(name, inn); OUT.set(name, state);
    if (changed) for (const e of successors(fn, b)) if (fn.block(e.block) && !queued.has(e.block)) { work.push(e.block); queued.add(e.block); }
  }
  const global = {};                              // the type at each value's definition
  for (const b of fn.blocks) for (const [k, v] of OUT.get(b.name)) global[k] = global[k] ? global[k].join(v) : v;
  for (const p of fn.params) global[p.id] = p.type;
  const at = (blockName, v) => { const s = OUT.get(blockName); return s && s.has(v) ? s.get(v) : (global[v] || t.top); };
  const inBlock = (blockName, v) => { const s = IN.get(blockName); return s && s.has(v) ? s.get(v) : (global[v] || t.top); };
  const show = m => Object.fromEntries([...m].map(([k, v]) => [k, lat.show(v)]));
  // the type of an operand just before op i of a block
  const before = (blockName, index, a) => {
    if (isLit(a)) return t.ofValue(a.lit);
    const b = fn.block(blockName);
    const state = new Map(IN.get(blockName));
    for (let i = 0; i < Math.min(index, b.ops.length); i++) {
      const o = b.ops[i]; if (o.result) state.set(o.result, opRegistry[o.op].typeOf(o.args.map(x => typeIn(state, x)), o, fn));
    }
    return state.has(a) ? state.get(a) : (global[a] || t.top);
  };
  return {
    kind: 'facts', analysis: 'types', steps, iterations: visits, in: show(IN), out: show(OUT),
    types: Object.fromEntries(Object.entries(global).map(([k, v]) => [k, v.toString()])),
    typeOf: v => global[v] || t.top, at, inBlock, before,
    of: v => ({ type: (global[v] || t.top).toString() }),
    exports: { types: Object.fromEntries(Object.entries(global).map(([k, v]) => [k, v.toString()])) },
  };
}

// ---------------------------------------------------------------- the same solver on plain graphs

function graph({ nodes = [], edges = [] } = {}) {
  return { kind: 'graph', nodes: nodes.map(n => (typeof n === 'string' ? { id: n } : n)), edges: edges.map(e => (Array.isArray(e) ? { from: e[0], to: e[1] } : e)) };
}

function solveGraph(analysis, gr, opts = {}) {
  const lat = analysis.lat, fwd = analysis.direction !== 'backward';
  const state = new Map(gr.nodes.map(n => [n.id, lat.bottom()]));
  const next = id => gr.edges.filter(e => (fwd ? e.from : e.to) === id).map(e => (fwd ? e.to : e.from));
  const prev = id => gr.edges.filter(e => (fwd ? e.to : e.from) === id).map(e => (fwd ? e.from : e.to));
  const start = opts.from ? [opts.from] : gr.nodes.map(n => n.id);
  const work = [...start], steps = [];
  let visits = 0;
  while (work.length) {
    const id = work.shift(); visits++;
    if (visits > 100000) break;
    let inn = lat.bottom();
    for (const p of prev(id)) inn = lat.join(inn, state.get(p));
    if (opts.from && id !== opts.from && prev(id).every(p => lat.eq(state.get(p), lat.bottom()))) continue;
    const node = gr.nodes.find(n => n.id === id);
    const out = analysis.opTransfer ? analysis.opTransfer(node, inn) : inn;
    const changed = !lat.eq(out, state.get(id));
    steps.push({ i: visits, block: id, before: lat.show(state.get(id)), after: lat.show(out), changed });
    if (changed || visits <= start.length) { state.set(id, out); for (const n of next(id)) work.push(n); }
  }
  return { kind: 'facts', analysis: analysis.name, iterations: visits, steps, of: id => lat.show(state.get(id)), state: Object.fromEntries([...state].map(([k, v]) => [k, lat.show(v)])) };
}

graph.scc = gr => {                               // Tarjan's strongly connected components
  let index = 0; const stack = [], on = new Set(), idx = new Map(), low = new Map(), out = [];
  const adj = id => gr.edges.filter(e => e.from === id).map(e => e.to);
  const visit = v => {
    idx.set(v, index); low.set(v, index); index++; stack.push(v); on.add(v);
    for (const w of adj(v)) {
      if (!idx.has(w)) { visit(w); low.set(v, Math.min(low.get(v), low.get(w))); }
      else if (on.has(w)) low.set(v, Math.min(low.get(v), idx.get(w)));
    }
    if (low.get(v) === idx.get(v)) { const comp = []; let w; do { w = stack.pop(); on.delete(w); comp.push(w); } while (w !== v); out.push(comp); }
  };
  for (const n of gr.nodes) if (!idx.has(n.id)) visit(n.id);
  return out;
};

// All the facts the workbench shows for one function.
function analyzeFn(fn) {
  const live = solve(analyses.liveness, fn), types = solve(analyses.types, fn), safe = solveSafepoints(fn), dom = dominators(fn);
  return {
    live: { in: live.in, out: live.out, across: live.across }, types: types.types, safepoints: safe.safepoints, idom: dom.idom,
    iterations: { liveness: live.iterations, types: types.iterations, dominators: dom.rounds },
    raw: { live, types, safe, dom },
  };
}
