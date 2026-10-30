# Variants and narrowing

`x + 1` in JavaScript is several operations at once: numeric addition, string concatenation after conversion, or a call to `valueOf` on an object. The general operation `js.add` covers all of them, so its contract is `callsUser` and it has no permissions. A **variant** is an operation with a smaller contract that computes the same result whenever a condition on the operand types holds: `num.add` for two numbers, `str.concat` for two strings. **Narrowing** replaces the general operation by a variant wherever the type facts prove the condition. On the screen, `describe` uses `+` three times, guarded by different `typeof` tests, and the standard rewrites narrow two of them.

> **Try it.** [Look at describe in L1](lab:fn?name=describe) and [turn on the types overlay](lab:overlay?name=types&on=1). [The first +](lab:node?id=describe/then1/0) is now `num.add`, [the second](lab:node?id=describe/then3/0) is `str.concat`, and [the third](lab:node?id=describe/endif4/0) is still `js.add`.

## Facts select the variant

The pipeline is `g.pipeline().rewrites(g.rewrites.standard())`, which adds `narrow-by-facts` to the canonical set. For each operation with variants, it asks the type facts for its operand types just before it and calls the operation's `narrow` function:

```text
then1() throws unwind:
  v7 = num.add(x, 1)
  return v7
```

`x` is a parameter of type `any`, but the type analysis refines it on branches: on the true edge of `typeof x === "number"` it knows `x: number`, so in `then1` the operands are `number, number` and the variant is `num.add`. In `then3` the second test has proved `string`, and `"!"` is a string literal, so the variant is `str.concat`. In `endif4` both tests have failed; the decision log records the operand types the facts found there, `undefined|null|boolean|object|function, int32`, which select no variant. [Events](lab:show?view=events) lists every `narrow-by-facts` decision with its reason.

## The variant table

[Show the table](lab:show?view=experiments): `g.op.narrow(op, types)` for six pairs of operand types and three operations. Two numbers (or an `int32` with a `double`) select the `num.*` variant of `js.add`, `js.lt` and `js.strict_eq`; two strings select `str.concat` for `js.add` and nothing for the comparisons; a number with a string, or anything with `any`, stays general. The table is conservative on purpose: `true + 1` never runs user code either, but no variant covers booleans, so it stays `js.add`.

## Laws for variants

A variant is correct when it agrees with the general operation on every input that satisfies its condition. `g.law.variant(variant, general)` checks that by sampling operands of the variant's types, with the awkward values included: `0` and `-0`, `NaN`, `Infinity`, `2^31 - 1`, `-2^31`, `2^53`.

```js
g.law.variant('num.add', 'js.add'),
g.law.variant('num.lt', 'js.lt'),
g.law.variant('i32.add', 'num.add'),
```

[The Laws view](lab:show?view=laws) shows the first two passing on 3,000 samples and the third failing on its second sample: `i32.add(117884139, 2066098173)` is `-2110984984`, while `num.add` gives `2183982312`. Thirty-two-bit addition wraps; JavaScript addition does not. `i32.add` is a variant of `num.add` only under a stronger fact (the sum stays in range), which is what an overflow check provides in a real JIT.

> **Try it.** [Run describe in plan mode with GC stress](lab:run?mode=plan&gc=stress). The output, `42 hi! 2`, does not change; narrowing only removed safepoints.

## What narrowing buys

`num.add` has behaviour `none`, so it gains every permission `js.add` lacked: it can be erased, merged, moved, hoisted. It also loses the obligation `mayCollect`, so it is no longer a safepoint and needs no root slots around it. In L2 it binds to the inline instruction `fadd` instead of the helper `shllvm_binary`. [T-04](lab:preset?id=T-04) measures these effects on the ledger's loop.

> **Exercise.** Change the last line of `describe` to `return x === true ? 2 : x + 1;` and rerun. Does the facts' type for `x` in the new last block change? Then add a fourth test `typeof x === "boolean"` before it and predict which variant, if any, the `+` gets.

## Where next

[Chapter 7](lab:book?ch=7) treats variants as the way to earn permissions; [Chapter 12](lab:book?ch=12) follows `num.add` into an unboxed representation. The doc [Type facts](lab:doc?id=type-facts) explains branch refinement, and [A-03](lab:preset?id=A-03) shows the facts themselves.
