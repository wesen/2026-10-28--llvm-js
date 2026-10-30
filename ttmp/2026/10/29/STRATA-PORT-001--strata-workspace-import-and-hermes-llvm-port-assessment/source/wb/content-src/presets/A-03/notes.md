# Type facts and branch refinement

`label` takes an `x` of unknown type and branches on `typeof x`. Inside each branch the program knows more about `x` than at the start, and so does the compiler: **type facts** are a forward analysis over the type lattice, and a branch on a type test **refines** the tested value on each of its two edges. The table in Experiments lists what the facts know about `x` on entry to every block, and the types of the block parameters where the branches join.

> **Try it.** [Turn on the types overlay](lab:overlay?name=types&on=1) and [select block then1](lab:node?id=label/then1). Then [show the table](lab:show?view=experiments): `x` is `any` in `entry`, `number` in `then1` and `string` in `then4`.

## A forward analysis

Type facts flow from definitions to uses, in program order, so the analysis is **forward**. Each value starts at `⊥` (no information yet); a parameter starts at its declared type, `any` here; each operation computes its result type from its operand types (`num.mul` of two numbers is a number, `js.typeof` is a string, `js.add` with a string operand is a string). Where edges meet, the facts are joined: the type of a block parameter is the join of the types of the arguments passed to it.

## Refinement on edges

A branch whose condition is a type test does not just pass facts along; it splits them. The analysis recognises `core.is_number(x)`, `core.is_int32(x)`, and the pattern the frontend emits for `typeof x === "…"`:

```text
entry throws unwind:
  v5 = js.typeof(x)
  v6 = js.strict_eq(v5, "number")
  branch v6, then1(), else3()
```

On the true edge `x` meets `number`; on the false edge `number` is subtracted. So in `else3`, `x` is `undefined|null|boolean|string|object|function`, and after the second test `then4` has `string` and `else6` has `undefined|null|boolean|object|function`. These are three different facts about one SSA value, attached to blocks rather than to the value, which is why the table is per block.

The join block `endif2` sees `x` as `any` again: the facts from `then1` (`number`) and from `endif5` (everything but `number`) join back to the whole type.

## What the facts buy

The pipeline uses the standard rewrites, so `narrow-by-facts` reads these facts. In [then1](lab:node?id=label/then1/0) the `x * 2` became `num.mul(x, 2)`: both operands are numbers there. In `then4`, [x.length](lab:node?id=label/then4/0) stays a `js.get`; knowing `x` is a string does not select a variant, because the standard set has no string-length operation. That is a gap in the operation set, not in the facts.

> **Try it.** In main.js, change the pipeline to `g.pipeline()` (canonical rewrites only) and [rerun](lab:build). The table does not change, but `then1` is back to `js.mul`: the facts were there, and nothing used them.

## Joins at merge points

The parameters show the other half of the lattice. `kind3_1` in `endif5` receives `"string of " + …` from `then4` and the literal `"something else"` from `else6`; both are strings, so the join is `string`. `kind3_2` in `endif2` joins that with the result of `then1`, also a string. The function's result is a string on every path, which the facts prove without running it.

## Where the facts stop

The analysis is intraprocedural: it does not know what callers pass, so a parameter stays `any` until a test refines it (or a pipeline assumes otherwise with `.assume`, as [W-02](lab:preset?id=W-02) does for Wasm). It does not track object shapes, so the result of `js.get` is `any` even on a string. And it refines only on tests it recognises: `x !== undefined` or `Array.isArray(x)` refine nothing.

> **Exercise.** Add a branch `else if (x === null) kind = "null";` before the last `else`. Rerun and read the type of `x` in the new blocks. Is `x === null` a test the analysis refines on? Check the table to find out, then explain the answer from the list of recognised tests above.

## Where next

[Chapter 9](lab:book?ch=9) develops type facts with liveness and safepoints. The doc [Type facts](lab:doc?id=type-facts) is the reference. [C-06](lab:preset?id=C-06) shows narrowing from the operations' side, [T-04](lab:preset?id=T-04) measures it on the ledger.
