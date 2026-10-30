// 23 · The throwing getter, through every layer
//
// Model: doc 03's worked example and comparison example 4. A getter mutates a
// shared object and throws it; the catch observes identity and the mutation.
// The program is followed from source to L1 (meaning), contracts (what may be
// done), the specification (what must be observed), analyses (what must be
// rooted), the plan (how), and the engine (what happens). Then the three
// variants doc 03 asks for are traced the same way.
//
// Notice: every layer is queried through the same Program object; the
// invalid optimization fails at the side condition and is also caught by the
// refinement law; forced GC at every safepoint does not change the output.

import { g, jobs } from 'strata'

const getter = g.source.text(`
let cell = {n: 0};
const receiver = { get x() { cell.n += 1; throw cell; } };
try { receiver.x; } catch (caught) { print(caught === cell, cell.n); }`, { name: 'getter.js' })

const p = g.compile(g.pipeline().use(g.preset.debug), getter)

// L1: meaning. A top-level let is a binding in the script's global environment, which a later
// script or an indirect eval may reassign, so it is a cell, not a value.
p.ir('L1', { fn: 'main' })
// → fn main() -> any {
//   entry:
//     b_cell = js.env.binding(global, "cell")
//     o1 = obj.literal({n: 0})
//     cell.store(b_cell, o1)
//     receiver = obj.literal({get x: getter_x})        ; getter_x reaches b_cell through its environment
//     invoke js.get(receiver, "x") normal done throw caught
//   done(unused: any):
//     return undefined
//   caught(thrown: any):
//     o2 = cell.load(b_cell)
//     same = core.ref_eq(o2, thrown)
//     invoke js.get(o2, "n") normal out throw propagate
//   out(n: any):
//     invoke js.call_global("print", same, n) normal finish throw propagate
//   finish(r: any):
//     return undefined
//   propagate(e: any):
//     throw e
//   }
//   (print is a global call that converts its arguments, so it may run user code and throw)

// Contracts: why the first read must stay.
p.perm('main/entry/js.get')
// → { erase: false, move: false, … because: ['throws', 'callsUser'] }

// Specification: the required observation.
const spec = g.semantics().profile('js-sync')
spec.run(p).trace                              // → [output(true, 1)]

// Analyses: what must survive the first call.
p.facts('main/entry/js.get').liveAcross        // → ['b_cell']   (receiver is needed only by the call itself)
p.facts('main/entry/js.get').safepoint         // → true         (js.get obligation mayCollect)

// Plan: how it survives, including the exceptional edge. Operands of a collecting call are
// borrowed (js.get: borrows 0 1), so receiver is rooted for the call.
p.plan('main')
// → { roots: [{ slot: 0, values: ['b_cell'], why: 'live across entry/js.get and caught/js.get' },
//             { slot: 1, values: ['receiver', 'o2'], why: 'borrowed by entry/js.get, then by caught/js.get' }],
//     unboxed: [{ value: 'same', rep: 'bool', root: 'none (not managed)' }],
//     fixed: 2, argv: 2, frame: '6 slots · 48 B on host64',
//     unwind: [{ at: 'entry/js.get', handler: 'caught', restores: ['root chain', 'managed frame'],
//                delivers: 'thrown value rooted by runtime exception slot' }] }

// Engine: what happens, with a collection forced at every safepoint.
const engine = await g.engine({ debug: { forceGC: 'every-safepoint' } })
const r = await engine.run(p, { budget: jobs(10) })
r.output                                       // → ['true 1']
r.collections                                  // → 4

// The invalid optimization, two ways.
const naive = g.rewrite('naive-dce').match(m => m.op('*').resultUnused()).to(m => m.erase())
g.compile(g.pipeline().use(g.preset.debug).rewrites(g.rewrites(naive)), getter).diagnostics
// → [{ level: 'error', kind: 'refinement', rewrite: 'naive-dce',
//      detail: 'output changed: [output(true, 1)] → []', check: 'interpret before/after (debug preset)' }]
g.law.refines(naive, { corpus: [getter], profile: 'js-sync' }).ok   // → false

// The three variants from doc 03, traced the same way.
const variants = {
  returns:  `let cell = {n: 0}; const r = { get x() { cell.n += 1; return 7; } }; try { r.x } catch (c) { print('caught') } print(cell.n)`,
  loops:    `let cell = {n: 0}; const r = { get x() { for (;;) {} } }; try { r.x } catch (c) {} print('unreachable')`,
  enqueues: `let cell = {n: 0}; const r = { get x() { queueMicrotask(() => print('job')); throw cell } }; try { r.x } catch (c) { print('caught') }`,
}
for (const [name, text] of Object.entries(variants)) {
  const q = g.compile(g.pipeline(), g.source.text(text, { name }))
  q.perm('main/entry/js.get')                  // → unchanged: erase/move false in all three (contract, not runtime path)
}
// returns:  observation [output(1)]; the catch block is reachable in the IR but not taken
// loops:    observation diverge; 'may diverge' alone forbids erasure, even with no writes
// enqueues: observation [output('caught'), output('job')]; js.get writes the jobs resource,
//           so it cannot move across another enqueue

await engine.close()
