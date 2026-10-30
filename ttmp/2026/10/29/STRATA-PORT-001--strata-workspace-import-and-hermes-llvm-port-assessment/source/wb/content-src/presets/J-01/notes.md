# A counter with closures

On the screen is a counter factory: `makeCounter(start)` returns an object with three arrow functions, `inc`, `dec` and `reset`, that all read and write one variable, `count`. The program makes two counters, steps them and prints `a 4, b 98` and then `a after reset 1`. Three closures sharing one variable is the smallest program where a compiler cannot keep that variable in a register, and this preset shows what it does instead.

> **Try it.** [Open program.js](lab:open?file=program.js&line=3), then [show makeCounter on the Stage](lab:fn?name=makeCounter) and [look at it before promotion](lab:level?l=L1.cells). Every variable is a `cell.new` there; [back at L1](lab:level?l=L1) only two are left.

## One cell, three functions

The frontend gives every variable a **cell** and the `promote-cells` pass turns the ones that no other function sees into SSA values. Here 5 cells are promoted (the trace in [Events](lab:show?view=events) counts them) and two survive in `makeCounter`: `c_count3` for `count` and `c_start2` for `start`. Each closure receives the cells it captures as leading parameters, which the closure operation lists:

```text
f6 = js.closure(@inc, c_count3)
f7 = js.closure(@dec, c_count3)
f8 = js.closure(@reset, c_count3, c_start2)
```

[Select the closure for reset](lab:node?id=makeCounter/entry/9): it captures both cells, because `reset` writes `count` and reads `start`. `start` is a parameter, yet it still needs a cell, because promotion is about who can see a variable, not about how it was declared.

## Reading through a cell

[Show inc](lab:fn?name=inc). Its first parameter is the cell, and the body is four operations:

```text
fn inc(c_count: cell, this: any) -> any {
entry throws unwind:
  count1 = cell.load_checked(c_count)
  v2 = js.add(count1, 1)
  cell.store(c_count, v2)
  count3 = cell.load_checked(c_count)
  return count3
}
```

The loads are `cell.load_checked`, not `cell.load`: `count` is a `let`, and `inc` cannot know whether `makeCounter` has run its declaration yet, so every read checks for the temporal dead zone. In `reset` the read of `start` is a plain `cell.load`, because a parameter is initialised before the body runs. [Compare the two in reset](lab:node?id=reset/entry/0).

> **Try it.** [Select the js.add in inc](lab:node?id=inc/entry/1). Its contract is `callsUser` with `mayCollect`: `count` could hold an object whose `valueOf` runs, so this addition is a safepoint, and the [plan](lab:show?view=plan) keeps `c_count` and `count1` in two root slots for a 40 B frame.

## What the counters cost

Each counter is one object with three function properties and two cells. The cells are made by `cell.new` inside `makeCounter`, so every call makes fresh ones: `a` and `b` share no state, which is why `b` counts down from 100 while `a` counts up from 0. Under [plan mode with GC stress](lab:run?mode=plan&gc=stress) the collector runs 42 times in the 81 steps of the run and moves the cells each time; the output stays `a 4, b 98`. `reset` has no safepoint at all, so its plan needs no root slots and its frame is the 24 B of the two fixed slots and the argument slot.

## What the optimiser may not do

`inc` stores and then immediately reloads `count`. Forwarding the stored value to the reload looks safe, and for a plain `cell.load` the standard rewrite `forward-store-to-load` does it. It does not touch `cell.load_checked`, which also checks for the dead zone, so the reload stays. In `makeCounter` the standard set does forward `cell.new(start)` to the load right after it.

> **Exercise.** In `main.js`, compile with `g.pipeline().rewrites(g.rewrites.standard())` and compare `makeCounter` and `inc` at L1. Then change `let count` to `var count` in `program.js`: which loads change kind, and why?

## Where next

[Chapter 4](lab:book?ch=4) builds SSA from source and explains which cells survive. [I-08](lab:preset?id=I-08) isolates captured variables, and [J-02](lab:preset?id=J-02) puts closures behind getters and setters.
