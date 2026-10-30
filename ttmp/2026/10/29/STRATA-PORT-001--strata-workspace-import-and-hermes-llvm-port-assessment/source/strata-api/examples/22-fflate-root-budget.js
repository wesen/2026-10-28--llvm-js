// 22 · The fflate factory: a storage question, answered by strategy
//
// Model: the unmodified fflate 0.8.2 module factory, compiled without
// optimization, asks for 1,084 roots plus 3 argument slots under today's
// one-slot-per-value policy, which exceeds the 1,024-slot native-frame limit.
// Under this design that is a fact about one strategy (distinct slots), not
// about the language. The same program is planned under each root strategy;
// semantic passes are identical; only L3 and below change.
//
// Notice: peak-live numbers below are illustrative placeholders; doc 03 is
// explicit that peak liveness has not been measured. The point is which
// quantity each strategy is limited by, and that switching strategy leaves
// L1 and L2 byte-for-byte equal.

import { g, kib, mib, slots } from 'strata'

const fflate = g.corpus.apps().get('fflate-0.8.2')          // unmodified library source, pinned hash
const o0 = g.pipeline().frontend(g.hermes.frontend({ optimize: false }))

// Today's behaviour, as a strategy.
const today = g.compile(o0.roots({ reuse: false }), fflate)
today.diagnostics
// → [{ level: 'error', kind: 'admission', fn: 'factory', limit: 'native-frame-slots',
//      measured: '1087 slots (1084 roots + 3 arguments)', max: '1024 slots', strategy: 'roots: distinct' }]

// The same program under every root strategy.
const strategies = {
  distinct: g.roots.distinct(),
  stackReuse: g.roots.stackReuse(),
  arena: g.roots.arena({ chunk: kib(16), budget: mib(4) }),
}
const plans = Object.fromEntries(Object.entries(strategies).map(([name, s]) =>
  [name, g.compile(o0.roots(s), fflate)]))

g.table(Object.entries(plans).map(([name, p]) => ({
  strategy: name,
  admitted: p.diagnostics.length === 0,
  rootSlots: p.plan('factory').rootSlots,
  peakLive: p.plan('factory').peakLive,
  limitedBy: p.plan('factory').limitedBy,
})))
// → strategy    admitted  rootSlots   peakLive              limitedBy
//   distinct    no        1084        (n/a: no reuse)       native frame: 1024 slots
//   stackReuse  yes*      peakLive+2  measured, e.g. 200    native frame: 1024 slots (+ 3 argument slots)
//   arena       yes       1084        (n/a: no reuse)       active-root budget: 4 MiB
//   * only if peak live + 2 fixed + 3 argument slots fits 1,024; the illustrative 200 is not a measurement

// What did not change: semantic levels are identical across strategies.
plans.distinct.ir('L1').hash() === plans.arena.ir('L1').hash()      // → true
plans.distinct.ir('L2').hash() === plans.stackReuse.ir('L2').hash() // → true
g.diff(plans.distinct, plans.arena).levels
// → { L0: 'equal', L1: 'equal', L2: 'equal', L3: 'differs', L4: 'differs' }

// Explain one slot in the reuse plan.
plans.stackReuse.why('slot:factory/17')
// → { values: ['v203 (u8 table)', 'v611 (closure inflt)', 'v980 (tmp)'],
//     disjointBecause: 'live ranges do not overlap at any collecting point',
//     interference: 'checked against liveness × safepoints (example 09)' }

// The arena's cost is stated in its own units.
plans.arena.plan('factory').activation
// → { rootBytes: '8672 B', argumentBytes: '24 B', chunk: '16 KiB', withinBudget: true }

// Acceptance from doc 01, restated: unmodified source, unoptimized frontend, JIT and AOT,
// independent oracle (Python zipfile/gzip decode of the produced archives).
const accept = g.acceptance('fflate-o0', {
  source: fflate, pipeline: o0.roots('arena'),
  modes: ['jit', 'aot'], oracle: g.oracle.external('python-zip-gzip'),
  forbid: ['source trimming', 'profile substitution', 'hidden fallback'],
})
accept.describe()                              // → the gate as data; running it is an effect: await accept.run()
