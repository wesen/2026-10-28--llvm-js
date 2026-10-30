// 13 · Staging: compile time, run time, and room for tiers
//
// Model: pure work on known input happens at compile time and is cached by
// content. Unknown input from a small finite set becomes guarded versions.
// Open input (eval strings, dynamic import) is compiled later or handed to a
// declared provider. Effects always happen at run time, inside the engine.
// Adaptive tiers are not implemented, but the design keeps them possible:
// assumptions are facts, every guard has a deoptimization exit with a
// frame-state map, and the reference interpreter is the place to resume.
//
// Notice: cache keys list what they include; the FUTURE section type-checks
// the tiering requirements without implementing tiers.

import { g, count } from 'strata'

const base = g.pipeline()
const src = g.source.text(`export function area(shape) { return shape.w * shape.h }`, { name: 'area.mjs' })

// Compile time: pure, cached per function by content.
const p = g.compile(base, src)
p.cache.key('area')
// → { irHash: 'b41f…', opsets: { 'js.object': '0.1.0', 'js.value': '0.1.0' }, providers: { 'js.object': 'hermes@f837b9d' },
//     passes: 'pipeline#9c2e', strategies: { roots: 'stackReuse', exceptions: 'setjmp' },
//     target: 'x86_64-linux-gnu', profile: 'js-sync+js-async+js-modules' }
g.compile(base, src).cache.stats()             // → { hits: 1, misses: 0 }
g.compile(base.roots('arena'), src).cache.stats()
// → { hits: 2 (L1, L2), misses: 2 (L3, L4), reason: "strategy 'roots' changed: L3 and below are recomputed" }

// Small finite unknown: guarded versions, chosen at run time.
const versioned = base.insert(g.pass.version('js.get', {
  shapes: g.shapes.declared(['{w, h}', '{h, w}']),  // declared by hand here, not from profiling
}), { after: 'lower-runtime' })
g.compile(versioned, src).ir('L2', { fn: 'area' })
// → guard shape(shape) == S1 → own_data loads; else guard S2 → own_data loads; else js.get (general)

// Open unknown: eval and Function. The default delegates to Hermes bytecode, as today.
base.dynamic()                                 // → g.dynamic.delegate(g.hermes.bytecode())
const later = base.dynamic(g.dynamic.compile({ pipeline: base.profile('js-dynamic') }))
later.check()
// → { ok: true, note: 'eval source compiled at run time through the same pipeline; shares binding cells (see 24)' }

// Effects are run time, owned by the engine. p.artifact is relocatable and not yet in memory;
// admission materializes it (LLVM ORC here), which is why it is awaited.
const engine = await g.engine()
await engine.admit(p.artifact)
await engine.close()

// FUTURE: adaptive tiers. Not implemented; written so the requirements are checkable now.
const tiered = base.tiers([
  g.tier.interpret(),                          // tier 0: the reference interpreter, also the deopt target
  g.tier.native({                              // tier 1: today's pipeline, no speculation
    when: f => f.calls.ge(count(2)),
  }),
  g.tier.native({                              // tier 2: speculative
    when: f => f.calls.ge(count(1000)),
    speculate: g.speculate.types({ from: 'profile' }),
  }),
])
tiered.check()
// → { ok: false, unmet: [
//      'tier 2 speculates: every guard needs a deoptimization exit with a frame-state map',
//      'tier 0 must accept resumption at any block that is a deopt target' ],
//     note: 'these are the three foundation choices from the note; nothing else is required now' }

// What a speculative guard would look like in the IR (illustrative).
// guard g1: fact(shape.w: int32) origin assumption('profile s12')
//   fail → deopt { resume: 'L1 area/entry op#1', frame: { shape: 'slot 0 (tagged)', w: 'reg (i32 → box)' } }
