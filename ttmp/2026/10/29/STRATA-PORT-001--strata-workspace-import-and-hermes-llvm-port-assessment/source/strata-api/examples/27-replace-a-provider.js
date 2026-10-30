// 27 · Replacing one provider soundly (stage E, one operation set)
//
// Model: to own part of the runtime, re-implement one operation set against
// its contracts and swap the provider. Nothing else in the pipeline changes,
// because callers only see contracts (Law 2). The replacement is checked
// three ways: coverage, property tests against the reference steps, and
// differential runs against the provider it replaces (Hermes as oracle).
//
// Notice: the contract law finds a NaN bug in a hand-written strict equality
// before any application runs; the swap is one line in the pipeline.

import { g } from 'strata'

const { jsValue } = g.opsets

// Our own implementation of js.value, written in C and lowered as runtime calls.
const ours = g.provider('strata.js.value', { version: '0.1.0', runtime: 'libstrata_value.a' })
  .implements(jsValue)
  .lowers('js.typeof',    (op, $) => $.call('sv_typeof',    op.operands, { collects: false, throws: false }))
  .lowers('js.strict_eq', (op, $) => $.call('sv_strict_eq', op.operands, { collects: false, throws: false }))
  .lowers('js.to_number', (op, $) => $.call('sv_to_number', op.operands, { collects: true,  throws: 'nonlocal' }))
  .delegate(g.hermes.provider('js.value'))     // anything not lowered above stays with Hermes, declared

ours.covers(jsValue)
// → { ok: true, own: ['js.typeof', 'js.strict_eq', 'js.to_number'], delegated: 41 }

// 1. The contract law, against the reference steps, on generated values.
g.law.contract(ours, jsValue, { ops: ['js.strict_eq'], samples: 20000, values: g.values.js({ include: ['NaN', '-0', 'bigint', 'symbol'] }) })
// → { ok: false,
//     counterexample: { op: 'js.strict_eq', args: [NaN, NaN], reference: false, ours: true },
//     note: 'sv_strict_eq compares bit patterns; IsStrictlyEqual uses Number::equal' }

// The fix: sv_strict_eq_v2 compares numbers with Number::equal (NaN ≠ NaN, -0 === 0), then
// falls back to identity. Version 0.1.1 lowers strict equality to it.
const fixed = ours.version('0.1.1')
  .lowers('js.strict_eq', (op, $) => $.call('sv_strict_eq_v2', op.operands, { collects: false, throws: false }))
g.law.contract(fixed, jsValue, { ops: ['js.strict_eq', 'js.typeof', 'js.to_number'], samples: 20000 })
// → { ok: true, samples: 60000, obligationsObserved: { 'js.to_number': { collected: 57, threw: 311 } } }

// An obligation lie is caught too: claiming "never collects" for a helper that can run user code.
const liar = fixed.lowers('js.to_number', (op, $) => $.call('sv_to_number', op.operands, { collects: false, throws: 'nonlocal' }))
g.law.contract(liar, jsValue, { ops: ['js.to_number'], forceGC: 'inside-helpers' })
// → { ok: false, violation: 'sv_to_number called a user valueOf that allocated, but declared collects: false',
//     counterexample: { args: ['{ valueOf() { return [1].length } }'] } }

// 2. The swap is one line; every other choice stays.
const before = g.pipeline()
const after = before.provide('js.value', fixed)
g.diff(before, after)                          // → providers['js.value']: hermes → strata.js.value@0.1.1

// 3. Differential runs: the 26-example ladder and the four applications, both providers.
const diff = await g.differential({
  pipelines: { hermes: before, ours: after },
  corpus: [...g.corpus.ladder(), ...g.corpus.apps()],
  observe: 'js-async',
})
diff.summary()
// → { programs: 30, agree: 30, disagree: 0, runs: 120 }

// The decision is recorded with its evidence.
g.decision('own js.value?')
  .evidence(['contract law 60000 samples', 'differential 30 programs', 'obligations instrumented'])
  .choose('adopt strata.js.value@0.1.1 behind a flag')
