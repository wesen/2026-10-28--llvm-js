# Errors across calls

On the screen is an invoice total that can fail: `readField` throws when a record lacks a field, `total` multiplies two fields, and `invoice` loops over the records, catching the failure of one record and going on with the next. The program prints `skipped: missing field qty`, then `sum 16, skipped 1`, and ends with an uncaught `Error: missing field price` from the last line, `total({})`. The preset follows a throw three frames down to a handler, and shows what the handler's existence does to the variables around it.

> **Try it.** [Open program.js](lab:open?file=program.js&line=11), [show invoice on the Stage](lab:fn?name=invoice) and [turn on the exceptional edges](lab:overlay?name=exceptional&on=1). The block `try7` has a dashed edge to `catch5`.

## Three frames down and back

`invoice` calls `total`, which calls `readField`, which throws in its block `then1`. Neither `readField` nor `total` has a handler: their blocks say `throws unwind`, so the exception leaves each function in turn. In `invoice` the call sits in `try7`, whose header is `throws to catch5`, and that is where it lands, with the error as `catch5`'s parameter `e13`.

> **Try it.** [Run it](lab:build) and [open Events](lab:show?view=events). The first `throw` is at `readField/then1/term` and the matching `catch` at `invoice/try7/2`, the call to `total`, with handler `catch5`. The last throw has no catch: the outcome pill shows `throw`.

## Two variables, two fates

`sum` and `bad` are both `let` variables of `invoice`, and both change inside the loop. After promotion they look nothing alike. `bad` became a block parameter: `forof1(bad4_2, i6_1)` carries it around the loop, `catch5` computes `v21 = js.add(bad4_2, 1)`, and the join block `endtry6(bad4_1)` receives either the old or the new count. `sum` is still a cell, `c_sum3`, read and written with `cell.load` and `cell.store`:

```text
try7() throws to catch5:
  sum14 = cell.load(c_sum3)
  total15 = cell.load(c_total)
  r17 = js.call(total15, undefined, item12)
  v18 = js.add(sum14, r17)
  cell.store(c_sum3, v18)
  jump endtry6(bad4_2)
```

The reason is the handler. `sum` is stored inside the protected block `try7`, and code after the handler (the final `return { sum, bad }`) reads it. If the call to `total` throws, the handler must see the value `sum` had at that moment, but an exceptional exit passes its arguments as they were at the head of the block. A cell sidesteps the problem: the handler and everything after it read the cell, which holds whatever was last stored. `bad` is only written in `catch5`, which is not protected, so it can be an SSA value.

> **Try it.** [Select the store to the cell](lab:node?id=invoice/try7/4), then [the block parameter of the join](lab:node?id=invoice/endtry6). The [decisions in Events](lab:show?view=events) list `invoice/c_bad4` as promoted and say nothing about `c_sum3`.

## What the handler costs the plan

Every call in `try7` is a safepoint, and the loop's values must survive each one whether it returns or throws, so the plan for `invoice` keeps 8 root slots, a 12-slot frame of 96 B. Under [GC stress](lab:run?mode=plan&gc=stress) the collector runs 70 times; the error object is moved while it travels up through `total` and `readField`, and the handler still reads its `message`.

> **Exercise.** Move `sum = sum + total(r);` so that `total(r)` is computed into a `const` first and the addition happens after the `try`. Does `sum` stay a cell? Compare the decisions and the number of root slots before and after.

## Where next

[Chapter 14](lab:book?ch=14) covers unwinding: how a throw in a helper reaches a handler. [J-03](lab:preset?id=J-03) adds `finally`, and [I-09](lab:preset?id=I-09) builds exceptional edges by hand.
