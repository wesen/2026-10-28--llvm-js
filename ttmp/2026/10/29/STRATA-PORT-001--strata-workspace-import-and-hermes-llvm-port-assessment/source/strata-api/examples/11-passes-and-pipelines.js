// 11 · Passes, pipelines and the checks between levels
//
// Model: a pass declares its input and output levels, the facts it requires,
// the guarantees it provides and the analyses it invalidates. Passes compose
// only when one's output satisfies the next one's requirements; the identity
// pass is the unit. Because refinement is transitive, a pipeline of correct
// passes is correct (Law 1); each level boundary still gets its own check, so
// a bug is caught in the pass that made it.
//
// Notice: requirement errors appear when the pipeline is built, not when it
// runs; `.passes()` replaces the pass list while `.insert()` adds one pass;
// invalidation forces recomputation; composition is associative by hash; the
// boundary-checks table makes the cost of each boundary explicit.

import { g } from 'strata'

// Named passes with declared contracts.
const importHermes = g.pass('import-hermes').from('L0').to('L1')
  .provides('verified-core')

const lowerRuntime = g.pass('lower-runtime').from('L1').to('L2')
  .requires('verified-core')
  .provides('runtime-bound')
  .invalidates('safepoints')                   // lowering adds runtime operations (boxing, helper calls) with their own safepoints

const analyze = g.pass.analyze(g.analysis.liveness, g.analysis.safepoints)   // an analysis pass: changes nothing

const planRoots = g.pass('plan-roots').from('L2').to('L3')
  .requires('runtime-bound', 'liveness', 'safepoints')
  .provides('root-plan')

const planUnwind = g.pass('plan-unwind').from('L3').to('L3')
  .requires('root-plan')
  .provides('unwind-plan')

const emit = g.pass('emit-llvm').from('L3').to('L4')
  .requires('root-plan', 'unwind-plan')

// The default pipeline uses this order, plus canonical rewrites after import-hermes and the
// behaviour and type-fact analyses; they are left out here to keep the list short.
// .passes(...) replaces the whole list.
const base = g.pipeline()
  .frontend(g.hermes.frontend({ optimize: false }))
  .passes(importHermes, lowerRuntime, analyze, planRoots, planUnwind, emit)
  .materialize(g.llvm.orc())

base.check()                                   // → { ok: true }

// Requirement errors are reported when the pipeline value is built.
g.pipeline().passes(planRoots).check()
// → { ok: false, diagnostics: [{ pass: 'plan-roots', missing: ['runtime-bound', 'liveness', 'safepoints'],
//                               hint: 'add lower-runtime and g.pass.analyze(liveness, safepoints) before it' }] }

// Invalidation: a CFG-changing pass after the analyses makes them stale.
const splitEdges = g.pass('split-critical-edges').from('L2').to('L2').invalidates('liveness', 'dominance')
const risky = base.insert(splitEdges, { after: 'analyze' })   // .insert adds one pass; the rest stays
risky.check()
// → { ok: true, inserted: [{ before: 'plan-roots', pass: 'analyze(liveness)', reason: 'invalidated by split-critical-edges' }] }
risky.check({ autoRecompute: false })
// → { ok: false, diagnostics: [{ pass: 'plan-roots', stale: ['liveness'], invalidatedBy: 'split-critical-edges' }] }

// Composition is a monoid: associative, with the identity pass as unit.
const a = lowerRuntime.then(analyze).then(planRoots)
const b = lowerRuntime.then(analyze.then(planRoots))
a.hash() === b.hash()                          // → true
lowerRuntime.then(g.pass.identity).hash() === lowerRuntime.hash()   // → true

// Each pass is tested for refinement on its own...
g.law.refines(lowerRuntime, { corpus: g.corpus.ladder(), profile: 'js-sync' })   // → { ok: true, programs: 26 }
g.law.refines(planRoots, { corpus: g.corpus.ladder(), profile: 'js-sync', forceGC: 'every-safepoint' })
// → { ok: true, programs: 26, collections: 4180 }
// ...and the composition follows by transitivity. It is still run end to end, as a check of the check.

// The checks at each boundary, with their cost. .checks({...}) sets switches (example 51);
// .boundaryChecks({...}) names what runs at each boundary.
const checked = base.boundaryChecks({
  'L0→L1': ['verify', 'interpret-vs-hermes'],
  'L1→L2': ['verify', 'legal: no unknown op survives'],
  'L2→L3': ['gc-safety', 'unwind-restoration'],
  'L3→L4': ['llvm-verify', 'descriptor-schema'],
  'L4→L5': ['abi', 'target', 'strategies'],
})
checked.summary().boundaryChecks
// → boundary  structural                         semantic                     mode
//   L0→L1     verify                             interpret-vs-hermes          check builds only
//   L1→L2     verify, legality                   translation validation: off  always / opt-in
//   L2→L3     gc-safety, unwind-restoration      forced GC in tests           always / tests
//   L3→L4     llvm-verify, descriptor-schema     differential vs interpreter  always / tests
//   L4→L5     abi, target, strategies            lifecycle tests              always / tests

// The trace shows every pass, its level and its cost.
const program = g.compile(checked, g.source.text(`function f(o, cb) { cb(); return o.value }`))
program.trace
// → [{ pass: 'import-hermes', level: 'L0→L1', ms: 0.41 }, { pass: 'lower-runtime', level: 'L1→L2', ms: 0.12 },
//    { pass: 'analyze', level: 'L2', ms: 0.05, note: 'liveness 3 iterations' }, { pass: 'plan-roots', ms: 0.03 }, …]
