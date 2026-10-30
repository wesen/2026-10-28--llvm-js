// 30 · A design space of pipelines
//
// Model: a design is a function from a point in a parameter space to a
// pipeline. Parameters are choices or ranges with defaults; the space is
// their product, optionally restricted by constraints (for example, only
// declared-compatible strategy pairs). Because pipelines are values, a design
// is a value too: it can be sampled, filtered, hashed and handed to search.
//
// Notice: constraints come from g.compat, so incompatible points never exist;
// every point shares the same semantic levels unless a parameter touches
// them, which is what makes search cheap (example 32).

import { g, kib } from 'strata'

const base = g.pipeline().frontend(g.hermes.frontend({ optimize: false }))

const space = g.design({
  roots:      g.param.choice(['distinct', 'stackReuse', 'arena'], { default: 'stackReuse' }),
  chunk:      g.param.choice([kib(4), kib(16), kib(64)], { default: kib(16), when: p => p.roots === 'arena' }),
  exceptions: g.param.choice(['setjmp', 'landingPads'], { default: 'setjmp' }),
  unbox:      g.param.choice([false, true], { default: false }),
  optimize:   g.param.choice([false, true], { default: false }),
}, p => base
  .frontend({ optimize: p.optimize })
  .roots(p.roots === 'arena' ? g.roots.arena({ chunk: p.chunk }) : p.roots)
  .exceptions(p.exceptions)
  .representation(p.unbox ? 'unboxWhenProven' : 'tagged'),
{ constraints: [g.constraint.compatible('roots', 'exceptions')] })

space.size()
// → { raw: 72, afterConditions: 40, afterConstraints: 20,
//     removed: "landingPads with any roots strategy: no declared compatible pair yet" }

space.defaults()
// → { roots: 'stackReuse', exceptions: 'setjmp', unbox: false, optimize: false }   (chunk inactive)

// A point is a pipeline.
const point = space.at({ roots: 'arena', chunk: kib(64) })
point.summary().strategies                     // → { roots: 'arena(chunk 64 KiB)', exceptions: 'setjmp', representation: 'tagged' }

// Which levels does each parameter touch? This is what the cache exploits.
space.influence()
// → { optimize: ['L1', 'L2', 'L3', 'L4'], unbox: ['L3', 'L4'], roots: ['L3', 'L4'],
//     chunk: ['L3', 'L4'], exceptions: ['L3', 'L4'] }
// chunk does not change the generated code, but it is part of the arena strategy's identity, so it
// re-keys L3 and L4. Moving it to engine configuration, g.engine({ arena: { chunk } }), would let
// arena points share L3 and L4; that is a design choice this space makes visible.

// Points can be listed, sampled and filtered like any collection.
space.points().filter(p => p.optimize === false).length    // → 10
space.sample({ n: 4, method: 'lhs', seed: 7 })
// → [{ roots: 'distinct', unbox: true, … }, { roots: 'arena', chunk: '4 KiB', … }, …]

// A design can be narrowed into a new design: the seminar's "one vertical slice".
const slice = space.where(p => p.exceptions === 'setjmp' && p.optimize === false)
slice.size().afterConstraints                  // → 10

// Designs compose with presets like pipelines do.
const checked = slice.map(pipeline => pipeline.use(g.preset.strictChecks))
checked.at({}).summary().checks                // → verify + translation validation + forced GC at every safepoint
