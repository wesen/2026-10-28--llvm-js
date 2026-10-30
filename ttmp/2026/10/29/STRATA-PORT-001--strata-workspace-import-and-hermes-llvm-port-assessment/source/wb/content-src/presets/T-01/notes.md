# Folding and propagation

`program.js` computes a width, a height and an area from literals, branches on the area and prints. None of it depends on input, so a compiler can do all of the arithmetic before the program runs. The canonical rewrite set does exactly that: it folds operations on literals, simplifies the branch whose condition became a literal, removes the block nothing reaches, and erases results nobody uses. The table in Experiments compares the program with no rewrites and with the canonical set.

> **Try it.** [Show the table](lab:show?view=experiments): 14 operations become 5, four blocks become three, and the run takes 5 steps instead of 12, with the same output `large 544 / w32`. Then [look at main in L1](lab:fn?name=main).

## Before

With `g.rewrites.none()`, after `promote-cells` has turned the five variables into SSA values:

```text
entry throws unwind:
  v6 = js.mul(4, 8)
  v8 = js.div(v6, 2)
  v9 = js.add(v8, 1)
  v12 = js.mul(v6, v9)
  v14 = js.gt(v12, 500)
  branch v14, then1(), else3()
```

Every operation is a general `js.*` operation, which in principle may call `valueOf`. Here every operand is a literal or a value computed from literals.

## Constant folding

`const-fold` matches an operation whose operands are all literals and whose result can be computed without running user code: the pure `num.*` and `bool.*` operations, and the `js.*` arithmetic on primitive literals (a literal number or string has no `valueOf` of its own to call). It runs the operation's reference step at compile time, then replaces every use of the result with the literal. `v6 = js.mul(4, 8)` becomes 32, which makes `js.div(32, 2)` foldable, and so on: the rewrites run to a fixed point, so one fold enables the next. [Events](lab:show?view=events) lists seven `const-fold` decisions, each with the reason "primitive literal operands: no user code can run". The string concatenations fold too: `"w" + 32` is `"w32"`.

## Branches and unreachable blocks

After folding, `v14` is the literal `true` and the branch reads `branch true, then1(), else3()`. `simplify-branch` turns it into `jump then1()`, recording "condition is the literal true; always goes to then1". Now nothing jumps to `else3`, and `remove-unreachable` deletes it ("no path from entry"). What is left:

```text
entry throws unwind:
  jump then1()
then1() throws unwind:
  host.print("large 544")
  jump endif2()
endif2() throws unwind:
  host.print("w32")
  return undefined
```

The two prints stay: `host.print` talks to the host, and no permission lets a rewrite remove it.

> **Try it.** In program.js, change `500` to `600` and [rerun](lab:build). The branch now folds the other way, `then1` is removed instead, and the output is `small / w32`.

## Copy propagation and erasing

Two more rewrites are in the set. `copy-propagation` replaces the uses of `x = core.copy(y)` by `y`; the frontend emits copies rarely, so it fires nothing here. `erase-dead-result` removes operations whose results are unused when `perm.erase` allows it; folding already replaced every use of the arithmetic results, and the folded operations are removed as part of each fold.

## Order and fixed points

The pass runs the set in rounds until a round changes nothing (at most eight). Order matters within a round only for speed: folding before branch simplification means one round does both. Whether the final program depends on the order is a property worth checking; [T-08](lab:preset?id=T-08) checks that the canonical set is idempotent.

What the set does not do is merge `entry` into `then1`, although `entry` only jumps. Block merging is a separate rewrite the standard set lacks, which is why the result still has three blocks.

> **Exercise.** Move the computation into a function `function area(w) { const h = w / 2 + 1; return w * h; }` and call `area(32)`. Which folds still happen, and why does the call itself not fold? ([C-03](lab:preset?id=C-03) has the permissions of `js.call`.)

## Where next

[Chapter 10](lab:book?ch=10) covers these rewrites and the decision log. The doc [Rewriting with side conditions](lab:doc?id=rewriting) is the reference. [T-02](lab:preset?id=T-02) shows a rewrite that is wrong, [T-03](lab:preset?id=T-03) one you write yourself.
