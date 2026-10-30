// 02 · Types, representations and facts
//
// Model: semantic types form a lattice from bottom to any. A representation
// (tagged, f64, i32) is how a value is stored, a separate question. A fact is
// knowledge about a value that carries its origin: a guard, a producer or an
// analysis. Facts let a general operation narrow to a cheaper variant, and a
// fact is dropped as soon as its origin no longer holds.
//
// Notice: join and meet, a fact pointing at the guard that produced it, and
// invalidation after a control-flow edit removes that guard's edge.

import { g } from 'strata'

const { t } = g

// The type lattice.
t.int32.le(t.number)                           // → true
t.int32.join(t.string)                         // → t.union(int32, string)
t.number.meet(t.string)                        // → t.bottom
t.any.join(t.object)                           // → t.any
g.law.lattice(t)                               // → { ok: true, samples: 2000 }

// Representations are not types. Boxing back to tagged is exact; unboxing needs a fact.
g.rep.f64.canHold(t.number)                    // → true
g.rep.i32.canHold(t.number)                    // → false (fractions, NaN, -0)
g.rep.i32.canHold(t.int32)                     // → true

// A function with a guard: is x an int32? js.add may throw (valueOf, toString), so both
// blocks that use it declare an exceptional exit, as example 07 requires.
const addOne = g.fn('addOne', { x: t.any }, t.any, (f, { x }) => {
  f.entry($ => $.branch($.op('core.is_int32', x), f.to('fast', x), f.to('slow', x)))
  f.block('fast', { y: t.any }, ($, { y }) => $.ret($.op('js.add', y, $.const(1))), { onThrow: 'failed' })
  f.block('slow', { z: t.any }, ($, { z }) => $.ret($.op('js.add', z, $.const(1))), { onThrow: 'failed' })
  f.block('failed', { error: t.any }, ($, { error }) => $.throw(error))
})
g.verify(addOne)                               // → { ok: true }

// Type facts come from the shared solver (example 09).
const facts = g.solve(g.analysis.typeFacts, addOne)

facts.of('fast.y')
// → { type: int32, origin: { kind: 'guard', op: 'core.is_int32', edge: 'entry→fast (true)' } }
facts.of('slow.z')
// → { type: any, origin: null }   (the false edge says "not int32", which is not useful here)

// The fact selects a cheaper variant of js.add in the fast block. num.add is a distinct
// operation that js.add declares as its variant for number operands (example 04).
g.op.narrow('js.add', facts.at('fast/op#0'))
// → { variant: 'num.add', because: 'both operands are numbers (int32 by guard, constant 1)',
//     contract: 'num.add refines js.add when both operands are numbers; it cannot throw' }

// Facts can also be stated by hand, with an explicit origin.
const assumed = g.fact.type('fast.y', t.int32, { origin: g.origin.assumption('profile at site s12') })
assumed.origin.kind                            // → 'assumption' (only legal with a deoptimization exit; see example 13)

// Invalidation: an edit that removes the guard's edge kills the fact.
const edited = addOne.edit(e => e.retarget('entry', { whenTrue: 'slow' }))
g.fact.valid(facts.of('fast.y'), edited)
// → { valid: false, reason: "origin edge 'entry→fast (true)' no longer exists" }

// A pass that edits the CFG and keeps using old facts is caught by the debug verifier.
g.verify(edited, { facts })
// → { ok: false, diagnostics: [{ rule: 'stale-fact', fact: 'fast.y: int32', origin: 'entry→fast' }] }
