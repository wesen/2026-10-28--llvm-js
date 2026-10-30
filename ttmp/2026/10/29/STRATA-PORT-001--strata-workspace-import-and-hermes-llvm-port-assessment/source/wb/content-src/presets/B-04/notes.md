# Reading the Stage

The Stage draws one function as a technical drawing: each block a box, each edge a line, and whatever the analyses and the last run found as overlays in one hue each. This preset gives it a function with everything at once: a loop, a `try` inside it, a throw, a variable that has to stay a cell, and a run under GC stress. [Open program.js](lab:open?file=program.js&line=2) beside it; `tally([1, 2, "x", 4])` prints `entry 2 is not a number` and `7`.

> **Try it.** [Show tally on the Stage](lab:fn?name=tally), [turn on the path overlay](lab:overlay?name=path&on=1) and [run it in plan mode with GC stress](lab:run?mode=plan&gc=stress). The blocks the run went through are marked with their visit counts; `then8` was visited once, for the `"x"`.

## Boxes are blocks

A box is a **block**: a header line with the block's name and parameters, one line per operation, and a last line for the terminator. `for1(i4_1)` is the loop header; its one parameter is the loop counter `i`, passed in by `jump for1(0)` from `entry` and by `jump for1(v29)` from `next3`. Blocks are numbered in the order the frontend made them, so `try7` comes after `endfor4` in the text even though it runs first: the drawing lays blocks out by the edges, not by the text order.

[Select the loop header](lab:node?id=tally/for1) and the Inspector on the right lists its parameters and what is live on entry.

## Lines are edges

A solid line is a normal edge: `jump`, or the `true` and `false` arms of a `branch`, labelled with the arguments they pass. The back edge from `next3` to `for1` routes around the left of the sheet so it never crosses the loop body.

A dashed line is an **exceptional edge**. `try7`, `then8` and `endif9` are headed `throws to catch5`: any operation in them that throws goes to `catch5`, which receives the thrown value as its parameter `e9`. [Turn on the exceptional overlay](lab:overlay?name=exceptional&on=1) to draw those three edges in teal. `next3`, outside the `try`, is headed `throws unwind`: a throw there leaves the function.

## Overlays are facts

Each overlay reads one result of the compiler and draws it in its own hue:

| overlay | shows | from |
|---|---|---|
| live | values live across each operation, live-in on headers | liveness |
| safepoints | operations that may collect, marked `gc` | contracts |
| types | the type fact of each value | type facts |
| roots | the root slot of each value at each safepoint | the L3 plan |
| path | blocks and edges of the last run, with visits | the run |
| exceptional | throw edges in teal | the IR |
| stale | missing roots and stale uses | the plan and the run |
| iteration | one step of the fixed-point solver | the solver |

> **Try it.** [Turn on live](lab:overlay?name=live&on=1) and [roots](lab:overlay?name=roots&on=1), then [select js.add in endif9](lab:node?id=tally/endif9/2). Live across it are `c_sum3`, `i4_1` and `items`; the plan roots `items` in slot 0, `c_sum3` in slot 1, `sum19` in slot 2 and `v22` in slot 3. `i4_1` gets no slot: it is a number, and numbers are not heap references.

## Why sum is still a cell

`sum` is stored inside the protected region (`endif9`) and read after the handler (`endfor4`). A handler sees the variable's value at the operation that threw, and a block-level exceptional exit can only pass values from the head of its block, so `promote-cells` leaves `sum` as the cell `c_sum3`. `i` is never stored inside the `try` and becomes the block parameter `i4_1`. [Chapter 5](lab:book?ch=5) explains the rule.

## The Inspector and the title block

Clicking an operation fills the Inspector with its contract, its six permissions with the reasons they are refused, the facts at that point and its root slot. [Select js.get in try7](lab:node?id=tally/try7/0): `callsUser`, so a getter may run, and nothing may erase, merge, move, duplicate, hoist or speculate it. The title block in the bottom right of the sheet records the function, the level, the overlays shown and the last run, so a screenshot of the Stage says what it is a drawing of.

> **Exercise.** Move `sum = sum + items[i];` out of the `try` (after the `catch`) and rerun. Does `c_sum3` disappear? Turn on types and say which values are numbers now.

## Where next

[Chapter 1](lab:book?ch=1) reads the running example on the Stage. [I-09](lab:preset?id=I-09) builds exceptional edges by hand, and [A-02](lab:preset?id=A-02) uses the iteration overlay to watch liveness converge.
