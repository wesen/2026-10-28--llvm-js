# Narrowing by facts

The canonical rewrites leave every `js.*` operation general, because they do not use type facts. The **standard** set adds `narrow-by-facts`: for each operation that has variants, it reads the facts' operand types and, when they prove a variant's condition, replaces the operation by that variant. On the screen is the ledger, the book's running example, compiled with `g.rewrites.standard()`; the table compares every function with the canonical result.

> **Try it.** [Show the table](lab:show?view=experiments), then [look at total in L1](lab:fn?name=total) and [turn on the safepoints overlay](lab:overlay?name=safepoints&on=1). `next3` has no safepoints left.

## What narrowed

Three operations in the whole program, at three sites the decision log records:

- [total/next3/0](lab:node?id=total/next3/0): `js.mul(i3_1, 1)` became `num.mul(i3_1, 1)`. This is the `ToNumeric` step of `i++`.
- [total/next3/1](lab:node?id=total/next3/1): `js.add(n14, 1)` became `num.add(n14, 1)`.
- `main/endtry2/6`: `js.add(v23, " ")` became `str.concat(v23, " ")`, in the line that prints the name, balance and total.

The loop counter is the clear case. `i3_1` is a parameter of the loop head `for1`, and its two incoming values are the literal `0` from `entry` and `v15` from `next3`. The facts begin with `0: int32`; `num.add` of numbers is a number; the join of `int32` and `number` is `number`. So the facts prove `i3_1: number` on every turn, both operations in `next3` have numeric operands, and both narrow. In `main`, `v23` is the result of `ledger.name + …`, and `+` with a string literal on one side is a string, so the next `+ " "` has two strings.

## What did not

[The js.add in body2](lab:node?id=total/body2/2), `sum2_1 + v11`, stays general. `v11` is `log[i]`, a `js.get`, and the facts do not know what an array element is. Since `v11` might be an object, the sum might be a string, so `sum2_1` is `number|string` and the loop's `js.lt(i3_1, length6)` stays general too (`length6` comes from `js.get(log5, "length")`). Nothing in `deposit` narrows either: `balance` lives in a cell, and the facts do not follow values through cells.

## What it buys

[Open the Plan view](lab:show?view=plan). `total` drops from 6 safepoints to 4: `num.mul` and `num.add` have no obligations, so they cannot collect and need no roots around them. In L2 they bind to the inline instructions `fmul` and `fadd` instead of calls to `shllvm_binary`. The root slots stay at 3, because the values live across the remaining safepoints (`c_log`, `sum2_1` and one temporary) are the same as before.

The standard set also includes `forward-store-to-load`, which replaced one `cell.load` in `main` with the value just stored to the cell (decision at `main/entry/4`); that is the one-step difference in the run, 133 steps against 134.

> **Try it.** [Run in plan mode with GC stress](lab:run?mode=plan&gc=stress). Output and outcome are unchanged: `rejected: amount must be a number`, `main 42 42`, `audit 42`. Narrowing is a refinement; [the law](lab:preset?id=T-02) for it is `g.law.refines(g.rewrites.narrow, …)`.

## Getting more

The facts stop at `js.get` and at cells. Two changes to the program would let more narrow: keeping the log's entries in a local array of known numbers, or guarding the sum with `typeof`. [C-06](lab:preset?id=C-06) shows narrowing under `typeof`, and [W-02](lab:preset?id=W-02) uses `.assume` to give parameters types, which is how a JIT uses profiled types.

> **Exercise.** Change `total` to `if (typeof log[i] === "number") sum = sum + log[i];`. Rerun and read the decisions. Does the `+` narrow? (The facts refine values, and `log[i]` is two different `js.get` results.) Rewrite it with `const x = log[i];` first and try again.

## Where next

[Chapter 10](lab:book?ch=10) has the rewrite, [Chapter 12](lab:book?ch=12) what the variants become after lowering. The doc [Type facts](lab:doc?id=type-facts) explains where facts come from; [B-01](lab:preset?id=B-01) is the same ledger with the canonical set.
