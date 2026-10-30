// 32 · Search over a design space, sharing work through the cache
//
// Model: search samples points from a design, compiles and runs each against
// a corpus, filters by feasibility and ranks by the objective. Because each
// level's output is cached by content, two points differing only in a
// lowering strategy reuse every L1 and L2 result. Search is an effect (it
// runs programs), so it is awaited; its result is a value with the whole
// table, the winner, and the provenance of every number.
//
// Notice: the cache report shows how much work was shared; an infeasible
// winner is impossible by construction; a result can be replayed exactly.

import { g, kib, jobs } from 'strata'

const base = g.pipeline().frontend(g.hermes.frontend({ optimize: false }))
const space = g.design({
  roots: g.param.choice(['stackReuse', 'arena'], { default: 'stackReuse' }),
  chunk: g.param.choice([kib(4), kib(16), kib(64)], { when: p => p.roots === 'arena' }),
  unbox: g.param.choice([false, true]),
}, p => base
  .roots(p.roots === 'arena' ? g.roots.arena({ chunk: p.chunk }) : 'stackReuse')
  .representation(p.unbox ? 'unboxWhenProven' : 'tagged'))

const objective = g.objective
  .require(g.check.differential({ oracle: 'interpreter' }), g.check.admitted())
  .then(g.objective.lexicographic(['activeRootBytes', 'execMs']))

const result = await g.search.grid(space, {
  corpus: g.corpus.apps(),                     // data pipeline, async queue, plugin host, fflate archive
  objective,
  run: { jobs: jobs(10000), repetitions: 3 },
})

result.best.point                              // → { roots: 'stackReuse', unbox: true }
result.table()
// → point                         feasible  activeRootBytes  execMs  notes
//   stackReuse, unbox             yes       2.6 KiB          371
//   stackReuse                    yes       3.1 KiB          412
//   arena 4k, unbox               yes       9.4 KiB          362
//   arena 16k, unbox              yes       9.4 KiB          380
//   …
//   (numbers illustrative)

result.cache()
// → { L1: { computed: 4, reused: 28 }, L2: { computed: 4, reused: 28 },
//     L3: { computed: 32, reused: 0 }, L4: { computed: 32, reused: 0 },
//     note: '8 points × 4 programs; L1/L2 depend only on the frontend; every point has its own
//            strategy identity (chunk included, see example 30), so L3/L4 are computed per point' }

// Every number knows where it came from.
result.why({ point: { roots: 'arena', chunk: kib(4), unbox: true }, metric: 'execMs' })
// → { program: 'async-queue (large)', runs: [361.8, 362.4, 365.0], statistic: 'median', engine: 'engine#14',
//     artifact: 'sha256:7c1e…', machine: 'x86_64, LLVM 18.1.3' }

// Other samplers, same result shape.
await g.search.random(space, { corpus: g.corpus.apps(), objective, budget: 6, seed: 7 })
await g.search.lhs(space, { corpus: g.corpus.apps(), objective, budget: 6, seed: 7 })

// Replay: a stored result names everything needed to run it again.
const stored = result.toJSON()
const replay = await g.search.replay(stored)
g.observe.equal(replay.best.run, result.best.run)   // → { equal: true }
