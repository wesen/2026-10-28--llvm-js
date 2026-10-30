# Coercion runs user code

In JavaScript, `price + 2` may call a function. When an operand of `+`, `<` or `*` is an object, the operator converts it to a primitive by calling the object's `valueOf` (and, if that does not give a primitive, its `toString`), and those are ordinary methods the program can define. This preset defines them, prints from inside them, and lets one throw. It is the reason most `js.*` operators in the workbench have the behaviour `callsUser`.

> **Try it.** [Run it](lab:build) and read the output: `valueOf ran` appears before `42` and again before `true`, and the program counts 2 calls. Then [select the js.add](lab:node?id=main/entry/8) on the Stage and read its contract in the Inspector.

## Steps inside an operator

[Show the Machine view at step 9](lab:step?n=9). Step 9 is at depth 2, inside `valueOf`: `js.add(o6, 2)` in `main` (at depth 1) is still running and has called the method. Steps 9 to 13 are the method's body: it loads `calls`, adds 1, stores it, prints `valueOf ran` and returns 40. Only then, at step 14, does the `js.add` in `main` finish, with the value 42. The comparison `price < 50` does it all again (steps 16 to 21), and `"item: " + label` calls `toString` (step 23), because `label` has no `valueOf` of its own.

| step | depth | operation | value |
|---|---|---|---|
| 10 | 2 | `valueOf/entry/1` `js.add(calls2, 1)` | 1 |
| 13 | 2 | `valueOf/entry/term` `return 40` | 40 |
| 14 | 1 | `main/entry/8` `js.add(o6, 2)` | 42 |
| 21 | 1 | `main/entry/10` `js.lt(o6, 50)` | true |
| 24 | 1 | `main/entry/12` `js.add("item: ", o8)` | "item: tag" |

## The contract says so

The table in [Experiments](lab:show?view=experiments) is `g.contract.table` for the operators this program uses:

| op | behaviour | obligations | permissions |
|---|---|---|---|
| `js.add` | callsUser | mayCollect, nonlocalThrow | none |
| `js.lt` | callsUser | mayCollect, nonlocalThrow | none |
| `js.mul` | callsUser | mayCollect, nonlocalThrow | none |
| `num.add` | none | none | all six |

`callsUser` means the operation may run any function, so it may read and write the heap, cells, jobs, timers and globals, throw, loop forever and print. Every permission a rewrite might want (erase, merge, move, duplicate, hoist, speculate) is refused, each with those reasons. [Select js.lt](lab:node?id=main/entry/10) to read them.

## What the compiler must not do

Three things follow, and this program shows each:

1. **Not erase** an operator whose result is unused: it may still print. Delete `print(` around `price + 2` and the line `valueOf ran` must still appear.
2. **Not reuse a load across it.** After the operators, `main` reads `calls` again with [cell.load(c_calls2)](lab:node?id=main/entry/14); it cannot reuse the 0 it stored at the start, because `valueOf` changed the cell.
3. **Not assume it returns.** `broken * 2` throws a RangeError out of `valueOf`, through `js.mul`, into the `catch` in `main`: [the multiplication](lab:node?id=main/try3/0) sits in a block headed `throws to catch1`.

## Narrowing is refused

The pipeline here uses the standard rewrites, which narrow `js.add` to `num.add` when both operands are known numbers. [Events](lab:show?view=events) lists every attempt and its reason: `operand types object, int32 select no variant` for `price + 2`. Narrowing is the way an operator earns its permissions back, and it needs facts this program does not have. [T-04](lab:preset?id=T-04) shows it succeed.

> **Exercise.** Give `label` a `valueOf` that returns 7 and rerun. Which method does `"item: " + label` call now, and what does it print? Then explain why `js.add` cannot know in advance which of the two methods it will call.

## Where next

[Chapter 2](lab:book?ch=2) treats coercion as part of the meaning of `+`, and [Chapter 6](lab:book?ch=6) turns it into the `callsUser` behaviour. [C-04](lab:preset?id=C-04) follows a throwing getter through the whole pipeline.
