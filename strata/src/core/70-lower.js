
// ---------------------------------------------------------------- lowering to the runtime (L2)
// Each operation is bound to how the provider implements it: an inline instruction or a
// call to a runtime helper. The binding keeps the contract's obligations, so the plan
// knows which calls may collect and which may throw through the setjmp protocol.

const ROOT_KINDS = KBIT.object | KBIT.function | KBIT.cell | KBIT.completion | KBIT.string;
const needsRoot = ty => (ty.bits & ROOT_KINDS) !== 0;

function bindOps(fn, providers = {}) {
  const bindings = {};
  const bind = (o, id) => {
    const d = lookupOp(o.op), set = SET_OF(o.op);
    const provider = providers[set] || (set === 'core' ? 'reference' : 'hermes');
    const l = d.lower || {};
    bindings[id] = {
      op: o.op, provider, kind: l.inline ? 'inline' : l.direct ? 'direct' : 'helper',
      name: l.inline || (l.direct ? '@' + o.attrs.callee : l.helper || 'shllvm_' + o.op.replace(/\W/g, '_')), code: l.code,
      collects: d.mayCollect, throws: d.mayThrow, nonlocal: d.obligations.has('nonlocalThrow'),
    };
  };
  for (const b of fn.blocks) {
    b.ops.forEach((o, i) => bind(o, `${fn.name}/${b.name}/${i}`));
    if (b.term && b.term.kind === 'invoke') bind(b.term.op, `${fn.name}/${b.name}/term`);
  }
  return bindings;
}

function chooseReps(fn, types, strategy = 'tagged') {
  const reps = {};
  for (const v of fn.values()) {
    const ty = types.typeOf(v);
    if (strategy === 'unboxWhenProven' && !ty.isBottom && ty.le(t.boolean)) reps[v] = 'bool';
    else if (strategy === 'unboxWhenProven' && !ty.isBottom && ty.le(t.number)) reps[v] = ty.le(t.int32) && false ? 'i32' : 'f64';
    else reps[v] = 'tagged';
  }
  return reps;
}

function printL2(fn, bindings, reps) {
  return printFn(fn, {
    annotate: (b, i) => {
      const bd = bindings[`${fn.name}/${b.name}/${i}`];
      if (!bd) return '';
      const parts = [bd.kind === 'inline' ? `inline ${bd.name}` : bd.kind === 'direct' ? `direct call ${bd.name}` : `call ${bd.name}${bd.code ? '(' + bd.code + ')' : ''}`];
      if (bd.collects) parts.push('collects');
      if (bd.throws) parts.push(bd.nonlocal ? 'throws (setjmp)' : 'throws');
      const o = i === 'term' ? b.term.op : b.ops[i];
      if (o && o.result && reps[o.result] && reps[o.result] !== 'tagged') parts.push(`${o.result}: ${reps[o.result]}`);
      return parts.join(' · ');
    },
  });
}

// ---------------------------------------------------------------- execution plans (L3)
// A plan says, for every collecting point, which managed values must be reachable by the
// collector, and in which root slot each one sits. Strategies choose the slots; one
// checker judges every plan by the same invariant.

const FIXED_SLOTS = 2;                             // scratch and discard, as in the Hermes emitter
const NATIVE_FRAME_LIMIT = 1024;                   // the emitter's admission limit, in slots

function safepointSites(fn, bindings) {
  const out = [];
  for (const b of fn.blocks) {
    b.ops.forEach((o, i) => { const id = `${fn.name}/${b.name}/${i}`; if (bindings[id] && bindings[id].collects) out.push({ id, block: b, index: i, op: o }); });
    if (b.term && b.term.kind === 'invoke') { const id = `${fn.name}/${b.name}/term`; if (bindings[id] && bindings[id].collects) out.push({ id, block: b, index: 'term', op: b.term.op }); }
  }
  return out;
}

function maxOutgoingArgs(fn) {
  let n = 1;
  const visit = o => { if (o.op === 'js.call') n = Math.max(n, o.args.length - 1); if (o.op === 'js.call_method') n = Math.max(n, o.args.length - 1); if (o.op === 'core.call' || o.op === 'js.closure') n = Math.max(n, o.args.length); };
  for (const b of fn.blocks) { b.ops.forEach(visit); if (b.term && b.term.kind === 'invoke') visit(b.term.op); }
  return n;
}

// What a collecting point needs rooted: managed values live across it, and the managed
// operands it borrows (the helper reads them after it may have collected).
function requiredRoots(fn, live, types, site) {
  const across = live.across[site.id] || [];
  const borrowed = site.op.args.filter(a => !isLit(a));
  const need = new Set();
  for (const v of [...across, ...borrowed]) if (needsRoot(types.typeOf(v))) need.add(v);
  return [...need].sort();
}

const ROOT_STRATEGIES = {
  distinct(fn, ctx) {                              // one slot per value, as today's emitter does
    const slotOf = {}; let n = 0;
    const used = new Set(); forEachUse(fn, v => used.add(v));
    for (const v of fn.values()) if (used.has(v) && needsRoot(ctx.types.typeOf(v))) slotOf[v] = n++;
    return { slotOf, rootSlots: n, storage: 'native stack' };
  },
  stackReuse(fn, ctx) {                            // colour the values rooted at the same points
    // Greedy colouring in order of first need: each value takes the smallest slot that no value
    // needed at one of the same safepoints already holds. Per safepoint, a bitmap of used slots.
    const slotOf = {}, order = [], seen = new Set(), sitesOf = new Map();
    const needs = ctx.sites.map(s => ctx.required(s));
    needs.forEach((need, k) => { for (const a of need) { if (!seen.has(a)) { seen.add(a); order.push(a); sitesOf.set(a, []); } sitesOf.get(a).push(k); } });
    const words = Math.ceil((order.length + 1) / 32) + 1;
    const used = needs.map(() => new Uint32Array(words));
    let n = 0;
    const taken = new Uint32Array(words);
    for (const v of order) {
      taken.fill(0);
      for (const k of sitesOf.get(v)) { const u = used[k]; for (let w = 0; w < words; w++) taken[w] |= u[w]; }
      let slot = 0; while (taken[slot >>> 5] & (1 << (slot & 31))) slot++;
      slotOf[v] = slot; n = Math.max(n, slot + 1);
      for (const k of sitesOf.get(v)) used[k][slot >>> 5] |= 1 << (slot & 31);
    }
    return { slotOf, rootSlots: n, storage: 'native stack' };
  },
  arena(fn, ctx, params = {}) {                    // one slot per managed value, in runtime-owned chunks
    const d = ROOT_STRATEGIES.distinct(fn, ctx);
    return { ...d, storage: 'arena', chunk: params.chunk || kib(16), budget: params.budget || mib(4) };
  },
  none() { return { slotOf: {}, rootSlots: 0, storage: 'none (a demonstration of a missing plan)' }; },
};

class Strategy {
  // A lambda strategy wraps the slot's default (ctx.default); it inherits the default's
  // declared compatibility, and the plan checker verifies whatever plan it returns.
  constructor(slot, name, params = {}, fnImpl = null, wraps = null) { this.slot = slot; this.name = name; this.params = params; this.fnImpl = fnImpl; this.wraps = wraps; Object.freeze(this); }
  get compatName() { return this.fnImpl && this.wraps ? this.wraps : this.name; }
  toString() { return this.fnImpl ? (this.name === 'custom' ? `lambda(${this.wraps || 'custom'})` : this.name) : (Object.keys(this.params).length ? `${this.name}(${Object.entries(this.params).map(([k, v]) => `${k} ${v}`).join(', ')})` : this.name); }
  toJSON() { return this.toString(); }
  yamlTag() { return `${this.slot} ${this.toString()}`; }
}
const strat = (slot, name, params) => new Strategy(slot, name, params);

const roots = {
  distinct: p => strat('roots', 'distinct', p), stackReuse: p => strat('roots', 'stackReuse', p),
  arena: (p = {}) => strat('roots', 'arena', p), none: () => strat('roots', 'none'),
};
const exceptions = { setjmp: () => strat('exceptions', 'setjmp'), statusReturn: () => strat('exceptions', 'statusReturn'), landingPads: () => strat('exceptions', 'landingPads') };
const representation = { tagged: () => strat('representation', 'tagged'), unboxWhenProven: () => strat('representation', 'unboxWhenProven') };

function planFunction(fn, ctx0) {
  const { live, types, bindings, rootsStrategy, exceptionStrategy } = ctx0;
  const sites = safepointSites(fn, bindings);
  const required = s => requiredRoots(fn, live, types, s);
  const ctx = { types, live, sites, required };
  const runNamed = (s) => {
    const name = s.name || 'stackReuse';
    const impl = ROOT_STRATEGIES[name];
    if (!impl) throw new StrataError(`unknown root strategy ${name}`);
    return { strategy: s.toString ? s.toString() : name, ...impl(fn, ctx, s.params || {}) };
  };
  let chosen;
  if (rootsStrategy && rootsStrategy.fnImpl) {
    const base = strat('roots', rootsStrategy.wraps || 'stackReuse');
    const r = rootsStrategy.fnImpl(fn, { ...ctx, default: () => runNamed(base), run: s => runNamed(typeof s === 'string' ? strat('roots', s) : s), strategies: roots });
    chosen = r instanceof Strategy ? runNamed(r) : { strategy: rootsStrategy.toString(), ...r };
  } else chosen = runNamed(rootsStrategy || roots.stackReuse());
  // The checker: every required value has a slot, and no two required values share one.
  const safepoints = {}, missing = [];
  let peakLive = 0;
  for (const s of sites) {
    const need = required(s), rooted = [], miss = [], bySlot = new Map();
    for (const v of need) {
      const slot = chosen.slotOf[v];
      if (slot === undefined) { miss.push(v); continue; }
      if (bySlot.has(slot)) { miss.push(v); continue; }
      bySlot.set(slot, v); rooted.push(v);
    }
    peakLive = Math.max(peakLive, need.length);
    safepoints[s.id] = { op: s.op.op, live: (live.across[s.id] || []).slice(), required: need, rooted, missing: miss };
    const acrossHere = new Set(live.across[s.id] || []);
    for (const v of miss) missing.push({ value: v, at: s.id, op: s.op.op, how: acrossHere.has(v) ? 'live across' : 'borrowed by',
      why: chosen.slotOf[v] === undefined ? 'no root assigned' : `shares slot ${chosen.slotOf[v]} with ${bySlot.get(chosen.slotOf[v])}, which is also needed here` });
  }
  const argSlots = maxOutgoingArgs(fn);
  const frameSlots = chosen.storage === 'arena' ? chosen.rootSlots : chosen.rootSlots + FIXED_SLOTS + argSlots;
  const slotsList = [];
  for (const [v, s] of Object.entries(chosen.slotOf)) { if (!slotsList[s]) slotsList[s] = { slot: s, values: [] }; slotsList[s].values.push(v); }
  const unwind = [];
  for (const b of fn.blocks) {
    if (b.onThrow && b.onThrow !== 'unwind') unwind.push({ at: `${fn.name}/${b.name}`, handler: b.onThrow, strategy: exceptionStrategy.name, restores: ['root chain', 'managed frame', ...(chosen.storage === 'arena' ? ['arena mark'] : [])] });
    if (b.term && b.term.kind === 'invoke') unwind.push({ at: `${fn.name}/${b.name}/term`, handler: b.term.exc.block, strategy: exceptionStrategy.name, restores: ['root chain', 'managed frame', ...(chosen.storage === 'arena' ? ['arena mark'] : [])] });
  }
  const plan = {
    kind: 'plan', fn: fn.name, strategy: chosen.strategy, storage: chosen.storage,
    rootSlots: chosen.rootSlots, fixedSlots: chosen.storage === 'arena' ? 0 : FIXED_SLOTS, argSlots, frameSlots,
    frameBytes: chosen.storage === 'arena' ? 32 + 8 * chosen.rootSlots : 8 * frameSlots,
    peakLive, slots: slotsList.filter(Boolean), slotOf: chosen.slotOf, safepoints, missing, unwind,
    limit: chosen.storage === 'native stack' ? { max: NATIVE_FRAME_LIMIT, measured: frameSlots, ok: frameSlots <= NATIVE_FRAME_LIMIT } : chosen.storage === 'arena' ? { budget: String(chosen.budget || mib(4)), bytes: 32 + 8 * chosen.rootSlots, ok: (32 + 8 * chosen.rootSlots) <= (chosen.budget ? chosen.budget.n : 4194304) } : { ok: true },
  };
  return plan;
}

function printL3(fn, bindings, plan) {
  const slot = v => (plan.slotOf[v] !== undefined ? `s${plan.slotOf[v]}` : null);
  const head = [`; plan for ${fn.name}: ${plan.strategy}, ${plan.storage}`,
    `; frame: ${plan.rootSlots} root slots${plan.fixedSlots ? ` + ${plan.fixedSlots} fixed + ${plan.argSlots} argument` : ''} = ${plan.frameSlots} slots, ${plan.frameBytes} B`,
    ...plan.slots.map(s => `;   s${s.slot}: ${s.values.join(', ')}`)];
  const body = printFn(fn, {
    annotate: (b, i) => {
      const id = `${fn.name}/${b.name}/${i}`, sp = plan.safepoints[id];
      if (!sp) { const bd = bindings[id]; return bd && bd.kind !== 'inline' ? `call ${bd.name}` : ''; }
      const r = sp.rooted.map(v => `${slot(v)}=${v}`).join(' ');
      return `safepoint · rooted ${r || 'nothing'}${sp.missing.length ? ' · MISSING ' + sp.missing.join(', ') : ''}`;
    },
  });
  const unwind = plan.unwind.map(u => `; unwind ${u.at} → ${u.handler}: ${u.strategy}, restores ${u.restores.join(', ')}`);
  return [...head, body, ...unwind].join('\n');
}

// ---------------------------------------------------------------- LLVM IR text
// The shape of the existing Hermes backend: one function `define internal i64 @f(ptr %shr)`,
// a frame of root slots from shllvm_enter, helpers that write their result through an
// out pointer to a slot, numbers unboxed with bitcast for inline double arithmetic.

// Constants that are not numbers or immediates live in a string table shared by the
// module, as in Hermes; shllvm_constant(out, shr, index) materialises entry `index`.
const constantIndex = (pool, v) => { const k = typeof v === 'string' ? JSON.stringify(v) : String(v); if (!pool.has(k)) pool.set(k, pool.size); return pool.get(k); };
const isImmediate = v => typeof v === 'number' || typeof v === 'boolean' || v === undefined || v === null;

function emitLLVM(fn, bindings, plan, reps = {}, pool = new Map()) {
  const lines = [], decls = new Set(), tmp = { n: 0 };
  const T = () => `%t${tmp.n++}`;
  const declare = (name, sig) => decls.add(`declare ${sig.ret} @${name}(${sig.args.join(', ')})`);
  const slotPtr = v => (plan.slotOf[v] !== undefined ? `%s${plan.slotOf[v]}` : `%r.${safeName(v)}`);
  const regs = new Set(fn.values().filter(v => plan.slotOf[v] === undefined));
  const nArgs = plan.argSlots;
  lines.push(`define internal i64 @${safeName(fn.name)}(ptr %shr) {`, 'entry:');
  declare('_sh_check_native_stack_overflow', { ret: 'void', args: ['ptr'] });
  lines.push('  call void @_sh_check_native_stack_overflow(ptr %shr)');
  declare('shllvm_frame_size', { ret: 'i64', args: ['i32'] });
  lines.push(`  %size = call i64 @shllvm_frame_size(i32 ${plan.rootSlots + FIXED_SLOTS})`);
  lines.push('  %storage = alloca i8, i64 %size, align 16', `  %argv = alloca [${nArgs} x i64], align 8`);
  declare('shllvm_enter', { ret: 'ptr', args: ['ptr', 'ptr', 'i32', 'i32', 'i32'] });
  lines.push(`  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 ${plan.rootSlots + FIXED_SLOTS}, i32 ${nArgs}, i32 0)`);
  declare('shllvm_roots', { ret: 'ptr', args: ['ptr'] });
  lines.push('  %roots = call ptr @shllvm_roots(ptr %storage)');
  for (let i = 0; i < plan.rootSlots; i++) lines.push(`  %s${i} = getelementptr i64, ptr %roots, i32 ${i}`);
  lines.push(`  %scratch = getelementptr i64, ptr %roots, i32 ${plan.rootSlots}`, `  %discard = getelementptr i64, ptr %roots, i32 ${plan.rootSlots + 1}`);
  for (const v of regs) lines.push(`  %r.${safeName(v)} = alloca i64, align 8                 ; ${v}: not rooted`);
  const extraLiteralsAt = lines.length;           // allocas for a third, fourth… literal operand go here
  const params = new Map();
  fn.params.forEach((p, i) => {
    declare('shllvm_param', { ret: 'void', args: ['ptr', 'ptr', 'i32'] });
    lines.push(`  call void @shllvm_param(ptr ${slotPtr(p.id)}, ptr %frame, i32 ${i})`);
  });
  const hasTry = fn.blocks.some(b => (b.onThrow && b.onThrow !== 'unwind') || (b.term && b.term.kind === 'invoke'));
  if (hasTry) {
    declare('shllvm_try_size', { ret: 'i64', args: [] }); declare('shllvm_try_begin', { ret: 'ptr', args: ['ptr', 'ptr'] }); declare('_setjmp', { ret: 'i32', args: ['ptr'] });
    lines.push('  %trysize = call i64 @shllvm_try_size()', '  %try_storage = alloca i8, i64 %trysize, align 16', '  %try_state = alloca i32, align 4',
      '  store volatile i32 0, ptr %try_state, align 4', '  %buffer = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)',
      '  %status = call i32 @_setjmp(ptr %buffer) returns_twice', '  %exceptional = icmp ne i32 %status, 0',
      `  br i1 %exceptional, label %catch.dispatch, label %b.${safeName(fn.entry)}`);
  } else lines.push(`  br label %b.${safeName(fn.entry)}`);
  // A literal operand is written to a fixed slot just before the helper reads it: the first
  // to %scratch, a second to %discard, which stays free until the helper writes its result;
  // any further ones to stack temporaries %lit2, %lit3… (constants need no root).
  const literalSlots = ['%scratch', '%discard']; let literalUse = 0, maxLiterals = 2;
  const literalSlot = k => { if (k < 2) return literalSlots[k]; maxLiterals = Math.max(maxLiterals, k + 1); return `%lit${k}`; };
  const writeConstant = (a, target) => {
    if (isImmediate(a.lit)) { lines.push(`  store i64 ${boxBits(a.lit)}, ptr ${target}       ; ${a}`); return target; }
    declare('shllvm_constant', { ret: 'void', args: ['ptr', 'ptr', 'i32'] });
    lines.push(`  call void @shllvm_constant(ptr ${target}, ptr %shr, i32 ${constantIndex(pool, a.lit)})          ; ${a}`);
    return target;
  };
  const constSlot = a => writeConstant(a, literalSlot(literalUse++));
  const ptrOf = a => (isLit(a) ? constSlot(a) : slotPtr(a));
  const storeArgv = list => list.forEach((a, k) => {
    const p = T(); lines.push(`  ${p} = getelementptr i64, ptr %argv, i32 ${k}`);
    if (isLit(a)) { writeConstant(a, p); return; }
    const x = T(); lines.push(`  ${x} = load i64, ptr ${slotPtr(a)}, align 8`, `  store i64 ${x}, ptr ${p}, align 8`);
  });
  const unitIndex = name => (plan.unitIndex && plan.unitIndex[name] !== undefined ? plan.unitIndex[name] : 0);
  ptrOf.literal = writeConstant; ptrOf.reset = () => { literalUse = 0; };
  const tries = new Map(); let tryN = 0;
  for (const b of fn.blocks) {
    lines.push(`b.${safeName(b.name)}:`);
    // Every block of a function with a try states its region: its handler's number, or 0 so
    // that a throw outside every region unwinds to the caller instead of re-entering a handler.
    const stateOf = blk => (blk.onThrow && blk.onThrow !== 'unwind' ? (tries.has(blk.onThrow) || tries.set(blk.onThrow, ++tryN), tries.get(blk.onThrow)) : 0);
    if (b.onThrow && b.onThrow !== 'unwind') lines.push(`  store volatile i32 ${stateOf(b)}, ptr %try_state, align 4    ; protected: a throw goes to ${b.onThrow}`);
    else if (hasTry && b.name !== fn.entry) lines.push('  store volatile i32 0, ptr %try_state, align 4    ; not protected: a throw unwinds to the caller');
    b.ops.forEach((o, i) => {
      const id = `${fn.name}/${b.name}/${i}`, bd = bindings[id];
      ptrOf.reset();
      lines.push(`  ; ${o.result ? o.result + ' = ' : ''}${opText(o)}`);
      if (bd.kind === 'inline' && /^f/.test(bd.name)) {
        const vals = o.args.map(a => { const x = T(), y = T(); if (isLit(a)) { lines.push(`  ${y} = fadd double 0.0, ${numLit(a.lit)}`); return y; } lines.push(`  ${x} = load i64, ptr ${slotPtr(a)}, align 8`, `  ${y} = bitcast i64 ${x} to double`); return y; });
        const r = T();
        if (bd.name.startsWith('fcmp')) {
          const c = T(); lines.push(`  ${c} = ${bd.name} double ${vals[0]}, ${vals[1]}`, `  ${r} = select i1 ${c}, i64 ${boxBits(true)}, i64 ${boxBits(false)}`);
        } else if (bd.name === 'fneg') {
          const c = T(); lines.push(`  ${c} = fneg double ${vals[0]}`, `  ${r} = bitcast double ${c} to i64`);
        } else { const c = T(); lines.push(`  ${c} = ${bd.name} double ${vals[0]}, ${vals[1]}`, `  ${r} = bitcast double ${c} to i64`); }
        if (o.result) lines.push(`  store i64 ${r}, ptr ${slotPtr(o.result)}, align 8`);
        return;
      }
      if (bd.kind === 'inline') {
        const r = T();
        if (o.args[0] !== undefined) { const x = T(); lines.push(`  ${x} = load i64, ptr ${ptrOf(o.args[0])}, align 8`, `  ${r} = add i64 ${x}, 0                         ; ${bd.name}`); }
        if (o.result) lines.push(`  store i64 ${r}, ptr ${slotPtr(o.result)}, align 8`);
        return;
      }
      if (bd.kind === 'direct') {                 // a known callee: arguments through argv, then a direct call
        storeArgv(o.args);
        declare('shllvm_push_args', { ret: 'void', args: ['ptr', 'ptr', 'i32', 'ptr'] });
        lines.push(`  call void @shllvm_push_args(ptr %shr, ptr %frame, i32 ${o.args.length}, ptr %argv)`);
        declare(safeName(o.attrs.callee), { ret: 'i64', args: ['ptr'] });
        const r = T(); lines.push(`  ${r} = call i64 @${safeName(o.attrs.callee)}(ptr %shr)      ; may collect`);
        if (o.result) lines.push(`  store i64 ${r}, ptr ${slotPtr(o.result)}, align 8`);
        return;
      }
      if (o.op === 'js.closure') {               // the function's index and its captured cells
        storeArgv(o.args);
        declare('shllvm_closure', { ret: 'void', args: ['ptr', 'ptr', 'ptr', 'i32', 'i32', 'ptr'] });
        lines.push(`  call void @shllvm_closure(ptr ${o.result ? slotPtr(o.result) : '%discard'}, ptr %shr, ptr %frame, i32 ${unitIndex(o.attrs.callee)}, i32 ${o.args.length}, ptr %argv)      ; @${o.attrs.callee} · may collect`);
        return;
      }
      emitHelper(lines, declare, bd, o, ptrOf, slotPtr, nArgs, T);
    });
    const term = b.term;
    ptrOf.reset();
    const copyEdge = (e, target) => {
      const tb = fn.block(e.block); if (!tb) return;
      const implicit = tb.params.length - e.args.length;
      const loaded = e.args.map(a => { const x = T(); lines.push(`  ${x} = load i64, ptr ${ptrOf(a)}, align 8`); return x; });
      loaded.forEach((x, k) => lines.push(`  store i64 ${x}, ptr ${slotPtr(tb.params[k + implicit].id)}, align 8`));
    };
    switch (term.kind) {
      case 'jump': copyEdge(term.to); lines.push(`  br label %b.${safeName(term.to.block)}`); break;
      case 'branch': {
        declare('shllvm_truthy', { ret: 'i32', args: ['ptr'] });
        const c = T(), d = T(); lines.push(`  ${c} = call i32 @shllvm_truthy(ptr ${ptrOf(term.cond)})`, `  ${d} = icmp ne i32 ${c}, 0`);
        const tl = `e.${safeName(b.name)}.t`, fl = `e.${safeName(b.name)}.f`;
        lines.push(`  br i1 ${d}, label %${tl}, label %${fl}`, `${tl}:`); copyEdge(term.t); lines.push(`  br label %b.${safeName(term.t.block)}`, `${fl}:`); copyEdge(term.f); lines.push(`  br label %b.${safeName(term.f.block)}`);
        break;
      }
      case 'return': { const x = T(); declare('shllvm_leave', { ret: 'void', args: ['ptr', 'ptr'] }); lines.push(`  ${x} = load i64, ptr ${ptrOf(term.value)}, align 8`, '  call void @shllvm_leave(ptr %shr, ptr %frame)', `  ret i64 ${x}`); break; }
      case 'throw': declare('shllvm_throw', { ret: 'void', args: ['ptr', 'ptr'] }); lines.push(`  call void @shllvm_throw(ptr %shr, ptr ${ptrOf(term.value)})`, '  unreachable'); break;
      case 'unreachable': lines.push('  unreachable'); break;
      case 'invoke': {
        const bd = bindings[`${fn.name}/${b.name}/term`];
        if (!tries.has(term.exc.block)) tries.set(term.exc.block, ++tryN);
        lines.push(`  store volatile i32 ${tries.get(term.exc.block)}, ptr %try_state, align 4    ; invoke: a throw goes to ${term.exc.block}`);
        emitHelper(lines, declare, bd, { ...term.op, result: fn.block(term.normal.block).params[0] && opRegistry[term.op.op].results.length ? fn.block(term.normal.block).params[0].id : null }, ptrOf, slotPtr, nArgs, T);
        lines.push(`  store volatile i32 ${stateOf(b)}, ptr %try_state, align 4    ; back to this block's region`);
        copyEdge(term.normal); lines.push(`  br label %b.${safeName(term.normal.block)}`); break;
      }
    }
  }
  if (hasTry) {
    declare('shllvm_catch_value', { ret: 'void', args: ['ptr', 'ptr'] }); declare('shllvm_rethrow', { ret: 'void', args: ['ptr'] });
    lines.push('catch.dispatch:', '  %state = load volatile i32, ptr %try_state, align 4', '  switch i32 %state, label %catch.rethrow [');
    for (const [h, n] of tries) lines.push(`    i32 ${n}, label %h.${safeName(h)}`);
    lines.push('  ]', 'catch.rethrow:', '  call void @shllvm_rethrow(ptr %shr)', '  unreachable');
    for (const [h] of tries) {
      const hb = fn.block(h);
      lines.push(`h.${safeName(h)}:`, `  call void @shllvm_catch_value(ptr ${hb && hb.params[0] ? slotPtr(hb.params[0].id) : '%discard'}, ptr %shr)`, `  br label %b.${safeName(h)}`);
    }
  }
  lines.push('}');
  if (maxLiterals > 2) lines.splice(extraLiteralsAt, 0, ...Array.from({ length: maxLiterals - 2 }, (_, i) => `  %lit${i + 2} = alloca i64, align 8                 ; a literal operand beyond the first two`));
  return { text: lines.join('\n'), declarations: [...decls].sort() };
}

function emitHelper(lines, declare, bd, o, ptrOf, slotPtr, nArgs, T) {
  const out = o.result ? slotPtr(o.result) : '%discard';
  const name = bd.name;
  if (name === 'shllvm_call') {
    const method = o.op === 'js.call_method';
    const [f, self, ...args] = method ? [o.args[0], o.args[0], ...o.args.slice(2)] : o.args;
    if (method) {                                    // the callee is the property, read first
      declare('shllvm_get', { ret: 'void', args: ['ptr', 'ptr', 'ptr', 'ptr'] });
      lines.push(`  call void @shllvm_get(ptr %scratch, ptr %shr, ptr ${ptrOf(o.args[0])}, ptr ${ptrOf(o.args[1])})      ; may collect`);
    }
    args.forEach((a, k) => {                         // arguments go straight into argv
      const p = T(); lines.push(`  ${p} = getelementptr i64, ptr %argv, i32 ${k}`);
      if (isLit(a)) { ptrOf.literal(a, p); return; }
      const x = T(); lines.push(`  ${x} = load i64, ptr ${slotPtr(a)}, align 8`, `  store i64 ${x}, ptr ${p}, align 8`);
    });
    declare(name, { ret: 'void', args: ['ptr', 'ptr', 'ptr', 'ptr', 'ptr', 'ptr', 'i32', 'ptr'] });
    // The method sits in %scratch, so a literal `this` (only for plain calls) also uses %scratch.
    const calleePtr = method ? '%scratch' : ptrOf(f);
    const thisPtr = method ? ptrOf(self) : (isLit(self) ? ptrOf.literal(self, '%discard') : ptrOf(self));
    lines.push(`  call void @shllvm_call(ptr ${out}, ptr %shr, ptr %frame, ptr ${calleePtr}, ptr ${thisPtr}, ptr null, i32 ${args.length}, ptr %argv)      ; may collect`);
    return;
  }
  const args = o.args.map(a => `ptr ${ptrOf(a)}`);
  const sig = ['ptr', 'ptr', ...o.args.map(() => 'ptr')];
  declare(name, { ret: 'void', args: bd.code ? ['ptr', 'ptr', 'i32', ...o.args.map(() => 'ptr')] : sig });
  const code = bd.code ? `, i32 ${opCodeNumber(bd.code)}` : '';
  lines.push(`  call void @${name}(ptr ${out}, ptr %shr${code}${args.length ? ', ' + args.join(', ') : ''})${bd.collects ? '      ; may collect' : ''}`);
}

const OPCODES = ['add', 'sub', 'mul', 'div', 'mod', 'lt', 'le', 'gt', 'ge', 'strict_eq', 'strict_ne', 'neg', 'typeof', 'print', 'queueMicrotask', 'setTimeout', 'Promise.resolve'];
const opCodeNumber = code => Math.max(0, OPCODES.indexOf(code));
const safeName = s => String(s).replace(/[^\w.]/g, '_');
const numLit = n => (Number.isFinite(n) ? (Number.isInteger(n) ? n.toFixed(1) : String(n)) : (Number.isNaN(n) ? '0x7FF8000000000000' : n > 0 ? '0x7FF0000000000000' : '0xFFF0000000000000'));
function boxBits(v) {                              // Hermes NaN-boxing: doubles as themselves, the rest tagged
  if (typeof v === 'number') { const b = new DataView(new ArrayBuffer(8)); b.setFloat64(0, v); return '0x' + b.getBigUint64(0).toString(16).toUpperCase().padStart(16, '0'); }
  if (v === true) return '0xFFF9000000000001';
  if (v === false) return '0xFFF9000000000000';
  if (v === null) return '0xFFF8C00000000000';
  return '0xFFF8800000000000';                     // undefined
}

// A structural check of the emitted text: labels defined once, every block terminated,
// every local defined before use, every called function declared.
function checkLLVM(text, declarations = []) {
  const errors = [], lines = text.split('\n').map(l => l.replace(/;.*$/, ''));
  const callable = new Set(declarations.map(d => /@([\w.]+)\(/.exec(d)[1]));
  for (const l of lines) { const m = /^define [^@]*@([\w.]+)\(/.exec(l.trim()); if (m) callable.add(m[1]); }
  const defined = new Set(['%shr']), labels = new Set();
  lines.forEach(l => { const m = /^\s*(%[\w.]+)\s*=/.exec(l); if (m) defined.add(m[1]); const lb = /^([\w.]+):\s*$/.exec(l.trim()); if (lb) { if (labels.has(lb[1])) errors.push({ message: `label ${lb[1]} defined twice` }); labels.add(lb[1]); } });
  let open = false, last = '';
  lines.forEach((raw, i) => {
    const line = raw.trim(); if (!line) return;
    if (/^define /.test(line)) { open = false; return; }
    if (/^[\w.]+:$/.test(line)) { if (open && !/^(br|ret|unreachable|switch|\])/.test(last)) errors.push({ line: i + 1, message: `the block before ${line} does not end in a terminator` }); open = true; last = ''; return; }
    for (const m of line.matchAll(/label %([\w.]+)/g)) if (!labels.has(m[1])) errors.push({ line: i + 1, message: `branch to unknown label %${m[1]}` });
    const rest = line.replace(/label %[\w.]+/g, '').replace(/^%[\w.]+\s*=/, '');
    for (const m of rest.matchAll(/%[\w.]+/g)) if (!defined.has(m[0])) errors.push({ line: i + 1, message: `${m[0]} is used but never defined` });
    for (const m of line.matchAll(/call [\w]+ @([\w.]+)\(/g)) if (!callable.has(m[1])) errors.push({ line: i + 1, message: `@${m[1]} is called but not declared` });
    if (line !== '}') last = line;
  });
  return { ok: errors.length === 0, errors: errors.slice(0, 20) };
}

// ---------------------------------------------------------------- WebAssembly for the core profile
// Functions that use only numbers, booleans and direct calls become a real Wasm module.
// Wasm wants structured control flow, so the CFG becomes a dispatch loop: a local holds
// the next block's index and br_table jumps to its code. Edge arguments are pushed on the
// operand stack, then stored into the target's parameters: a parallel copy for free.

const WASM_OPS = {
  'num.add': [0xa0], 'num.sub': [0xa1], 'num.mul': [0xa2], 'num.div': [0xa3], 'num.neg': [0x9a],
  'num.lt': [0x63], 'num.gt': [0x64], 'num.le': [0x65], 'num.ge': [0x66], 'num.eq': [0x61], 'num.ne': [0x62],
  'bool.not': [0x45], 'bool.and': [0x71], 'bool.or': [0x72],
  'i32.add': [0x6a], 'i32.sub': [0x6b], 'i32.mul': [0x6c], 'i32.lt': [0x48], 'i32.eq': [0x46],
};
const WAT_NAMES = { 0xa0: 'f64.add', 0xa1: 'f64.sub', 0xa2: 'f64.mul', 0xa3: 'f64.div', 0x9a: 'f64.neg', 0x63: 'f64.lt', 0x64: 'f64.gt', 0x65: 'f64.le', 0x66: 'f64.ge', 0x61: 'f64.eq', 0x62: 'f64.ne', 0x45: 'i32.eqz', 0x71: 'i32.and', 0x72: 'i32.or', 0x6a: 'i32.add', 0x6b: 'i32.sub', 0x6c: 'i32.mul', 0x48: 'i32.lt_s', 0x46: 'i32.eq' };
const F64 = 0x7c, I32 = 0x7f;

function wasmEligible(module, fn, types) {
  for (const b of fn.blocks) {
    for (const o of b.ops) {
      if (WASM_OPS[o.op] || o.op === 'num.mod' || o.op === 'core.copy') continue;
      if (o.op === 'host.print') { if (o.args.every(a => types.typeOf(a).le(t.number.join(t.boolean)) || (isLit(a) && typeof a.lit !== 'string'))) continue; return `host.print of a value that is not a number or boolean in ${b.name}`; }
      if (o.op === 'core.call') { const c = module.fn(o.attrs.callee); if (c && c !== fn && typeof wasmEligible(module, c, solveTypes(c)) === 'string') return `calls @${o.attrs.callee}, which is not in the core profile`; continue; }
      return `${o.op} in ${b.name} is outside the core profile (numbers, booleans, direct calls)`;
    }
    if (b.term.kind === 'invoke' || b.term.kind === 'throw') return `${b.term.kind} in ${b.name}: Wasm here has no exceptions`;
  }
  const used = usesOf(fn);
  for (const v of fn.values()) {
    if (!used.has(v) && fn.params.some(p => p.id === v)) continue;   // an unused parameter (such as `this`) is passed as 0
    const ty = types.typeOf(v); if (!ty.isBottom && !ty.le(t.number.join(t.boolean))) return `${v}: ${ty} is not a number or boolean`;
  }
  return true;
}

function encodeWasm(module, names) {
  const leb = n => { const out = []; do { let b = n & 0x7f; n >>>= 7; if (n) b |= 0x80; out.push(b); } while (n); return out; };
  const sleb = n => { const out = []; for (;;) { const b = n & 0x7f; n >>= 7; if ((n === 0 && !(b & 0x40)) || (n === -1 && (b & 0x40))) { out.push(b); return out; } out.push(b | 0x80); } };
  const str = s => [...leb(s.length), ...[...s].map(c => c.charCodeAt(0))];
  const vec = items => [...leb(items.length), ...items.flat()];
  const section = (id, body) => [id, ...leb(body.length), ...body];
  const f64 = v => { const b = new DataView(new ArrayBuffer(8)); b.setFloat64(0, v, true); return [...new Uint8Array(b.buffer)]; };
  const imports = [['print_num', [F64], []], ['print_bool', [I32], []], ['print_end', [], []], ['fmod', [F64, F64], [F64]]];
  const fns = names.map(n => module.fn(n));
  const typesOf = new Map(fns.map(f => [f.name, solveTypes(f)]));
  const vt = (f, v) => { const ty = typesOf.get(f.name).typeOf(v); return ty.le(t.boolean) && !ty.isBottom ? I32 : F64; };
  const sigs = [...imports.map(([, p, r]) => [p, r]), ...fns.map(f => [f.params.map(p => vt(f, p.id)), [f.result.le(t.boolean) && !f.result.isBottom ? I32 : F64]])];
  const typeSec = vec(sigs.map(([p, r]) => [0x60, ...vec(p.map(x => [x])), ...vec(r.map(x => [x]))]));
  const importSec = vec(imports.map(([name], i) => [...str('env'), ...str(name), 0x00, ...leb(i)]));
  const funcSec = vec(fns.map((f, i) => leb(imports.length + i)));
  const exportSec = vec(fns.map((f, i) => [...str(f.name), 0x00, ...leb(imports.length + i)]));
  const index = new Map(fns.map((f, i) => [f.name, imports.length + i]));
  const wat = [];
  const bodies = fns.map(f => {
    const locals = [], localIndex = new Map(), w = [];
    f.params.forEach((p, i) => localIndex.set(p.id, i));
    const extra = f.values().filter(v => !localIndex.has(v));
    extra.forEach((v, i) => { localIndex.set(v, f.params.length + i); locals.push(vt(f, v)); });
    const blk = f.params.length + extra.length; locals.push(I32);
    const code = [], n = f.blocks.length, bi = new Map(f.blocks.map((b, i) => [b.name, i]));
    const ind = d => '  '.repeat(d);
    w.push(`(func $${f.name} (export "${f.name}") ${f.params.map(p => `(param $${p.id} ${vt(f, p.id) === I32 ? 'i32' : 'f64'})`).join(' ')} (result ${sigs[index.get(f.name)][1][0] === I32 ? 'i32' : 'f64'})`);
    extra.forEach(v => w.push(`  (local $${v} ${vt(f, v) === I32 ? 'i32' : 'f64'})`)); w.push('  (local $blk i32)');
    const push = (a, depth, want) => {
      if (isLit(a)) {
        if (typeof a.lit === 'boolean' || want === I32) { code.push(0x41, ...sleb(a.lit ? 1 : 0)); w.push(ind(depth) + `i32.const ${a.lit ? 1 : 0}`); }
        else { code.push(0x44, ...f64(Number(a.lit))); w.push(ind(depth) + `f64.const ${a.lit}`); }
        return;
      }
      code.push(0x20, ...leb(localIndex.get(a))); w.push(ind(depth) + `local.get $${a}`);
    };
    code.push(0x03, 0x40); w.push('  (loop $dispatch');
    for (let k = n - 1; k >= 0; k--) { code.push(0x02, 0x40); w.push(ind(2 + (n - 1 - k)) + `(block $${f.blocks[k].name}`); }
    code.push(0x20, ...leb(blk), 0x0e, ...leb(n), ...f.blocks.flatMap((_, i) => leb(i)), ...leb(n - 1));
    w.push(ind(n + 2) + `(br_table ${f.blocks.map(b => '$' + b.name).join(' ')} (local.get $blk))`);
    f.blocks.forEach((b, k) => {
      code.push(0x0b);
      const d = 1 + (n - 1 - k);
      w.push(ind(d + 1) + `) ;; ${b.name}`);
      for (const o of b.ops) {
        if (o.op === 'host.print') {
          for (const a of o.args) { const isBool = isLit(a) ? typeof a.lit === 'boolean' : vt(f, a) === I32; push(a, d + 1, isBool ? I32 : F64); code.push(0x10, ...leb(isBool ? 1 : 0)); w.push(ind(d + 1) + `call $${isBool ? 'print_bool' : 'print_num'}`); }
          code.push(0x10, ...leb(2)); w.push(ind(d + 1) + 'call $print_end'); continue;
        }
        if (o.op === 'core.call') { o.args.forEach(a => push(a, d + 1)); code.push(0x10, ...leb(index.get(o.attrs.callee))); w.push(ind(d + 1) + `call $${o.attrs.callee}`); }
        else if (o.op === 'num.mod') { o.args.forEach(a => push(a, d + 1, F64)); code.push(0x10, ...leb(3)); w.push(ind(d + 1) + 'call $fmod'); }
        else if (o.op === 'core.copy') push(o.args[0], d + 1);
        else { const want = /^(bool|i32)\./.test(o.op) ? I32 : F64; o.args.forEach(a => push(a, d + 1, want)); code.push(...WASM_OPS[o.op]); w.push(ind(d + 1) + WAT_NAMES[WASM_OPS[o.op][0]]); }
        if (o.result) { code.push(0x21, ...leb(localIndex.get(o.result))); w.push(ind(d + 1) + `local.set $${o.result}`); }
        else if (o.op === 'core.call') { code.push(0x1a); w.push(ind(d + 1) + 'drop'); }
      }
      const goto = (e, depth, extra) => {          // extra: 1 inside an if
        const tb = f.block(e.block);
        e.args.forEach((a, i) => push(a, depth, vt(f, tb.params[i].id)));
        for (let i = tb.params.length - 1; i >= 0; i--) { code.push(0x21, ...leb(localIndex.get(tb.params[i].id))); w.push(ind(depth) + `local.set $${tb.params[i].id}`); }
        code.push(0x41, ...sleb(bi.get(e.block)), 0x21, ...leb(blk), 0x0c, ...leb(n - 1 - k + extra)); w.push(ind(depth) + `(local.set $blk (i32.const ${bi.get(e.block)}))`, ind(depth) + `br $dispatch`);
      };
      const term = b.term;
      if (term.kind === 'jump') goto(term.to, d + 1, 0);
      else if (term.kind === 'branch') {
        push(term.cond, d + 1, I32); code.push(0x04, 0x40); w.push(ind(d + 1) + 'if');
        goto(term.t, d + 2, 1); code.push(0x05); w.push(ind(d + 1) + 'else');
        goto(term.f, d + 2, 1); code.push(0x0b); w.push(ind(d + 1) + 'end');
      } else if (term.kind === 'return') { push(term.value, d + 1, sigs[index.get(f.name)][1][0]); code.push(0x0f); w.push(ind(d + 1) + 'return'); }
      else { code.push(0x00); w.push(ind(d + 1) + 'unreachable'); }
    });
    code.push(0x0b, 0x00, 0x0b); w.push('  ) ;; end dispatch', '  unreachable)');
    wat.push(w.join('\n'));
    const localDecls = vec(locals.map(x => [0x01, x]));
    const body = [...localDecls, ...code];
    return [...leb(body.length), ...body];
  });
  const codeSec = vec(bodies.map(b => [b]).map(x => x[0]));
  const bin = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, ...section(1, typeSec), ...section(2, importSec), ...section(3, funcSec), ...section(7, exportSec), ...section(10, codeSec)];
  const watText = '(module\n  (import "env" "print_num" (func $print_num (param f64)))\n  (import "env" "print_bool" (func $print_bool (param i32)))\n  (import "env" "print_end" (func $print_end))\n  (import "env" "fmod" (func $fmod (param f64 f64) (result f64)))\n' + wat.map(x => x.split('\n').map(l => '  ' + l).join('\n')).join('\n') + '\n)';
  return { bytes: new Uint8Array(bin), wat: watText };
}

function runWasm(module, names, entry, args = []) {
  const { bytes, wat } = encodeWasm(module, names);
  const output = [], trace = [];
  let line = [];
  const env = {
    print_num: x => line.push(x), print_bool: x => line.push(!!x),
    print_end: () => { output.push(line.map(v => (Object.is(v, -0) ? '0' : String(v))).join(' ')); trace.push({ type: 'print', values: line }); line = []; },
    fmod: (a, b) => a % b,
  };
  const mod = new WebAssembly.Module(bytes);
  const inst = new WebAssembly.Instance(mod, { env });
  const t0 = now();
  const raw = inst.exports[entry](...args);
  const fnDef = module.fn(entry);
  const value = fnDef.result.le(t.boolean) && !fnDef.result.isBottom ? !!raw : raw;
  return { kind: 'run', mode: 'wasm', outcome: { kind: 'normal', value, display: String(value) }, output, trace, events: output.map((l, i) => ({ n: i, type: 'print', line: l })), steps: 0, records: [], metrics: { steps: 0, bytes: bytes.length, ms: round(now() - t0, 3) }, wat, bytes: bytes.length };
}
