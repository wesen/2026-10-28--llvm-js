# Constraints and feasibility

On the screen is a design with eight raw points of which only two are acceptable compilers, and the three different ways the other six are ruled out. The parameters are the root strategy (`stackReuse` or `none`), whether the GC-safety check runs (`true` or `false`), and the exception strategy (`setjmp` or `statusReturn`). The table in [Experiments](lab:show?view=experiments) has four rows, two of them infeasible, and the program on the Stage is the worst of them: compiled with no roots and the check switched off.

> **Try it.** [Run it in plan mode with GC stress](lab:run?mode=plan&gc=stress). The outcome pill turns to `error`: `f4 (object #9) was not rooted, so the collection at main/entry/2 freed it`. Then [run it with GC off](lab:run?mode=plan&gc=off): the same program prints the right three lines, which is why a missing root can hide.

## 1. Points that are never generated

`design.where(g.constraint.compatible())` keeps a point only if its pipeline passes `check()`. The four `statusReturn` points fail it, with the reason: `statusReturn` needs runtime helpers that report errors by returning a status, but the JavaScript operation sets are provided by Hermes, whose helpers throw nonlocally. Such a point is not a slow compiler or a wrong one; it is not a compiler at all, so the design removes it before anything is compiled. The Events view prints `raw 8 points, compatible 4`.

## 2. Points that are not admitted

`roots: 'none'` with the GC-safety check on does not compile. The plan checker finds 98 values that are live across a collecting operation with no root slot, and the first diagnostic names the first of them: `c_ledger3 is live across js.closure at main/entry/1 but no root assigned`. The row is marked `admitted: false` and its metrics are zero, because there is nothing to measure.

## 3. Points that are admitted and wrong

`roots: 'none'` with `checks({ gcSafety: false })` compiles: the missing roots become warnings. In plan mode with GC stress the collection at `main/entry/2` frees the closure `f4` that `main` is about to call, and the run stops at step 2 reading a freed address. The search compares this run with the specification, finds them different, and marks the row `correct: false`.

> **Try it.** [Select the call that fails](lab:node?id=main/entry/2) and [turn on the stale overlay](lab:overlay?name=stale&on=1).

## Feasibility is not a score

The objective is `g.objective.require('admitted', 'correct').then(g.objective.minimize('rootSlots'))`. Without the requirement, the broken point would win: zero root slots is the best number in the table. With it, infeasible points rank last whatever their numbers, and the best point is `roots=stackReuse gcSafety=true exceptions=setjmp` with 15 root slots. A compiler that is wrong is not a cheap compiler, so correctness belongs in feasibility, never in a weighted sum where enough savings could outvote it.

The two feasible rows are identical: switching the GC-safety check off does not change a correct plan. The check costs compile time and protects against exactly one kind of mistake, the kind in row 3.

> **Exercise.** Add `'distinct'` to the root strategies and rerun: how many points does the constrained design have, and which wins? Then declare the pair with `g.compat.declare(g.roots.stackReuse(), g.exceptions.statusReturn(), { evidence: 'none' })` before the design: why does the constraint still remove it?

## Where next

[Chapter 20](lab:book?ch=20) treats feasibility and search. [L-05](lab:preset?id=L-05) looks at the stale reference itself, and [L-09](lab:preset?id=L-09) explains why `statusReturn` needs other providers.
