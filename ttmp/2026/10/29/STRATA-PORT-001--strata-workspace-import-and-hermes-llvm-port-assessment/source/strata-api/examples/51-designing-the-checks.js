// 51 · Designing the verification process: which checks earn their cost?
//
// Model: the checks at each level boundary are themselves a design space.
// To compare check configurations, inject known bugs (mutants) into the
// compiler: drop a root, ignore edge arguments, erase a may-throw operation,
// forget an arena mark, swap two enqueues. A configuration's quality is which
// mutants it kills and at what cost in CI time. This is meta-design: the
// object being optimized is how we gain confidence in the compiler.
//
// Notice: the verifier alone kills two of eight mutants; one mutant survives
// everything except forced GC on exceptional edges, which justifies that
// check's cost; the cheapest configuration that kills all eight leaves out the
// gc-safety checker and the nightly laws, because other checks already cover
// what they find; the choice is recorded as a decision.

import { g, ms } from 'strata'

const mutants = g.mutants([
  g.mutant('drop-root', 'plan-roots omits one value live across a collecting call'),
  g.mutant('ignore-edge-args', 'liveness edge rule ignores block arguments'),
  g.mutant('erase-may-throw', 'erase-dead-result ignores behaviour.throws'),
  g.mutant('no-arena-mark', 'catch checkpoint does not save the arena mark'),
  g.mutant('swap-enqueues', 'scheduler pass sinks job.enqueue below another'),
  g.mutant('sequential-edge-copy', 'edge lowering writes before all reads'),
  g.mutant('bigint-via-f64', 'constant emission converts BigInt through double'),
  g.mutant('stale-fact', 'split-critical-edges keeps old type facts'),
])

const checks = g.design({
  verify:                g.param.choice([true], { default: true }),
  gcSafety:              g.param.choice([false, true]),
  translationValidation: g.param.choice([false, true]),
  forcedGC:              g.param.choice(['off', 'normal-edges', 'every-safepoint']),
  differential:          g.param.choice(['off', 'ladder', 'ladder+apps']),
  lawSuite:              g.param.choice(['off', 'nightly-5k']),
}, p => g.pipeline().checks(p))

const results = await g.search.grid(checks, {
  mutants,
  objective: g.objective.require(g.check.killsAll(mutants)).then(g.objective.minimize('ciMs')),
})

results.matrix()
// → mutant                 verify  gc-safety  tv   forcedGC(all)  differential  laws
//   drop-root              ·       ✓          ·    ✓              ✓ (apps)      ✓
//   ignore-edge-args       ·       ✓          ·    ✓              ·             ✓
//   erase-may-throw        ·       ·          ✓    ·              ✓             ✓
//   no-arena-mark          ·       ·          ·    ✓              ·             ·
//   swap-enqueues          ·       ·          ✓    ·              ✓             ✓
//   sequential-edge-copy   ·       ·          ✓    ·              ✓             ✓
//   bigint-via-f64         ✓       ·          ·    ·              ✓             ✓ (roundTrip)
//   stale-fact             ✓       ·          ·    ·              ·             ·
//   (illustrative)

results.best.point
// → { verify: true, gcSafety: false, translationValidation: false,
//     forcedGC: 'every-safepoint', differential: 'ladder', lawSuite: 'off' }
results.best.metrics                           // → { killed: 8/8, ciMs: 151000 }
// verify kills bigint-via-f64 and stale-fact; forced GC kills drop-root, ignore-edge-args and no-arena-mark;
// the ladder differential kills erase-may-throw, swap-enqueues and sequential-edge-copy.

// The interesting survivor: only forced GC across exceptional edges finds a missing arena mark.
results.survivors({ without: 'forcedGC' })     // → ['no-arena-mark']

// The configuration becomes a decision, with the mutant matrix as evidence.
g.decision('boundary checks for the first slice')
  .evidence([g.ref.search(results)])
  .choose(results.best.point)
  .overturnIf('a field bug that no configured check would have caught: add its mutant first')
