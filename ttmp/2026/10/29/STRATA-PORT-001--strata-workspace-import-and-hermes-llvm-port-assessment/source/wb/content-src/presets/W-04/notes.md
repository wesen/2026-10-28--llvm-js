# LLVM IR in the Hermes shape

The IR view shows `deposit` from the ledger as LLVM IR text. The text has the shape of the code the Hermes LLVM backend emits: one LLVM function per JavaScript function, a frame of 64-bit slots obtained from the runtime, and a call to a runtime helper for every operation that is not plain arithmetic. The workbench prints it from the L3 plan and checks it structurally; it does not compile it, because LLVM is not in the page. Reading it is the last step of the pipeline: every name and number in it was decided earlier, and this preset traces each back to where it came from.

> **Try it.** [Show deposit as LLVM](lab:level?l=LLVM), and keep [its L3 plan](lab:show?view=plan) open beside it. The [Events view](lab:show?view=events) has one line per function with its frame size and the result of the structural check.

## The signature and the frame

```llvm
define internal i64 @deposit(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %size = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %size, align 16
  %argv = alloca [1 x i64], align 8
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 1, i32 0)
```

Every function takes one argument, `%shr`, the runtime, and returns a 64-bit tagged word. Its JavaScript arguments are not LLVM arguments: they arrive in the caller's outgoing area and are read with `shllvm_param`. The frame is stack memory (`alloca`) whose size the runtime computes from the slot count. The `6` is the plan's 4 root slots plus the 2 fixed slots; the `1` is room for one outgoing argument. `shllvm_enter` links the frame into the runtime's chain of frames, which is how the collector will find these slots.

## Root slots and registers

```llvm
  %s0 = getelementptr i64, ptr %roots, i32 0
  %scratch = getelementptr i64, ptr %roots, i32 4
  %discard = getelementptr i64, ptr %roots, i32 5
  %r.v9 = alloca i64, align 8                 ; v9: not rooted
```

`%s0` to `%s3` are the plan's root slots: `s0` holds `amount`, `s1` holds `balance7` and later `log11`, `s2` holds `c_balance`, `s3` holds `c_log`, then `log12`, then `length13`, exactly as the L3 header lists. `%scratch` and `%discard` are the two fixed slots: scratch receives a literal operand just before a helper reads it, discard receives results nobody uses (and a second literal of the same operation). An operation with three or more literal operands, such as `print(1, 2, 3)`, writes the rest to stack temporaries `%lit2`, `%lit3`…, allocated in the prologue. Values that need no root (`v9`, the sum, is stored straight into the cell) get a plain stack word, `%r.v9`, which the collector does not see.

> **Try it.** [Select the js.add](lab:node?id=deposit/endif2/1) and find its call: `shllvm_binary(ptr %r.v9, ptr %shr, i32 0, ptr %s1, ptr %s0)`. The result goes to an unrooted word; the two operands, `balance7` and `amount`, are read from root slots because the helper may collect before it reads them.

## Helpers with an out pointer

Every helper writes its result through its first argument and takes the runtime second. `js.get(log12, "length")` becomes:

```llvm
  call void @shllvm_constant(ptr %scratch, ptr %shr, i32 11)          ; "length"
  call void @shllvm_get(ptr %s3, ptr %shr, ptr %s3, ptr %scratch)      ; may collect
```

The string `"length"` is entry 11 of the module's string table, printed at the top of the text. Results and operands are pointers to slots, never values in registers, so a moving collection inside the helper updates them in place. The same slot can be operand and result (`%s3` here), because the plan gave `log12` and `length13` the same slot.

## Control flow and the throw

`branch v5, then1(), endif2()` becomes a call to `shllvm_truthy` (JavaScript truthiness of a tagged word) and an LLVM `br`. The throw is a helper that does not return:

```llvm
  call void @shllvm_throw(ptr %shr, ptr %r.err6)
  unreachable
```

`deposit` has no `try`, so it needs no `setjmp`: the exception leaves through the runtime to whichever caller saved a jump buffer, here `main`.

> **Exercise.** Find `main` in the [LLVM view](lab:level?l=LLVM) with all functions shown: it has a `try`. List what its prologue does that `deposit`'s does not, and compare with [W-06](lab:preset?id=W-06).

## Where next

[Chapter 16](lab:book?ch=16) reads this text in full and says what changes when it meets a real LLVM. [W-05](lab:preset?id=W-05) covers closures and calls, [W-07](lab:preset?id=W-07) the structural checker, and the shelf doc on the [Hermes LLVM backend](lab:doc?id=hermes-llvm) lists the helpers.
