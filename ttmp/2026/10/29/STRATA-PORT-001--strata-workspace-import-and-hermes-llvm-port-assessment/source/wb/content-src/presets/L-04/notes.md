# A plan with a hole

This preset compiles a small program with the `none` root strategy, which assigns no root slots at all, and lets the plan checker say what is wrong. `pair(a, b)` makes an object, stores `a` and `b` into it and returns it; `main` makes two boxes, pairs them and prints `3`. With every default the program compiles and runs. With `none` it does not compile: the status pill shows 28 errors, one for each value a safepoint needs and does not get.

> **Try it.** [Show the Plan](lab:show?view=plan), [select pair on the Stage](lab:fn?name=pair) and [turn on the stale overlay](lab:overlay?name=stale&on=1): every safepoint is marked. The [Events view](lab:show?view=events) lists the 28 missing roots that `main.js` prints.

## What the checker checks

A **safepoint** is an operation that may run the collector. At each one the checker computes the values the plan must root there, and then looks for each of them in the plan's slots. A value is required when it is a possible heap reference (its type includes objects, functions, strings, cells or completions) and either

- it is **live across** the safepoint: some later operation still reads it, or
- it is **borrowed by** the safepoint: the helper itself reads it as an operand, after it may already have collected.

The plan is correct when every required value has a slot, and no two values required at the same safepoint share one. The checker does not care how the slots were chosen; it judges the result.

## Reading the missing list

`pair` has three safepoints:

```text
  o5 = obj.new()                             ; safepoint · rooted nothing · MISSING a, b
  js.define(o5, "first", a)                  ; safepoint · rooted nothing · MISSING a, b, o5
  js.put(o5, "second", b)                    ; safepoint · rooted nothing · MISSING b, o5
```

At `obj.new` the new object does not exist yet, but `a` and `b` are both needed later, so a collection during the allocation would leave both stale. At `js.define` the operation borrows `o5` and `a`, and `b` is still to come. At `js.put`, `a` has been stored and is no longer needed by this function; `b` and `o5` are. [Select the js.put](lab:node?id=pair/entry/2) to see its required set in the Inspector.

With the default strategy the same function gets three slots, one per value, because at `js.define` all three are needed at once:

```text
; frame: 3 root slots + 2 fixed + 1 argument = 6 slots, 48 B
;   s0: a
;   s1: b
;   s2: o5
```

> **Try it.** [Open main.js](lab:open?file=main.js&find=none), change `'none'` to `'stackReuse'` and [rerun](lab:build). The errors go, and `pair`'s plan shows the three slots above.

## Why the errors come before any run

A missing root is a property of the plan, not of a particular run. The collector might not run at that operation on a given input (here, with GC off, the program would even print the right answer), but a plan is admitted for all inputs, so the checker refuses it statically. [L-05](lab:preset?id=L-05) turns the check off and shows what a run then does under a stress collector.

> **Exercise.** Change `pair` so that it stores `b` first: `const p = { second: b }; p.first = a;`. Predict the new missing list for `pair` before rerunning. Which value changes from "borrowed by" to "live across" at the first `js.define`?

## Where next

[Chapter 13](lab:book?ch=13) states the rooting rule and the checker's invariant. [L-03](lab:preset?id=L-03) compares strategies that pass, [L-06](lab:preset?id=L-06) writes your own, and the shelf doc on [moving collectors and root slots](lab:doc?id=gc-roots) explains why borrowed operands count.
