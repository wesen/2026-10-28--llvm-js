# The 1,024-slot frame

The Hermes LLVM backend gives each compiled function one frame of 64-bit slots on the native stack and refuses a function whose frame would exceed 1,024 slots. The workbench's plan checker applies the same limit. This preset builds a function that needs many slots, measures how its frame grows, and shows the limit check as a value you can tighten. `program.js` is the smallest case, `wide(8)`, written out; `main.js` generates larger ones from the same template.

> **Try it.** [Show wide's plan at L3](lab:level?l=L3) and read the header: 8 root slots + 2 fixed + 1 argument = 11 slots, 88 B. Then open the [Experiments view](lab:show?view=experiments) for the larger sizes.

## Why nothing can share a slot here

`wide(n)` makes `n` objects and only afterwards reads one property from each. Every object is created at a safepoint (`obj.new` may collect) and every later object creation is another safepoint, so the first object is live across all of them, the second across all but one, and so on. At the moment the last object is created, all `n` are needed at once:

```text
  o18 = obj.new()                            ; safepoint · rooted s0=o11 s1=o12 s2=o13 s3=o14 s4=o15 s5=o16 s6=o17
```

Values required at the same safepoint conflict, and `stackReuse` can only share slots between values that never conflict. So the plan needs at least `n` root slots, and `stackReuse` finds exactly `n`. The slots it does share are the short-lived ones: [slot 0](lab:node?id=wide/entry/16) holds `o11` until its property is read, then the property values and partial sums in turn.

## How the frame grows

A frame on the native stack is the root slots, two fixed slots (scratch and discard) and room for the largest outgoing call's arguments (one here). Measured with `main.js`:

| n | root slots | frame slots | frame bytes | under 1,024 | compile ms |
|---|---|---|---|---|---|
| 8 | 8 | 11 | 88 | yes | 26 |
| 32 | 32 | 35 | 280 | yes | 19 |
| 64 | 64 | 67 | 536 | yes | 39 |
| 128 | 128 | 131 | 1,048 | yes | 102 |

(Compile times are from one run in Node and vary.) The frame is exactly $n + 3$ slots, so the limit is reached at $n = 1{,}021$ and exceeded at $n = 1{,}022$. The preset stops at 128 to keep `main.js` quick, but the real limit is cheap enough to check directly. In a scratch run in Node, `wide(1021)` compiled in about 2.2 s to a frame of 1,021 + 2 + 1 = 1,024 slots and was admitted, and `wide(1022)` got 1,025 slots and the error `wide exceeds the 1024-slot native frame limit (1022 roots + 2 fixed + 1 arguments = 1025 slots, strategy stackReuse)`. About 1.1 s of that is the root planner and 0.7 s the promotion of cells.

Real code reaches the limit without anything this artificial. A large module factory compiled without optimisation keeps every top-level binding of the module live across every call in it; in the investigation this workbench grew out of, fflate's factory at O0 needed 1,084 slots before its arguments.

## The limit as a value

`g.limit(name, { measure, max })` makes a check you can run on any program:

```js
const small = g.limit('frame of at most 64 slots', { measure: p => slots(p.plan('wide').frameSlots), max: slots(64) });
```

`main.js` runs it on `wide(32)` and `wide(64)` and prints the results to the [Events view](lab:show?view=events): 35 slots pass, 67 slots fail, and the check converts slots to bytes through the 64-bit layout (536 B against 512 B). The plan checker's own limit is the same check with `max: slots(1024)`, applied to every function as an admission error.

> **Try it.** [Open main.js](lab:open?file=main.js&find=slots(64)) and change the maximum to `slots(32)`. Rerun: now both sizes fail.

## Ways out

There are three, and the workbench has the first two. An **arena** strategy takes root slots from runtime-owned memory instead of the native stack, so the limit becomes an arena budget (4 MiB by default); `wide(8)` under `arena` needs 224 B of arena. **Packing** helps only where values do not conflict, which is exactly what `wide` prevents. The third is to change the code: an optimiser that keeps fewer bindings alive across calls, or a frontend that splits a huge function.

> **Exercise.** Change the template in `main.js` so each object is read immediately after it is created (`sum = sum + oK.i` right after `const oK`). Predict the root slots for `n = 128`, then measure. Why does `distinct` not benefit?

## Where next

[Chapter 13](lab:book?ch=13) explains the frame and the limit. [L-03](lab:preset?id=L-03) compares strategies on the ledger, and the shelf doc on the [Hermes LLVM backend](lab:doc?id=hermes-llvm) shows the frame in LLVM IR.
