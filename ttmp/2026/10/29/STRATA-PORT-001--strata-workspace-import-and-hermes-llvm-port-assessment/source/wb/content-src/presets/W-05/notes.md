# Closures and calls in LLVM

`makeCounter(5)` returns an arrow function that adds `step` to a captured `n` and returns it; `main` calls the counter twice and prints `10`. This preset reads the LLVM text for the two things that program does that arithmetic does not: it makes a **closure** (a function together with the variables it captures) and it **calls** through one. Both are runtime helpers, and both pass more than fits in a helper's fixed arguments.

> **Try it.** [Show makeCounter as LLVM](lab:level?l=LLVM) and find `shllvm_closure`. Then [switch to main](lab:fn?name=main) and find the three `shllvm_call`s.

## A closure is an index and some cells

The frontend gives every captured variable a cell and passes the cells to the inner function as its first parameters. At L1, `makeCounter` creates two cells and the closure:

```text
  c_step2 = cell.new(step)
  c_n3 = cell.new()
  cell.store(c_n3, 0)
  f4 = js.closure(@arrow, c_n3, c_step2)
```

and `arrow` begins `fn arrow(c_n: cell, c_step: cell, this: any)`. The LLVM text copies the two cells into the outgoing area and asks the runtime for a closure over function 2 of the module with 2 captures:

```llvm
  %t0 = getelementptr i64, ptr %argv, i32 0
  %t1 = load i64, ptr %s1, align 8
  store i64 %t1, ptr %t0, align 8
  %t2 = getelementptr i64, ptr %argv, i32 1
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %t2, align 8
  call void @shllvm_closure(ptr %r.f4, ptr %shr, ptr %frame, i32 2, i32 2, ptr %argv)      ; @arrow · may collect
```

The function index (`i32 2`) is the position of `arrow` in the module (`main` 0, `makeCounter` 1, `arrow` 2). The cells are managed objects, so the plan roots them in `s0` and `s1` across the `js.closure`, which may allocate.

> **Try it.** [Select the js.closure](lab:node?id=makeCounter/entry/3) and read its rooted set in the Inspector: both cells, because the helper borrows them.

## A call passes arguments through argv

`js.call(f4, undefined, 5)` in `main` becomes:

```llvm
  %t0 = getelementptr i64, ptr %argv, i32 0
  store i64 0x4014000000000000, ptr %t0       ; 5
  store i64 0xFFF8800000000000, ptr %discard       ; undefined
  call void @shllvm_call(ptr %s0, ptr %shr, ptr %frame, ptr %s0, ptr %discard, ptr null, i32 1, ptr %argv)      ; may collect
```

The arguments go to `shllvm_call` in this order: the out pointer, the runtime, the caller's frame, the callee, `this`, `new.target` (`null` for an ordinary call), the argument count and the arguments. The literal `5` is written straight into `argv[0]` as its tagged word; `this` is `undefined`, written to `%discard`. The callee `f4` and the result `r6` share slot `s0`: the closure is not needed after the call, and the counter it returns is needed by the next two calls.

The `argv` array is sized by the largest outgoing call or closure of the function: two slots in `main` and `makeCounter`. The [Events view](lab:show?view=events) prints, per function, the closures, the calls and the size of `argv`.

## A gap the text shows

The frame size passed to `shllvm_enter` counts the argument slots (`i32 3, i32 2` in `main`: three slots, two of them for arguments), as in Hermes, where outgoing arguments live in the register stack the collector scans. The printer, however, allocates `%argv` as a separate stack array. A helper that collected before reading its arguments would read stale copies there; what keeps plan mode correct is that the plan roots the originals (the cells in `s0` and `s1`). A production emitter would place the outgoing area inside the scanned frame. Reading the generated text with the plan beside it is how such gaps are found.

> **Exercise.** Give the counter an argument (`return (k) => { n = n + step * k; return n; }`, and call `tick(2)`). Predict the `shllvm_closure` and `shllvm_call` lines before rerunning: which counts change, and how large is `argv` in `main`?

## Where next

[Chapter 16](lab:book?ch=16) covers the calling convention; [W-04](lab:preset?id=W-04) reads a function's frame and [W-06](lab:preset?id=W-06) the setjmp protocol. [I-08](lab:preset?id=I-08) explains why captured variables stay cells.
