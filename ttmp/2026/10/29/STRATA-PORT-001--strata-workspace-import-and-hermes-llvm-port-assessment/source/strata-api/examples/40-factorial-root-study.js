// 40 · A pre-registered factorial study: root storage × exception transfer
//
// Model: a study is a value: hypotheses written before running, factors and
// their levels, a corpus, measurements with units, repetitions, a
// randomized run order and an analysis plan. Running it is an effect. The
// output is a table plus a verdict per hypothesis, and it can feed a
// decision record (example 50) without retyping numbers.
//
// Notice: hypotheses are falsifiable and stated with thresholds; infeasible
// cells (incompatible strategy pairs) are excluded by the design, not by
// the analyst after the fact; results distinguish 'supported', 'refuted' and
// 'inconclusive'.

import { g, kib, mib, ms, slots, jobs } from 'strata'

const study = g.study('root-storage-2026-11')
  .question('Which root strategy should the first vertical slice use?')
  .hypothesis('H1', 'stackReuse admits unoptimized fflate on host64', {
    measure: 'peakLiveSlots(factory) + 2 fixed + argumentSlots', threshold: { le: slots(1024) },
  })
  .hypothesis('H2', 'arena costs at most 5% execution time vs stackReuse on the async queue', {
    measure: 'execMs ratio arena/stackReuse', threshold: { le: 1.05 }, statistic: 'median of 10',
  })
  .hypothesis('H3', 'root strategy never changes observable behaviour', {
    measure: 'differential disagreements', threshold: { eq: 0 },
  })
  .factors({
    roots: ['distinct', 'stackReuse', g.roots.arena({ chunk: kib(16), budget: mib(4) })],
    exceptions: ['setjmp'],                    // the only pair family declared compatible today
    optimize: [false, true],
    size: ['small', 'medium', 'large'],
  })
  .corpus(g.corpus.apps())
  .measure(['admitted', 'peakLiveSlots', 'execMs', 'activeRootBytes', 'reservedArenaBytes', 'compileMs'])
  .repeat(10)
  .randomize({ seed: 2026 })
  .analysis({ compare: 'roots', within: ['optimize', 'size'], effect: 'ratio of medians', ci: 0.95 })
  .environment({ machine: 'x86_64', llvm: '18.1.3', hermes: 'f837b9d', isolation: 'one process per run' })

study.plan()
// → { cells: 18, programs: 4, repetitions: 10, runs: 720, estimated: '≈ 40 min', excluded: [] }
study.preregistration()                        // → a frozen, hashed text of hypotheses and analysis: 'sha256:51aa…'

const results = await study.run()

results.verdicts()
// → H1  supported     peak 211 + 2 + 3 = 216 slots ≤ 1024   (illustrative)
//   H2  inconclusive  ratio 1.04, 95% CI [0.99, 1.09] crosses the threshold
//   H3  supported     0 disagreements in 720 runs

results.table({ rows: 'roots', cols: 'size', cell: 'execMs median' })
// → roots        small   medium  large
//   distinct     —       —       —        (fflate O0 not admitted; other apps shown separately)
//   stackReuse   12.1    96.4    402.0
//   arena 16k    12.4    99.8    418.3

// What the study does not claim, recorded with the results.
results.limitations()
// → ['one machine', 'four applications', 'no adversarial inputs', 'no concurrency', 'timer-heavy workloads only in async queue']

// Hand the evidence to a decision record (example 50) by reference, not by retyping.
const evidence = results.cite(['H1', 'H3'])   // → [{ study: 'root-storage-2026-11', hypothesis: 'H1', hash: '…' }, …]
