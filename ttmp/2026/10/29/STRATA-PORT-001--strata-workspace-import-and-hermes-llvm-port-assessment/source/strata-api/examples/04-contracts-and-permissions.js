// 04 · Contracts and derived permissions
//
// Model: an operation's contract states its signature, its reference step
// (what it means), its behaviour summary and its runtime obligations.
// Permissions (erase, merge, move, duplicate, hoist, speculate) are derived
// from the contract plus facts; they are never declared by hand. Permissions
// are antitone: adding behaviour can only remove permissions.
//
// Notice: an unused result is not enough to erase js.get; a variant is checked
// against the general operation's reference step, not just its summary; a
// collecting call borrows its operands, so lowering must root them for the call.

import { g } from 'strata'

const { t, fx, ob } = g

// A pure, total numeric operation. Every step function takes the machine state first.
const numAdd = g.op('num.add')
  .operands(t.number, t.number)
  .results(t.number)
  .behaviour(fx.none)
  .obligations(ob.none)
  .step((s, [a, b]) => a + b)                  // reference semantics: IEEE-754 double addition
  .laws({ commutative: true, associative: false })  // stated, and tested; floating point is not associative

// A JavaScript property read: may run a getter or a proxy trap.
// ob.borrows(0, 1): the receiver and key must stay valid (rooted) while the call runs.
const jsGet = g.op('js.get')
  .operands(t.any, t.propertyKey)
  .results(t.any)
  .behaviour(fx.callsUser.join(fx.throws))
  .obligations(ob.mayCollect.join(ob.nonlocalThrow).join(ob.borrows(0, 1)))
  .step((s, [o, k]) => s.spec.get(o, k))       // ECMA-262 [[Get]] through the semantic provider

// js.add declares num.add, an operation of its own, as its variant for number operands.
const jsAdd = g.op('js.add')
  .operands(t.any, t.any)
  .results(t.any)
  .behaviour(fx.callsUser.join(fx.throws))     // valueOf and toString may run
  .obligations(ob.mayCollect.join(ob.nonlocalThrow).join(ob.borrows(0, 1)))
  .step((s, [a, b]) => s.spec.add(a, b))
  .variant(numAdd, { when: (f, [a, b]) => f.type(a).le(t.number) && f.type(b).le(t.number) })

// A fresh allocation and a job enqueue.
const objNew = g.op('obj.new').results(t.object).behaviour(fx.fresh).obligations(ob.mayCollect)
const enqueue = g.op('job.enqueue').operands(t.callable).behaviour(fx.writes('jobs'))
  .obligations(ob.mayCollect.join(ob.borrows(0)))

// Derived permissions.
g.perm(numAdd)
// → { erase: true, merge: true, move: true, duplicate: true, hoist: true, speculate: true }
g.perm(jsGet)
// → { erase: false, merge: false, move: false, duplicate: false, hoist: false, speculate: false }
g.perm(objNew, { resultUsed: false, identityObserved: false })
// → { erase: true, merge: false, move: true, duplicate: false, hoist: false, speculate: true }
g.perm(enqueue)
// → { erase: false, merge: false, move: 'not across writes(jobs)', duplicate: false, hoist: false, speculate: false }

// Every "no" has a reason, built from the contract.
g.perm.explain(jsGet, 'erase', { resultUsed: false })
// → { allowed: false,
//     because: ['behaviour includes throws', 'behaviour includes callsUser (may diverge, may write)'],
//     note: 'an unused result alone is not sufficient' }

// The antitone law: more behaviour can only remove permissions.
g.law.antitone(g.perm)                         // → { ok: true, samples: 5000 }

// Variants: a variant is any operation whose contract refines the general one under a fact.
// It can be an existing operation (num.add above) or a new one declared here.
const ownData = jsGet.variant('js.get.own_data', {
  when: (f, [o, k]) => f.type(o).le(t.object) && f.dataProperty(o, k),
  behaviour: fx.reads('heap'),
  obligations: ob.none,
  step: (s, [o, k]) => s.heap.slot(o, k),
})
g.law.variant(ownData, jsGet)
// → { ok: true, under: 'object ∧ own data property', samples: 3000 }
g.law.variant(numAdd, jsAdd)
// → { ok: true, under: 'both operands number', samples: 3000 }

// The variant's permissions hold only where its fact holds: the read is defined only for that object.
g.perm(ownData)
// → { erase: true, merge: 'if no writes(heap) between', move: 'not across writes(heap)', duplicate: true,
//     hoist: 'with the fact', speculate: 'with the fact' }

// A wrong variant: its summary is smaller, so the summary check alone would accept it.
const wrong = jsGet.variant('js.get.pure', {
  when: () => true,
  behaviour: fx.none,
  step: (s, [o, k]) => s.heap.slot(o, k),
})
g.law.variant(wrong, jsGet)
// → { ok: false,
//     counterexample: { receiver: '{ get x() { throw 1 } }', key: 'x',
//                       general: 'throw(1)', variant: 'normal(undefined)' },
//     lesson: 'behaviour inclusion is necessary, not sufficient; steps are compared too' }

// Contracts print as a table for review.
g.contract.table([numAdd, jsAdd, jsGet, objNew, enqueue, ownData])
// → op               behaviour            obligations                            permissions
//   num.add          none                 none                                   all
//   js.add           callsUser, throws    mayCollect, nonlocalThrow, borrows 0 1  none (narrows to num.add)
//   js.get           callsUser, throws    mayCollect, nonlocalThrow, borrows 0 1  none
//   obj.new          fresh                mayCollect                             erase if unobserved, move, speculate
//   job.enqueue      writes(jobs)         mayCollect, borrows 0                  move not across writes(jobs)
//   js.get.own_data  reads(heap)          none                                   erase, duplicate; move, merge, hoist and
//                                                                                speculate only with the fact
