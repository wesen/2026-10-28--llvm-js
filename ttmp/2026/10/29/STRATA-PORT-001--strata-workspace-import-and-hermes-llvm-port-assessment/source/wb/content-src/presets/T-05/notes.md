# Forwarding stores to loads

`count` in `makeCounter` is captured by the closure it returns, so it stays a **cell**: every assignment is a `cell.store` and every read a `cell.load`. Many of those loads read a value the function stored a moment ago. `forward-store-to-load`, part of the standard rewrites, replaces such a load with the stored value, provided nothing in between may write a cell. Its side condition reads the behaviour of every operation between the store and the load. The table lists which loads it forwarded and why the others stayed.

> **Try it.** [Show the table](lab:show?view=experiments), then [look at makeCounter in L1](lab:fn?name=makeCounter). The output, `first 1 / report 1 / 2 3`, is the same with both rewrite sets ([Events](lab:show?view=events)).

## Before

With the canonical set, `makeCounter` reads the cell four times:

```text
  cell.store(c_count2, 0)
  count6 = cell.load(c_count2)
  v7 = js.add(count6, 1)
  cell.store(c_count2, v7)
  count8 = cell.load(c_count2)
  v10 = js.add("first ", count8)
  host.print(v10)
  count11 = cell.load(c_count2)
  report12 = cell.load(c_report)
  r14 = js.call(report12, undefined, count11)
  count15 = cell.load(c_count2)
```

## The side condition

For a `cell.load(c)`, the rewrite walks backwards through the block. If it reaches a `cell.store(c, v)`, the load can become `v`. If it first reaches an operation whose behaviour includes writing `cells`, it stops and refuses, naming that operation. `js.add` and `js.call` are `callsUser`, which includes writing every user resource, `cells` among them. `host.print` talks to the host and writes nothing, so it does not block.

## Rounds

The rewrites run to a fixed point, and forwarding works with folding:

1. `count6` reads the store of `0` directly above it: forwarded, so `js.add(0, 1)` folds to `1`, and the store becomes `cell.store(c_count2, 1)`.
2. `count8` was blocked by the `js.add` in round 1. Now that the `js.add` is gone, it reads the store of `1`: forwarded, and `"first " + 1` folds to `"first 1"`.
3. `count11` is behind `host.print`, which does not write cells: forwarded, and the call becomes `js.call(report12, undefined, 1)`.

Three loads forwarded, two folds made possible, six operations fewer.

## What stayed

[count15](lab:node?id=makeCounter/entry/7) comes after `js.call(report12, …)`. `report` is user code and could have assigned `count` (it does not, but its behaviour, `callsUser`, says it might), so the load stays. That is the case the condition exists for: if `report` had been `x => { count = 99; }`, forwarding would make `third` wrong.

[report12](lab:node?id=makeCounter/entry/5) is a load of a different cell, `c_report`, and it is kept too, because of the `cell.store(c_count2, 1)` before it. The resource in a behaviour is `cells`, all of them: the condition cannot tell that a store to `count` does not change `report`. Distinguishing cells would need a finer resource, one per cell, which the workbench does not have.

> **Try it.** In program.js, replace `report(second);` with `print("report " + second);` and [rerun](lab:build). With no call left, `count15` is forwarded too, and `makeCounter` ends with `cell.store(c_third5, 1)`: the value of `third` is known at compile time.

## Why the cell stays at all

`promote-cells` would turn `count` into SSA values, making every load a plain use, if the closure did not capture it. Here two functions share the variable, so it must live in memory (a cell) that both can reach, and forwarding is the local substitute for promotion: inside one block, between two calls, the compiler can still use the value it just wrote. [I-08](lab:preset?id=I-08) shows which variables stay cells.

> **Exercise.** Move `print("first " + first);` so it comes after `report(second);`. Predict which loads are forwarded now, then rerun and compare with the table.

## Where next

[Chapter 10](lab:book?ch=10) covers rewrites with side conditions; the doc [Rewriting with side conditions](lab:doc?id=rewriting) lists `ctx.noWritesBetween`, the helper for conditions of this kind. [C-03](lab:preset?id=C-03) has the permissions of `cell.load` (`merge: if nothing writes cells between them`), which this rewrite applies.
