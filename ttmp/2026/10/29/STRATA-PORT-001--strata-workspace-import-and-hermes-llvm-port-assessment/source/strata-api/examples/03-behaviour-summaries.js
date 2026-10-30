// 03 · Behaviour summaries: a join-semilattice
//
// Model: a behaviour summary is an upper bound on what an operation may do:
// read or write a resource, create a fresh identity, throw, diverge, run user
// code, talk to the host. Summaries combine with join, which is associative,
// commutative and idempotent, and `unknown` is the top element. Runtime
// obligations (may collect, needs a write barrier) are a separate summary,
// because they answer a different question: what must lowering guarantee?
//
// Notice: the laws are about summaries, not about operations. "join is
// commutative" never means two operations may be swapped.

import { g } from 'strata'

const { fx, ob } = g

// Atoms.
fx.none
fx.reads('heap')
fx.writes('cells')
fx.fresh                                       // produces a new object identity
fx.throws
fx.diverges
fx.callsUser                                   // may run arbitrary user code
fx.host('print')
fx.unknown                                     // top: may do anything, engine internals included

// Join builds summaries.
const getterCall = fx.callsUser.join(fx.throws)
getterCall.le(fx.unknown)                      // → true
fx.reads('heap').join(fx.reads('heap'))        // → fx.reads('heap')   (idempotent)

// callsUser implies everything user code can reach, but it stays strictly below unknown:
// user code cannot touch engine internals (roots, code memory, the module registry's records).
fx.callsUser.expand()
// → reads(js-reachable) ∪ writes(js-reachable) ∪ fresh ∪ throws ∪ diverges ∪ host(via user code)
fx.callsUser.le(fx.unknown) && !fx.unknown.le(fx.callsUser)   // → true
// A known callee narrows callsUser: direct eval writes only the cells its scope can name (example 24).
fx.writes(g.resource('cells', { scope: 'counter' })).le(fx.callsUser)   // → true

// Resources start coarse and can be refined later.
const buffers = g.resource('array-buffer', { within: 'heap' })
fx.writes(buffers).le(fx.writes('heap'))       // → true
fx.writes(buffers).join(fx.writes('cells'))    // → writes(array-buffer, cells)

// The laws, checked on generated summaries.
g.law.join(fx)
// → { associative: ok, commutative: ok, idempotent: ok, top: 'unknown', samples: 2000 }

// Obligations are their own summary.
const allocObject = { behaviour: fx.fresh, obligations: ob.mayCollect }
const storeField = { behaviour: fx.writes('heap'), obligations: ob.writeBarrier }
ob.mayCollect.join(ob.writeBarrier)            // → obligations(mayCollect, writeBarrier)

// Why two summaries: allocation writes nothing observable, yet live values must be
// rooted around it. Erasing it is a behaviour question; rooting is an obligation question.
g.perm.explain(g.ops['obj.new'], 'erase', { resultUsed: false, identityObserved: false })
// → { allowed: true, because: ['fresh identity unobserved', 'no observable writes'],
//     note: 'mayCollect is an obligation; it does not block erasure' }

// The summary of a block is the join of its operations' summaries (conservative).
const block = g.ir.parse(`
fn f(o: object, k: any) -> any {
entry:
  a = obj.new()
  invoke js.get(o, k) normal done throw failed
done(v: any):
  return v
failed(e: any):
  throw e
}`).block('entry')
fx.of(block)                                   // → fresh ∪ callsUser ∪ throws  (still below unknown)

// Joining summaries does not license commuting operations.
const enqueue = g.ops['job.enqueue']          // the standard registry of operations
g.perm.commute(enqueue, enqueue)
// → { allowed: false, because: 'both write the ordering resource jobs' }
