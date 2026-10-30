# Every level of one function

The compiler keeps every stage of its work, and each stage can be printed. This preset follows one function, `poly`, through all of them: the source (L0), the core IR straight from the frontend (L1.cells), the core IR after promotion and rewrites (L1), the runtime IR bound to helpers (L2), the root plan (L3), LLVM IR text and WebAssembly text. The table in [the Experiments view](lab:show?view=experiments) counts the lines of each.

> **Try it.** [Open the IR view](lab:show?view=ir) and step through the levels with [L1.cells](lab:level?l=L1.cells), [L1](lab:level?l=L1), [L2](lab:level?l=L2), [L3](lab:level?l=L3), [LLVM](lab:level?l=LLVM) and [WAT](lab:level?l=WAT). Then [run it as Wasm](lab:run?mode=wasm): `main` is refused, but `poly` compiled, and main.js printed `wasm poly(2) = 11` in Events.

## The function

```js
function poly(x) {
  let acc = 0;
  for (let i = 1; i <= 3; i++) acc = acc * x + i;
  return acc;
}
```

Horner's rule evaluates $x^2 + 2x + 3$ as $((0 \cdot x + 1) \cdot x + 2) \cdot x + 3$, so `poly(2)` is 11. `main.js` compiles it with one assumption, `assume({ poly: { x: 'number' } })`, and the standard rewrites. The assumption is what a just-in-time compiler would speculate after seeing `poly` called with numbers; here it is unchecked, and the decision log records it as such.

## L1.cells and L1: from variables to values

At L1.cells every variable is a cell: `c_acc3`, `c_i4`, even `c_x2` for the parameter. The loop reads and writes them with `cell.load` and `cell.store`, 31 lines in all. Nothing outside `poly` can see these cells, so `promote-cells` turns them into SSA values. At L1 the loop header `for1(acc3_1, i4_1)` receives the two loop-carried values as **block parameters**, and the back edge `jump for1(v11, v14)` passes the new ones. [Select the loop header](lab:node?id=poly/for1) on the Stage to see the edges carry them.

Because `x` is assumed to be a number and the loop starts from number literals, the type facts find that `acc` and `i` are numbers too, and the narrowing rewrite turns every `js.mul`, `js.add` and `js.le` into its `num` variant. [Select num.mul](lab:node?id=poly/body2/0): its behaviour is `none`, so every permission is granted.

## L2 and L3: nothing to root

L2 says how each operation will be implemented. Here every one is `inline` (`fmul`, `fadd`, `fcmp ole`): no runtime helper is called, so nothing can collect. L3 adds the root plan, and the plan is empty: 0 root slots plus the 2 fixed slots (scratch and discard) and 1 argument slot, 3 slots or 24 B.

> **Try it.** [Show the Plan view](lab:show?view=plan) for `poly`, then [switch to main](lab:fn?name=main): `main` calls a closure and prints, and its plan is not empty.

## LLVM and WAT: two backends

The LLVM text has the shape of the Hermes LLVM backend: `define internal i64 @poly(ptr %shr)`, a frame from `shllvm_enter`, and the arithmetic inline on doubles (`%t15 = fmul double %t11, %t13`). Values that need no root live in `alloca` registers marked `not rooted`. The workbench checks this text structurally; it does not run it.

The WAT is different: it is encoded to a real WebAssembly binary of 289 bytes and run by the browser. Every value is an `f64` local, block parameters become locals assigned on the edge, and a `loop $dispatch` with a `br_table` jumps to the block whose number is in `$blk`. [Chapter 15](lab:book?ch=15) builds this by hand.

> **Exercise.** Delete the `assume` line in main.js and rerun. Which levels change? Read the WAT tab and the reason it gives, then find in L1 the first operation that keeps `poly` out of the core profile.

## Where next

[Chapter 1](lab:book?ch=1) reads the running example through the same levels. [B-04](lab:preset?id=B-04) explains what the Stage draws, and [W-02](lab:preset?id=W-02) takes more JavaScript to Wasm with assumptions.
