# Liveness, one step at a time

A value is **live** at a point if some path from that point uses it before anything redefines it. Liveness is what decides which values need registers or root slots, and it is the first analysis most compilers run. On the screen is the ledger's `total` loop on its own. `main.js` returns the solver's record of every block it visited while computing liveness, eight visits in all, and the Facts view and the Stage can replay them one at a time.

> **Try it.** [Turn on the live overlay](lab:overlay?name=live&on=1), then [show step 3](lab:analysis?name=liveness&i=3) and [step 6](lab:analysis?name=liveness&i=6). The Stage marks the block being visited and the sets before and after it.

## The equations

For a block `b`, let `use(b)` be the values it reads before defining them and `def(b)` the values it defines (its parameters and its operations' results). Then

$$\mathrm{in}(b) = \mathrm{use}(b) \cup (\mathrm{out}(b) \setminus \mathrm{def}(b)), \qquad \mathrm{out}(b) = \bigcup_{s \in \mathrm{succ}(b)} \sigma_{b \to s}(\mathrm{in}(s)).$$

The second equation is where block parameters enter. `σ` substitutes along the edge: if a parameter of `s` is live, the argument `b` passes for it is live at the end of `b`, and the parameter itself is not (it does not exist in `b`). This is the engine's edge rule, `g.edge.substituteBlockArgs()`. Facts flow backward, from uses to definitions, so liveness is a **backward** analysis.

## The loop

```text
for1(sum3_1: any, i4_1: any) throws unwind:
  length7 = js.get(log, "length")
  v8 = js.lt(i4_1, length7)
  branch v8, body2(), endfor4()
...
next3() throws unwind:
  n15 = js.mul(i4_1, 1)
  v16 = js.add(n15, 1)
  jump for1(v13, v16)
```

The loop carries `sum` and `i` as the parameters `sum3_1` and `i4_1` of `for1`; `next3` passes `v13` (the new sum) and `v16` (the new index) back along the edge.

## Visit by visit

[Show the table](lab:show?view=experiments). The solver starts every block at `∅`, the bottom of the powerset lattice, and visits them from a worklist in reverse order:

1. `endfor4` returns `sum3_1`, so its in-set is `sum3_1`.
2. `next3` sees `for1` still at `∅`, so its out-set is empty and its in-set is `i4_1` (read by `js.mul`).
3. `body2` reads `log`, `i4_1` and `sum3_1`; `i4_1` is also live out.
4. `for1` gets the union over its two successors and adds `log`, which `js.get` reads. Its in-set is `i4_1, log, sum3_1`. Because it changed, its predecessors `entry` and `next3` go back on the worklist.
5. `entry` passes no live parameters: only `log` is live.
6. `next3` again: the in-set of `for1` now contains its parameters, and substitution turns `sum3_1, i4_1` into the arguments `v13, v16`. Out is `log, v13, v16`; in is `i4_1, log, v13`.
7. `body2` is revisited and does not change its in-set.
8. `for1` is revisited and nothing changes: the fixed point.

> **Try it.** [Select the js.add in body2](lab:node?id=total/body2/1). The Inspector lists the values live across it: `i4_1` and `log`. `sum3_1` is used by the operation but dies there, and `v13` is born there.

## Why it terminates

Every step only adds to sets drawn from a finite universe (the function's values), and the transfer function is monotone: a larger out-set never gives a smaller in-set. So each block's sets can grow only finitely often, and the worklist empties. Eight visits for five blocks is typical: one pass to propagate uses, one more around the back edge. [Chapter 8](lab:book?ch=8) proves the general theorem.

## What liveness is used for

The engine uses the per-operation version, `facts(fn).live.across`, to find what each safepoint must root. [A-08](lab:preset?id=A-08) follows those sets into the root plan, and [L-03](lab:preset?id=L-03) compares strategies that use them.

> **Exercise.** Add `const count = log.length;` before the loop and use `count` in the condition instead of `log.length`. Rerun: how many visits does the solver need now, and which value joins the in-set of `for1`?

## Where next

[Chapter 9](lab:book?ch=9) covers liveness, safepoints and types together; the doc [Liveness](lab:doc?id=liveness) is the reference. [A-01](lab:preset?id=A-01) has the powerset lattice, [A-07](lab:preset?id=A-07) checks the monotonicity the proof relies on.
