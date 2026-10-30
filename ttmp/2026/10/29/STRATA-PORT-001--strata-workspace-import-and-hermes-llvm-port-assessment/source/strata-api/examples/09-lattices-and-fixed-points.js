// 09 · One analysis substrate: lattices, monotone transfer, fixed points
//
// Model: an analysis is a lattice, a direction and a monotone transfer
// function per operation, plus an edge rule. One worklist solver computes the
// least fixed point for every analysis. Products of analyses are analyses.
// Termination comes from finite height or an explicit widening, never from an
// iteration cap. The solver imports nothing from Hermes or LLVM, so it serves
// other graphs too.
//
// Notice: liveness through block arguments and exceptional edges; a
// non-monotone transfer caught by a law; an infinite-height lattice refused
// without widening; the same solver run on a workflow graph.

import { g, ms } from 'strata'

const { t } = g

// Liveness, written out (the library's g.analysis.liveness is exactly this).
const liveness = g.analysis('liveness')
  .lattice(g.lattice.powerset())               // sets of SSA values
  .backward()
  .transfer((op, live) => live.minus(op.results).union(op.operands))
  .edge(g.edge.substituteBlockArgs())          // a live target parameter makes its edge argument live
  .exceptional('include')                      // values used in a handler are live across the invoke

// Safepoints: which program points may collect (from contract obligations).
const safepoints = g.analysis('safepoints')
  .lattice(g.lattice.flat([false, true]))
  .forward()
  .transfer((op, _in) => op.contract.obligations.has('mayCollect'))

// What root planning needs: both, solved together.
const rooting = g.analysis.product(liveness, safepoints)

// A loop with throwing calls inside:
//   function sumKeys(o, keys, n) { let s = 0; for (let i = 0; i < n; i++) s += o[keys[i]]; return s }
const sumKeys = g.ir.parse(`
fn sumKeys(o: any, keys: any, n: int32) -> any {
entry:
  jump head(0, 0)
head(i: number, s: any):
  c = num.lt(i, n)
  branch c, body(i, s), exit(s)
body(i1: number, s1: any):
  invoke js.get(keys, i1) normal fetch(i1, s1) throw failed
fetch(k: any, i2: number, s2: any):
  invoke js.get(o, k) normal add(i2, s2) throw failed
add(v: any, i3: number, s3: any):
  invoke js.add(s3, v) normal next(i3) throw failed
next(s4: any, i4: number):
  i5 = num.add(i4, 1)
  jump head(i5, s4)
exit(r: any):
  return r
failed(e: any):
  throw e
}`)
// (the counter is a number: num.add returns number, so int32 would not type-check; see int-ranges below)

const facts = g.solve(rooting, sumKeys)
facts.liveAcross('fetch/js.get')               // → ['o', 'keys', 'n', 'i2', 's2']   (needed after the call)
facts.liveAcross('add/js.add')                 // → ['o', 'keys', 'n', 'i3']
facts.iterations                               // → 4
facts.explain('o', 'fetch/js.get')
// → 'o is used by js.get in fetch on the next iteration: fetch→add→next→head→body→fetch'

// What must be rooted at the call: values needed after it, plus the operands it borrows
// (js.get's contract: borrows 0 1). Numbers are not managed references, so they need no root.
g.roots.needed(facts, 'fetch/js.get')
// → { liveAfter: ['o', 'keys', 's2'], borrowed: ['o', 'k'], rooted: ['o', 'keys', 's2', 'k'], unboxed: ['n', 'i2'] }

// Edge substitution matters: i2 and s2 in fetch are used only as edge arguments to add.
const naive = liveness.edge(g.edge.ignoreBlockArgs())
g.diff(g.solve(naive, sumKeys), facts).missing
// → [{ value: 's2', at: 'fetch/js.get', consequence: 'a managed value needed after the call would have no root' },
//    { value: 'i2', at: 'fetch/js.get', consequence: 'a number: no root, but its register would not be kept' },
//    { value: 'i3', at: 'add/js.add',   consequence: 'a number: no root, but its register would not be kept' }]

// The laws behind termination.
g.law.lattice(g.lattice.powerset({ universe: sumKeys.values() }))   // → ok, height 19 (one per SSA value)
g.law.monotone(liveness)                       // → { ok: true, samples: 2000 }

const sloppy = liveness.transfer((op, live) => live.size > 3 ? live.empty() : live.union(op.operands))
g.law.monotone(sloppy)
// → { ok: false, counterexample: { op: 'js.get(o, k)', x: '{o}', y: '{o, keys, i2, s2}',
//     fx: '{o, k}', fy: '{}', violation: 'x ⊑ y but f(x) ⋢ f(y)' } }

// Infinite height needs widening, stated explicitly.
const ranges = g.analysis('int-ranges').lattice(g.lattice.interval()).forward()
// g.solve(ranges, sumKeys)                    // → AnalysisError: 'interval lattice has infinite height; add .widen(...)'
const rangesW = ranges.widen(g.widen.thresholds([0, 255, 2 ** 31 - 1]))
g.solve(rangesW, sumKeys).of('head.i')         // → [0, 2147483647]  (bounded by n: int32; now i fits int32, soundly)

// Budgets end in a sound fallback, never a silently partial answer.
g.solve(liveness, sumKeys, { budget: ms(0.01) })
// → { status: 'budget-exhausted', result: 'fallback: every value live at every safepoint (sound, imprecise)' }

// The same solver on a graph that has nothing to do with compilers.
const workflow = g.graph({
  nodes: ['draft', 'review', 'legal', 'publish', 'archive'],
  edges: [['draft', 'review'], ['review', 'draft'], ['review', 'legal'], ['legal', 'publish'], ['publish', 'archive']],
})
const reach = g.analysis('reachable-from')
  .lattice(g.lattice.powerset())
  .forward()
  .transfer((node, seen) => seen.add(node.id))
g.solve(reach, workflow, { from: 'review' }).of('archive')   // → {review, draft, legal, publish, archive}
