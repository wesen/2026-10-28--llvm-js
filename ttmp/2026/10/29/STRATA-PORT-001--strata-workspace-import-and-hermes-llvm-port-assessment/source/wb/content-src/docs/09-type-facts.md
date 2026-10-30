---
id: type-facts
title: Type facts
group: Analysis
about: What the compiler knows about each value's kind: the type lattice, the forward analysis, refinement on branches, and what the facts are used for.
order: 9
---
# Type facts

JavaScript values carry their kind at run time, so a compiler starts knowing nothing about a parameter. **Type facts** are what it can prove anyway: that `i` in a loop is always a number, that `x` is a string inside `if (typeof x === "string")`, that a function always returns a string. In the workbench they are a forward analysis over the type lattice, solved by the same solver as liveness, and they feed narrowing, representation choice, root plans and the Wasm backend. [A-03](lab:preset?id=A-03) shows them block by block; [Chapter 9](lab:book?ch=9) develops them.

## The type lattice

A type is a set of **kinds**: `undefined`, `null`, `boolean`, `int32`, `double`, `string`, `object`, `function`, and two internal kinds, `cell` and `completion`. Join is union, meet is intersection, `⊑` is inclusion, and the lattice has height 10. Named types are unions: `number` is `int32|double`, `any` is every JavaScript kind, `top` adds the internal kinds. `int32` is the kind of a number that is an integer in 32-bit range and not `-0`; `t.ofValue(7)` is `int32`, `t.ofValue(0.5)` and `t.ofValue(-0)` are `double`. Types print as their union, `number|string`, with `number` used when both numeric kinds are present.

## The forward analysis

Facts flow from definitions to uses, so the analysis runs **forward**, from `⊥` for every value. A function's parameters start at their declared types (`any` from JavaScript, or what the pipeline assumes). Each operation's result type comes from its operand types through the operation's definition: `num.add` of anything gives `number`; `js.typeof` gives `string`; `js.strict_eq` gives `boolean`; `js.add` gives `string` if either operand is a string, `number` if neither can become one, and `number|string` otherwise; `js.get` gives `any`. A block parameter's type is the join of the types of the arguments on every edge into it. On the ledger's loop the counter's parameter receives `int32` (the literal 0) and `number` (the result of an addition), and settles at `number`.

## Refinement on branches

A branch whose condition is a recognised type test splits the facts along its two edges. The engine recognises three forms:

| condition | true edge | false edge |
|---|---|---|
| `core.is_number(x)` | `x ⊓ number` | `x ∖ number` |
| `core.is_int32(x)` | `x ⊓ int32` | unchanged |
| `js.strict_eq(js.typeof(x), "k")` | `x ⊓ k` | `x ∖ k` |

where `"k"` names a kind: `"number"`, `"string"`, `"boolean"`, `"undefined"`, `"function"`, and `"object"`, which in JavaScript also covers `null` (`typeof null === "object"`), so the true edge gets `null|object`. A condition passed through `js.truthy` is looked through. `core.is_int32`'s false edge stays unchanged because a non-`int32` value may still be a `double`.

This is why the facts are attached to blocks, not only to values: in A-03's `label`, one SSA value `x` is `any` in `entry`, `number` in `then1`, `string` in `then4` and `undefined|null|boolean|object|function` after both tests have failed, and `any` again where the branches join.

## Exceptional edges

A handler block receives the thrown value, whose type is `any`, and the values in the protected block's `throws to H(args)` list, whose types are taken at the head of the protected block. The analysis treats the edge like any other, so facts proved before the `try` remain known in the `catch`.

## What the facts are used for

**Narrowing.** `narrow-by-facts` in the standard rewrites replaces a general operation by a variant whose condition the facts prove: `js.add` by `num.add` or `str.concat`, `js.lt` by `num.lt`, `js.strict_eq` by `num.eq`, `js.truthy` of a boolean by `core.copy`. On the ledger this narrows three operations and removes two safepoints from `total` ([T-04](lab:preset?id=T-04)). Narrowing is only as correct as two things: the facts (a wrong fact selects a variant outside its domain) and the variant (which must agree with the general operation wherever its condition holds, as `g.law.variant` checks on sampled operands, `-0`, `NaN` and the 32-bit boundaries included).

**Root plans.** A value that is proved a number or a boolean does not live in the heap, so it never needs a root slot. A value of type `any` might be an object and is rooted.

**Representations.** With `representation('unboxWhenProven')` the lowering keeps proved numbers as unboxed `f64` and booleans as `bool` instead of tagged words ([Chapter 12](lab:book?ch=12)).

**Wasm.** The WebAssembly backend accepts only functions whose values are all numbers or booleans; type facts decide eligibility ([W-02](lab:preset?id=W-02)).

**Side conditions.** Custom rewrites read the facts through `ctx.typeAt(site, operand)`; [T-03](lab:preset?id=T-03) removes `x * 1` only where `x` is proved a number.

## The running example

On the ledger compiled with the standard rewrites, the facts make three different kinds of statement about `total` and `deposit`, and each one is visible in the IR.

In `total`, the loop counter `i3_1` is proved `number`: its incoming arguments are the literal `0` and the result of `num.add`. The two operations of the increment narrow to `num.mul` and `num.add`, and with `representation('unboxWhenProven')` the plan stores `i3_1`, `n14` and `v15` as `f64` instead of tagged words. The comparison `v7 = js.lt(i3_1, length6)` stays general, because `length6` comes from a `js.get`, but its result is proved `boolean` and gets the `bool` representation.

The running sum `sum2_1` is `number|string`: it starts at `0` and is then `sum + log[i]`, and `log[i]` is `any`, so the addition might concatenate. The sum keeps a tagged representation and a root slot.

In `deposit`, `amount` is `any` after the guard `if (typeof amount !== "number") throw …`. The guard proves the opposite on its true edge, but the analysis refines only the positive form `===`, so the knowledge that `amount` is a number on the fall-through path is lost. The addition `balance + amount` would not narrow anyway, since `balance` comes out of a cell, but the example shows how much a compiler's knowledge depends on the exact shape of a test.

## Assumptions

`pipeline.assume({ fib: { n: 'number' } })` sets a parameter's type before the analysis runs. Nothing checks it: the decision log records it as unchecked, and a call with a string would then run code compiled for numbers. A JIT makes the same move from profiling data and guards it, with a type check on entry and a way back (deoptimisation) when the check fails. The workbench leaves the guard out so the facts' effect can be seen on its own.

## What the facts leave out

The analysis is intraprocedural: it does not look at callers, so parameters are `any` unless assumed. It does not track object shapes or array contents, so every `js.get` result is `any`, including `s.length` on a proved string. It does not follow values through cells, so a captured variable read with `cell.load` is `any` however it was written. It refines only the three forms in the table: `x === null`, `Array.isArray(x)` and, notably, the negated form `typeof x !== "number"` refine nothing, so a guard written as an early exit (`if (typeof x !== "number") throw …`, as in the ledger's `deposit`) leaves `x` unrefined after it. Writing the test positively gets the refinement. Each of these is a place where a production compiler adds an analysis (inline caches and shapes, interprocedural types, escape analysis) that the workbench does not have.
