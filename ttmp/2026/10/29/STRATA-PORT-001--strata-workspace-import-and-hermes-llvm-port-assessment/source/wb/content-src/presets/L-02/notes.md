# Representations

This preset compiles three small functions and shows how each value will be stored after lowering. `hyp(a, b)` computes $a^2 + b^2$, `isBig(x)` compares with 100, and `label(o)` reads a property and appends `"!"`. The program prints `25`, `true` and `box!`. The [Experiments view](lab:show?view=experiments) counts, per function, how many values stay tagged words and how many become unboxed `f64` or `bool`.

> **Try it.** [Show L2](lab:level?l=L2), [select hyp on the Stage](lab:fn?name=hyp) and read the annotations: `inline fmul · v6: f64`. Then [select isBig's comparison](lab:node?id=isBig/entry/0): `inline fcmp ogt · v4: bool`.

## A type is not a representation

A **type** says which values a name can hold; a **representation** says how one of them sits in memory or in a register. The engine has four representations (`g.rep.tagged`, `f64`, `i32`, `bool`). `tagged` can hold anything: it is the 64-bit word in which the runtime keeps every JavaScript value, with the kind of value encoded in the bits. The others hold one kind only, and are allowed only where the type facts prove it.

The representation strategy decides. `tagged` keeps every value as a word. `unboxWhenProven` gives `f64` to every value whose type is at most `number` and `bool` to every value whose type is at most `boolean`:

| fn | values | f64 | bool | still tagged |
|---|---|---|---|---|
| main | 8 | 0 | 0 | 8 |
| hyp | 6 | 5 | 0 | 1 |
| isBig | 3 | 1 | 1 | 1 |
| label | 4 | 0 | 0 | 4 |

The one tagged value left in `hyp` and `isBig` is `this`, which nothing proves. `label` has no numbers to unbox.

## Where the facts come from

`main.js` assumes the parameters of `hyp` and `isBig` are numbers. That one assumption feeds the type analysis, which proves `v6 = num.mul(a, a)` is a number, and so on through the function. Without it, `hyp` operates on `any` values: its operations stay `js.mul` and `js.add`, which may call `valueOf`, and nothing can be unboxed. An assumption is unchecked: a real tier would guard it at the function's entry and fall back to the general code when it fails.

> **Exercise.** [Open main.js](lab:open?file=main.js&find=assume) and remove `isBig` from the assumption. Rerun: which counts change in the table, and what happens to the comparison's lowering on L2?

## What the words look like

A tagged word for a double is the double's own IEEE 754 bits, so `10` is `0x4024000000000000` and `0.5` is `0x3FE0000000000000`. Every other kind of value sits in the space of bit patterns that are not ordinary doubles (NaNs with a tag in the high bits). `main.js` prints the words the LLVM printer writes for seven immediates to the [Events view](lab:show?view=events):

```text
  store i64 0x4024000000000000, ptr %scratch       ; 10
  store i64 0x8000000000000000, ptr %scratch       ; -0
  store i64 0xFFF9000000000001, ptr %scratch       ; true
  store i64 0xFFF8C00000000000, ptr %scratch       ; null
  store i64 0xFFF8800000000000, ptr %scratch       ; undefined
```

Because a double is its own word, unboxing a proven number costs nothing more than a `bitcast` between `i64` and `double`; that is what the [LLVM text](lab:level?l=LLVM) of `hyp` shows around each `fmul`. A boolean costs more: the comparison produces an `i1`, and the printer selects between the two boolean words.

## Representations and roots

Representations do not decide roots. A root slot is needed for a value that may be a heap reference when a collection happens, and that is a question about its type: `a` in `hyp` needs no root whether it is stored as `f64` or as a tagged word, because its type, `number`, has no heap kinds. In the table, `hyp` and `isBig` need no root slots; `label` needs one, for `o`. The LLVM printer keeps every value as a 64-bit word; the representation choice is recorded at L2 and in each plan's `reps`, where a register allocator would use it.

> **Exercise.** Change `isBig` in `program.js` to return `x > 100 ? 1 : 0`. Which representation does its result get now, and why?

## Where next

[Chapter 12](lab:book?ch=12) covers values and representations; the shelf doc on [tagged values and NaN-boxing](lab:doc?id=nan-boxing) explains the bit layout. [L-01](lab:preset?id=L-01) shows the bindings these annotations sit on, and [C-06](lab:preset?id=C-06) the variants that narrowing chooses.
