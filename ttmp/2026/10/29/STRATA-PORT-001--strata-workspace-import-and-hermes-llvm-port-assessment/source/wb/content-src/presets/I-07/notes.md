# Building SSA: promote-cells

`promote-cells` is the workbench's version of the classic **mem2reg** pass: it takes the cells the frontend made ([I-06](lab:preset?id=I-06)) and turns the ones no other function can see into SSA values, with block parameters where several values meet. It follows the algorithm of Cytron, Ferrante, Rosen, Wegman and Zadeck (1991), with block parameters in place of phi nodes. This preset runs it on a loop with an `if` inside and shows each of its three steps.

> **Try it.** [Show classify at L1.cells](lab:level?l=L1.cells) and then [at L1](lab:level?l=L1). Seven cells disappear, the loop header becomes [for1(pos3_2, other4_2, last5_2, i7_1)](lab:node?id=classify/for1), and the merge after the `if` becomes [endif6(pos3_1, other4_1, last5_1)](lab:node?id=classify/endif6).

## Step 1: which cells

A cell can be promoted when the only things that use it are `cell.load` and `cell.store` in the same function. A cell passed to `js.closure` is held by another function, which might read or write it at any call, so it stays ([I-08](lab:preset?id=I-08)). One more rule comes from exceptions: a cell created or stored inside a `try` stays a cell if any of its loads can run after the handler ([I-10](lab:preset?id=I-10)). Here no closure and no `try` are involved, so all seven cells of `classify` qualify, including `this` and the parameter `xs`.

## Step 2: where the parameters go

When a variable is stored in two places, a block reached from both must receive the value through a parameter. Those blocks are found with **dominance frontiers** ([I-05](lab:preset?id=I-05)): a parameter goes at the frontier of every block that stores the variable, and since the parameter is itself a new definition, at the frontier of that block too, until nothing new is added. The table in [Experiments](lab:show?view=experiments) is that computation, done in main.js by hand:

| cell | stored in | parameters at |
|---|---|---|
| `c_pos3` | `entry`, `then5` | `endif6`, `for1` |
| `c_other4` | `entry`, `else7` | `endif6`, `for1` |
| `c_last5` | `entry`, `then5`, `else7` | `endif6`, `for1` |
| `c_touched6` | `entry`, `then5` | `endif6`, `for1` |
| `c_i7` | `entry`, `next3` | `for1` |
| `c_this1`, `c_xs2` | `entry` | none |

That is 9 parameters, and the pass reports `placed 9 parameters` in [Events](lab:show?view=events). `i` gets none at `endif6`, because neither arm of the `if` stores it.

## Step 3: renaming

The pass then walks the **dominator tree** from the entry, carrying the current value of every cell. A `cell.store` changes the current value and is deleted; a `cell.load` is deleted and every use of its result is replaced by the current value; at a block with placed parameters the parameters become the current values; and each edge out of a block gets the current values appended as arguments for the target's new parameters. In `then5`:

```text
then5() throws unwind:
  v17 = js.add(pos3_2, 1)
  jump endif6(v17, other4_2, "positive")
```

The load of `pos` became `pos3_2` (the value at the loop header), the store of `pos + 1` made `v17` current, and the edge passes `v17`, the unchanged `other4_2`, and the literal stored to `last`.

## Step 4: dead parameters

`touched` is written in the loop and never read. Its two parameters were placed anyway, because placement looks only at stores. A last sweep marks a parameter live when an operation uses it, or when it flows along an edge into a live parameter, and removes the rest with their edge arguments. Here that removes 2, leaving the 7 the Stage shows. This is the difference between minimal SSA and **pruned SSA**: same meaning, fewer values to keep alive.

> **Try it.** [Turn on the live overlay](lab:overlay?name=live&on=1) at L1 and select [the js.add in then5](lab:node?id=classify/then5/0): live across it are the values the rest of the loop still needs, and `touched` is not among them.

> **Exercise.** Print `touched` at the end of `classify` and rerun. How many parameters are removed now? Then move `last = "positive"` out of the `if`, to just before it, and predict the new row for `c_last5` before you look.

## Where next

[Chapter 4](lab:book?ch=4) explains promotion in full and proves why the frontier is the right place. [I-08](lab:preset?id=I-08) shows what keeps a cell from being promoted.
