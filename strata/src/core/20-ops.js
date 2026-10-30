
// ---------------------------------------------------------------- operations and contracts
// An operation's contract is the one place its behaviour is declared: operand and
// result types, a reference step (what it means), a behaviour summary, runtime
// obligations, how it lowers, and the cheaper variants that facts may select.

class OpDef {
  constructor(spec) {
    Object.assign(this, {
      name: spec.name, set: spec.set || spec.name.split('.')[0],
      operands: spec.operands || [], variadic: !!spec.variadic, results: spec.results || [],
      behaviour: spec.behaviour || fx.none, obligations: spec.obligations || ob.none,
      step: spec.step || null, resultType: spec.resultType || null, lower: spec.lower || null,
      narrow: spec.narrow || null, laws: spec.laws || {}, about: spec.about || '', attrs: spec.attrs || [],
    });
    Object.freeze(this);
  }
  with(patch) { return new OpDef({ ...this, ...patch }); }
  operandsOf(...types) { return this.with({ operands: types }); }
  resultsOf(...types) { return this.with({ results: types }); }
  behaves(b) { return this.with({ behaviour: b }); }
  obliges(o) { return this.with({ obligations: o }); }
  steps(fn) { return this.with({ step: fn }); }
  get mayThrow() { return this.behaviour.throws; }
  get mayCollect() { return this.obligations.has('mayCollect'); }
  get contract() { return { behaviour: this.behaviour, obligations: this.obligations }; }
  typeOf(argTypes, op, fn) {
    if (this.resultType) return this.resultType(argTypes, op, fn);
    return this.results[0] || t.undefined;
  }
  toJSON() { return { name: this.name, behaviour: this.behaviour.toString(), obligations: this.obligations.toString() }; }
  yamlTag() { return `op ${this.name}`; }
}

// The fluent builder spelled as on the API page: g.op('x').operands(...).results(...)...
function opBuilder(name) {
  let spec = { name };
  const b = {
    operands: (...ts) => (spec.operands = ts, b), results: (...ts) => (spec.results = ts, b),
    behaviour: x => (spec.behaviour = x, b), obligations: x => (spec.obligations = x, b),
    step: f => (spec.step = f, b), resultType: f => (spec.resultType = f, b),
    lower: l => (spec.lower = l, b), narrow: f => (spec.narrow = f, b), laws: l => (spec.laws = l, b),
    about: s => (spec.about = s, b), variadic: () => (spec.variadic = true, b),
    build: () => new OpDef(spec),
  };
  Object.defineProperty(b, 'def', { get: () => new OpDef(spec) });
  return b;
}

// Behaviours used by many operations.
const USER = fx.callsUser;                          // may run getters, valueOf, proxies…
const ALLOC = fx.fresh;
const COLLECTS = ob.mayCollect;
const CALLING = ob.join(ob.mayCollect, ob.nonlocalThrow);

const N = t.number, A = t.any, B = t.boolean, S = t.string;
const numeric = (types) => types.every(x => x.le(t.number));
const stringy = (types) => types.some(x => x.le(t.string));

// The result type of js.add from its operand types: string if either is a string,
// number if neither can become a string, otherwise either.
const addType = ([a, b]) => {
  if (a.isBottom || b.isBottom) return t.bottom;   // an operand with no value yet: nothing flows out
  const prim = t.number.join(t.boolean).join(t.null).join(t.undefined);
  if (a.le(t.string) || b.le(t.string)) return t.string;
  if (a.le(prim) && b.le(prim)) return t.number;
  return t.number.join(t.string);
};

const STD = [
  // core: numbers, booleans, identity, guards, direct calls
  { name: 'num.add', operands: [N, N], results: [N], step: (s, [a, b]) => a + b, laws: { commutative: true, associative: false }, lower: { inline: 'fadd' } },
  { name: 'num.sub', operands: [N, N], results: [N], step: (s, [a, b]) => a - b, lower: { inline: 'fsub' } },
  { name: 'num.mul', operands: [N, N], results: [N], step: (s, [a, b]) => a * b, laws: { commutative: true, associative: false }, lower: { inline: 'fmul' } },
  { name: 'num.div', operands: [N, N], results: [N], step: (s, [a, b]) => a / b, lower: { inline: 'fdiv' } },
  { name: 'num.mod', operands: [N, N], results: [N], step: (s, [a, b]) => a % b, lower: { inline: 'frem' } },
  { name: 'num.neg', operands: [N], results: [N], step: (s, [a]) => -a, lower: { inline: 'fneg' } },
  { name: 'num.lt', operands: [N, N], results: [B], step: (s, [a, b]) => a < b, lower: { inline: 'fcmp olt' } },
  { name: 'num.le', operands: [N, N], results: [B], step: (s, [a, b]) => a <= b, lower: { inline: 'fcmp ole' } },
  { name: 'num.gt', operands: [N, N], results: [B], step: (s, [a, b]) => a > b, lower: { inline: 'fcmp ogt' } },
  { name: 'num.ge', operands: [N, N], results: [B], step: (s, [a, b]) => a >= b, lower: { inline: 'fcmp oge' } },
  { name: 'num.eq', operands: [N, N], results: [B], step: (s, [a, b]) => a === b, lower: { inline: 'fcmp oeq' } },
  { name: 'num.ne', operands: [N, N], results: [B], step: (s, [a, b]) => a !== b, lower: { inline: 'fcmp une' } },
  { name: 'i32.add', operands: [t.int32, t.int32], results: [t.int32], step: (s, [a, b]) => (a + b) | 0, laws: { commutative: true, associative: true }, lower: { inline: 'add i32' } },
  { name: 'i32.sub', operands: [t.int32, t.int32], results: [t.int32], step: (s, [a, b]) => (a - b) | 0, lower: { inline: 'sub i32' } },
  { name: 'i32.mul', operands: [t.int32, t.int32], results: [t.int32], step: (s, [a, b]) => Math.imul(a, b), laws: { commutative: true, associative: true }, lower: { inline: 'mul i32' } },
  { name: 'i32.lt', operands: [t.int32, t.int32], results: [B], step: (s, [a, b]) => a < b, lower: { inline: 'icmp slt' } },
  { name: 'i32.eq', operands: [t.int32, t.int32], results: [B], step: (s, [a, b]) => a === b, lower: { inline: 'icmp eq' } },
  { name: 'bool.not', operands: [B], results: [B], step: (s, [a]) => !a, lower: { inline: 'xor i1' } },
  { name: 'bool.and', operands: [B, B], results: [B], step: (s, [a, b]) => a && b, lower: { inline: 'and i1' } },
  { name: 'bool.or', operands: [B, B], results: [B], step: (s, [a, b]) => a || b, lower: { inline: 'or i1' } },
  { name: 'core.copy', operands: [t.top], results: [t.top], step: (s, [a]) => a, resultType: ([a]) => a, lower: { inline: 'copy' } },
  { name: 'core.ref_eq', operands: [A, A], results: [B], step: (s, [a, b]) => s.sameRef(a, b), lower: { inline: 'icmp eq i64' } },
  { name: 'core.is_number', operands: [A], results: [B], step: (s, [a]) => typeof a === 'number', lower: { helper: 'shllvm_typeof_is' } },
  { name: 'core.is_int32', operands: [A], results: [B], step: (s, [a]) => typeof a === 'number' && (a | 0) === a && !Object.is(a, -0), lower: { helper: 'shllvm_typeof_is' } },
  { name: 'core.call', variadic: true, results: [A], behaviour: USER, obligations: CALLING, attrs: ['callee'],
    step: (s, args, op) => s.callDirect(op.attrs.callee, args), resultType: (ts, op, fn) => {
      if (op && op.attrs.resultType) return t.parse(op.attrs.resultType);
      const callee = fn && fn.module && op && fn.module.fn(op.attrs.callee);   // the callee's declared result
      return callee ? callee.result : t.any;
    }, lower: { direct: true } },

  // js.value: the JavaScript operators. Those that convert objects may run user code.
  { name: 'js.add', operands: [A, A], results: [A], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.add(a, b), resultType: addType,
    narrow: ts => numeric(ts) ? 'num.add' : ts.every(x => x.le(t.string)) ? 'str.concat' : null, lower: { helper: 'shllvm_binary', code: 'add' } },
  { name: 'js.sub', operands: [A, A], results: [N], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.toNumber(a) - s.toNumber(b), narrow: ts => numeric(ts) ? 'num.sub' : null, lower: { helper: 'shllvm_binary', code: 'sub' } },
  { name: 'js.mul', operands: [A, A], results: [N], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.toNumber(a) * s.toNumber(b), narrow: ts => numeric(ts) ? 'num.mul' : null, lower: { helper: 'shllvm_binary', code: 'mul' } },
  { name: 'js.div', operands: [A, A], results: [N], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.toNumber(a) / s.toNumber(b), narrow: ts => numeric(ts) ? 'num.div' : null, lower: { helper: 'shllvm_binary', code: 'div' } },
  { name: 'js.mod', operands: [A, A], results: [N], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.toNumber(a) % s.toNumber(b), narrow: ts => numeric(ts) ? 'num.mod' : null, lower: { helper: 'shllvm_binary', code: 'mod' } },
  { name: 'js.neg', operands: [A], results: [N], behaviour: USER, obligations: CALLING, step: (s, [a]) => -s.toNumber(a), narrow: ts => numeric(ts) ? 'num.neg' : null, lower: { helper: 'shllvm_unary', code: 'neg' } },
  { name: 'js.lt', operands: [A, A], results: [B], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.compare(a, b, (x, y) => x < y), narrow: ts => numeric(ts) ? 'num.lt' : null, lower: { helper: 'shllvm_binary', code: 'lt' } },
  { name: 'js.le', operands: [A, A], results: [B], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.compare(a, b, (x, y) => x <= y), narrow: ts => numeric(ts) ? 'num.le' : null, lower: { helper: 'shllvm_binary', code: 'le' } },
  { name: 'js.gt', operands: [A, A], results: [B], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.compare(a, b, (x, y) => x > y), narrow: ts => numeric(ts) ? 'num.gt' : null, lower: { helper: 'shllvm_binary', code: 'gt' } },
  { name: 'js.ge', operands: [A, A], results: [B], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.compare(a, b, (x, y) => x >= y), narrow: ts => numeric(ts) ? 'num.ge' : null, lower: { helper: 'shllvm_binary', code: 'ge' } },
  { name: 'js.strict_eq', operands: [A, A], results: [B], step: (s, [a, b]) => s.strictEquals(a, b), narrow: ts => numeric(ts) ? 'num.eq' : null, lower: { helper: 'shllvm_binary', code: 'strict_eq' } },
  { name: 'js.strict_ne', operands: [A, A], results: [B], step: (s, [a, b]) => !s.strictEquals(a, b), narrow: ts => numeric(ts) ? 'num.ne' : null, lower: { helper: 'shllvm_binary', code: 'strict_ne' } },
  { name: 'js.not', operands: [A], results: [B], step: (s, [a]) => !s.truthy(a), narrow: ts => ts[0].le(t.boolean) ? 'bool.not' : null, lower: { helper: 'shllvm_truthy' } },
  { name: 'js.truthy', operands: [A], results: [B], step: (s, [a]) => s.truthy(a), resultType: () => t.boolean, narrow: ts => ts[0].le(t.boolean) ? 'core.copy' : null, lower: { helper: 'shllvm_truthy' } },
  { name: 'js.typeof', operands: [A], results: [S], step: (s, [a]) => s.typeOf(a), lower: { helper: 'shllvm_unary', code: 'typeof' } },
  { name: 'str.concat', operands: [S, S], results: [S], behaviour: ALLOC, obligations: COLLECTS, step: (s, [a, b]) => a + b, lower: { helper: 'shllvm_binary', code: 'add' } },

  // js.object: allocation and properties. A get or put may run a getter or setter.
  { name: 'obj.new', results: [t.object], behaviour: ALLOC, obligations: COLLECTS, step: s => s.newObject(), lower: { helper: 'shllvm_object' } },
  { name: 'arr.new', variadic: true, results: [t.object], behaviour: ALLOC, obligations: COLLECTS, step: (s, args) => s.newArray(args), lower: { helper: 'shllvm_array' } },
  { name: 'js.define', operands: [t.object, S, A], results: [], behaviour: fx.writes('heap'), obligations: ob.join(COLLECTS, ob.writeBarrier), step: (s, [o, k, v]) => s.define(o, k, v), lower: { helper: 'shllvm_define' } },
  { name: 'js.define_getter', operands: [t.object, S, t.function], results: [], behaviour: fx.writes('heap'), obligations: ob.join(COLLECTS, ob.writeBarrier), step: (s, [o, k, f]) => s.defineAccessor(o, k, f, 'get'), lower: { helper: 'shllvm_define_accessor' } },
  { name: 'js.define_setter', operands: [t.object, S, t.function], results: [], behaviour: fx.writes('heap'), obligations: ob.join(COLLECTS, ob.writeBarrier), step: (s, [o, k, f]) => s.defineAccessor(o, k, f, 'set'), lower: { helper: 'shllvm_define_accessor' } },
  { name: 'js.get', operands: [A, t.propertyKey], results: [A], behaviour: USER, obligations: CALLING, step: (s, [o, k]) => s.getProperty(o, k), lower: { helper: 'shllvm_get' } },
  { name: 'js.put', operands: [A, t.propertyKey, A], results: [], behaviour: USER, obligations: ob.join(CALLING, ob.writeBarrier), step: (s, [o, k, v]) => s.setProperty(o, k, v), lower: { helper: 'shllvm_set' } },
  { name: 'js.get_own_data', operands: [t.object, t.propertyKey], results: [A], behaviour: fx.reads('heap'), step: (s, [o, k]) => s.getOwnData(o, k), lower: { helper: 'shllvm_get_id' } },

  // js.function: closures, calls, cells (the storage of captured variables)
  { name: 'js.closure', variadic: true, results: [t.function], behaviour: ALLOC, obligations: COLLECTS, attrs: ['callee'], step: (s, caps, op) => s.newClosure(op.attrs.callee, caps), lower: { helper: 'shllvm_closure' } },
  { name: 'js.call', variadic: true, results: [A], behaviour: USER, obligations: CALLING, step: (s, [f, self, ...args]) => s.callValue(f, self, args), lower: { helper: 'shllvm_call' } },
  { name: 'js.call_method', variadic: true, results: [A], behaviour: USER, obligations: CALLING, step: (s, [o, key, ...args]) => s.callMethod(o, key, args), lower: { helper: 'shllvm_call' } },
  { name: 'cell.new', variadic: true, results: [t.cell], behaviour: ALLOC, obligations: COLLECTS, step: (s, args) => s.newCell(args.length ? args[0] : s.HOLE), lower: { helper: 'shllvm_env_create' } },
  { name: 'cell.load', operands: [t.cell], results: [A], behaviour: fx.reads('cells'), step: (s, [c]) => s.cellLoad(c, false), lower: { helper: 'shllvm_env_load' } },
  { name: 'cell.load_checked', operands: [t.cell], results: [A], behaviour: fx.reads('cells').join(fx.throws), obligations: ob.nonlocalThrow, step: (s, [c], op) => s.cellLoad(c, true, op.attrs.name), lower: { helper: 'shllvm_check_tdz' } },
  { name: 'cell.store', operands: [t.cell, A], results: [], behaviour: fx.writes('cells'), obligations: ob.writeBarrier, step: (s, [c, v]) => s.cellStore(c, v), lower: { helper: 'shllvm_env_store' } },
  { name: 'js.global_get', operands: [S], results: [A], behaviour: fx.reads('globals').join(fx.throws), obligations: ob.nonlocalThrow, step: (s, [n]) => s.globalGet(n), lower: { helper: 'shllvm_global' } },
  { name: 'js.global_put', operands: [S, A], results: [], behaviour: fx.writes('globals'), obligations: ob.writeBarrier, step: (s, [n, v]) => s.globalPut(n, v), lower: { helper: 'shllvm_declare_global' } },
  { name: 'js.new_error', operands: [A], results: [t.object], behaviour: ALLOC.join(USER), obligations: CALLING, attrs: ['kind'], step: (s, [m], op) => s.newError(op.attrs.kind || 'Error', m), lower: { helper: 'shllvm_constructed_object' } },
  { name: 'js.type_error', operands: [S], results: [], behaviour: fx.throws.join(ALLOC), obligations: CALLING, step: (s, [m]) => s.throwError('TypeError', m), lower: { helper: 'shllvm_throw_type_error' } },

  // js.control: the host, jobs, timers, promises, completion records for finally
  { name: 'host.print', variadic: true, results: [], behaviour: fx.host('print'), obligations: COLLECTS, step: (s, args) => s.print(args), lower: { helper: 'shllvm_builtin', code: 'print' } },
  { name: 'job.enqueue', variadic: true, results: [], behaviour: fx.writes('jobs'), obligations: COLLECTS, step: (s, [f, ...args]) => s.enqueue(f, args), lower: { helper: 'shllvm_builtin', code: 'queueMicrotask' } },
  { name: 'timer.set', operands: [t.function, N], results: [], behaviour: fx.writes('timers'), obligations: COLLECTS, step: (s, [f, d]) => s.setTimer(f, d), lower: { helper: 'shllvm_builtin', code: 'setTimeout' } },
  { name: 'promise.resolve', operands: [A], results: [t.object], behaviour: ALLOC.join(fx.writes('jobs')), obligations: COLLECTS, step: (s, [v]) => s.promiseResolve(v), lower: { helper: 'shllvm_builtin', code: 'Promise.resolve' } },
  { name: 'completion.normal', results: [t.completion], behaviour: ALLOC, obligations: COLLECTS, step: s => s.completion('normal'), lower: { helper: 'shllvm_object' } },
  { name: 'completion.return', operands: [A], results: [t.completion], behaviour: ALLOC, obligations: COLLECTS, step: (s, [v]) => s.completion('return', v), lower: { helper: 'shllvm_object' } },
  { name: 'completion.throw', operands: [A], results: [t.completion], behaviour: ALLOC, obligations: COLLECTS, step: (s, [v]) => s.completion('throw', v), lower: { helper: 'shllvm_object' } },
  { name: 'completion.is', operands: [t.completion], results: [B], attrs: ['kind'], step: (s, [c], op) => s.completionIs(c, op.attrs.kind), lower: { helper: 'shllvm_get_id' } },
  { name: 'completion.value', operands: [t.completion], results: [A], step: (s, [c]) => s.completionValue(c), lower: { helper: 'shllvm_get_id' } },
];

const ops = {};
for (const spec of STD) ops[spec.name] = new OpDef(spec);
const opRegistry = Object.assign({}, ops);         // std plus registered extensions

function lookupOp(name) {
  const d = opRegistry[name];
  if (!d) throw new StrataError(`unknown operation ${name}`, { kind: 'unknown-op' });
  return d;
}

// Operation sets group operations; union is a monoid over disjoint names.
class OpSet {
  constructor(name, defs = [], meta = {}) {
    this.name = name; this.version = meta.version || '0.1.0'; this.defs = new Map(defs.map(d => [d.name, d]));
    Object.freeze(this);
  }
  ops(...defs) { return new OpSet(this.name, [...this.defs.values(), ...defs.map(d => (d.def || d))], { version: this.version }); }
  get size() { return this.defs.size; }
  get(name) { return this.defs.get(name); }
  names() { return [...this.defs.keys()]; }
  register() { for (const d of this.defs.values()) opRegistry[d.name] = d; return this; }
  rename(prefix) { return new OpSet(prefix, [...this.defs.values()].map(d => d.with({ name: prefix + d.name.slice(d.name.indexOf('.')) })), { version: this.version }); }
  yamlTag() { return `opset ${this.name}@${this.version} (${this.defs.size} ops)`; }
}
function opsetUnion(...sets) {
  const out = new Map();
  for (const s of sets) for (const d of s.defs.values()) {
    if (out.has(d.name)) throw new StrataError(`OpsetConflict: ${d.name} defined twice`);
    out.set(d.name, d);
  }
  return new OpSet(sets.map(s => s.name).join('+'), [...out.values()]);
}

const SET_OF = name => {
  if (/^(num|i32|bool|core)\./.test(name) || name === 'host.print') return 'core';   // output is the core observation
  if (/^(js\.(add|sub|mul|div|mod|neg|lt|le|gt|ge|strict_eq|strict_ne|not|truthy|typeof)$|str\.)/.test(name)) return 'js.value';
  if (/^(obj|arr)\.|^js\.(define|get|put|get_own_data|new_error)/.test(name)) return 'js.object';
  if (/^(cell|js\.(closure|call|call_method|global_get|global_put|type_error))/.test(name)) return 'js.function';
  return 'js.control';
};
const opsets = {};
for (const d of Object.values(ops)) {
  const set = SET_OF(d.name);
  opsets[set] = (opsets[set] || new OpSet(set)).ops(d);
}
const OPSET_KEYS = { core: 'core', jsValue: 'js.value', jsObject: 'js.object', jsFunction: 'js.function', jsControl: 'js.control' };
for (const [k, v] of Object.entries(OPSET_KEYS)) opsets[k] = opsets[v];

// Narrowing: a general operation becomes a cheaper one when facts about its operand
// types justify it. The variant's contract must refine the general one under those facts.
function narrowOp(name, argTypes) {
  const d = lookupOp(name);
  return d.narrow ? d.narrow(argTypes) : null;
}

function permsOf(nameOrDef, facts = {}) {
  const d = typeof nameOrDef === 'string' ? lookupOp(nameOrDef) : (nameOrDef.def || nameOrDef);
  return derivePermissions(d.behaviour, facts);
}
