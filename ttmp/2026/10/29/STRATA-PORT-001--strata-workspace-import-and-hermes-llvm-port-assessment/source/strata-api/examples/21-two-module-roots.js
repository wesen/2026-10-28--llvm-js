// 21 · Two module roots, one dependency identity
//
// Model: module identity belongs to the engine, not to a bundle. Two programs
// compiled and submitted separately import the same dependency; the engine's
// registry links both to one record, so they share live bindings and the
// dependency runs once. Linking and evaluation are separate state machines,
// and a cached evaluation error stays attached to its record.
//
// Notice: the compiler emits module definitions, never a registry; the
// SCC algorithm is generic, while linking rules and top-level await are JS
// policy layered on it.

import { g, jobs } from 'strata'

const sources = g.source.modules({
  'counter.mjs': `export let count = 0; export function increment() { count += 1; } print('counter evaluated');`,
  'a.mjs':       `import {count, increment} from './counter.mjs'; increment(); export const seenByA = () => count;`,
  'b.mjs':       `import {count, increment} from './counter.mjs'; increment(); print('b sees', count);`,
})

const pipeline = g.pipeline().modules({ resolver: g.resolve.relative({ root: '/app' }) })

// Two separate compilations: each artifact declares modules; neither contains a registry.
const progA = g.compile(pipeline, sources.pick('a.mjs', 'counter.mjs'))
const progB = g.compile(pipeline, sources.pick('b.mjs', 'counter.mjs'))
progA.artifact.describe().modules
// → [{ key: '/app/a.mjs', imports: ['/app/counter.mjs'] }, { key: '/app/counter.mjs', exports: ['count', 'increment'] }]
progA.artifact.audit().registries              // → 0

const engine = await g.engine()
await engine.admit(progA.artifact)
await engine.admit(progB.artifact)             // counter.mjs: same key, same source hash → same record

const a = await engine.evaluateModule('/app/a.mjs')
const b = await engine.evaluateModule('/app/b.mjs')
await engine.runJobs({ budget: jobs(10) })
engine.output()                                // → ['counter evaluated', 'b sees 2']   (counter ran once)

const ns = await engine.moduleNamespace('/app/a.mjs')
await engine.call(ns.get('seenByA'))           // → 2   (a live binding, not a copied value)

// Redefining a key with different source is an explicit error, not a second record.
await engine.admit(g.compile(pipeline, g.source.modules({ 'counter.mjs': 'export let count = 99' })).artifact)
  .catch(e => e)
// → AdmissionError { reason: 'module key already defined with different source', key: '/app/counter.mjs' }

// Cycles: the generic part and the JS part, separately.
const graph = g.graph.fromModules(g.source.modules({
  'x.mjs': `import {y} from './y.mjs'; export const x = () => y;`,
  'y.mjs': `import {x} from './x.mjs'; export const y = 1;`,
}))
g.graph.scc(graph)                             // → [['x.mjs', 'y.mjs']]   (generic algorithm, reusable)
g.js.moduleLinking.plan(graph)
// → { order: ['y.mjs', 'x.mjs'], cycle: true, liveBindings: 2, earlyReads: [] }   (x reads y only when called)

// A cached failure belongs to its record and is stable.
const bad = await engine.defineModule('/app/bad.mjs', g.source.text(`throw new Error('init')`))
const e1 = await engine.evaluateModule(bad)
const e2 = await engine.evaluateModule(bad)
engine.evaluationState(e1)                     // → 'rejected'
engine.sameEvaluation(e1, e2)                  // → true   (each dynamic import() still gets its own promise)

await engine.close()
