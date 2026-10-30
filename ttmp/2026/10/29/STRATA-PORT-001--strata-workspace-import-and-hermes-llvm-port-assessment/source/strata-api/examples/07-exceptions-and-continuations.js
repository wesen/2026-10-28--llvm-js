// 07 · Exceptional control flow and continuations
//
// Model: an operation that may throw is written as `invoke`, with a normal
// successor and an exceptional successor. The normal edge passes the result
// as the first argument; the exceptional edge passes the thrown value. The
// exceptional successor sees the state *after* any effects already performed;
// nothing rolls back. `finally` is lowered to plain blocks that carry an
// explicit completion value (normal, return, throw, break).
//
// Notice: the verifier refuses a may-throw operation with no exceptional exit;
// moving a property read across a call is refused with a reason; the
// completion record is visible in the core IR.

import { g } from 'strata'

const { t } = g

// readAfterCall from doc 02:
//   function readAfterCall(object, callback) { callback(); return object.value }
const readAfterCall = g.fn('readAfterCall', { object: t.any, callback: t.any }, t.any, (f, { object, callback }) => {
  f.entry($ => $.invoke('js.call', [callback, $.const(undefined)],
    { normal: f.to('afterCall'), throw: f.to('failed') }))
  f.block('afterCall', { ignored: t.any }, $ =>
    $.invoke('js.get', [object, $.const('value')], { normal: f.to('done'), throw: f.to('failed') }))
  f.block('done', { value: t.any }, ($, { value }) => $.ret(value))
  f.block('failed', { error: t.any }, ($, { error }) => $.throw(error))
})
g.verify(readAfterCall)                        // → { ok: true }

// A may-throw operation outside invoke needs a block-level exceptional exit.
const implicit = g.fn('implicit', { o: t.any }, t.any, (f, { o }) => {
  f.entry($ => $.ret($.op('js.get', o, $.const('x'))), { onThrow: 'failed' })
  f.block('failed', { error: t.any }, ($, { error }) => $.throw(error))
})
g.verify(implicit)                             // → { ok: true }: entry declares onThrow

const missing = g.fn('missing', { o: t.any }, t.any, (f, { o }) => {
  f.entry($ => $.ret($.op('js.get', o, $.const('x'))))
})
g.verify(missing)
// → { ok: false, diagnostics: [{ rule: 'may-throw-without-exit', op: 'js.get', block: 'entry',
//                               fix: "use $.invoke(...) or declare { onThrow: '<block>' }" }] }

// Reordering: can the read move before the call? The contract says no.
g.rewrite.tryMove(readAfterCall, { op: 'afterCall/js.get', before: 'entry/js.call' })
// → { allowed: false, because: ['js.call: callsUser (may write object.value)', 'js.get: callsUser, throws'],
//     wouldChange: 'which exception escapes first, and the value read' }

// The exceptional successor receives the post-effect state.
const spec = g.semantics().profile('js-sync')
const run = spec.run(readAfterCall, {
  args: [
    g.value.object({ value: 1 }),
    g.value.fn('() => { o.value = 2; throw "boom" }', { captures: { o: 'arg0' } }),
  ],
})
run.outcome                                    // → throw('boom')
run.heap.get('arg0').value                     // → 2   (the write before the throw is kept)

// finally lowers to blocks with an explicit completion value.
const src = g.source.text(`
function withCleanup(work) {
  try { return work() } finally { log('cleanup') }
}`)
const p = g.compile(g.pipeline().stopAfter('L1'), src)
p.ir('L1', { fn: 'withCleanup' })
// → fn withCleanup(work: any) -> any {
//   entry:
//     invoke js.call(work, undefined) normal ret_path throw throw_path
//   ret_path(v: any):
//     c1 = completion.return(v)
//     jump finally(c1)
//   throw_path(e: any):
//     c2 = completion.throw(e)
//     jump finally(c2)
//   finally(c: completion):
//     invoke js.call_global("log", "cleanup") normal resume(c) throw failed
//   resume(r: any, c3: completion):
//     isReturn = completion.is_return(c3)
//     branch isReturn, do_return(c3), do_throw(c3)
//   do_return(c4: completion):
//     rv = completion.value(c4)
//     return rv
//   do_throw(c5: completion):
//     tv = completion.value(c5)
//     throw tv
//   failed(e2: any):
//     throw e2
//   }
//   (flat SSA: every name is defined once in the function; terminators take values, not operations)
p.why('withCleanup/finally.c')
// → 'completion value introduced by lower-finally (L0→L1); variants: return, throw'
