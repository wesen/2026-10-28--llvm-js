# finally with return

On the screen is the usual shape of resource handling: `withResource(name, work)` prints `open`, runs `work()` inside `try`, returns its result, and prints `close` in `finally`. It is called three times: with work that returns 5, with work that returns 0, and with work that throws a TypeError, which `main` catches. The output shows `close` on every path: `open a`, `close a`, `5`, then the same for `b` with `0`, then `open c`, `close c`, `caught expected a number`. A `return` inside `try` does not return yet, and this preset shows how the compiler makes it wait.

> **Try it.** [Open program.js](lab:open?file=program.js&line=4) and [show withResource on the Stage](lab:fn?name=withResource), then [turn on the exceptional edges](lab:overlay?name=exceptional&on=1): the protected block `try4` has a dashed edge to `finthrow2`.

## Every exit becomes a record

The frontend lowers `try … finally` with **completion records**: small heap values that say how the protected region ended. A normal end makes `completion.normal()`, a `return v` makes `completion.return(v)`, and a throw caught by the region's handler makes `completion.throw(e)`. All three jump to one block, `finally1`, with the record as its parameter:

```text
try4() throws to finthrow2:
  r9 = js.call(work, undefined)
  c10 = completion.return(r9)
  jump finally1(c10)
finthrow2(e7: any) throws unwind:
  c11 = completion.throw(e7)
  jump finally1(c11)
finally1(c6: completion) throws unwind:
  v13 = js.add("close ", name)
  host.print(v13)
  isret14 = completion.is[return](c6)
  branch isret14, fin_return5(), fin_rest6()
```

The finally body runs once, in `finally1`, whichever way the region ended. After it, the record decides where to go: [fin_return5](lab:node?id=withResource/fin_return5/0) takes the value out and returns it, `fin_throw7` rethrows the stored exception, and a normal completion falls through to `endfinally3`. [Select the branch at the end of finally1](lab:node?id=withResource/finally1/term) to see the first test.

## Why records and not duplicated code

A compiler could copy the finally body onto each exit instead: one copy before the return, one in the handler, one on the normal path. The Java compiler does this for `finally`, and it is fast. It also multiplies code by the number of exits, and every copy must be kept identical. The workbench keeps one copy and pays for it with a record that is allocated and tested at run time: `completion.return(r9)` is an allocation, and so it is a safepoint.

## What the record costs the plan

The record is a heap value, so it needs a root slot while anything can collect. [The Plan view](lab:show?view=plan) shows `c6` rooted at both safepoints of `finally1`, the `js.add` and the `host.print` that write `close a`; `name` is rooted there too, because the finally body reads it. Three root slots serve the whole function: `name` and `v13` share one, and `work`, `c6`, `e7` and `r9` share another, because no two of them are needed at the same safepoint. The frame is 6 slots, 48 B.

> **Try it.** [Run with GC stress](lab:run?mode=plan&gc=stress) and [open Events](lab:show?view=events). The throw from `parsePositive` is caught at `withResource/try4/0` by `finthrow2`, rethrown at `fin_throw7`, and caught again by `main` in `catch1`. The record carried the TypeError across the `finally` while the collector moved it.

## Where the throw goes

`parsePositive("x")` throws inside `work`, which runs inside `withResource`'s protected block. The exceptional exit of `try4` sends it to `finthrow2`, which wraps it in a record; `finally1` prints `close c`; `fin_throw7` throws it again, and this time the block's exit is `throws unwind`, so it leaves `withResource` and reaches `main`.

> **Exercise.** Add `return -1;` at the end of the `finally` block. JavaScript says a `return` in `finally` replaces whatever the region was doing, including a pending throw. Predict the output for `c`, run it, and find the new edge in `finally1`.

## Where next

[Chapter 5](lab:book?ch=5) treats exceptions as edges and completion records in general. [I-10](lab:preset?id=I-10) lowers `try`, `catch` and `finally` one at a time, and [J-07](lab:preset?id=J-07) follows a throw across several calls.
