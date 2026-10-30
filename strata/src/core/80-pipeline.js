
// ---------------------------------------------------------------- sources

const source = {
  // Core IR text is recognised by its first line that is not a comment: `fn name(`.
  text: (text, opts = {}) => {
    const name = opts.name || 'program.js';
    const first = String(text).split('\n').map(l => l.replace(/(\/\/|;).*$/, '').trim()).find(Boolean) || '';
    const lang = opts.lang || (/\.ir$/.test(name) || /^fn\s+[\w$.]+\s*\(/.test(first) ? 'ir' : 'js');
    return { kind: 'source', text: String(text), name, lang };
  },
  ir: (text, opts = {}) => ({ kind: 'source', text: String(text), name: opts.name || 'program.ir', lang: 'ir' }),
};

// ---------------------------------------------------------------- passes

class Pass {
  constructor(spec) { Object.assign(this, { src: null, dst: null, needs: [], gives: [], kills: [], body: null }, spec); Object.freeze(this); }
  with(p) { return new Pass({ ...this, ...p }); }
  from(l) { return this.with({ src: l }); }
  to(l) { return this.with({ dst: l }); }
  requires(...f) { return this.with({ needs: f.flat() }); }
  provides(...f) { return this.with({ gives: f.flat() }); }
  invalidates(...f) { return this.with({ kills: f.flat() }); }
  run(f) { return this.with({ body: f }); }
  then(next) { return seqPass([this, next]); }
  hash() { return hashString(stable({ n: this.name, from: this.src, to: this.dst, needs: this.needs, gives: this.gives, kills: this.kills, parts: this.parts ? this.parts.map(p => p.name) : null })); }
  yamlTag() { return `pass ${this.name}${this.src ? ` (${this.src}→${this.dst || this.src})` : ''}`; }
}
const pass = name => new Pass({ name });
function seqPass(parts) {
  const flat = parts.flatMap(p => (p.parts ? p.parts : [p])).filter(p => p.name !== 'identity');
  return new Pass({ name: flat.map(p => p.name).join(' ; '), parts: flat, src: flat[0] && flat[0].src, dst: flat.length ? flat[flat.length - 1].dst : null,
    needs: flat.length ? flat[0].needs : [], gives: flat.flatMap(p => p.gives), kills: [] });
}
pass.identity = new Pass({ name: 'identity' });

// The standard passes. Each runs on the compilation state and may add to it.
const STD_PASSES = {
  frontend: pass('frontend').from('L0').to('L1').provides('core-ir').run((st, cfg) => {
    const src = st.source;
    if (src instanceof Fn) st.module = new Module([src.clone()], { main: src.name });
    else if (src instanceof Module) st.module = src.clone();
    else if (src.lang === 'ir') { const parsed = parseIR(src.text); st.module = parsed instanceof Module ? parsed : new Module([parsed], { main: parsed.name }); }
    else {
      if (!root.strata.frontend) throw new StrataError('the JavaScript frontend (frontend.js) is not loaded');
      st.module = root.strata.frontend.compile(src.text, { name: src.name });
    }
    // Assumptions about parameter types (what a JIT speculates from profiles). They are not
    // checked here: a real tier guards each one and deoptimises when it fails.
    const assumed = [];
    for (const [fname, ps] of Object.entries(cfg.assume || {})) {
      const fn = st.module.fn(fname);
      if (!fn) { st.diagnostics.push({ severity: 'warning', kind: 'assume', message: `assume: no function ${fname}`, at: { fn: fname } }); continue; }
      for (const [pname, ty] of Object.entries(ps)) {
        const prm = fn.params.find(x => x.id === pname);
        if (!prm) { st.diagnostics.push({ severity: 'warning', kind: 'assume', message: `assume: ${fname} has no parameter ${pname}`, at: { fn: fname } }); continue; }
        prm.type = ty instanceof Type ? ty : t.parse(ty);
        assumed.push(`${fname}.${pname}: ${prm.type}`);
        st.decisions.push({ by: 'assume', at: `${fname}/${pname}`, fired: true, because: `assumed ${pname}: ${prm.type}, unchecked; a JIT would guard this and deoptimise when it fails` });
      }
    }
    st.levels['L1.cells'] = st.module.toString();
    return `${st.module.functions.size} functions${assumed.length ? ' · assumed ' + assumed.join(', ') : ''}`;
  }),
  promoteCells: pass('promote-cells').from('L1').to('L1').requires('core-ir').provides('ssa').run((st, cfg) => {
    if (cfg.frontend.promote === false) return 'skipped (frontend promote: false)';
    let n = 0;
    for (const fn of st.module.functions.values()) n += promoteCells(fn, st.decisions).promoted.length;
    st.levels['L1.ssa'] = st.module.toString();
    return `${n} cells promoted`;
  }),
  verify: pass('verify').from('L1').to('L1').requires('core-ir').provides('verified').run((st) => {
    const r = verify(st.module);
    st.diagnostics.push(...r.diagnostics);
    if (!r.ok) throw new StrataError('the core IR does not verify', { diagnostics: r.diagnostics, quiet: true });
    return 'ok';
  }),
  rewrite: pass('rewrite').from('L1').to('L1').requires('verified').invalidates('analyses').run((st, cfg) => {
    let fired = 0;
    for (const fn of st.module.functions.values()) fired += runRewrites(fn, cfg.rewrites, st.decisions).fired;
    const r = verify(st.module);
    if (!r.ok) { st.diagnostics.push(...r.diagnostics.map(d => ({ ...d, message: 'after rewrites: ' + d.message }))); throw new StrataError('a rewrite broke the IR', { quiet: true }); }
    return `${fired} rewrites fired (${cfg.rewrites.names.join(', ') || 'none'})`;
  }),
  analyze: pass('analyze').from('L1').to('L1').requires('verified').provides('liveness', 'safepoints', 'types', 'dominators').run((st) => {
    for (const fn of st.module.functions.values()) st.facts[fn.name] = analyzeFn(fn);
    const it = Object.values(st.facts).reduce((n, f) => n + f.iterations.liveness, 0);
    return `liveness ${it} block visits`;
  }),
  lowerRuntime: pass('lower-runtime').from('L1').to('L2').requires('verified', 'types').provides('runtime-bound').run((st, cfg) => {
    for (const fn of st.module.functions.values()) {
      st.bindings[fn.name] = bindOps(fn, cfg.providers);
      st.reps[fn.name] = chooseReps(fn, st.facts[fn.name].raw.types, cfg.representation.name || cfg.representation);
    }
    return 'bound to providers';
  }),
  planRoots: pass('plan-roots').from('L2').to('L3').requires('runtime-bound', 'liveness', 'safepoints').provides('root-plan', 'unwind-plan').run((st, cfg) => {
    let slotsTotal = 0;
    for (const fn of st.module.functions.values()) {
      const f = st.facts[fn.name];
      const plan = planFunction(fn, { live: f.raw.live, types: f.raw.types, bindings: st.bindings[fn.name], rootsStrategy: cfg.roots, exceptionStrategy: cfg.exceptions });
      st.plans[fn.name] = plan; slotsTotal += plan.rootSlots;
    }
    return `${slotsTotal} root slots in ${st.module.functions.size} functions`;
  }),
  checkPlan: pass('check-plan').from('L3').to('L3').requires('root-plan').run((st, cfg) => {
    let problems = 0;
    for (const plan of Object.values(st.plans)) {
      for (const m of plan.missing) { problems++; st.diagnostics.push({ severity: cfg.checks.gcSafety === false ? 'warning' : 'error', kind: 'gc-safety', rule: 'root-missing', message: `${m.value} is ${m.how || 'live across'} ${m.op} at ${m.at} but ${m.why}`, at: { fn: plan.fn, op: m.at }, value: m.value }); }
      if (plan.limit && plan.limit.ok === false) { problems++; st.diagnostics.push({ severity: 'error', kind: 'admission', message: plan.storage === 'arena' ? `${plan.fn} needs ${plan.limit.bytes} B of activation storage, over the arena budget ${plan.limit.budget}` : `${plan.fn} exceeds the ${NATIVE_FRAME_LIMIT}-slot native frame limit (${plan.rootSlots} roots + ${plan.fixedSlots} fixed + ${plan.argSlots} arguments = ${plan.frameSlots} slots, strategy ${plan.strategy})`, at: { fn: plan.fn } }); }
    }
    return problems ? `${problems} problems` : 'every collecting point roots what it needs';
  }),
  emitLLVM: pass('emit-llvm').from('L3').to('LLVM').requires('root-plan').run((st, cfg) => {
    let bad = 0;
    st.constants = new Map();                     // the module's string table
    const unitIndex = Object.fromEntries([...st.module.functions.keys()].map((n, i) => [n, i]));
    for (const fn of st.module.functions.values()) {
      st.plans[fn.name].unitIndex = unitIndex;
      const out = emitLLVM(fn, st.bindings[fn.name], st.plans[fn.name], st.reps[fn.name], st.constants);
      st.llvm[fn.name] = out;
      if (cfg.checks.llvm !== false) { const c = checkLLVM(out.text, out.declarations); out.check = c; if (!c.ok) { bad++; st.diagnostics.push({ severity: 'warning', kind: 'llvm-check', message: `LLVM text for ${fn.name}: ${c.errors[0].message}`, at: { fn: fn.name } }); } }
    }
    return bad ? `${bad} functions fail the structural check` : 'textual LLVM IR, structurally checked';
  }),
};

// ---------------------------------------------------------------- pipelines
// A pipeline is an immutable value. Every slot takes four forms: nothing (the default),
// partial parameters, a named strategy, or a lambda whose context offers the default.

const DEFAULTS = {
  profile: 'js', frontend: { promote: true }, assume: {}, providers: {}, rewrites: null, representation: 'tagged',
  roots: null, exceptions: null, materializer: 'llvm.orc', target: 'x86_64-linux-gnu', checks: { verify: true, gcSafety: true, llvm: true }, budget: {}, passes: null, raw: {}, stopAfter: null,
};

function slotValue(slot, x, prev) {
  if (x === undefined || x === null) return null;
  if (x instanceof Strategy) return x;
  if (typeof x === 'function') return new Strategy(slot, x.strategyName || 'custom', {}, x, (prev && !prev.fnImpl ? prev.name : null) || defaultStrategy(slot).name);
  if (typeof x === 'string') return strat(slot, x);
  if (typeof x === 'object') {
    if (slot === 'roots' && x.reuse === false) return roots.distinct();
    if (slot === 'roots' && x.reuse === true) return roots.stackReuse();
    const base = prev || defaultStrategy(slot);
    return strat(slot, base.name, { ...base.params, ...x });
  }
  throw new StrataError(`cannot use ${typeof x} as a ${slot} strategy`);
}
const defaultStrategy = slot => ({ roots: roots.stackReuse(), exceptions: exceptions.setjmp(), representation: representation.tagged() }[slot]);

class Pipeline {
  constructor(cfg = {}) { this.cfg = Object.freeze({ ...DEFAULTS, ...cfg }); this.kind = 'pipeline'; Object.freeze(this); }
  _with(p) { return new Pipeline({ ...this.cfg, ...p }); }
  profile(p) { return this._with({ profile: p }); }
  assume(map) {                                    // { fnName: { param: type } }, merged
    const next = { ...this.cfg.assume };
    for (const [f, ps] of Object.entries(map || {})) next[f] = { ...(next[f] || {}), ...ps };
    return this._with({ assume: next });
  }
  frontend(opts) { return this._with({ frontend: { ...this.cfg.frontend, ...(opts && opts.cfg ? opts.cfg : opts) } }); }
  provide(set, provider) { return this._with({ providers: { ...this.cfg.providers, ...(typeof set === 'string' ? { [set]: provider.name || provider } : set) } }); }
  rewrites(x) {
    if (typeof x === 'function' && !(x instanceof Rewrite)) return this._with({ rewrites: x(this.resolved().rewrites) });
    if (x instanceof Rewrite) x = rewriteSet(x);
    return this._with({ rewrites: x || null });
  }
  representation(x) { return this._with({ representation: slotValue('representation', x, this.cfg.representation) }); }
  roots(x) { return this._with({ roots: slotValue('roots', x, this.cfg.roots) }); }
  exceptions(x) { return this._with({ exceptions: slotValue('exceptions', x, this.cfg.exceptions) }); }
  materialize(m) { return this._with({ materializer: m.name || m, target: (m && m.target) || this.cfg.target }); }
  checks(c) { return this._with({ checks: { ...this.cfg.checks, ...c } }); }
  budget(b) { return this._with({ budget: { ...this.cfg.budget, ...b } }); }
  passes(list) { return this._with({ passes: list }); }
  insert(p, where = {}) {
    const list = (this.cfg.passes || defaultPassList(this.resolved())).slice();
    const anchor = where.after || where.before;
    const i = anchor ? list.findIndex(x => x.name === anchor) : list.length - 1;
    if (anchor && i < 0) throw new StrataError(`no pass ${anchor} in the pipeline`);
    list.splice(where.before ? i : i + 1, 0, p);
    return this._with({ passes: list });
  }
  stopAfter(level) { return this._with({ stopAfter: level }); }
  use(...presets) { return presets.flat().reduce((p, f) => (f ? f(p) || p : p), this); }
  with(f) { return f(this) || this; }
  set(k, v) { return this._with({ raw: { ...this.cfg.raw, [k]: v } }); }
  get(slot) { return this.resolved()[slot]; }
  resolved() {
    const c = this.cfg;
    return { ...c, rewrites: c.rewrites || rewrites.canonical(), roots: c.roots || roots.stackReuse(), exceptions: c.exceptions || exceptions.setjmp(),
      representation: c.representation instanceof Strategy ? c.representation : strat('representation', c.representation || 'tagged') };
  }
  passList() {
    const r = this.resolved();
    let list = r.passes || defaultPassList(r);
    if (r.stopAfter) {
      const rank = l => ['L0', 'L1', 'L2', 'L3', 'LLVM'].indexOf(l);
      const limit = rank(r.stopAfter);
      list = list.filter(p => rank(p.dst || p.src || 'L0') <= limit);
    }
    return list;
  }
  check() {
    const diags = [], have = new Set(), inserted = [];
    for (const p of this.passList()) {
      const missing = p.needs.filter(n => !have.has(n));
      if (missing.length) diags.push({ severity: 'error', kind: 'pass-requirements', pass: p.name, missing, message: `${p.name} needs ${missing.join(', ')}, which no earlier pass provides` });
      for (const g of p.gives) have.add(g);
      for (const k of p.kills) { if (k === 'analyses') ['liveness', 'safepoints', 'types', 'dominators'].forEach(x => have.delete(x)); else have.delete(k); }
    }
    const r = this.resolved();
    const c = compat(r.roots, r.exceptions);
    if (c.ok === false) diags.push({ severity: 'error', kind: 'strategy', message: c.reason });
    if (c.ok === 'unknown') diags.push({ severity: 'error', kind: 'strategy', message: c.reason });
    if (r.exceptions.name !== 'setjmp') {
      const hermesSets = ['js.value', 'js.object', 'js.function', 'js.control'].filter(s => !r.providers[s] || r.providers[s] === 'hermes');
      if (hermesSets.length) diags.push({ severity: 'error', kind: 'strategy', message: `exceptions: ${r.exceptions.name} needs helpers that report errors without longjmp, but ${hermesSets.join(', ')} ${hermesSets.length > 1 ? 'are' : 'is'} provided by Hermes, whose helpers throw nonlocally; keep setjmp or provide those sets yourself` });
    }
    return { ok: !diags.some(d => d.severity === 'error'), diagnostics: diags, inserted };
  }
  summary() {
    const r = this.resolved();
    const providers = { core: 'reference' };
    for (const s of ['js.value', 'js.object', 'js.function', 'js.control']) providers[s] = r.providers[s] || 'hermes';
    return {
      profile: r.profile, frontend: `strata.frontend (acorn) · promote cells: ${r.frontend.promote !== false}`, providers,
      rewrites: r.rewrites.names.join(', ') || 'none', ordering: 'ordered blocks + contracts',
      analyses: 'liveness, safepoints, types, dominators (one solver)',
      strategies: { representation: String(r.representation), roots: String(r.roots), exceptions: String(r.exceptions) },
      materializer: `${r.materializer} · ${r.target} · textual LLVM IR`, checks: r.checks, raw: r.raw,
      assume: Object.entries(r.assume || {}).flatMap(([f, ps]) => Object.entries(ps).map(([k, ty]) => `${f}.${k}: ${ty}`)),
      passes: this.passList().map(p => p.name),
    };
  }
  hash() { return hashString(stable({ ...this.summary(), passes: this.passList().map(p => p.hash()), lambdas: [this.cfg.roots, this.cfg.exceptions].filter(s => s && s.fnImpl).map(s => String(s.fnImpl)) })); }
  yamlTag() { return `pipeline ${this.hash().slice(0, 6)}`; }
}
// pipeline({ roots: 'none', rewrites: g.rewrites.standard() }) goes through the slot methods,
// so a configuration object means the same as the chained calls.
const pipeline = (cfg = {}) => {
  let p = new Pipeline({});
  for (const [k, v] of Object.entries(cfg || {})) {
    if (typeof p[k] === 'function' && !['check', 'summary', 'hash', 'resolved', 'passList', 'get', 'set', 'with', 'use', 'insert'].includes(k)) p = p[k](v);
    else p = p.set(k, v);
  }
  return p;
};

function defaultPassList(r) {
  const P = STD_PASSES;
  return [P.frontend, P.promoteCells, P.verify, P.rewrite, P.analyze, P.lowerRuntime, P.planRoots, P.checkPlan, P.emitLLVM];
}

function compat(r, e) {
  const rn = r ? (r.compatName || r.name) : 'stackReuse', en = e ? (e.compatName || e.name) : 'setjmp';
  const key = `${rn}|${en}`;
  if (DECLARED_PAIRS.has(key)) return { ok: true, ...DECLARED_PAIRS.get(key) };
  return { ok: 'unknown', reason: `roots ${rn} with exceptions ${en}: no declared compatible pair; declare one with g.compat.declare(roots, exceptions, { requires, tests }) after tracing throw, catch, collection and suspension` };
}
const DECLARED_PAIRS = new Map([
  ['distinct|setjmp', { evidence: 'the current Hermes protocol: _sh_catch_no_pop restores locals and the frame together' }],
  ['stackReuse|setjmp', { evidence: 'same protocol; slots are plain frame storage' }],
  ['arena|setjmp', { requires: 'the arena mark saved in every catch checkpoint', evidence: 'declared, traced in the workbench (L-presets)' }],
  ['none|setjmp', { evidence: 'a demonstration: nothing is rooted, so the plan checker reports every missing root' }],
  ['distinct|statusReturn', { requires: 'helpers that return a status', evidence: 'declared' }],
  ['stackReuse|statusReturn', { requires: 'helpers that return a status', evidence: 'declared' }],
]);
compat.declare = (r, e, info = {}) => { DECLARED_PAIRS.set(`${r.compatName || r.name || r}|${e.compatName || e.name || e}`, info); return { ok: true, ...info }; };

// ---------------------------------------------------------------- compile and the Program

function compile(pipe, src) {
  pipe = pipe || pipeline();
  if (typeof src === 'string') src = source.text(src);
  const r = pipe.resolved();
  const st = { source: src, module: null, levels: {}, facts: {}, plans: {}, bindings: {}, reps: {}, llvm: {}, diagnostics: [], trace: [], decisions: [] };
  const chk = pipe.check();
  st.diagnostics.push(...chk.diagnostics);
  const t0 = now();
  if (chk.ok) {
    for (const p of pipe.passList()) {
      const ts = now();
      let note;
      try { note = p.body ? p.body(st, r) : 'no body'; }
      catch (e) {
        if (!e.quiet) st.diagnostics.push({ severity: 'error', kind: e.kind || 'pass', message: e.message, at: e.loc ? { file: src.name, line: e.loc.line, col: e.loc.col } : { pass: p.name } });
        st.trace.push({ pass: p.name, level: `${p.src || ''}${p.dst && p.dst !== p.src ? '→' + p.dst : ''}`, ms: round(now() - ts, 2), note: 'stopped: ' + e.message });
        break;
      }
      st.trace.push({ pass: p.name, level: `${p.src || ''}${p.dst && p.dst !== p.src ? '→' + p.dst : ''}`, ms: round(now() - ts, 2), note: note || '' });
    }
  }
  return new Program(pipe, st, round(now() - t0, 2));
}

class Program {
  constructor(pipe, st, ms) {
    this.kind = 'program'; this.pipeline = pipe; this.st = st; this.compileMs = ms;
    this.name = st.source && st.source.name || (st.module && st.module.main) || 'program';
    this.source = st.source && st.source.text !== undefined ? st.source.text : (st.module ? st.module.toString() : '');
    this.diagnostics = st.diagnostics; this.trace = st.trace; this.decisions = st.decisions;
    this.module = st.module;
  }
  get ok() { return !this.diagnostics.some(d => d.severity === 'error') && !!this.module; }
  functions() { if (!this.module) return []; const n = this.module.names(); const m = this.module.main; return [m, ...n.filter(x => x !== m)]; }
  fnOf(name) { const f = this.module && this.module.fn(name || this.module.main); if (!f) throw new StrataError(`no function ${name}`); return f; }
  ir(level = 'L1', opts = {}) {
    const fmt = opts.format || 'text', names = opts.fn ? [opts.fn] : this.functions();
    if (level === 'L0') return this.source;
    if (!this.module) return '; nothing compiled: ' + (this.diagnostics[0] ? this.diagnostics[0].message : 'no module');
    if (level === 'L1.cells' || level === 'L1.ssa') {
      const text = this.st.levels[level] || '; this level was not produced';
      return opts.fn ? extractFn(text, opts.fn) : text;
    }
    if (level === 'L1') return fmt === 'json' ? JSON.stringify(names.map(n => fnToJSON(this.fnOf(n))), null, 1) : names.map(n => printFn(this.fnOf(n))).join('\n\n');
    if (level === 'L2') { if (!this.st.bindings[names[0]]) return '; L2 was not produced'; return fmt === 'json' ? JSON.stringify(Object.fromEntries(names.map(n => [n, this.st.bindings[n]])), null, 1) : names.map(n => printL2(this.fnOf(n), this.st.bindings[n], this.st.reps[n] || {})).join('\n\n'); }
    if (level === 'L3') { if (!this.st.plans[names[0]]) return '; L3 was not produced'; return fmt === 'json' ? JSON.stringify(Object.fromEntries(names.map(n => [n, this.plan(n)])), null, 1) : names.map(n => printL3(this.fnOf(n), this.st.bindings[n], this.st.plans[n])).join('\n\n'); }
    if (level === 'LLVM') {
      if (!this.st.llvm[names[0]]) return '; LLVM IR was not produced';
      const decls = [...new Set(names.flatMap(n => this.st.llvm[n].declarations))].sort();
      const table = [...(this.st.constants || new Map())].map(([k, i]) => `;   ${i}: ${k}`);
      return [`; ModuleID = '${this.name}'`, `target triple = "${this.pipeline.resolved().target}"`, '', ...(table.length ? ['; string table (shllvm_constant index: value)', ...table, ''] : []), ...decls, '', ...names.map(n => this.st.llvm[n].text)].join('\n');
    }
    if (level === 'WAT') return this.wasm(opts.fn).wat;
    return `; unknown level ${level}`;
  }
  wasm(fnName) {
    const names = this.functions(), ok = [], reasons = {};
    for (const n of names) { const r = wasmEligible(this.module, this.fnOf(n), this.st.facts[n] ? this.st.facts[n].raw.types : solveTypes(this.fnOf(n))); if (r === true) ok.push(n); else reasons[n] = r; }
    if (!ok.length) return { ok: [], reasons, wat: `;; no function is in the core profile the Wasm backend accepts\n${Object.entries(reasons).map(([n, r]) => `;; ${n}: ${r}`).join('\n')}` };
    const enc = encodeWasm(this.module, ok);
    return { ok, reasons, wat: enc.wat + (Object.keys(reasons).length ? '\n' + Object.entries(reasons).map(([n, r]) => `;; not compiled: ${n}: ${r}`).join('\n') : ''), bytes: enc.bytes };
  }
  cfg(fnName, level = 'L1') {
    const fn = this.fnOf(fnName), bd = this.st.bindings[fn.name] || {};
    const opView = (o, id) => {
      const d = opRegistry[o.op];
      return { id, text: (o.result ? o.result + ' = ' : '') + opText(o), op: o.op, args: o.args.map(operandText), results: o.result ? [o.result] : [], invoke: id.endsWith('/term'), mayThrow: !!(d && d.mayThrow), safepoint: !!(bd[id] ? bd[id].collects : d && d.mayCollect), loc: o.loc };
    };
    return {
      name: fn.name, entry: fn.entry, params: fn.params.map(p => ({ id: p.id, type: String(p.type) })), meta: fn.meta,
      blocks: fn.blocks.map(b => ({
        name: b.name, params: b.params.map(p => ({ id: p.id, type: String(p.type) })), onThrow: b.onThrow, throwArgs: (b.throwArgs || []).map(operandText),
        ops: b.ops.map((o, i) => opView(o, `${fn.name}/${b.name}/${i}`)),
        term: { kind: b.term.kind, text: termText(b.term), op: b.term.kind === 'invoke' ? opView(b.term.op, `${fn.name}/${b.name}/term`) : null,
          edges: successors(fn, b).map(e => ({ to: e.block, args: e.args.map(operandText), kind: e.kind })) },
      })),
    };
  }
  facts(fnName) {
    const f = this.st.facts[this.fnOf(fnName).name] || analyzeFn(this.fnOf(fnName));
    return { live: f.live, types: f.types, safepoints: f.safepoints, idom: f.idom, iterations: f.iterations };
  }
  steps(fnName, analysis = 'liveness') {
    const fn = this.fnOf(fnName), f = this.st.facts[fn.name] || analyzeFn(fn);
    return analysis === 'types' ? f.raw.types.steps : f.raw.live.steps;
  }
  plan(fnName) {
    const p = this.st.plans[this.fnOf(fnName).name];
    if (!p) return null;
    const { slotOf, ...rest } = p;
    return { ...rest, reps: this.st.reps[p.fn] || {} };
  }
  perm(opId) {
    const site = this.site(opId);
    if (!site) throw new StrataError(`no operation ${opId}`);
    const d = lookupOp(site.op.op);
    const uses = usesOf(site.fn);
    const unused = !site.op.result || !(uses.get(site.op.result) || []).length;
    const p = derivePermissions(d.behaviour, { identityObserved: !unused });
    return { op: site.op.op, text: opText(site.op), contract: { behaviour: d.behaviour.toString(), obligations: d.obligations.toString() }, resultUnused: unused, ...p };
  }
  site(opId) {
    const [fname, bname, idx] = String(opId).split('/');
    const fn = this.module && this.module.fn(fname); if (!fn) return null;
    const b = fn.block(bname); if (!b) return null;
    if (idx === 'term') return b.term.kind === 'invoke' ? { fn, block: b, index: 'term', op: b.term.op } : { fn, block: b, index: 'term', op: { op: 'term', args: [], result: null }, term: b.term };
    const o = b.ops[Number(idx)]; return o ? { fn, block: b, index: Number(idx), op: o } : null;
  }
  why(target) {
    target = String(target);
    if (target.startsWith('slot:')) {
      const [fname, s] = target.slice(5).split('/');
      const plan = this.st.plans[fname]; if (!plan) return { error: `no plan for ${fname}` };
      const values = Object.entries(plan.slotOf).filter(([, k]) => String(k) === s).map(([v]) => v);
      const points = Object.entries(plan.safepoints).filter(([, sp]) => sp.rooted.some(v => values.includes(v)));
      return { slot: Number(s), fn: fname, values, strategy: plan.strategy, rootedAt: points.map(([id, sp]) => `${id} ${sp.op}: ${sp.rooted.filter(v => values.includes(v)).join(', ')}`),
        because: values.length > 1 ? 'these values are never required at the same collecting point, so they can share it' : 'live across a collecting call (or borrowed by one)' };
    }
    if (target.split('/').length === 3) {
      const site = this.site(target); if (!site) return { error: `no operation ${target}` };
      const plan = this.st.plans[site.fn.name], sp = plan && plan.safepoints[target];
      return { op: target, text: site.op.op === 'term' ? termText(site.term) : opText(site.op), contract: site.op.op === 'term' ? null : lookupOp(site.op.op).contract,
        liveAcross: (this.st.facts[site.fn.name] && this.st.facts[site.fn.name].live.across[target]) || [], safepoint: sp || null,
        decisions: this.decisions.filter(d => d.at === target) };
    }
    const [fname, v] = target.includes(':') ? target.split(':') : [null, target];
    for (const fn of this.module.functions.values()) {
      if (fname && fn.name !== fname) continue;
      const defs = definitions(fn); if (!defs.has(v)) continue;
      const d = defs.get(v), f = this.st.facts[fn.name], plan = this.st.plans[fn.name];
      return { value: v, fn: fn.name, defined: d.kind === 'op' ? `${fn.name}/${d.block}/${d.index} ${opText(d.op)}` : `${d.kind} of ${d.block}`, type: f ? f.types[v] : undefined,
        liveAcross: f ? Object.entries(f.live.across).filter(([, s]) => s.includes(v)).map(([k]) => k) : [], slot: plan && plan.slotOf[v] !== undefined ? plan.slotOf[v] : null,
        uses: (usesOf(fn).get(v) || []).map(u => `${fn.name}/${u.block.name}/${u.term ? 'term' : u.index}`) };
    }
    return { error: `nothing called ${target}` };
  }
  find(pred) {
    const out = [];
    for (const fn of this.module.functions.values()) for (const b of fn.blocks) b.ops.forEach((o, i) => { const s = { id: `${fn.name}/${b.name}/${i}`, fn: fn.name, block: b.name, index: i, op: o.op, text: opText(o), result: o.result }; if (!pred || pred(s)) out.push(s); });
    return out;
  }
  summary() {
    const s = this.pipeline.summary();
    const counts = { functions: 0, blocks: 0, ops: 0, values: 0 };
    if (this.module) for (const fn of this.module.functions.values()) { counts.functions++; counts.blocks += fn.blocks.length; counts.ops += fn.blocks.reduce((n, b) => n + b.ops.length + 1, 0); counts.values += fn.values().length; }
    return { ...s, counts, ok: this.ok, compileMs: this.compileMs, errors: this.diagnostics.filter(d => d.severity === 'error').length };
  }
  metrics() {
    const plans = Object.values(this.st.plans);
    return { compileMs: this.compileMs, functions: this.module ? this.module.functions.size : 0, rootSlots: plans.reduce((n, p) => n + p.rootSlots, 0),
      maxFrameSlots: plans.reduce((n, p) => Math.max(n, p.frameSlots), 0), peakLive: plans.reduce((n, p) => Math.max(n, p.peakLive), 0),
      ops: this.summary().counts.ops, rewritesFired: this.decisions.filter(d => d.fired && d.by !== 'promote-cells' && d.by !== 'assume').length,
      cellsPromoted: this.decisions.filter(d => d.fired && d.by === 'promote-cells').length, errors: this.diagnostics.filter(d => d.severity === 'error').length };
  }
  run(opts = {}) {
    if (!this.module) return { kind: 'run', mode: opts.mode || 'spec', outcome: { kind: 'error', message: 'nothing compiled' }, output: [], trace: [], events: [], records: [], steps: 0, metrics: {}, error: { message: 'nothing compiled' } };
    const mode = opts.mode || 'spec';
    const steps = opts.budget && opts.budget.n !== undefined ? opts.budget.n : opts.steps || opts.budget || 200000;
    const entryFn = this.module.fn(opts.entry || this.module.main);
    const entryArgs = entryFn && opts.args ? this.argsFor(entryFn, opts.args) : opts.args;
    if (mode === 'wasm') {
      const entry = opts.entry || this.module.main, w = this.wasm();
      if (!w.ok.includes(entry)) return { kind: 'run', mode: 'wasm', outcome: { kind: 'error', message: `wasm: ${entry} is not in the core profile: ${w.reasons[entry]}` }, output: [], trace: [], events: [], records: [], steps: 0, metrics: {}, error: { message: `${entry}: ${w.reasons[entry]}` } };
      try { return runWasm(this.module, w.ok, entry, (entryArgs || []).map(a => (a === undefined ? 0 : a))); }
      catch (e) { return { kind: 'run', mode: 'wasm', outcome: { kind: 'error', message: e.message }, output: [], trace: [], events: [], records: [], steps: 0, metrics: {}, error: { message: e.message } }; }
    }
    if (mode === 'plan' && !Object.keys(this.st.plans).length) return { kind: 'run', mode, outcome: { kind: 'error', message: 'no execution plan: the pipeline stopped before plan-roots' }, output: [], trace: [], events: [], records: [], steps: 0, metrics: {}, error: { message: 'no plan' } };
    const plans = {};
    for (const [n, p] of Object.entries(this.st.plans)) plans[n] = { safepoints: p.safepoints, slotOf: p.slotOf, frameSlots: p.frameSlots };
    const r = runModule(this.module, { mode, plans, gc: opts.gc || 'off', budget: steps, entry: opts.entry, args: entryArgs, jobs: opts.jobs, recordLimit: opts.recordLimit });
    return r;
  }
  // A function from the JavaScript frontend takes its captured cells and `this` first;
  // run({ entry, args }) passes JavaScript arguments, so the rest are filled in.
  argsFor(fn, args) {
    const js = fn.meta && fn.meta.jsParams !== undefined;
    if (!js) return args;
    const lead = fn.params.length - fn.meta.jsParams;
    if (fn.params.slice(0, lead).some(p => p.type.has && p.type.has('cell'))) throw new StrataError(`${fn.name} captures variables, so it cannot be run on its own; run the function that creates it`);
    return [...Array(lead).fill(undefined), ...args];
  }
  get artifact() {
    const r = this.pipeline.resolved();
    return { kind: 'artifact', abi: 'strata-abi/1', target: r.target, relocatable: true,
      requires: { roots: String(r.roots), exceptions: String(r.exceptions), calls: 'hermesNative', runtime: 'hermes static_h f837b9d' },
      functions: Object.values(this.st.plans).map(p => ({ name: p.fn, rootSlots: p.rootSlots, frameSlots: p.frameSlots, argumentSlots: p.argSlots })),
      hash: this.module ? this.module.hash() : null, program: this };
  }
  yamlTag() { return `[Program ${this.name}: ${this.ok ? 'ok' : this.diagnostics.filter(d => d.severity === 'error').length + ' errors'}, ${this.module ? this.module.functions.size : 0} functions]`; }
  toJSON() { return { kind: 'program', name: this.name, ok: this.ok, summary: this.summary() }; }
}

function extractFn(text, name) {
  const start = text.indexOf(`fn ${name}(`);
  if (start < 0) return text;
  const end = text.indexOf('\n}', start);
  return text.slice(start, end + 2);
}
