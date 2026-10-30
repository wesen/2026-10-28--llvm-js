---
id: exceptions
title: Exceptional control flow
group: Representation
about: Operations that may throw, invoke and block-level exits, try, catch and finally as completion records, and what handlers may see.
order: 5
---
# Exceptional control flow

In JavaScript almost anything can throw: a property read can run a getter, `+` can run `valueOf`, a call can run anything. A compiler that treated throwing as a rare accident would get most programs wrong, so core IR treats it as control flow. Every operation that may throw has an edge to where the exception goes, the analyses follow those edges like any others, and the lowering implements them. This doc describes the two ways core IR writes exceptional edges, how the frontend lowers `try`, `catch` and `finally`, and the one rule that shapes everything else: a handler sees values from the head of the protected block. Presets [I-09](lab:preset?id=I-09) and [I-10](lab:preset?id=I-10) show both forms.

## Which operations may throw

Whether an operation may throw is part of its contract. Its behaviour includes `throws` (as `js.type_error` and `cell.load_checked` do) or `callsUser` (as `js.get`, `js.add` and `js.call` do, since user code may throw), and its obligations include `nonlocalThrow` when the exception may leave through a runtime helper. `num.add`, `js.strict_eq` and `js.typeof` cannot throw. The verifier uses the contract: an operation that may throw must be in a block that says where throws go, or be the operation of an `invoke` (rule `may-throw-without-exit`).

## invoke

An **invoke** terminator wraps one operation and names two successors:

```text
entry:
  invoke js.call(callback, undefined) normal afterCall() throw failed()
afterCall(ignored: any):
  invoke js.get(object, "value") normal done() throw failed()
done(value: any):
  return value
failed(e: any):
  return "failed"
```

When the operation returns, control takes the normal edge and the result becomes the target's first parameter; when it throws, control takes the throw edge and the thrown value becomes the handler's first parameter. These first parameters are **implicit**: the edges list only the extra arguments. An invoke gives each operation its own handler and its own arguments, which is the form a backend with landing pads wants.

## Block-level exits

Writing an invoke for every operation of a twenty-line `try` would be tedious and would split the code into twenty blocks. So a block header can declare one exit for all its operations:

```text
entry throws to handler(fallback):
  v = js.get(o, "value")
  return v
handler(e: any, fb: any):
  return fb
```

`throws to H(args)` sends a throw from any operation of the block to `H`, with the thrown value first and then `args`. `throws unwind` sends it out of the function. The frontend writes one of the two on every block it makes, using the innermost enclosing handler.

## The head-of-block rule

A block-level exit can be taken by the first operation of the block, before anything else in it has run. So its arguments are evaluated at the block's head and may use only values available there. The engine's dominance computation makes this precise by splitting each block into a head and a body and attaching exceptional edges to the head ([Dominance and dominance frontiers](lab:doc?id=dominance)), and the verifier refuses a throw argument defined inside its own block.

The rule has a consequence for variables. A handler that reads a variable must see its value at the moment of the throw. If the variable is written in the middle of a protected block, no value available at the block's head is right for every throwing operation after the write. So `promote-cells` leaves such a variable as a cell when any of its loads can run after the handler, and the handler reads the cell. In [B-04](lab:preset?id=B-04), `sum` is written inside a `try` and read after the loop: it stays the cell `c_sum3`, while the loop counter, never written inside the `try`, becomes a block parameter.

## try and catch

`try { A } catch (e) { B }` lowers to: the blocks of `A`, each headed `throws to catchN`; a block `catchN(e)` that starts `B` with the exception as its parameter; and a join after both. A `throw` statement inside `A` is a `throw` terminator, which follows its block's exit like any throwing operation: it goes to `catchN` without leaving the function. The catch binding `e` is an ordinary variable of the catch block (a cell first, then usually promoted).

## finally and completion records

`finally` must run however the region is left, and afterwards continue the way the region was going. The frontend lowers it with **completion records**, values of type `completion` made by `completion.normal()`, `completion.return(v)` and `completion.throw(e)`:

```js
// frontend.js
  tryFinally(st) {
    // Every way out of the protected region becomes a completion record: normal, return
    // or throw. The finally body runs once, then the record says where to continue.
    const join = this.newBlock('finally', [this.value('c')]);
// …
    if (!this.done()) this.jump(join, [this.emit('completion.normal', { hint: 'c' })]);
    this.handlers.pop();
    this.cur = thrown; this.jump(join, [this.emit('completion.throw', thrown.params[0].id, { hint: 'c' })]);
```

Falling off the end jumps to the join with a normal record; a `return` inside the region jumps there with a return record (the frontend's `ret` looks for an enclosing `finally` first); a throw goes to a `finthrow` block that makes a throw record. The join runs the `finally` body once, then tests the record with `completion.is[return]` and `completion.is[throw]`, and returns `completion.value(c)`, rethrows it, or continues after the statement. In [I-10](lab:preset?id=I-10) all three happen, in three calls of one function.

A `break` or `continue` that would cross a `finally` is outside the frontend's subset: it would need a fourth kind of record per target.

## Liveness and roots across exceptional edges

Liveness flows backward along exceptional edges too. A handler's throw arguments are live at the head of the protected block and therefore across every operation that may throw in it: in `guarded`, `fallback` is live across the `js.get` although nothing after the get uses it. The root planner sees the same sets, so a managed value a handler needs keeps its root slot until the last operation that could reach the handler.

## Lowering

Exceptional edges are a property of the IR; how they are implemented is a lowering strategy. The default, `setjmp`, follows the Hermes LLVM backend: a function with handlers calls `_setjmp` once in its prologue, each protected block stores its handler's number into a volatile `%try_state`, and a throw from a runtime helper long-jumps back to the prologue, where `catch.dispatch` switches on `%try_state` to the right handler block. `statusReturn` instead has helpers return a status that the caller tests. [Unwinding](lab:doc?id=unwinding) and [L-08](lab:preset?id=L-08) cover both, and [Chapter 14](lab:book?ch=14) explains what a handler must restore.

## What this model leaves out

There are no asynchronous exceptions (a rejected promise is a value, not a throw through frames), no `finally` crossed by `break` or `continue`, and no exceptions from the engine itself inside the program's meaning (a stale reference in plan mode stops the run instead). Every exception carries one value; there is no separate stack trace.

[Chapter 5](lab:book?ch=5) develops exceptional control flow in full.
