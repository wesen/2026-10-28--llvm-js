# Bound to helpers

The IR view shows this preset's program at level L2, the **runtime IR**: the same core IR as L1, with each operation annotated by how the runtime will carry it out. `area` reads two properties and multiplies them, `scale` doubles a number and adds one, and `main` prints `23`. Lowering starts here: before a compiler can choose registers, frames or root slots, it has to know which operations are a single machine instruction and which are calls into the runtime.

> **Try it.** [Show L2](lab:level?l=L2) and [select area's js.get](lab:node?id=area/entry/0). Then [select scale's num.mul](lab:node?id=scale/entry/0) and compare the two inspectors.

## Three kinds of binding

The `lower-runtime` pass gives every operation a **binding** of one of three kinds. An **inline** binding is a machine instruction: `num.mul(n, 2)` becomes `fmul`, `num.add` becomes `fadd`. A **helper** binding is a call to a function of the runtime, named as in the Hermes LLVM backend: `js.get` becomes `shllvm_get`, `obj.new` becomes `shllvm_object`, `js.mul` on unknown operands becomes `shllvm_binary(mul)`. A **direct** binding is a call to a known function of the same module: `core.call(@square, 7)` becomes `direct call @square`.

```text
fn scale(this: any, n: number) -> any {
entry throws unwind:
  v4 = num.mul(n, 2)                         ; inline fmul
  v5 = num.add(v4, 1)                        ; inline fadd
  return v5
}
```

In this program 2 operations bind inline and 12 to helpers. The second module, `direct.ir`, has the direct call; `main.js` prints its L2 to the [Events view](lab:show?view=events).

## Obligations travel with the binding

A binding is more than a name. It keeps the obligations of the operation's contract, and L2 prints them: `collects` when the helper may run the garbage collector, and `throws (setjmp)` when an exception may leave the helper by a long jump instead of a return. In `area` every operation carries both:

```text
  w4 = js.get(box, "w")                      ; call shllvm_get · collects · throws (setjmp)
```

A getter on `box` could allocate (so a collection may happen inside `shllvm_get`) and could throw (so control may never come back to the next line). The next level, L3, uses exactly these two marks: each `collects` is a **safepoint** that needs a root plan, and each `throws` needs an unwinding plan. `area` has three safepoints and needs two root slots; `scale` has none and needs none.

> **Try it.** [Show the Plan](lab:show?view=plan) and [switch the Stage to scale](lab:fn?name=scale): no safepoints, no roots, a three-slot frame.

## Why narrowing matters here

`main.js` assumes `scale`'s parameter is a number. With that fact the standard rewrites narrow `js.mul` and `js.add` to their numeric variants, and the numeric variants have inline lowerings. Without the assumption, `scale` lowers like `area`:

```text
  v4 = js.mul(n, 2)                          ; call shllvm_binary(mul) · collects · throws (setjmp)
  v5 = js.add(v4, 1)                         ; call shllvm_binary(add) · collects · throws (setjmp)
```

The difference is the reason type facts exist. A helper call costs a call, and it also costs everything its obligations demand: roots for every managed value live across it, a jump buffer for every protected region it sits in.

> **Exercise.** [Open main.js](lab:open?file=main.js&line=8) and delete `.assume({ scale: { n: 'number' } })`. Rerun, and count the safepoints in `scale` on the Plan view. Then put the assumption back and add `area: { box: 'number' }`: what does the verifier or the run say, and why is that assumption wrong?

## Where next

[Chapter 12](lab:book?ch=12) explains bindings and representations together. [L-02](lab:preset?id=L-02) shows unboxed representations, [W-04](lab:preset?id=W-04) shows these helper names in LLVM IR, and the doc on [tagged values](lab:doc?id=nan-boxing) explains what a helper receives.
