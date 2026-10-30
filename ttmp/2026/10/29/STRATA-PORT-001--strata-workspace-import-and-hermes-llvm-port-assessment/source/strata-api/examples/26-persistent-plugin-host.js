// 26 · A persistent plugin host
//
// Model: one engine accepts hundreds of submissions over its lifetime. Some
// fail to parse (nothing is admitted), some initializers publish a closure and
// then throw (code is admitted and must be retained), most succeed. Each
// failure is reported in its phase. Memory is reported per owner, not as
// process RSS, so expected retention is distinguishable from a leak.
//
// Notice: diagnostics name the phase; code retention after a failed
// initializer is a lifecycle rule (example 15), not an accident; the metrics
// separate code bytes, active roots, reserved storage and heap.

import { g, jobs } from 'strata'

const engine = await g.engine()
const ledger = await engine.defineModule('ledger.mjs', g.source.text(`
export const plugins = new Map(); export let total = 0;
export function register(name, fn) { plugins.set(name, fn); total += 1; }`))
await engine.evaluateModule(ledger)

const plugin = i => g.source.text(`
import {register} from './ledger.mjs';
const secret = ${i};
register('p${i}', () => secret * 2);
setTimeout(() => register('cb${i}', () => secret), 0);
${i % 10 === 4 ? `throw new Error('init failed after publishing p${i}');` : ''}`, { name: `p${i}.mjs` })

const broken = i => g.source.text(`export const x = ;`, { name: `bad${i}.mjs` })

const results = []
for (let i = 0; i < 344; i++) {
  const source = i % 10 === 9 ? broken(i) : plugin(i)
  const program = g.compile(g.pipeline(), source)
  if (program.diagnostics.some(d => d.level === 'error')) {
    results.push({ i, phase: 'compile', admitted: false })   // nothing reached the engine
    continue
  }
  const code = await engine.admit(program.artifact)
  const ev = await engine.evaluateModule(source.name)
  await engine.runJobs({ budget: jobs(4) })
  results.push({ i, phase: engine.evaluationState(ev), code })
}

g.table.count(results, r => r.phase)
// → { fulfilled: 276, rejected: 34, compile: 34 }
//   (mirrors the LLVM-APPS-001 corpus: 344 submissions, 310 admitted, 34 parse errors, 34 initializer errors)

// A rejected initializer still published p4; its code is retained and the closure works.
const ns = await engine.moduleNamespace('ledger.mjs')
await engine.call(ns.get('plugins').get('p4'))   // → 8

// Diagnostics say which phase failed.
results.find(r => r.phase === 'compile')
// → { i: 9, phase: 'compile', admitted: false }   with program.diagnostics:
//   [{ level: 'error', kind: 'parse', phase: 'L0', source: 'bad9.mjs:1:18', message: "Unexpected token ';'" }]

// Memory per owner, not process RSS.
await engine.collect()
engine.metrics()
// → { code: { admittedUnits: 311, codeBytes: '4.1 MiB', retainedAfterInitFailure: 34 },   (310 plugins + the ledger)
//     roots: { activeBytes: '0 B', reservedBytes: '0 B (stackReuse keeps roots on the native stack)', highWater: '2.3 KiB' },
//     heap: { liveBytes: '1.8 MiB' }, modules: { records: 311 }, jobs: { pending: 0 } }

// Identity never inherits a previous engine's high-water mark.
const fresh = await g.engine()
fresh.metrics().code.nextLocalId               // → 1
await fresh.close()
await engine.close()                           // runtime destroyed first, then executable memory
