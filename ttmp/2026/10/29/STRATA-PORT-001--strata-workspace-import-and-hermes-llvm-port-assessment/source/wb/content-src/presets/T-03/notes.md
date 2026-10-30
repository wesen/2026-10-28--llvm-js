# Your own rewrite

A rewrite has three parts: a **match** that picks candidate operations, a **side condition** that decides whether this candidate may be rewritten, and an **action**. The side condition is where correctness lives. `main.js` writes `mul-one`, which removes `x * 1`, twice: once with the condition "x is already a number" and once without it. Both are added to the canonical set and checked with `g.law.refines`.

> **Try it.** [Show Events](lab:show?view=events): with `mul-one` the program prints `10 6`, with `mul-one-naive` it prints `10 51`. Then [show the Laws](lab:show?view=laws).

## Where `x * 1` comes from

`i++` in JavaScript converts `i` to a number before adding 1, and the frontend expresses the conversion as a multiplication by 1. [Open program.js](lab:open?file=program.js&line=4): the loop in `count` has one, at `next3`, and `asNumber` has an explicit `x * 1`, which is how JavaScript code turns `"5"` into `5`. In the first case the multiplication does nothing, because `i` is always a number; in the second it is the whole point of the function.

## The rewrite

```js
const mulOne = g.rewrite('mul-one')
  .match(isMulByOne)
  .when((s, ctx) => {
    const ty = ctx.typeAt(s, s.op.args[0]);
    return { ok: ty.le(t.number), because: `the operand is ${ty}${ty.le(t.number) ? '' : ', and x * 1 converts it'}` };
  })
  .to(s => g.act.replaceWith(s.op.args[0]));
```

`isMulByOne` matches `num.mul` and `js.mul` whose second operand is the literal 1. `ctx.typeAt(site, operand)` asks the type facts for the operand's type just before the operation. `g.act.replaceWith(x)` replaces every use of the result with `x` and removes the operation. The `because` string goes into the decision log, so the reason for each answer is kept.

[Events](lab:show?view=events) shows the two decisions. At `count/next3/0` it fired: "the operand is number". The facts know that `i` starts at 0 and is only ever the result of an addition of numbers. At [asNumber's js.mul](lab:node?id=asNumber/entry/0) it was refused: "the operand is any, and x * 1 converts it".

> **Try it.** [Look at count in L1](lab:fn?name=count): `next3` now reads `v12 = js.add(i4_1, 1)` directly. Then [look at asNumber](lab:fn?name=asNumber): the multiplication is still there.

## The naive version

`mul-one-naive` has the same match and action and no `when`. It fires at both sites. In `asNumber` the result is now `x` itself, the string `"5"`, so `asNumber("5") + 1` is the string `"51"` instead of the number 6. The law reports it:

```js
g.law.refines(mulOneNaive, { corpus: [source()], samples: 30 }),
```

fails on program.js with before `10 6`, after `10 51`, at "trace[0] argument 1". The sound version passes on program.js and 30 generated programs.

## How to write a side condition

Ask what the rewrite assumes. `x * 1 → x` assumes that multiplying by one returns its operand unchanged, which is true of numbers (including `-0` and `NaN`) and false of everything else. The condition should state exactly that assumption in terms the engine can check: here a type fact. A condition that is too weak gives a wrong compiler; one that is too strong only gives up optimisations. When unsure, check the rewrite with `g.law.refines` on generated programs before trusting it.

> **Exercise.** Write `mul-zero`: `x * 0 → 0` when `x` is a number. Check it with `g.law.refines` on the corpus `function z(x) { if (typeof x === "number") return x * 0; return 0; } print(z(-1), z(Infinity));` (generated programs rarely multiply by zero, so a law with no corpus would pass without testing anything). It fails: find out why from the counterexample (`-1 * 0` is `-0`, `Infinity * 0` is `NaN`) and decide whether any type fact makes it correct.

## Where next

[Chapter 10](lab:book?ch=10) covers rewrites, side conditions and refinement. The doc [Rewriting with side conditions](lab:doc?id=rewriting) lists the context a condition can use. [T-04](lab:preset?id=T-04) shows the built-in rewrite that narrows by facts, and [T-08](lab:preset?id=T-08) checks that a set of rewrites reaches one canonical form.
