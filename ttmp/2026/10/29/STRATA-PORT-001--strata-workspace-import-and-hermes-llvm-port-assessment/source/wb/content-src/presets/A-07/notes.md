# Monotone or not

The solver's guarantee (it stops, and what it finds is the least fixed point) rests on one property of the transfer function: **monotonicity**. If `x ⊑ y` then `f(x) ⊑ f(y)`: knowing more going in never means claiming less coming out. This preset writes liveness twice as a custom backward analysis, once honestly and once with a "register budget" that forgets everything when more than two values are live, checks both with `g.law.monotone`, and solves the ledger's `total` loop with each.

> **Try it.** [Show the Laws](lab:show?view=laws): the engine's liveness and the honest copy pass on 500 samples; `monotone(live-within-2)` fails on its 27th.

## Two transfer functions

The honest one is the textbook rule, written per operation and applied from the bottom of a block up: remove the operation's result, add its operands.

```js
.transfer((op, live) => { const s = new Set(live); if (op.result) s.delete(op.result); uses(op).forEach(a => s.add(a)); return s; });
```

The budgeted one does the same and then, if more than two values are live, returns the empty set. It models an allocator that gives up when it runs out of registers, and it is wrong as an analysis: a value does not stop being live because there are many of them.

## The counterexample

`g.law.monotone` generates small core IR functions, picks a block, draws a set `x` of values and a larger set `y ⊒ x`, and runs the block's transfer on both. For the budgeted analysis it found, in block `loop` of a generated function:

- `x = {b}` gives `f(x) = {b, i}`;
- `y = {acc1, b, v1, v2}` gives `f(y) = ∅`.

`x ⊑ y` but `f(x) ⋢ f(y)`. More values live after the block made fewer live before it.

## What the solver does with it

[Show the table](lab:show?view=experiments). The honest analysis reaches the same fixed point as the built-in one in 8 visits: `i4_1, log, sum3_1` live into the loop head. The budgeted one also stops after 8 visits, with only `log` live into the loop head. That answer is wrong: `sum3_1` and `i4_1` are used on the next turn. A root plan built from it would leave `sum3_1` unrooted across the loop's safepoints, and a moving collection would make it stale ([L-05](lab:preset?id=L-05) shows that failure).

The solver did not complain. It cannot: it checks only that the sets stopped changing. With a non-monotone function the worklist may stop at a wrong point, as here, or never stop at all, since a set can now shrink and grow again. For the second case the engine's solver takes a time budget (`{ budget: { n: 300 } }` in main.js, in milliseconds) and falls back to "every value live at every point", which is sound and useless. Neither the stop nor the fallback can tell you the transfer function is broken. The law can.

> **Try it.** [Open main.js](lab:open?file=main.js&find=s.size%20%3E%202) and change `2` to `10`. [Rerun](lab:build): the law still fails (any threshold does), though `total` now gets the right answer. A test on one program passes where a law on generated programs does not.

## Why monotone is enough

On a lattice of finite height, a monotone function iterated from `⊥` produces an increasing chain `⊥ ⊑ f(⊥) ⊑ f(f(⊥)) ⊑ …`, which must stop within the height. Where it stops is a fixed point, and it is below every other fixed point (Kleene's theorem; for dataflow, Kildall 1973). Monotonicity is what makes the chain increasing; without it there is no chain, and no theorem.

> **Exercise.** Write a transfer function that is monotone but unsound: for example, one that never adds the operands of `js.get`. Check that `g.law.monotone` passes it. What law would catch it? (Compare its answer with the built-in liveness on generated functions, or use a root plan from it and run with GC stress.)

## Where next

[Chapter 8](lab:book?ch=8) proves the theorem. [A-02](lab:preset?id=A-02) steps through the honest solve; [A-01](lab:preset?id=A-01) checks the lattice side of the bargain. The doc [Liveness](lab:doc?id=liveness) has the equations.
