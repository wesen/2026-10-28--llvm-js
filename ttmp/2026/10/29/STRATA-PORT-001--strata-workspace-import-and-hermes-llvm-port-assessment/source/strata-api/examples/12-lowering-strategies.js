// 12 · Lowering strategies and their invariants
//
// Model: lowering picks physical strategies for representation, GC roots,
// exception transfer, suspension and calls. Every strategy slot takes the
// four usual forms: nothing (default), partial params, a named strategy, or
// a lambda that returns a strategy, possibly the default. A strategy produces
// an execution plan, and every plan passes the same invariant checker.
// Strategies combine only in pairs declared compatible, because roots and
// unwinding interact. Conflicts are reported by check(), before any artifact.
//
// Notice: a hand-written root planner that forgets a value is rejected with
// the value, the call and the reason; an undeclared strategy pair is
// 'unknown', not 'ok'; frame sizes follow one accounting rule everywhere.

import { g, kib, mib, slots } from 'strata'

const base = g.pipeline()

// The four forms of a slot.
const p1 = base.roots()                                    // default: stackReuse (liveness-based slot reuse)
const p2 = base.roots({ reuse: false })                    // params: one slot per value, today's behaviour
const p3 = base.roots('arena')                             // named: runtime-owned activation storage
const p4 = base.roots(g.roots.arena({ chunk: kib(16), budget: mib(4) }))
const p5 = base.roots((fn, ctx) =>                         // lambda: returns a strategy for each function
  fn.peakLive.gt(slots(900)) ? g.roots.arena() : ctx.default)

p5.summary().roots
// → { strategy: 'lambda(anonymous): arena or stackReuse per function', cacheable: 'session only (unnamed lambda)' }

// A named lambda has a stable identity, so its results can be cached across sessions.
const bigFramesToArena = g.strategy.name('big-frames-to-arena', (fn, ctx) =>
  fn.peakLive.gt(slots(900)) ? g.roots.arena() : ctx.default)
base.roots(bigFramesToArena).summary().roots.cacheable    // → 'persistent'

// The plan for readAfterCall under the default. Frame accounting, the same in every strategy:
// rooted values + distinct managed constants used as operands + 2 fixed slots (scratch, discard)
// + outgoing argument slots, max(1, largest call's argument count without this).
const src = g.source.text(`function readAfterCall(object, callback) { callback(); return object.value }`)
const prog = g.compile(base, src)
prog.plan('readAfterCall')
// → { roots: [{ slot: 0, values: ['object'], why: 'live across c0 js.call' },
//             { slot: 1, values: ['callback'], why: 'operand borrowed by c0 js.call (borrows 0)' }],
//     constants: 0, fixed: 2, argv: 1,
//     frame: '5 slots · 40 B on host64',
//     unwind: { checkpoint: 'entry', restores: ['root chain', 'managed frame'] } }
prog.why('slot:readAfterCall/0')
// → { value: 'object', source: '1:24', liveAcross: 'c0 js.call(callback)',
//     becauseCollecting: 'js.call obligation mayCollect (contract js.function@0.1.0)',
//     chosenBy: 'roots: stackReuse', sharedWith: [] }

// A buggy planner: a custom strategy whose plan roots only values used in the *next* block.
const nextBlockOnly = g.roots.custom('next-block-only', (fn, ctx) => ctx.plan.rootsFor(fn, { horizon: 'next-block' }))
g.compile(base.roots(nextBlockOnly), src).diagnostics
// → [{ check: 'gc-safety', fn: 'readAfterCall', value: 'object', liveAcross: 'c0 js.call',
//      problem: 'no root assigned', note: 'a moving collection here would leave object stale' }]

// Representation: unbox only where facts allow, and box back exactly.
const fibSrc = g.source.text(`function fib(n) { let a = 0, b = 1; for (let i = 0; i < n; i++) [a, b] = [b, a + b]; return a }`)
g.compile(base.representation('unboxWhenProven'), fibSrc).plan('fib').values
// → { i: 'f64 (fact number: constant 0, num.add)', a: 'f64 (fact number)', b: 'f64 (fact number)',
//     n: 'tagged (unknown argument)', returned: 'tagged (boxed from f64, exact)' }
// i stays f64: with n unknown, i < n does not bound i to int32. An i32 counter needs a fact
// n: int32 (a guard at entry) or an overflow exit on the increment.

// Exceptions: the transfer mechanism must match the providers' helpers. check() says so.
base.exceptions('statusReturn').check()
// → { ok: false, diagnostics: [{ slot: 'exceptions', strategy: 'statusReturn',
//      conflict: 'provider hermes.js.object lowers js.get with nonlocalThrow',
//      fix: 'use providers whose helpers return status, or keep setjmp' }] }

// Strategy pairs must be declared compatible, with the evidence that backs them.
g.compat(g.roots.stackReuse(), g.exceptions.setjmp())
// → { ok: true, evidence: 'current Hermes protocol: _sh_catch_no_pop restores locals and frame together' }
g.compat(g.roots.arena(), g.exceptions.setjmp())
// → { ok: 'unknown', reason: 'no declared pair', fix: 'g.compat.declare(...) with traces for throw, catch, GC, suspension' }

g.compat.declare(g.roots.arena(), g.exceptions.setjmp(), {
  requires: ['checkpoint stores {rootHead, managedStack, arenaMark}', 'rewind after thrown value is rooted'],
  tests: ['nested throw', 'catch in same activation', 'outer catch', 'finally', 'host escape', 'repeat 1000x'],
})
g.compat(g.roots.arena(), g.exceptions.setjmp())
// → { ok: true, requires: 'arena mark saved in every catch checkpoint', evidence: 'declared, with 6 trace tests' }
g.compat(g.roots.statepoints(), g.exceptions.setjmp())
// → { ok: 'unknown', reason: 'no declared pair' }

// Suspension and calls follow the same pattern.
base.suspension()                              // default: g.suspension.hermes()
base.calls()                                   // default: g.calls.hermesNative()
base.suspension('continuationObjects').calls('engineLocal').check()
// → { ok: true, note: 'engineLocal calls require artifacts with strata-abi/2; old artifacts are rejected at admission' }
