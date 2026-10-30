# try/catch in LLVM

`readBoth(a, b)` reads `a.value` and `b.value`, each inside its own `try`, and returns both joined with `/`. With a good `a` and a throwing getter on `b` it prints `b failed: no value` and returns `x/none`; with the arguments swapped, the other handler runs. This preset reads the LLVM text that makes those two handlers work under the setjmp protocol, including the stores that tell a long jump which region it came from.

> **Try it.** [Show readBoth as LLVM](lab:level?l=LLVM) and search it for `try_state`. The [Events view](lab:show?view=events) has every line of the protocol that `main.js` picks out.

## One buffer per function

A function with any protected region saves a jump buffer once, in its prologue:

```llvm
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %buffer = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %status = call i32 @_setjmp(ptr %buffer) returns_twice
  %exceptional = icmp ne i32 %status, 0
  br i1 %exceptional, label %catch.dispatch, label %b.entry
```

`_setjmp` returns twice: once now, with status 0, and once more each time a helper raises an exception and the runtime long-jumps to the buffer, with a nonzero status. `returns_twice` tells LLVM so, which keeps it from caching values in registers across the call. The cost of a protected region is paid once on entry to the function, not on every call inside it.

## A state per region

Each protected block starts by recording which region it is:

```llvm
b.try3:
  store volatile i32 1, ptr %try_state, align 4    ; protected: a throw goes to catch1
```

and `try6` stores `2`. After a long jump, the dispatch reads the state and goes to that region's handler, which first fetches the exception from the runtime into a root slot:

```llvm
catch.dispatch:
  %state = load volatile i32, ptr %try_state, align 4
  switch i32 %state, label %catch.rethrow [
    i32 1, label %h.catch1
    i32 2, label %h.catch4
  ]
```

State 0, or any state without a handler, goes to `catch.rethrow`, which passes the exception on to the caller. `try_state` must be `volatile`: the store in `b.try3` happens before the call that throws, and the load in `catch.dispatch` happens after the long jump, so LLVM must not keep it in a register or drop the store as dead.

> **Try it.** [Select the protected block try3](lab:node?id=readBoth/try3) on the Stage with [exceptional edges](lab:overlay?name=exceptional&on=1) on, and compare its dashed edge to `catch1` with the `switch` entry for state 1.

## What survives the jump

The handlers read the exception (`e6`, `e13`) and, after the second region, the two cells `c_first4` and `c_second5`. All of these live in root slots (`s0`, `s2`, `s3`), which are frame memory, so the long jump leaves them intact. `first` and `second` stay cells for the same reason: they are assigned inside a protected region and read after it, and a block-level exceptional exit cannot pass a value that changes in the middle of the block ([Chapter 5](lab:book?ch=5)).

## Leaving a region

Every block of `readBoth` states its region, not only the protected ones. `endtry2`, the block after the first `try`, and `catch1`, the handler itself, both start with

```llvm
  store volatile i32 0, ptr %try_state, align 4    ; not protected: a throw unwinds to the caller
```

and so do `catch4` and `endtry5`. Without that store the state would still be `1` after the first region: if an operation in `catch1` threw (if `e.message` were a getter that throws), the dispatch would send the exception back to `catch1` instead of out of the function. State `0` has no case in the `switch`, so it goes to `catch.rethrow`. The run in the page does not depend on any of this, because the specification and plan mode execute the IR, not this text; the structural checker cannot see it either, because a text without these stores is just as well formed ([W-07](lab:preset?id=W-07) deletes one and shows that).

> **Try it.** [Select catch1](lab:node?id=readBoth/catch1) and find its block at [the LLVM level](lab:level?l=LLVM): the first line after the label is the store of `0`.

> **Exercise.** Decide what `catch1` should store if it contained a nested `try` of its own, and which blocks of that nested region would store which numbers. Then check your answer: add a nested `try` to `catch1` in `program.js`, [rebuild](lab:build) and read the stores.

## Where next

[Chapter 16](lab:book?ch=16) reads the protocol in context and [Chapter 14](lab:book?ch=14) compares it with status returns and landing pads. [L-08](lab:preset?id=L-08) covers the plan side and the shelf doc on [unwinding](lab:doc?id=unwinding) the mechanisms.
