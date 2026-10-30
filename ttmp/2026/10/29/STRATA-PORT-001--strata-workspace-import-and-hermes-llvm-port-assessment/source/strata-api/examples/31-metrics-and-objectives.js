// 31 · Metrics, objectives, and where rankings disagree
//
// Model: metrics are a registry of named, unit-carrying measurements with a
// direction (min or max) and a level. Objectives compose: `require` defines
// feasibility (a wrong compiler is infeasible, never merely low-scoring),
// `weighted` trades metrics off, `lexicographic` ranks by one metric first.
// Measurements are observations tied to a run; compile artifacts are cached,
// timings are not.
//
// Notice: the weighted and lexicographic objectives pick different winners on
// the same table; that disagreement *is* the trade-off, and it is shown
// rather than hidden.

import { g, bytes, ms } from 'strata'

// Built-in metrics, and one of our own.
g.metrics.list()
// → compileMs (min, ms, L0→L4) · execMs (min, ms, run) · peakLiveSlots (min, slots, L3) ·
//   activeRootBytes (min, bytes, run) · reservedArenaBytes (min, bytes, run) · codeBytes (min, bytes, L4) ·
//   admitted (max, count, L5) · permissionsGranted (max, count, L2) · diagnostics (min, count, all)

const rootBytesPerCall = g.metric('rootBytesPerCall',
  run => run.metrics.activeRootBytes.div(run.metrics.calls),
  { dir: 'min', unit: 'bytes', level: 'run', about: 'average rooted storage per activation' })

// Feasibility first: correctness and admission are requirements, not weights.
const feasible = g.objective.require(
  g.check.differential({ oracle: 'interpreter', profile: 'js-async' }),
  g.check.admitted({ corpus: g.corpus.apps() }),
)

const weighted = feasible.then(g.objective.weighted({
  execMs: 1.0,
  activeRootBytes: [0.5, { per: bytes(1024) }],
  compileMs: 0.2,
}))

const lexi = feasible.then(g.objective.lexicographic([
  ['activeRootBytes', { tolerance: bytes(512) }],   // memory first, ties within 512 B
  ['execMs', { tolerance: ms(1) }],
]))

// The same measured table, ranked two ways (numbers illustrative).
const table = g.results([
  { point: 'distinct',    feasible: false, reason: 'fflate-o0 not admitted' },
  { point: 'stackReuse',  feasible: true, execMs: 412, activeRootBytes: 3100, compileMs: 960 },
  { point: 'arena-16k',   feasible: true, execMs: 455, activeRootBytes: 9800, compileMs: 905 },
  { point: 'arena-4k',    feasible: true, execMs: 398, activeRootBytes: 9900, compileMs: 905 },
])

g.rank(table, weighted).map(r => r.point)      // → ['arena-4k', 'stackReuse', 'arena-16k']
g.rank(table, lexi).map(r => r.point)          // → ['stackReuse', 'arena-4k', 'arena-16k']
//   (the two arenas tie on memory within 512 B, so execMs breaks the tie)
g.rank.disagreement(table, weighted, lexi)
// → { winners: { weighted: 'arena-4k', lexicographic: 'stackReuse' },
//     why: 'arena-4k runs 14 ms faster and compiles 55 ms faster but holds 6.6 KiB more roots;
//           at these weights memory costs 3.3 points and speed gains 25' }

// Pareto view: no single winner, the frontier instead.
g.rank(table, g.objective.pareto(['execMs', 'activeRootBytes'])).frontier
// → ['stackReuse', 'arena-4k']

// Timing is an observation: cached artifacts, fresh measurements, recorded conditions.
table.conditions()
// → { warm: true, repetitions: 5, statistic: 'median', machine: 'x86_64, LLVM 18.1.3', seed: 7 }
