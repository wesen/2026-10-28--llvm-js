// 33 · Property tests, generated programs and differential fuzzing
//
// Model: laws are executable. Generators produce well-typed core IR (and
// small JS sources) within a profile; each law runs on them and returns
// either ok or a minimized counterexample. Differential fuzzing compares the
// reference interpreter with compiled code at each level boundary, so a
// disagreement points at the pass that introduced it. Counterexamples become
// fixtures and stay forever.
//
// Notice: the shrinker reduces a 40-block program to 3 blocks; the failing
// boundary (L2→L3) names the pass; fixtures carry the law that produced them.

import { g, ms } from 'strata'

// Generators.
const graphs = g.gen.coreIR({
  profile: 'js-sync',
  blocks: [1, 40], ops: [0, 12],
  include: ['invoke', 'loops', 'exceptional-edges', 'block-args-swaps', 'cells'],
  values: g.gen.values({ include: ['NaN', '-0', 'bigint', 'getters', 'proxies'] }),
})
// plan-roots runs on runtime IR (L2), so its law gets graphs already lowered and analysed.
const lowered = graphs.map(gr => g.pass.lowerRuntime.then(g.pass.analyze(g.analysis.liveness, g.analysis.safepoints)).run(gr))
const sources = g.gen.jsSource({ profile: 'js-async', size: [5, 60], features: ['closures', 'try', 'await', 'getters'] })

// The law suite, as one value.
const suite = g.laws([
  g.law.join(g.fx),
  g.law.antitone(g.perm),
  g.law.monotone(g.analysis.liveness),
  g.law.monotone(g.analysis.typeFacts),
  g.law.idempotent(g.rewrites.canonical()),
  g.law.roundTrip(g.ir.json, { exact: ['bigint bytes', 'utf16'] }),
  g.law.parallelTransfer(g.lower.edges),
  g.law.refines(g.pass.lowerRuntime, { corpus: graphs }),
  g.law.refines(g.pass.planRoots, { corpus: lowered, forceGC: 'every-safepoint' }),
])

const report = await suite.run({ samples: 5000, seed: 2026, budget: ms(60000) })
report.summary()
// → 9 laws · 8 ok · 1 failed · 45000 samples · 41.3 s

const failure = report.failures[0]
failure.law                                    // → 'refines(plan-roots, forceGC every-safepoint)'
failure.original.size                          // → { blocks: 40, ops: 311 }
failure.minimized.size                         // → { blocks: 3, ops: 3 }   (one invoke, two returns)
failure.minimized.text
// → fn m(o: any, k: any) -> any {
//   entry:
//     invoke js.get(o, k) normal next(o) throw h(o)
//   next(v: any, o2: any):
//     return o2
//   h(e: any, o3: any):
//     return o3
//   }
failure.explanation
// → "o is live only through edge arguments on both successors; the plan rooted it for 'next'
//    but not for the exceptional edge to 'h'"

// Differential fuzzing across levels localizes the bug.
const fuzz = await g.fuzz.differential({
  inputs: sources,
  pipeline: g.pipeline().use(g.preset.debug),
  compare: ['interpreter@L1', 'interpreter@L2', 'executor@L3', 'engine@L5'],
  budget: ms(60000),
})
fuzz.disagreements[0]
// → { firstDivergence: 'L2→L3 (plan-roots)', L1: [output(true, 1)], L2: [output(true, 1)],
//     L3: [output(false, 1)], L5: [output(false, 1)],
//     cause: 'stale object after forced GC in handler' }

// Counterexamples become permanent fixtures with their provenance.
await failure.saveAs('fixtures/plan-roots-exceptional-edge-arg.ir', {
  law: failure.law, seed: 2026, foundBy: 'law suite', fixedIn: null,
})
g.corpus.fixtures().length                     // → 23 (includes naive-dce-throwing-getter from example 10)
