# From JavaScript to Wasm

[W-01](lab:preset?id=W-01) wrote the Fibonacci loop in core IR with number types everywhere. This preset starts from the JavaScript instead and asks what it takes for the same loop to reach the Wasm backend. The [Experiments view](lab:show?view=experiments) shows three pipelines side by side: with the defaults `fib` is refused, with an assumption alone it is still refused, and with the assumption and the standard rewrites it compiles to Wasm and returns `832040`.

> **Try it.** [Show fib at L1](lab:fn?name=fib) and read its operations: `num.lt`, `num.add`, `num.mul`. Then [open main.js](lab:open?file=main.js&find=steps[2]), change `steps[2]` to `steps[0]`, [rerun](lab:build) and read them again.

## What stands in the way

With the defaults, `fib`'s loop is made of JavaScript operations, and the backend names the first one it meets:

```text
js.lt in for1 is outside the core profile (numbers, booleans, direct calls)
```

`js.lt(i, n)` is JavaScript's `<`. If `n` were an object, it would call `n.valueOf()`, which could do anything: print, throw, allocate. Nothing in `fib` says `n` is a number, so the compiler must keep the general operation, and the general operation needs the JavaScript runtime, which Wasm does not have.

## Step 1: an assumption

`.assume({ fib: { n: 'number' } })` gives the parameter a type. This is what a JIT does after watching a function run: every call so far passed a number, so it compiles a version that assumes one. The decision log records the assumption as **unchecked**:

```text
assumed n: number, unchecked; a JIT would guard this and deoptimise when it fails
```

A real tier would test `n` on entry and fall back to the general code (deoptimise) when the test fails; the workbench has no second tier, so it records the risk instead. The assumption alone changes nothing in the IR. The type facts now know more, but `js.lt` is still `js.lt`: knowing a fact and using it are different steps.

## Step 2: narrowing

The standard rewrite set includes `narrow-by-facts`, which replaces a general operation by its **variant** when the facts at that point prove the variant's operand types. Four rewrites fire in `fib`:

| at | rewrite |
|---|---|
| `fib/for1/0` | js.lt → num.lt |
| `fib/body2/0` | js.add → num.add |
| `fib/next3/0` | js.mul → num.mul |
| `fib/next3/1` | js.add → num.add |

The facts come from the fixed point of the type analysis over the loop. `i` starts as `0` and is updated by `num.add(n16, 1)`; `a` and `b` start as `0` and `1` and are updated by additions of numbers. The block parameters of `for1` are printed as `any` (that is their declared type), but the analysis proves each is a number on every path into the loop. [Ask the agent to show the facts](lab:ask?q=Show%20me%20the%20type%20facts%20of%20fib%20at%20the%20loop%20head%20for1) to see them.

> **Try it.** [Select the comparison](lab:node?id=fib/for1/0) and read its contract in the Inspector: `num.lt` has behaviour `none`, so every permission is granted, where `js.lt` had none.

The `js.mul(i, 1)` that became `num.mul(i5_1, 1)` comes from `i++`, which converts `i` to a number before adding one. A peephole rewrite could delete the multiplication by one; [T-03](lab:preset?id=T-03) writes that rewrite.

## What stays out

`main` cannot go to Wasm in any of the three pipelines: it creates a closure (`js.closure`) and calls through it, and its output goes through `host.print` of whatever `fib` returns. A program reaches Wasm one function at a time, and the functions that stay out are the ones that touch objects, closures or the host. `main.js` runs only `fib`, with `entry: 'fib', args: [30]`; the header's Wasm mode would try `main` and report the same reason.

> **Exercise.** Add `function half(x) { return x / 2; }` and call it from `main`. What does the Experiments table say about `half` with the defaults, and what is the smallest change to `main.js` that gets it into Wasm too?

## Where next

[Chapter 15](lab:book?ch=15) covers the backend and the profile; [T-04](lab:preset?id=T-04) is about narrowing and [C-06](lab:preset?id=C-06) about variants. The shelf doc on [WebAssembly](lab:doc?id=wasm) lists what the profile admits.
