// 08 · The specification: reference interpreter, profiles, observations
//
// Model: the reference interpreter steps a machine state
// (block, env, heap, continuation, jobs, trace). A behaviour is the trace of
// labels (output, host calls, job settlements) plus a final outcome (normal,
// throw, diverge). A profile names which language features are admitted and
// which observations are preserved. Two behaviours are equal up to a
// renaming of heap locations that preserves identity; numbers compare with
// SameValue. Running out of a resource is reported separately from meaning.
//
// Notice: the interpreter delegates operation sets we don't own to Hermes as a
// declared oracle; NaN and -0 are exact; a resource failure is not a semantic
// difference.

import { g, kib } from 'strata'

// The specification for the js-sync profile.
const partial = g.semantics()
  .profile('js-sync')
  .delegate('js.object', g.hermes.oracle())    // steps for sets we don't own come from Hermes, declared
  .delegate('js.value', g.hermes.oracle())

partial.coverage()
// → { owned: ['core', 'js.function.cells'], delegated: ['js.value', 'js.object'],
//     missing: ['js.function (calls)', 'js.control (exceptions)'] }

const spec = partial
  .delegate('js.function', g.hermes.oracle())
  .delegate('js.control', g.hermes.oracle())
spec.coverage()
// → { owned: ['core', 'js.function.cells'], delegated: ['js.value', 'js.object', 'js.function', 'js.control'], missing: [] }

// Profiles are values ordered by inclusion.
g.profile('core').le(g.profile('js-sync'))     // → true
g.profile('js-sync').observes
// → ['output', 'outcome', 'thrown value', 'object identity', 'heap mutation seen later']
g.profile('js-async').observes.includes('job order')   // → true

// Define a small teaching profile (the seminar's "minimal educational language").
const edu = g.profile.define('edu', {
  admits: ['core', 'js.function.cells', 'js.object.basic', 'js.control.exceptions'],
  observes: ['output', 'outcome', 'object identity'],
})

// Run a program and read its behaviour.
const src = g.source.text(`
const a = {}; const b = a;
print(a === b, 0 / -1, NaN)`)
const run = spec.run(g.compile(g.pipeline().stopAfter('L1'), src))
run.trace                                      // → [output(true, -0, NaN)]
run.outcome                                    // → normal(undefined)
run.steps                                      // → 31

// Equality of behaviours is defined, not ad hoc.
const other = spec.run(g.compile(g.pipeline().stopAfter('L1'), g.source.text(`
const b = {}; const a = b;
print(a === b, -0, NaN)`)))
g.observe.equal(run, other, { upTo: 'heap-renaming', numbers: 'SameValue' })
// → { equal: true }

const positiveZero = spec.run(g.compile(g.pipeline().stopAfter('L1'), g.source.text(`print(true, 0, NaN)`)))
g.observe.equal(run, positiveZero)
// → { equal: false, at: 'trace[0] argument 1', left: -0, right: 0, rule: 'SameValue distinguishes -0' }

// Resource limits are a separate profile, so storage changes can't masquerade as semantic changes.
// The specification's state has no roots or frames, so its resources are heap and steps.
const big = spec.run(g.corpus.apps().get('fflate-0.8.2'), { resources: { heapBytes: kib(64) } })
big.outcome                                    // → resource-exhausted('heapBytes')
g.observe.equal(big, spec.run(g.corpus.apps().get('fflate-0.8.2')))
// → { equal: 'unknown', reason: 'left run exhausted a resource; compare under equal budgets' }

// Refinement: every behaviour of the target is allowed by the source.
// A host profile may leave equal-deadline timers unordered; a concrete host picks one order.
const timers = g.source.text(`setTimeout(() => print('a'), 5); setTimeout(() => print('b'), 5)`)
const loose = g.semantics().profile('js-async').host({ timers: 'equal-deadline-unordered' })
loose.behaviours(timers)
// → { count: 2, traces: [[output('a'), output('b')], [output('b'), output('a')]] }
g.refines(g.compile(g.pipeline(), timers), timers, { via: loose })
// → { ok: true, target: 1 behaviour, source: 2 behaviours, note: 'refinement, not equivalence' }

// Divergence is an outcome, observed with a step budget, never by wall-clock timeout.
spec.run(g.source.text(`while (true) {}`), { steps: 1e6 }).outcome
// → diverges-within-budget(1000000 steps)   (inconclusive by design; not 'normal')
