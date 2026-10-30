# Unwinding with setjmp

`risky(o)` makes a box, then reads `o.x` inside `try`. The first call reads a plain property and returns `2`; the second call's `x` is a getter that throws, so control leaves the getter, leaves the runtime helper that called it, and arrives in `risky`'s `catch`, which prints `caught no x 1` and returns `-1`. This preset is about the second path: how an exception raised deep inside a helper finds the handler in compiled code, and what has to be true of the frame when it gets there.

> **Try it.** [Show risky at L3](lab:level?l=L3) and read the last line of the listing, the unwind plan. Then [select the protected block](lab:node?id=risky/try3) and [turn on exceptional edges](lab:overlay?name=exceptional&on=1).

## The protected region in core IR

The frontend puts the body of `try` in its own block and gives the block an exceptional exit:

```text
try3() throws to catch1:
  x7 = js.get(o, "x")
  v9 = js.get(o4, "v")
  v10 = js.add(x7, v9)
  return v10
```

Any operation in `try3` that throws sends control to `catch1`, which receives the thrown value as its parameter `e5`. A block-level exit is cheaper to write down than one `invoke` per operation, and it is what the Hermes protocol implements: one region, one handler.

## The setjmp protocol

Hermes's helpers report an exception by `longjmp`, so a function that catches must have called `setjmp` first. The workbench's plan records the strategy for every protected region, and its LLVM text follows the same shape: one jump buffer per function, a `try_state` variable saying which region is current, and a dispatch that goes to that region's handler.

```text
; unwind risky/try3 → catch1: setjmp, restores root chain, managed frame
```

On entry, `risky` calls `shllvm_try_begin` and `_setjmp`. On the first return the status is zero and execution starts at `entry`. Entering `try3` stores `1` into `try_state`. When the getter throws, `shllvm_get` does not return: the runtime long-jumps to the buffer, `_setjmp` returns again with a nonzero status, the dispatch loads `try_state`, finds `1` and goes to `h.catch1`, which fetches the exception into a slot and branches to `catch1`. [W-06](lab:preset?id=W-06) reads that LLVM text line by line.

## What survives the jump

A `longjmp` restores the registers saved by `setjmp`, not the ones in use when the exception was raised. Anything the handler needs must therefore be in memory: `try_state` is a `volatile` stack variable, and every value the handler reads is in a root slot, which is frame memory the collector also updates. That is why `box` gets a slot. Liveness follows the exceptional edge from `try3` to `catch1`, and `catch1` reads `o4`, so `o4` is live across the `js.get` that may throw:

```text
  x7 = js.get(o, "x")                        ; safepoint · rooted s0=o s1=o4
```

> **Try it.** [Select that js.get](lab:node?id=risky/try3/0) with the [live overlay](lab:overlay?name=live&on=1) on: `o4` is in its live-across set only because of the handler.

The plan also says what the catch must restore besides values. The **root chain** is the runtime's list of frames whose slots it scans; frames of the helpers and of the getter that the jump skipped must be unlinked. The **managed frame** is `risky`'s own register frame in the runtime. With the `arena` strategy there is a third item, the **arena mark**: slots taken from the arena by skipped frames must be given back. The [Experiments view](lab:show?view=experiments) lists both plans; under GC stress both print `2 / caught no x 1 / -1`.

## Where the throw came from

The [Events view](lab:show?view=events) shows the two sides of the jump at the same step: a `throw` at `get_x/entry/term`, inside the getter, and a `catch` at `risky/try3/0`, the `js.get` whose helper called the getter. The getter is its own compiled function with its own frame, and nothing in it knows about `risky`'s handler. That separation is what the protocol buys: a function only pays for exceptions where it catches them.

> **Exercise.** Add `let step = 0;` before the `try`, set `step = 1;` as the first statement inside it, and print `step` in the `catch`. Rerun and look at `risky` at L1: `step` stays a cell (`c_step3`), although nothing captures it. Why can the promote-cells pass not turn it into a block parameter of `catch1` ([Chapter 5](lab:book?ch=5))?

## Where next

[Chapter 14](lab:book?ch=14) compares setjmp with status returns and landing pads; [L-09](lab:preset?id=L-09) shows strategy compatibility, and the shelf doc on [unwinding](lab:doc?id=unwinding) covers the mechanisms.
