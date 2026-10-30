// 60 · Capstone: one vertical slice, end to end
//
// Model: everything at once, in the order a team would use it. Fix the
// profile and the specification; take the standard operation sets with
// Hermes providers; build the pipeline with explicit strategies; check the
// laws; compile the four applications; run them in one engine; explain one
// decision across levels; compare two strategies; record the decision; export
// the IR bundle for review. Every step is a value or an awaited effect.
//
// Notice: there is no step where meaning is defined twice; replacing any
// provider or strategy later is a one-line change checked by the same laws.

import { g, kib, mib, jobs, ms } from 'strata'

// 1. Meaning: profile and specification.
const profile = g.profile('js-sync').and('js-async').and('js-modules')
const spec = g.semantics().profile(profile).delegate('js.*', g.hermes.oracle())

// 2. Operations: standard sets, Hermes providers, our own core.
const providers = { core: g.reference.provider('core'), 'js.*': g.hermes.provider('js.*') }

// 3. The pipeline, every slot stated even where it equals the default.
const slice = g.pipeline()
  .profile(profile)
  .frontend(g.hermes.frontend({ optimize: false }))
  .provide(providers)
  .ordering('blocks')
  .analyses(g.analysis.liveness, g.analysis.safepoints, g.analysis.behaviour, g.analysis.typeFacts)
  .rewrites(g.rewrites.canonical())
  .representation('tagged')
  .roots('stackReuse')
  .exceptions('setjmp')
  .suspension('hermes')
  .calls('hermesNative')
  .materialize(g.llvm.orc({ target: g.target.host64 }))
  .checks({ gcSafety: true, forcedGC: 'every-safepoint', differential: 'ladder' })
  .budget({ activeRoots: mib(4) })

slice.check()                                  // → { ok: true }

// 4. Laws before programs.
const laws = await g.laws.standard({ pipeline: slice, profile }).run({ samples: 2000, seed: 1 })
laws.summary()                                 // → 14 laws · 14 ok

// 5. Compile the applications (pure, cached).
const apps = g.corpus.apps()
const programs = apps.map(app => g.compile(slice, app))
programs.map(p => [p.name, p.diagnostics.length])
// → [['data-pipeline', 0], ['async-queue', 0], ['persistent-host', 0],
//    ['fflate-0.8.2', '0 only if its measured frame fits 1,024 slots under stackReuse (unmeasured; example 22)']]

// 6. Run them in one engine (effects).
const engine = await g.engine({ strategies: slice.summary().strategies, budget: { activeRoots: mib(4) } })
for (const p of programs) {
  const r = await engine.run(p, { budget: jobs(100000) })
  r.check(apps.oracle(p.name))                 // independent oracles: Python, Node, archive decoding
}
engine.metrics().code                          // → { admittedUnits: 4, codeBytes: '6.3 MiB', rejectedArtifacts: 0 }

// 7. Explain one decision across levels.
const fflate = programs.find(p => p.name === 'fflate-0.8.2')
fflate.why('slot:factory/17')
// → value(s), source spans, the collecting calls they are live across, the contract obligations that
//   made those calls collecting, and the strategy that let them share a slot (see example 22)

// 8. Compare against the alternative strategy on the same programs.
const arena = slice.roots(g.roots.arena({ chunk: kib(16) }))
const cmp = await g.differential({ pipelines: { stackReuse: slice, arena }, corpus: apps, observe: profile })
cmp.diff()                                     // → { behaviour: 'equal', resources: { … per program … } }

// 9. Record the decision with its evidence.
const decision = g.decision('first vertical slice')
  .options(['stackReuse', 'arena'])
  .evidence([g.ref.laws(laws), g.ref.differential(cmp)])
  .counterexampleSought('forced GC at every safepoint across exceptional edges (example 51)')
  .choose('stackReuse')
  .overturnIf('an admitted program whose measured peak live set exceeds the native frame budget')

// 10. Export the review bundle: every level as text and JSON, trace, decisions, laws, the decision record.
await g.export.bundle({ programs, pipeline: slice, laws, decision, path: 'review/first-slice.zip' })
// → { files: 61, levels: ['L0', 'L1', 'L2', 'L3', 'L4'], size: '3.4 MiB' }

await engine.close()                           // runtime first, then executable memory
