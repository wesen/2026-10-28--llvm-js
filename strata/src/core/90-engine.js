
// ---------------------------------------------------------------- semantics and profiles
// A profile names which operation sets a program may use and which observations a
// correctness claim preserves. The specification runs a program under a profile.

const PROFILES = {
  core: { sets: ['core'], observes: ['output', 'outcome'] },
  'js-sync': { sets: ['core', 'js.value', 'js.object', 'js.function'], observes: ['output', 'outcome', 'thrown value', 'object identity', 'heap mutation seen later'] },
  'js-async': { sets: ['core', 'js.value', 'js.object', 'js.function', 'js.control'], observes: ['output', 'outcome', 'thrown value', 'object identity', 'heap mutation seen later', 'job order'] },
};
PROFILES.js = PROFILES['js-async'];

class Profile {
  constructor(name, spec) { this.name = name; this.sets = spec.sets; this.observes = spec.observes; Object.freeze(this); }
  le(o) { return this.sets.every(s => o.sets.includes(s)); }
  admits(opName) { return this.sets.includes(SET_OF(opName)); }
  and(other) { const o = typeof other === 'string' ? profile(other) : other; return new Profile(`${this.name}+${o.name}`, { sets: [...new Set([...this.sets, ...o.sets])], observes: [...new Set([...this.observes, ...o.observes])] }); }
  check(module) {
    const bad = [];
    for (const fn of module.functions.values()) for (const b of fn.blocks) for (const o of [...b.ops, ...(b.term && b.term.kind === 'invoke' ? [b.term.op] : [])]) if (!this.admits(o.op)) bad.push(`${o.op} in ${fn.name}/${b.name}`);
    return bad;
  }
  toString() { return this.name; }
  yamlTag() { return `profile ${this.name} (${this.sets.join(', ')})`; }
}
function profile(name) {
  if (name instanceof Profile) return name;
  if (!PROFILES[name]) throw new StrataError(`unknown profile ${name}; known: ${Object.keys(PROFILES).join(', ')}`);
  return new Profile(name, PROFILES[name]);
}
profile.define = (name, spec) => { PROFILES[name] = { sets: spec.admits || spec.sets, observes: spec.observes || ['output', 'outcome'] }; return profile(name); };

class Semantics {
  constructor(p = 'js') { this.prof = profile(p); Object.freeze(this); }
  profile(p) { return new Semantics(p); }
  coverage() { return { owned: this.prof.sets, delegated: [], note: 'every reference step in this profile is implemented by the engine itself' }; }
  run(target, opts = {}) {
    const module = toModule(target);
    const bad = this.prof.check(module);
    if (bad.length) return { kind: 'run', mode: 'spec', outcome: { kind: 'error', message: `outside profile ${this.prof.name}: ${bad[0]}` }, output: [], trace: [], events: [], records: [], steps: 0, metrics: {}, error: { message: `outside profile ${this.prof.name}: ${bad.slice(0, 3).join('; ')}` } };
    return runModule(module, { mode: 'spec', budget: opts.steps || 200000, args: opts.args, entry: opts.entry, jobs: opts.jobs });
  }
  yamlTag() { return `semantics (${this.prof.name})`; }
}

function toModule(target) {
  if (target instanceof Module) return target;
  if (target instanceof Fn) return new Module([target], { main: target.name });
  if (target && target.kind === 'program') return target.module;
  if (target && target.kind === 'source') return compile(pipeline().passes([STD_PASSES.frontend, STD_PASSES.promoteCells, STD_PASSES.verify]), target).module;
  if (typeof target === 'string') return toModule(source.text(target));
  throw new StrataError('run takes a function, a module, a program or a source');
}

function refines(target, src, opts = {}) {
  const run = x => (x && x.kind === 'run' ? x : x && x.kind === 'program' ? x.run({ mode: opts.mode || 'spec', gc: opts.gc }) : new Semantics(opts.profile || 'js').run(x, opts));
  const a = run(target), b = run(src);
  const eq = observeEqual(a, b);
  return { ok: eq.equal === true, method: 'one behaviour each (the engine is deterministic)', detail: eq, target: a.output, source: b.output };
}

// ---------------------------------------------------------------- the engine
// One engine owns one execution domain: a heap, the job queues, and the code it admitted.
// Admission is a check before any code runs; code stays until the engine closes.

class AdmissionError extends Error { constructor(m, d) { super(m); this.name = 'AdmissionError'; Object.assign(this, d); } }

class Engine {
  constructor(opts = {}) {
    this.opts = opts; this.mode = opts.mode || 'spec';
    this.machine = new Machine(new Module([]), { mode: this.mode, gc: opts.gc || 'off', budget: opts.budget || 2000000, recordLimit: 0 });
    this.units = []; this.closed = false; this.state = 'ready';
    this.require = opts.strategies || null;
  }
  check() { if (this.closed) { const e = new Error('the engine is closed'); e.name = 'EngineClosed'; throw e; } }
  admit(x) {
    this.check();
    const art = x && x.kind === 'artifact' ? x : x && x.kind === 'program' ? x.artifact : null;
    if (!art) throw new AdmissionError('admit takes a program or an artifact', { reason: 'not an artifact', ranCode: false });
    const prog = art.program;
    if (!prog.ok) throw new AdmissionError(`${prog.name} did not compile: ${(prog.diagnostics.find(d => d.severity === 'error') || {}).message}`, { reason: 'compile errors', ranCode: false });
    if (this.require) for (const [k, v] of Object.entries(this.require)) if (art.requires[k] && String(v) !== art.requires[k] && !art.requires[k].startsWith(String(v))) throw new AdmissionError(`strategy mismatch: ${k} is ${art.requires[k]} in the artifact and ${v} in the engine`, { reason: 'strategy mismatch', field: k, ranCode: false });
    const unit = this.units.length + 1, prefix = `u${unit}.`;
    const rename = new Map(prog.module.names().map(n => [n, prefix + n]));
    const fns = [...prog.module.functions.values()].map(f => {
      const c = f.clone(); c.name = rename.get(f.name);
      for (const b of c.blocks) for (const o of [...b.ops, ...(b.term && b.term.kind === 'invoke' ? [b.term.op] : [])]) if (o.attrs && o.attrs.callee && rename.has(o.attrs.callee)) o.attrs.callee = rename.get(o.attrs.callee);
      return c;
    });
    for (const f of fns) this.machine.module.functions.set(f.name, f);
    for (const [n, p] of Object.entries(prog.st.plans)) {
      const sp = {}; for (const [k, v] of Object.entries(p.safepoints)) sp[k.replace(n + '/', prefix + n + '/')] = v;
      this.machine.plans[prefix + n] = { safepoints: sp, slotOf: p.slotOf, frameSlots: p.frameSlots };
    }
    this.units.push({ unit, name: prog.name, main: prefix + prog.module.main, functions: fns.length, retained: true, codeBytes: fns.reduce((s, f) => s + f.blocks.reduce((k, b) => k + 16 * (b.ops.length + 1), 0), 0) });
    return { kind: 'code', id: unit, name: prog.name, yamlTag: () => `code #${unit} ${prog.name}` };
  }
  evaluateScript(code) {
    this.check();
    const u = this.units[(code.id || code) - 1]; if (!u) throw new Error(`no code ${code.id || code}`);
    this.state = 'executing';
    const outcome = this.machine.runMain(u.main);
    this.state = 'ready';
    return { kind: 'evaluation', state: outcome.kind === 'normal' ? 'fulfilled' : outcome.kind === 'throw' ? 'rejected' : outcome.kind, value: outcome.value !== undefined ? this.machine.display(outcome.value) : undefined, error: outcome.message };
  }
  runJobs({ budget } = {}) { this.check(); const n = budget ? (budget.n !== undefined ? budget.n : budget) : 10000; const r = this.machine.runJobs(n); return { ran: r.ran, remaining: r.remaining !== undefined ? r.remaining : this.machine.microtasks.length + this.machine.timers.length }; }
  run(program, opts = {}) {
    const code = this.admit(program);
    const ev = this.evaluateScript(code);
    const jobsOut = this.runJobs({ budget: opts.budget || jobs(10000) });
    return { state: ev.state, output: this.output(), jobsRun: jobsOut.ran, remaining: jobsOut.remaining, error: ev.error, collections: this.machine.metrics.collections };
  }
  output() { return this.machine.output.slice(); }
  metrics() {
    const m = this.machine.metrics;
    return { code: { admittedUnits: this.units.length, codeBytes: this.units.reduce((s, u) => s + u.codeBytes, 0), retained: this.units.filter(u => u.retained).length },
      heap: { objects: this.machine.heap.size, allocations: m.allocations }, jobs: { ran: m.jobs, pending: this.machine.microtasks.length + this.machine.timers.length }, collections: m.collections, steps: this.machine.steps };
  }
  snapshot() { return { state: this.closed ? 'closed' : this.state, units: this.units.map(({ unit, name, functions, retained }) => ({ unit, name, functions, retained })), globals: [...this.machine.globals.keys()] }; }
  close() { this.check(); this.closed = true; this.state = 'closed'; return 'closed: runtime destroyed, then code released'; }
  yamlTag() { return `[Engine ${this.closed ? 'closed' : this.units.length + ' units'}]`; }
}

// ---------------------------------------------------------------- lifecycle state machines
// Labelled transition systems; a product synchronizes machines on the labels they share.

class LTS {
  constructor(name, trans = new Map(), current = null, finals = [], initial = null) { this.name = name; this.trans = trans; this.current = current; this.finals = finals; this.initial = initial; Object.freeze(this); }
  state(s) { const tr = new Map(this.trans); if (!tr.has(s)) tr.set(s, new Map()); return new LTS(this.name, tr, s, this.finals, this.initial || s); }
  on(label, to) {
    const tr = new Map([...this.trans].map(([k, v]) => [k, new Map(v)]));
    tr.get(this.current).set(label, to); if (!tr.has(to)) tr.set(to, new Map());
    return new LTS(this.name, tr, this.current, this.finals, this.initial);
  }
  final(...ss) { return new LTS(this.name, this.trans, this.current, [...this.finals, ...ss], this.initial); }
  retarget(s, label, to) { return this.state(s).on(label, to); }
  alphabet() { const a = new Set(); for (const m of this.trans.values()) for (const l of m.keys()) a.add(l); return a; }
  yamlTag() { return `machine ${this.name} (${this.trans.size} states)`; }
}
const machine = name => new LTS(name);
machine.product = (...ms) => ({ kind: 'product', machines: ms, invariants: [], invariant(name, pred) { return { ...this, invariants: [...this.invariants, { name, pred }] }; }, yamlTag() { return `product of ${ms.map(m => m.name).join(', ')}`; } });

function checkMachine(prod, { depth = 12 } = {}) {
  const ms = prod.machines, alpha = ms.map(m => m.alphabet());
  const labels = new Set(alpha.flatMap(a => [...a]));
  const start = ms.map(m => m.initial), key = s => s.join('|');
  const seen = new Map([[key(start), null]]), queue = [[start, []]];
  let transitions = 0;
  const view = s => Object.fromEntries(ms.map((m, i) => [m.name, s[i]]));
  while (queue.length) {
    const [s, path] = queue.shift();
    for (const inv of prod.invariants) if (!inv.pred(view(s))) return { ok: false, violated: inv.name, trace: path, state: view(s), states: seen.size };
    if (path.length >= depth) continue;
    for (const l of labels) {
      const next = s.slice(); let possible = true, moved = false;
      ms.forEach((m, i) => {
        if (!alpha[i].has(l)) return;
        const to = m.trans.get(s[i]) && m.trans.get(s[i]).get(l);
        if (to === undefined) possible = false; else { next[i] = to; moved = true; }
      });
      if (!possible || !moved) continue;
      transitions++;
      if (!seen.has(key(next))) { seen.set(key(next), s); queue.push([next, [...path, `${l} → ${ms.map((m, i) => next[i]).join(', ')}`]]); }
    }
  }
  return { ok: true, states: seen.size, transitions };
}

// ---------------------------------------------------------------- laws, generators, shrinking
// A law is a property checked on generated inputs; a failure comes back with the
// smallest counterexample the shrinker found.

function sampleBehaviour(r) {
  const pickSome = list => list.filter(() => r.chance(0.3));
  if (r.chance(0.08)) return fx.unknown;
  return new Behaviour({ reads: pickSome(USER_RESOURCES), writes: pickSome(USER_RESOURCES), fresh: r.chance(0.3), throws: r.chance(0.3), diverges: r.chance(0.15), callsUser: r.chance(0.1), host: r.chance(0.1) ? ['print'] : [] });
}

const law = {
  vectorSpace(unit, { samples = 1000, seed = 1 } = {}) {
    const r = rng(seed);
    for (let i = 0; i < samples; i++) {
      const a = unit(r.int(-1000, 1000)), b = unit(r.int(-1000, 1000)), c = unit(r.int(-1000, 1000)), k = r.int(-9, 9);
      if (!a.add(b).add(c).eq(a.add(b.add(c))) || !a.add(b).eq(b.add(a)) || !a.add(b).mul(k).eq(a.mul(k).add(b.mul(k)))) return { name: `vectorSpace(${unit.unitName})`, ok: false, samples: i + 1, counterexample: { a, b, c, k } };
    }
    return { name: `vectorSpace(${unit.unitName})`, ok: true, samples };
  },
  lattice(L, { samples = 2000, seed = 1, universe } = {}) {
    // Join-semilattice laws by sampling: commutative, associative, idempotent, and the
    // order agreeing with join (a ⊑ b exactly when a ⊔ b = b). Meet absorption if there is a meet.
    const r = rng(seed);
    const isTypes = L === t || L.parse || (L && L.name === 'types');
    const J = isTypes ? (a, b) => a.join(b) : L.join, LE = isTypes ? (a, b) => a.le(b) : L.le, EQ = isTypes ? (a, b) => a.eq(b) : L.eq;
    const M = isTypes ? (a, b) => a.meet(b) : L.meet;
    const show = isTypes ? String : (L.show || String);
    let sample;
    if (isTypes) sample = () => Type.of(r.int(0, (1 << KINDS.length) - 1));
    else if (L.name === 'powerset') { const U = [...(universe || L.universe || ['a', 'b', 'c', 'd'])]; sample = () => new Set(U.filter(() => r.chance(0.5))); }
    else if (L.name === 'flat') { const vs = L.values.length ? L.values : [0, 1, 2]; sample = () => (r.chance(0.15) ? L.BOT : r.chance(0.15) ? L.TOP : r.pick(vs)); }
    else if (L.name === 'interval') sample = () => (r.chance(0.1) ? null : (x => [x, x + r.int(0, 20)])(r.int(-20, 20)));
    else if (L.sample) sample = () => L.sample(r);
    else throw new StrataError(`law.lattice: no way to sample ${L.name || 'this lattice'}; give it a sample(rng) function`);
    const name = `lattice(${isTypes ? 'types' : L.name})`;
    for (let i = 0; i < samples; i++) {
      const a = sample(), b = sample(), c = sample();
      const checks = [['commutative', EQ(J(a, b), J(b, a))], ['associative', EQ(J(J(a, b), c), J(a, J(b, c)))], ['idempotent', EQ(J(a, a), a)],
        ['order agrees with join', LE(a, b) === EQ(J(a, b), b)]];
      if (M) checks.push(['meet absorbs join', EQ(M(a, J(a, b)), a)]);
      const bad = checks.find(([, ok]) => !ok);
      if (bad) return { name, ok: false, samples: i + 1, counterexample: { law: bad[0], a: show(a), b: show(b), c: show(c) } };
    }
    return { name, ok: true, samples };
  },
  join(F = fx, { samples = 2000, seed = 1 } = {}) {
    const r = rng(seed);
    for (let i = 0; i < samples; i++) {
      const a = sampleBehaviour(r), b = sampleBehaviour(r), c = sampleBehaviour(r);
      const bad = [['associative', a.join(b).join(c).eq(a.join(b.join(c)))], ['commutative', a.join(b).eq(b.join(a))], ['idempotent', a.join(a).eq(a)],
        ['unit none', a.join(fx.none).eq(a)], ['top unknown', a.join(fx.unknown).eq(fx.unknown)]].find(([, ok]) => !ok);
      if (bad) return { name: 'join(fx)', ok: false, samples: i + 1, counterexample: { law: bad[0], a: String(a), b: String(b), c: String(c) } };
    }
    return { name: 'join(fx)', ok: true, samples, note: 'associative, commutative, idempotent; none is the unit, unknown the top' };
  },
  antitone(P = null, { samples = 5000, seed = 1 } = {}) {
    const r = rng(seed);
    for (let i = 0; i < samples; i++) {
      const a = sampleBehaviour(r), b = a.join(sampleBehaviour(r));
      const pa = derivePermissions(a), pb = derivePermissions(b);
      const bad = PERMS.find(k => PERM_RANK(pb[k]) > PERM_RANK(pa[k]));
      if (bad) return { name: 'antitone(perm)', ok: false, samples: i + 1, counterexample: { permission: bad, smaller: String(a), larger: String(b), smallerSays: pa[bad], largerSays: pb[bad] } };
    }
    return { name: 'antitone(perm)', ok: true, samples, note: 'more behaviour never grants a permission' };
  },
  monotone(an, { samples = 500, seed = 1, corpus } = {}) {
    const r = rng(seed);
    const fns = (corpus || [gen.coreIR({ seed }), gen.coreIR({ seed: seed + 1 })]).map(x => (x instanceof Fn ? x : toModule(x).fn(toModule(x).main)));
    const rule = an.edgeRule || edgeRules.substituteBlockArgs();
    for (let i = 0; i < samples; i++) {
      const fn = r.pick(fns), b = r.pick(fn.blocks), universe = fn.values();
      const x = new Set(universe.filter(() => r.chance(0.3))), y = new Set([...x, ...universe.filter(() => r.chance(0.3))]);
      const f = s => (an.opTransfer ? b.ops.slice().reverse().reduce((acc, o) => an.opTransfer(o, acc, { fn, block: b }), s) : livenessBlock(fn, b, s, () => new Set(), rule));
      const fx1 = f(x), fy = f(y);
      if (![...fx1].every(v => fy.has(v))) return { name: `monotone(${an.name})`, ok: false, samples: i + 1, counterexample: { block: `${fn.name}/${b.name}`, x: [...x].sort(), y: [...y].sort(), fx: [...fx1].sort(), fy: [...fy].sort(), violation: 'x ⊑ y but f(x) ⋢ f(y)' } };
    }
    return { name: `monotone(${an.name})`, ok: true, samples };
  },
  refines(target, { corpus = [], samples = 0, seed = 1, mode, gc = 'stress', pipeline: base } = {}) {
    const items = [...corpus.map(c => (typeof c === 'string' ? source.text(c) : c))];
    for (let i = 0; i < samples; i++) items.push(gen.js({ seed: seed + i }));
    const name = target instanceof Rewrite ? `refines(${target.name})` : target && target.kind === 'rewrites' ? `refines(${target.names.join(' + ') || 'no rewrites'})`
      : target instanceof Pipeline ? 'refines(pipeline plan)' : `refines(${target})`;
    let checked = 0;
    for (const item of items) {
      const verdict = refinesOne(target, item, { mode, gc, base });
      checked++;
      if (!verdict.ok) {
        let minimized = null;
        if (item.statements) {
          const small = shrink(item.statements, sts => !refinesOne(target, gen.fromStatements(sts), { mode, gc, base }).ok);
          minimized = gen.fromStatements(small).text;
        }
        return { name, ok: false, samples: checked, counterexample: { source: item.text, before: verdict.before, after: verdict.after, detail: verdict.detail }, minimized };
      }
    }
    return { name, ok: true, samples: checked, note: 'spec run before and after compared observation by observation' };
  },
  idempotent(set = rewrites.canonical(), { corpus, seed = 1, samples = 50 } = {}) {
    const items = corpus || Array.from({ length: samples }, (_, i) => gen.coreIR({ seed: seed + i }));
    for (const item of items) {
      const fns = item instanceof Fn ? [item] : [...toModule(item).functions.values()];
      for (const f0 of fns) {
        const once = f0.clone(); runRewrites(once, set);
        const twice = once.clone(); runRewrites(twice, set);
        if (once.hash() !== twice.hash()) return { name: 'idempotent(rewrites)', ok: false, counterexample: { fn: f0.name, once: printFn(once), twice: printFn(twice) } };
      }
    }
    return { name: 'idempotent(rewrites)', ok: true, samples: items.length };
  },
  roundTrip({ samples = 100, seed = 1 } = {}) {
    for (let i = 0; i < samples; i++) {
      const f = gen.coreIR({ seed: seed + i });
      const back = parseIR(printFn(f));
      if (back.hash() !== f.hash()) return { name: 'roundTrip(text)', ok: false, samples: i + 1, counterexample: { printed: printFn(f), reparsed: printFn(back) } };
      const viaJSON = fnFromJSON(JSON.parse(JSON.stringify(fnToJSON(f))));
      if (viaJSON.hash() !== f.hash()) return { name: 'roundTrip(json)', ok: false, samples: i + 1 };
    }
    return { name: 'roundTrip(text and JSON)', ok: true, samples };
  },
  variant(variant, general, { samples = 3000, seed = 1, values } = {}) {
    const v = typeof variant === 'string' ? lookupOp(variant) : variant.def || variant, gdef = typeof general === 'string' ? lookupOp(general) : general.def || general;
    const r = rng(seed), m = new Machine(new Module([]));
    const pool = values || [0, -0, 1, -1, 0.5, 2 ** 31 - 1, -(2 ** 31), 2 ** 53, NaN, Infinity, -Infinity, 1e-300, 3, 7];
    for (let i = 0; i < samples; i++) {
      const args = v.operands.map(ty => (ty.le(t.number) ? (ty.le(t.int32) ? r.int(-2147483648, 2147483647) : r.pick(pool)) : ty.le(t.boolean) ? r.chance(0.5) : r.pick(pool)));
      let a, b;
      try { a = v.step(m, args, { attrs: {} }); } catch (e) { a = 'throws'; }
      try { b = gdef.step(m, args, { attrs: {} }); } catch (e) { b = 'throws'; }
      if (!Object.is(a, b)) return { name: `variant(${v.name} of ${gdef.name})`, ok: false, samples: i + 1, counterexample: { args, variant: a, general: b } };
    }
    return { name: `variant(${v.name} of ${gdef.name})`, ok: true, samples, note: `operands drawn from ${v.operands.join(', ')}` };
  },
  declared(set, opts = {}) {
    const out = [];
    for (const d of set.defs.values()) {
      if (d.laws.commutative) out.push(law.algebra(d, 'commutative', opts));
      if (d.laws.associative) out.push(law.algebra(d, 'associative', opts));
    }
    return { name: `declared(${set.name})`, ok: out.every(x => x.ok), results: out };
  },
  algebra(d, which, { samples = 2000, seed = 1 } = {}) {
    const r = rng(seed), m = new Machine(new Module([]));
    const val = () => (d.operands[0].le(t.int32) ? r.int(-2147483648, 2147483647) : r.pick([0.1, 0.2, 0.3, 1e16, -1e16, 1, 3, -0, 0.5]));
    for (let i = 0; i < samples; i++) {
      const a = val(), b = val(), c = val(), f = (x, y) => d.step(m, [x, y], { attrs: {} });
      const ok = which === 'commutative' ? Object.is(f(a, b), f(b, a)) : Object.is(f(f(a, b), c), f(a, f(b, c)));
      if (!ok) return { name: `${which}(${d.name})`, ok: false, samples: i + 1, counterexample: { a, b, c, left: which === 'commutative' ? f(a, b) : f(f(a, b), c), right: which === 'commutative' ? f(b, a) : f(a, f(b, c)) } };
    }
    return { name: `${which}(${d.name})`, ok: true, samples };
  },
};

function refinesOne(target, item, { mode, gc, base } = {}) {
  const p0 = (base || pipeline()).rewrites(rewrites.none());
  const before = compile(p0, item).run({ mode: 'spec' });
  let after;
  if (target instanceof Rewrite || (target && target.kind === 'rewrites')) after = compile(p0.rewrites(target instanceof Rewrite ? rewriteSet(target) : target), item).run({ mode: 'spec' });
  else if (target instanceof Pipeline) after = compile(target, item).run({ mode: mode || 'plan', gc });
  else if (target instanceof Strategy) after = compile(p0.roots(target), item).run({ mode: 'plan', gc });
  else throw new StrataError('refines takes a rewrite, a rewrite set, a pipeline or a root strategy');
  if (before.outcome.kind === 'error') return { ok: true, skipped: true };
  const eq = observeEqual(after, before);
  return { ok: eq.equal === true, before: before.output.concat(before.outcome.kind === 'throw' ? ['(uncaught ' + before.outcome.display + ')'] : []), after: after.output.concat(after.outcome.kind === 'throw' ? ['(uncaught ' + after.outcome.display + ')'] : after.outcome.kind === 'error' ? ['(error: ' + after.outcome.message + ')'] : []), detail: eq };
}

// Delta debugging, one statement at a time: drop each statement while the failure stays.
function shrink(items, fails) {
  let cur = items.slice(), changed = true;
  while (changed) {
    changed = false;
    for (let i = 0; i < cur.length; i++) {
      const trial = cur.slice(0, i).concat(cur.slice(i + 1));
      if (trial.length && fails(trial)) { cur = trial; changed = true; break; }
    }
  }
  return cur;
}

const gen = {
  // Random numeric core IR: arithmetic, a diamond, a bounded loop, prints.
  coreIR({ seed = 1, size = 6 } = {}) {
    const r = rng(seed);
    return fnBuilder(`gen${seed}`, { a: t.number, b: t.number }, t.number, (f, { a, b }) => {
      const pickOp = () => r.pick(['num.add', 'num.sub', 'num.mul']);
      let vals = [a, b];
      f.entry($ => {
        for (let i = 0; i < r.int(1, size); i++) vals.push($.op(pickOp(), r.pick(vals), r.chance(0.3) ? $.const(r.int(-3, 9)) : r.pick(vals)));
        const c = $.op('num.lt', r.pick(vals), r.pick(vals));
        $.branch(c, f.to('left', r.pick(vals)), f.to('right', r.pick(vals)));
      });
      f.block('left', { x: t.number }, ($, { x }) => $.jump(f.to('loop', $.const(0), $.op(pickOp(), x, $.const(r.int(1, 5))))));
      f.block('right', { y: t.number }, ($, { y }) => $.jump(f.to('loop', $.const(0), y)));
      f.block('loop', { i: t.number, acc: t.number }, ($, { i, acc }) => $.branch($.op('num.lt', i, $.const(r.int(1, 4))), f.to('body', i, acc), f.to('done', acc)));
      f.block('body', { i: t.number, acc: t.number }, ($, { i, acc }) => {
        const nacc = $.op(pickOp(), acc, r.chance(0.5) ? i : $.const(r.int(1, 3)));
        if (r.chance(0.5)) $.op('host.print', nacc);
        $.jump(f.to('loop', $.op('num.add', i, $.const(1)), nacc));
      });
      f.block('done', { z: t.number }, ($, { z }) => { $.op('host.print', z); $.ret(z); });
    });
  },
  // Random JavaScript statements over a few templates, kept as a list so they can shrink.
  js({ seed = 1, size = 7 } = {}) {
    const r = rng(seed), sts = [];
    sts.push('let cell = { n: 0 };');
    sts.push(`const r = { get x() { cell.n += 1; ${r.chance(0.5) ? 'throw cell;' : 'return cell.n;'} } };`);
    const pool = [
      () => `try { r.x; } catch (e) { print('caught', e === cell, cell.n); }`,
      () => `print(cell.n + ${r.int(1, 9)});`,
      () => `let k${r.int(0, 99)} = [1, 2, 3].length + cell.n;`,
      () => `for (let i = 0; i < ${r.int(1, 4)}; i++) { cell.n = cell.n + i; }`,
      () => `const f${r.int(0, 99)} = () => cell.n * 2; print(f${0}());`.replace(/f(\d+) = /, 'f0 = '),
      () => `queueMicrotask(() => print('job', cell.n));`,
      () => `if (cell.n > ${r.int(0, 3)}) { print('big'); } else { print('small'); }`,
      () => `try { r.x; print('no throw'); } finally { print('finally', cell.n); }`,
    ];
    for (let i = 0; i < size; i++) sts.push(r.pick(pool)());
    return gen.fromStatements(sts);
  },
  fromStatements(sts) { return { kind: 'source', lang: 'js', name: 'generated.js', text: sts.join('\n'), statements: sts.slice() }; },
  values() { return [0, -0, 1, -1, 0.5, NaN, Infinity, 2 ** 31, '', 'a', '1', true, false, null, undefined]; },
};

// ---------------------------------------------------------------- designs, objectives, search

class Param { constructor(values, opts = {}) { this.values = values; this.def = opts.default; this.when = opts.when || null; Object.freeze(this); } }
const param = {
  choice: (values, opts = {}) => new Param(values, opts),
  range: (lo, hi, { step = 1, ...opts } = {}) => { const v = []; for (let x = lo; x <= hi + 1e-9; x += step) v.push(round(x, 6)); return new Param(v, opts); },
};

class Design {
  constructor(params, fn, opts = {}) { this.params = params; this.fn = fn; this.constraints = opts.constraints || []; this.objective = opts.objective || null; this.kind = 'design'; Object.freeze(this); }
  defaults() { const o = {}; for (const [k, p] of Object.entries(this.params)) if (!p.when || p.when(o)) o[k] = p.def !== undefined ? p.def : p.values[(p.values.length - 1) >> 1]; return o; }
  points() {
    let out = [{}];
    for (const [k, p] of Object.entries(this.params)) {
      const next = [];
      for (const pt of out) { if (p.when && !p.when(pt)) next.push(pt); else for (const v of p.values) next.push({ ...pt, [k]: v }); }
      out = next;
    }
    return out.filter(pt => this.constraints.every(c => c(pt, this)));
  }
  size() {
    const raw = Object.values(this.params).reduce((n, p) => n * p.values.length, 1);
    return { raw, points: this.points().length };
  }
  at(pt = {}) { return this.fn({ ...this.defaults(), ...pt }); }
  where(pred) { return new Design(this.params, this.fn, { constraints: [...this.constraints, pred], objective: this.objective }); }
  map(f) { return new Design(this.params, p => f(this.fn(p)), { constraints: this.constraints, objective: this.objective }); }
  sample({ n = 4, seed = 1 } = {}) { const r = rng(seed), pts = this.points(); return Array.from({ length: Math.min(n, pts.length) }, () => pts.splice(Math.floor(r() * pts.length), 1)[0]); }
  yamlTag() { return `design (${this.points().length} points)`; }
}
const design = (params, fn, opts) => new Design(params, fn, opts);
const constraint = { compatible: () => (pt, d) => { const p = d.fn({ ...d.defaults(), ...pt }); return p.check().ok; } };

const METRICS = {
  steps: { dir: 'min', unit: 'steps', of: r => r.run.steps }, collections: { dir: 'min', unit: 'count', of: r => r.run.metrics.collections || 0 },
  rootSlots: { dir: 'min', unit: 'slots', of: r => r.program.metrics().rootSlots }, maxFrameSlots: { dir: 'min', unit: 'slots', of: r => r.program.metrics().maxFrameSlots },
  peakLive: { dir: 'min', unit: 'slots', of: r => r.program.metrics().peakLive }, peakRootSlots: { dir: 'min', unit: 'slots', of: r => r.run.metrics.peakRootSlots || 0 },
  rootBytes: { dir: 'min', unit: 'B', of: r => r.run.metrics.rootBytes || 0 }, compileMs: { dir: 'min', unit: 'ms', of: r => r.program.compileMs },
  ops: { dir: 'min', unit: 'count', of: r => r.program.metrics().ops }, rewritesFired: { dir: 'max', unit: 'count', of: r => r.program.metrics().rewritesFired },
};
const metric = (name, of, opts = {}) => { METRICS[name] = { dir: opts.dir || 'min', unit: opts.unit || '', of, about: opts.about }; return name; };
metric.list = () => Object.entries(METRICS).map(([k, m]) => `${k} (${m.dir}, ${m.unit})`);

const objective = {
  require: (...checks) => ({ kind: 'objective', requires: checks, then(o) { return { ...o, requires: checks, label: `${o.label}, requiring ${checks.join(', ')}` }; }, key: () => 0, label: `feasibility: ${checks.join(', ')}` }),
  minimize: m => ({ kind: 'objective', label: `minimize ${m}`, key: row => row[m] }),
  maximize: m => ({ kind: 'objective', label: `maximize ${m}`, key: row => -row[m] }),
  weighted: w => ({ kind: 'objective', label: 'weighted ' + Object.entries(w).map(([k, v]) => `${v}·${k}`).join(' + '), key: row => Object.entries(w).reduce((s, [k, v]) => s + (Array.isArray(v) ? v[0] * row[k] / (v[1] && v[1].per ? v[1].per.n || v[1].per : 1) : v * row[k]) * (METRICS[k] && METRICS[k].dir === 'max' ? -1 : 1), 0) }),
  lexicographic: list => ({ kind: 'objective', label: 'lexicographic ' + list.map(x => (Array.isArray(x) ? x[0] : x)).join(' then '), compare: (a, b) => {
    for (const item of list) {
      const [k, o] = Array.isArray(item) ? item : [item, {}];
      const tol = o.tolerance ? (o.tolerance.n !== undefined ? o.tolerance.n : o.tolerance) : 0;
      const d = (a[k] - b[k]) * (METRICS[k] && METRICS[k].dir === 'max' ? -1 : 1);
      if (Math.abs(d) > tol) return d;
    }
    return 0;
  } }),
  pareto: ms => ({ kind: 'objective', label: 'pareto ' + ms.join(', '), pareto: ms }),
};

function feasible(row, requires = []) {
  for (const c of requires) {
    if (c === 'correct' && !row.correct) return { ok: false, reason: 'output differs from the specification' };
    if (c === 'admitted' && !row.admitted) return { ok: false, reason: row.reason || 'did not compile' };
    if (typeof c === 'function' && !c(row)) return { ok: false, reason: 'a requirement failed' };
  }
  return { ok: true };
}

function rank(results, obj) {
  const rows = results.rows.map(r => ({ ...r, feasible: r.feasible !== false && feasible(r, obj.requires || []).ok }));
  const ok = rows.filter(r => r.feasible), bad = rows.filter(r => !r.feasible);
  if (obj.pareto) {
    // Each metric in its own direction (rewritesFired is better larger). The frontier comes
    // first, marked onFrontier, then the dominated points, then the infeasible ones.
    const sign = m => (METRICS[m] && METRICS[m].dir === 'max' ? -1 : 1);
    const dom = (a, b) => obj.pareto.every(m => sign(m) * a[m] <= sign(m) * b[m]) && obj.pareto.some(m => sign(m) * a[m] < sign(m) * b[m]);
    const frontier = ok.filter(a => !ok.some(b => dom(b, a)));
    const rest = ok.filter(r => !frontier.includes(r));
    const ranked = [...frontier.map(r => ({ ...r, onFrontier: true })), ...rest.map(r => ({ ...r, onFrontier: false })), ...bad.map(r => ({ ...r, onFrontier: false }))];
    return { ranked, frontier: frontier.map(r => r.point) };
  }
  ok.sort(obj.compare || ((a, b) => obj.key(a) - obj.key(b)));
  const ranked = [...ok, ...bad];
  ranked.best = ok[0]; return ranked;
}
rank.disagreement = (results, a, b) => {
  const ra = rank(results, a), rb = rank(results, b);
  return { [a.label]: ra.map(r => r.point), [b.label]: rb.map(r => r.point), winners: { first: ra[0] && ra[0].point, second: rb[0] && rb[0].point }, disagree: !!(ra[0] && rb[0] && ra[0].point !== rb[0].point) };
};

const label = pt => Object.entries(pt).map(([k, v]) => `${k}=${v instanceof Quantity ? v : typeof v === 'object' && v !== null ? (v.name || JSON.stringify(v)) : v}`).join(' ');

function evaluatePoint(pipe, corpus, runOpts = {}) {
  const agg = { admitted: true, correct: true, steps: 0, collections: 0, rootSlots: 0, maxFrameSlots: 0, peakLive: 0, peakRootSlots: 0, rootBytes: 0, compileMs: 0, ops: 0, rewritesFired: 0 };
  for (const item of corpus) {
    const program = compile(pipe, item);
    if (!program.ok) { agg.admitted = false; agg.reason = (program.diagnostics.find(d => d.severity === 'error') || {}).message; continue; }
    const run = program.run({ mode: runOpts.mode || 'plan', gc: runOpts.gc || 'stress' });
    const spec = program.run({ mode: 'spec' });
    if (observeEqual(run, spec).equal !== true) agg.correct = false;
    for (const [k, m] of Object.entries(METRICS)) { const v = m.of({ program, run }); agg[k] = (k === 'maxFrameSlots' || k === 'peakLive' || k === 'peakRootSlots' || k === 'rootBytes') ? Math.max(agg[k] || 0, v) : (agg[k] || 0) + v; }
  }
  agg.compileMs = round(agg.compileMs, 2);
  return agg;
}

const search = {
  grid(d, { corpus = [], objective: obj, run } = {}) {
    obj = obj || d.objective || objective.minimize('steps');
    const rows = d.points().map(pt => ({ point: label(pt), params: pt, ...evaluatePoint(d.at(pt), corpus, run) }));
    return makeResults(rows, obj, `grid over ${Object.keys(d.params).join(', ')}`);
  },
  random(d, { budget = 6, seed = 1, ...rest } = {}) {
    const pts = d.sample({ n: budget, seed });
    const obj = rest.objective || d.objective || objective.minimize('steps');
    return makeResults(pts.map(pt => ({ point: label(pt), params: pt, ...evaluatePoint(d.at(pt), rest.corpus || [], rest.run) })), obj, `random sample of ${budget}`);
  },
};

function makeResults(rows, obj, title) {
  const ranked = rank({ rows }, obj);
  const best = Array.isArray(ranked) ? ranked.best : ranked.ranked[0];
  const columns = [{ key: 'point', label: 'point' }, { key: 'feasible', label: 'feasible' }, { key: 'admitted', label: 'admitted' }, { key: 'correct', label: 'correct' },
    ...['rootSlots', 'maxFrameSlots', 'peakLive', 'collections', 'steps', 'compileMs'].map(k => ({ key: k, label: k, unit: METRICS[k].unit }))];
  const list = Array.isArray(ranked) ? ranked : ranked.ranked;
  return { kind: 'results', title, objective: obj.label || 'objective', columns, rows: list.map(r => ({ ...r, params: undefined })), best: best ? best.point : null,
    frontier: ranked.frontier, note: `ranked by ${obj.label || 'objective'}; infeasible points last`, table() { return this.rows; } };
}

function table(rows, { title = 'table', columns } = {}) {
  const cols = columns || Object.keys(rows[0] || {}).map(k => ({ key: k, label: k }));
  return { kind: 'results', title, columns: cols.map(c => (typeof c === 'string' ? { key: c, label: c } : c)), rows, note: '' };
}

// ---------------------------------------------------------------- decision records and processes

class Decision {
  constructor(spec) { Object.assign(this, { question: '', ctx: '', opts: [], ev: [], sought: null, chosen: null, overturn: null, st: 'proposed' }, spec); Object.freeze(this); }
  _w(p) { return new Decision({ ...this, ...p }); }
  context(s) { return this._w({ ctx: s }); }
  options(o) { return this._w({ opts: o }); }
  evidence(e) { return this._w({ ev: e }); }
  counterexampleSought(s) { return this._w({ sought: s }); }
  choose(c) { return this._w({ chosen: c }); }
  overturnIf(s) { return this._w({ overturn: s }); }
  status(s) { return this._w({ st: s }); }
  check() {
    const issues = [];
    if (this.opts.length < 2) issues.push('fewer than two options compared');
    if (!this.ev.length) issues.push('no evidence');
    if (!this.sought) issues.push('no counterexample sought');
    if (!this.chosen) issues.push('nothing chosen');
    if (!this.overturn) issues.push('nothing would overturn it');
    return { ok: !issues.length, issues };
  }
  toJSON() { return { question: this.question, status: this.st, context: this.ctx, options: this.opts, evidence: this.ev, counterexampleSought: this.sought, choice: this.chosen, overturnIf: this.overturn }; }
  toYAML() { return this.toJSON(); }
}
const decision = q => new Decision({ question: q });

class Process {
  constructor(name, steps = [], meta = {}) { this.name = name; this.steps = steps; this.meta = meta; Object.freeze(this); }
  _add(kind, name, spec = {}) { return new Process(this.name, [...this.steps, { kind, name, ...spec }], this.meta); }
  step(n, s) { return this._add('step', n, s); }
  diverge(n, s) { return this._add('diverge', n, s); }
  converge(n, s) { return this._add('converge', n, s); }
  critique(n, s) { return this._add('critique', n, s); }
  loop(n, s) { return this._add('loop', n, s); }
  check({ requires = [] } = {}) {
    const produced = this.steps.flatMap(s => [].concat(s.produces || [])).map(p => (p instanceof Decision ? p.question : typeof p === 'string' ? p : p && p.name));
    const issues = requires.filter(r => !produced.includes(r)).map(r => `no step produces "${r}"`);
    for (const s of this.steps) if (s.kind === 'diverge' && !this.steps.some(c => c.kind === 'converge' && c.name === s.name)) issues.push(`"${s.name}" diverges and never converges`);
    return { ok: !issues.length, issues, steps: this.steps.length };
  }
  toYAML() { return { name: this.name, steps: this.steps.map(s => `${s.kind} ${s.name}${s.week ? ' (week ' + s.week + ')' : ''}`) }; }
}
const process_ = (name, meta) => new Process(name, [], meta || {});

// ---------------------------------------------------------------- running a preset's script

async function runScript(code, scope, { timeoutMs = 25000 } = {}) {
  const logs = [];
  const log = (...xs) => logs.push(xs.map(x => (typeof x === 'string' ? x : toYAML(x).replace(/\n/g, ' '))).join(' '));
  const sc = { ...scope, log, console: { log, warn: (...x) => log('warn:', ...x), error: (...x) => log('error:', ...x) } };
  const names = Object.keys(sc).filter(k => /^[A-Za-z_$][\w$]*$/.test(k));
  const t0 = now();
  let timer = null;
  try {
    const f = new Function(...names, '"use strict";\nreturn (async () => {\n' + code + '\n})();\n//# sourceURL=main.js');
    const value = await Promise.race([f(...names.map(k => sc[k])), new Promise((_, rej) => { timer = setTimeout(() => rej(new Error(`main.js timed out after ${timeoutMs / 1000} s`)), timeoutMs); })]);
    clearTimeout(timer);
    return { ok: true, ms: round(now() - t0, 1), value, logs };
  } catch (e) {
    clearTimeout(timer);
    const m = /main\.js:(\d+)/.exec(e.stack || '');
    return { ok: false, ms: round(now() - t0, 1), logs, error: { message: e.message, line: m ? Number(m[1]) - 2 : null, name: e.name } };
  }
}

function presetScope(files = {}, { log } = {}) {
  return {
    g, strata: root.strata, bytes, kib, mib, slots, jobs, ms, count, t,
    files: Object.freeze({ ...files }),
    source: (name = 'program.js') => {
      if (files[name] === undefined) throw new StrataError(`no file ${name} in this preset`);
      return source.text(files[name], { name });
    },
    print: (...xs) => (log ? log(...xs) : undefined),
  };
}

function classify(value) {
  if (!value || typeof value !== 'object') return { other: value };
  if (value.kind === 'program') return { program: value };
  if (value.kind === 'run') return { run: value };
  if (value.kind === 'laws') return { laws: value };
  if (value.kind === 'results') return { results: value };
  if (value.name && typeof value.ok === 'boolean' && (value.samples !== undefined || value.counterexample)) return { laws: { kind: 'laws', laws: [value] } };
  const out = {};
  for (const k of ['program', 'run', 'laws', 'results']) if (value[k]) out[k] = value[k];
  if (out.laws && Array.isArray(out.laws)) out.laws = { kind: 'laws', laws: out.laws };
  if (out.results && Array.isArray(out.results)) out.results = table(out.results);
  if (!Object.keys(out).length) out.other = value;
  else { const rest = Object.fromEntries(Object.entries(value).filter(([k]) => !['program', 'run', 'laws', 'results'].includes(k))); if (Object.keys(rest).length) out.other = rest; }
  return out;
}

// ---------------------------------------------------------------- the g namespace

const opApi = Object.assign(name => opBuilder(name), {
  narrow: narrowOp,
  opaque: (name, attrs = {}) => new OpDef({ name, variadic: true, results: [t.any], behaviour: fx.unknown, obligations: ob.join(ob.mayCollect, ob.nonlocalThrow, ob.writeBarrier), about: 'an opaque escape: behaviour unknown, every obligation assumed' }),
});
const permApi = Object.assign((op, facts) => permsOf(op, facts), {
  explain: (op, which, facts = {}) => { const p = permsOf(op, facts); return { allowed: p[which], because: p.because[which], note: which === 'erase' ? 'an unused result alone is not sufficient' : undefined }; },
  commute: (a, b) => {
    const A = (typeof a === 'string' ? lookupOp(a) : a.def || a).behaviour, B = (typeof b === 'string' ? lookupOp(b) : b.def || b).behaviour;
    const clash = [...A.writes].filter(r => B.writes.has(r) || B.reads.has(r)).concat([...B.writes].filter(r => A.reads.has(r)));
    if (A.callsUser || B.callsUser) return { allowed: false, because: 'one of them may run user code' };
    if (clash.length) return { allowed: false, because: `they conflict on ${[...new Set(clash)].join(', ')}` };
    if (A.throws && B.throws) return { allowed: false, because: 'both may throw: swapping changes which error escapes' };
    return { allowed: true, because: 'no shared resource is written' };
  },
});

const g = {
  version: VERSION,
  t, rep, fx, ob, lit,
  ops, opsets, op: opApi, opset: Object.assign((name, meta) => new OpSet(name, [], meta), { union: opsetUnion }), perm: permApi,
  contract: { table: list => list.map(d => { const x = typeof d === 'string' ? lookupOp(d) : d.def || d; const p = derivePermissions(x.behaviour); return { op: x.name, behaviour: String(x.behaviour), obligations: String(x.obligations), permissions: PERMS.filter(k => p[k] === true).join(', ') || (PERMS.some(k => p[k] !== false) ? 'conditional' : 'none') }; }) },
  resource: (name, { within } = {}) => name,
  fn: fnBuilder, module: (...fns) => new Module(fns), ir: { parse: parseIR, text: x => (x instanceof Module ? x.toString() : printFn(x)), json: { encode: x => JSON.stringify(fnToJSON(x)), decode: s => fnFromJSON(JSON.parse(s)) } },
  verify, dominators,
  semantics: () => new Semantics('js'), profile, observe: { equal: observeEqual }, refines,
  lattice, analysis: Object.assign(analysisBuilder, analyses), solve, edge: edgeRules, widen, graph,
  rewrite, rewrites, act, pass: Object.assign(pass, { ...Object.fromEntries(Object.entries(STD_PASSES)) }), pipeline, compile, source,
  promoteCells: fn => promoteCells(fn),
  roots, exceptions, representation, compat, strategy: { name: (s, n) => new Strategy(s.slot, n, s.params, s.fnImpl, s.wraps) },
  lower: { bindings: bindOps, plan: planFunction, needsRoot },
  llvm: { orc: (o = {}) => ({ name: 'llvm.orc', target: o.target || 'x86_64-linux-gnu' }), aot: (o = {}) => ({ name: 'llvm.aot', target: o.target || 'x86_64-linux-gnu', output: o.output }), check: checkLLVM },
  target: { host64: 'x86_64-linux-gnu', linuxX64: 'x86_64-linux-gnu', riscv32: 'riscv32-unknown-elf' },
  wasm: { encode: encodeWasm, eligible: wasmEligible },
  layout, limit: (name, spec) => ({ name, ...spec, check: x => { const m = spec.measure(x); return { ok: m.le(spec.max), measured: String(m), max: String(spec.max), asBytes: m.unit === 'slots' ? { measured: String(layout.host64.bytes(m)), max: String(layout.host64.bytes(spec.max)) } : undefined }; } }),
  engine: (opts) => new Engine(opts), machine, check: { machine: checkMachine },
  law, laws: list => ({ kind: 'laws', laws: list.flatMap(x => (x.results ? [x, ...x.results] : [x])) }), gen, shrink,
  design, param, constraint, metric, metrics: { list: metric.list }, objective, rank, search, table,
  decision, process: process_,
  hermes: { provider: set => ({ name: 'hermes', set }) }, reference: { provider: set => ({ name: 'reference', set }) },
  units: { bytes, kib, mib, slots, jobs, ms, count },
};

const strataApi = {
  version: VERSION, g, yaml: toYAML, runScript, presetScope, classify,
  internals: { lit, Lit, Fn, Module, t, StrataError, lookupOp, opRegistry, printFn, parseIR, Machine, runModule, analyzeFn, solveTypes, observeEqual, verify },
};

root.strata = Object.assign(root.strata || {}, strataApi);
if (typeof module !== 'undefined' && module.exports) module.exports = root.strata;
})(typeof globalThis !== 'undefined' ? globalThis : this);
