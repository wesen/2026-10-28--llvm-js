---
id: nan-boxing
title: Tagged values and NaN-boxing
group: Lowering
about: How every JavaScript value fits in one 64-bit word, why doubles are stored as themselves, what unboxing costs, and what the collector must decode.
order: 13
---
# Tagged values and NaN-boxing

A JavaScript variable can hold a number, a string, an object, `true`, `undefined` or a function, and the compiled code usually cannot know which. So the runtime represents every value as one machine word that carries its own kind: a **tagged value**. This doc explains the scheme the workbench's lowering assumes, **NaN-boxing**, in which a 64-bit word is either a double stored as itself or one of the bit patterns doubles do not use, with a tag. It is the representation behind every `i64` in the [LLVM text](lab:doc?id=hermes-llvm) and every root slot, and the reason unboxing a proven number is almost free. [L-02](lab:preset?id=L-02) shows the words; [Chapter 12](lab:book?ch=12) covers representations in full.

## The space doubles leave unused

An IEEE 754 double is a sign bit, 11 exponent bits and 52 fraction bits. When all exponent bits are 1 and the fraction is nonzero, the value is NaN, "not a number", and every such pattern means the same thing to arithmetic. That leaves more than $2^{52}$ bit patterns, almost all of which no computation needs to tell apart. Arithmetic produces one of them, the canonical quiet NaN `0x7FF8000000000000`, and the runtime makes sure any NaN that enters a tagged word is that one. Every other NaN pattern is free to mean something else.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 660 190">
  <text x="20" y="20" font-size="11" class="lbl">a double</text>
  <rect x="20" y="30" width="20" height="30" fill="none" stroke="currentColor" class="ink"/>
  <rect x="40" y="30" width="160" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="200" y="30" width="440" height="30" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="50" font-size="10" text-anchor="middle">s</text>
  <text x="120" y="50" font-size="10" text-anchor="middle">exponent (11 bits)</text>
  <text x="420" y="50" font-size="10" text-anchor="middle">fraction (52 bits)</text>
  <text x="20" y="90" font-size="11" class="lbl">a tagged non-double</text>
  <rect x="20" y="100" width="20" height="30" class="f-fill2" stroke="currentColor"/>
  <rect x="40" y="100" width="160" height="30" class="f-fill2" stroke="currentColor"/>
  <rect x="200" y="100" width="70" height="30" class="f-acc" stroke="currentColor" fill-opacity="0.25"/>
  <rect x="270" y="100" width="370" height="30" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="120" font-size="10" text-anchor="middle">1</text>
  <text x="120" y="120" font-size="10" text-anchor="middle">all ones</text>
  <text x="235" y="120" font-size="10" text-anchor="middle">tag</text>
  <text x="455" y="120" font-size="10" text-anchor="middle">payload: a pointer, a boolean bit, nothing</text>
  <text x="20" y="160" font-size="10" class="mut">0x4024000000000000 is the double 10; 0xFFF9000000000001 is true; 0xFFF8800000000000 is undefined</text>
  <text x="20" y="178" font-size="10" class="mut">(the words the workbench prints; a real runtime assigns its own tags in the same space)</text>
</svg>
```

**Figure 13.1.** Two readings of the same 64 bits. If the top 13 bits are all ones, the next bits are a tag and the rest a payload; otherwise the word is a double (the canonical NaN, `0x7FF8000000000000`, has a zero sign bit and stays a double). Schematic.

## The words the workbench prints

The LLVM printer writes immediates as tagged words, and [L-02](lab:preset?id=L-02) prints them:

| value | word |
|---|---|
| `10` | `0x4024000000000000` |
| `0.5` | `0x3FE0000000000000` |
| `-0` | `0x8000000000000000` |
| `true` | `0xFFF9000000000001` |
| `false` | `0xFFF9000000000000` |
| `null` | `0xFFF8C00000000000` |
| `undefined` | `0xFFF8800000000000` |

The doubles are their own IEEE bits (`-0` differs from `0` only in the sign, which is why the specification compares numbers by SameValue). The other values sit above `0xFFF8000000000000`, in the negative-NaN space, with a tag in the bits below the exponent: `false` and `true` share a tag and differ in the lowest bit. A heap reference would carry its own tag with the object's address in the low 48 bits, which is enough for the address spaces of current 64-bit hardware.

## Why this scheme

The alternative most engines know is **pointer tagging**: a word is a pointer unless its low bit says it is a small integer, and every double is a separate heap object (a "heap number"). V8 works this way. It makes integers and pointers cheap and doubles expensive: adding two doubles allocates a third. NaN-boxing makes doubles free and every pointer slightly more expensive (the tag must be removed before the address is used). SpiderMonkey, JavaScriptCore and Hermes use variants of NaN-boxing. For a language whose only number type is the double, it is the better default, and it is the one the workbench assumes.

## Unboxing

A value whose type facts prove it a number can be stored **unboxed**, as a plain `double`. Under NaN-boxing that costs nothing: the tagged word of a double is the double, so the conversion is an LLVM `bitcast` from `i64` to `double` and back, which generates no instruction. That is what the printer emits around every inline `fadd` and `fmul`; here is `a * a` from `hyp`:

```llvm
  %t0 = load i64, ptr %r.a, align 8
  %t1 = bitcast i64 %t0 to double
  %t2 = load i64, ptr %r.a, align 8
  %t3 = bitcast i64 %t2 to double
  %t5 = fmul double %t1, %t3
  %t4 = bitcast double %t5 to i64
  store i64 %t4, ptr %r.v6, align 8
```

A boolean costs more: a comparison yields an `i1`, and turning it into a tagged word means choosing between two constants (`select i1 %c, i64 0xFFF9000000000001, i64 0xFFF9000000000000`). An `int32` would need a conversion as well. The representation strategy `unboxWhenProven` records `f64` and `bool` for proven values at L2; the printer keeps every value in a 64-bit word, which for doubles is the same thing.

## Operations on tagged words

Every general operation starts by reading tags. `js.add(a, b)` on two tagged words is, inside its helper `shllvm_binary(add)`, a test of both words: if both are doubles, an `fadd` and done; if either is a string, a concatenation that allocates; otherwise a conversion that may call `valueOf` or `toString` on an object and so run arbitrary code. Only the first path is cheap, and only it is free of the obligations `mayCollect` and `nonlocalThrow`, but the helper must be prepared for all three, and so must the code around it: the call is a safepoint and a possible throw.

Type facts change that. When the analysis proves both operands numbers, the rewrite `narrow-by-facts` replaces `js.add` by its variant `num.add`, whose contract has no obligations and whose lowering is a single inline `fadd` between two bitcasts. The tag test disappears because the compiler has already done it, once, on paper. That is the whole economic argument for type facts in a dynamically typed language: the tags make every value self-describing, and the facts let the compiler skip reading them.

## What the collector must decode

A tagged word is a reference only if its tag says so. A root slot holds a tagged word, and the collector must check the tag before following it: a double that happens to look like an address must never be treated as one, which is exactly what the NaN space guarantees. Conversely, a value the type facts prove to be a number needs no root at all, whatever its representation, because no bit pattern of a double is a reference. This is why the root planner asks about types, not representations: in [L-02](lab:preset?id=L-02), `hyp`'s numbers need no slots whether they are stored as `f64` or as tagged words.

## What this model leaves out

The workbench has no strings in its tag picture (they are heap objects behind a reference, like every object), no symbols or BigInts, and no small-integer representation: `int32` exists as a type and a representation but the lowering never chooses it. A production runtime also needs to canonicalise NaNs at every boundary where foreign doubles enter (typed arrays, the host), and on platforms with addresses wider than 48 bits the payload no longer fits, which is why some runtimes use a different split of the 64 bits.
