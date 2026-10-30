# Exceptions as edges

An operation that may throw has two possible successors: the next operation, and wherever the exception goes. Core IR writes the second one down as an edge, so analyses and the root planner see exceptional control flow exactly like ordinary control flow. There are two ways to write it, and this preset uses both on objects whose `value` is a plain property or a getter that throws. It prints `42 failed 42 fallback`.

> **Try it.** [Show readAfterCall on the Stage](lab:fn?name=readAfterCall) with [exceptional edges in teal](lab:overlay?name=exceptional&on=1), then [guarded](lab:fn?name=guarded). [Events](lab:show?view=events) lists each throw and the handler that caught it.

## invoke: one operation, two edges

```text
fn readAfterCall(object: any, callback: any) -> any {
entry:
  invoke js.call(callback, undefined) normal afterCall() throw failed()
afterCall(ignored: any):
  invoke js.get(object, "value") normal done() throw failed()
done(value: any):
  return value
failed(e: any):
  return "failed"
}
```

An **invoke** is a terminator wrapping one operation. If the operation returns, control takes the `normal` edge and the result arrives as the target's first parameter: `afterCall(ignored)` receives the callback's result, `done(value)` the property. If it throws, control takes the `throw` edge and the thrown value arrives as the handler's first parameter: `failed(e)`. Those first parameters are **implicit**: the edge `normal done()` passes no arguments, but `done` has one parameter, filled by the invoke.

[Select the second invoke](lab:node?id=readAfterCall/afterCall/term): for the `bad` object its `js.get` runs the getter `explode`, which throws; the run's catch event names `readAfterCall/afterCall/term` and the handler `failed`.

## A block's exceptional exit

```text
fn guarded(o: any, fallback: any) -> any {
entry throws to handler(fallback):
  v = js.get(o, "value")
  return v
handler(e: any, fb: any):
  return fb
}
```

A block header can declare one exceptional exit for every operation in it: `throws to handler(fallback)`. Any operation of `entry` that throws goes to `handler`, which receives the thrown value first (`e`) and then the listed arguments (`fb`). The arguments are evaluated at the head of the block, so they may use only values available there, such as parameters of the block or of the function. `throws unwind` is the other choice: the exception leaves the function, as in `main` and `explode`.

> **Try it.** [Turn on the live overlay](lab:overlay?name=live&on=1) on `guarded`. `fallback` is live across [the js.get](lab:node?id=guarded/entry/0) even though nothing after it in `entry` uses it: the handler edge needs it if the get throws.

## Why two forms

`invoke` is precise: each operation has its own handler and its own arguments, which is what a backend with landing pads wants. The block-level exit is compact: a `try` block of twenty operations needs one header, not twenty invokes, and the JavaScript frontend uses it for every `try`. The price is the head-of-block rule. A handler that needs a variable's value *at the operation that threw* cannot get it as a throw argument, because the value may change in the middle of the block; the frontend keeps such variables as cells instead ([I-10](lab:preset?id=I-10) and [B-04](lab:preset?id=B-04)).

## The verifier insists

Every operation that may throw must have an exit. Delete `throws to handler(fallback)` from `guarded` and the verifier refuses the function: `js.get may throw but entry has no exceptional exit`. [I-04](lab:preset?id=I-04) lists that rule with the others. A `throw` terminator follows its block's exit too: in `explode` it unwinds to whoever called the getter.

> **Exercise.** Give `failed` a second parameter that receives `object` from both invokes (`throw failed(object)`), and print it in `main`'s output by returning it. Then add an operation to `guarded`'s `entry` after the `js.get`, and decide whether its result could be passed to `handler`.

## Where next

[Chapter 5](lab:book?ch=5) explains exceptional edges and the head-of-block rule. [I-10](lab:preset?id=I-10) lowers `try`, `catch` and `finally` from JavaScript, and [L-08](lab:preset?id=L-08) shows how these edges are implemented with `setjmp`.
