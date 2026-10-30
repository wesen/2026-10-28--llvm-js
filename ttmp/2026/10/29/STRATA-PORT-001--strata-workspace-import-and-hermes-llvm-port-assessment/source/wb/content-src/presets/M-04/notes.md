# Differential testing

On the screen is every executor the workbench has, run on the same programs and compared with the specification. **Differential testing** needs no expected output written by hand: the reference interpreter says what a program does, and any other way of running it must agree. `main.js` runs three programs (a Collatz count in core IR, the counter of [J-01](lab:preset?id=J-01), the thermometer of [J-02](lab:preset?id=J-02)) through two compilers, and each compiled program four ways: plan mode with GC off, with collections every 16 allocations, with a collection at every safepoint, and as WebAssembly.

> **Try it.** [Run main.js](lab:build) and [open Experiments](lab:show?view=experiments). Every cell says `same`, `stale` or `outside the core profile`. The two `stale` cells are both in the `forgets a root` rows, both in the `plan, gc stress` column.

## The executors

The **specification** runs core IR (L1) step by step with no notion of roots. **Plan mode** runs the lowered program (L3) with its root plan and a simulated moving collector: when a collection happens, everything reachable from rooted slots moves and the rest is freed, so a value the plan forgot is left pointing at a freed address. **Wasm** encodes the program to a WebAssembly binary and runs it in the page; it accepts only the core profile, numbers and booleans, which is why the two JavaScript programs are refused there and the IR program is accepted.

```text
fn main() -> number {
entry:
  jump loop(27, 0)
loop(x: number, k: number):
  v1 = num.le(x, 1)
  branch v1, done(k), body(x, k)
```

The IR program counts the Collatz steps from 27 and prints `111` in every executor. [Run it as Wasm](lab:run?mode=wasm) and the header shows the same outcome as [the specification](lab:run?mode=spec).

## A compiler that is wrong on purpose

The second compiler uses a root strategy that wraps the default and deletes the first rooted value of every function, with the GC-safety check turned off so the plan is accepted:

```js
const forgetOne = (fn, ctx) => {
  const plan = ctx.default();
  const victim = Object.keys(plan.slotOf)[0];
  if (victim) delete plan.slotOf[victim];
  return plan;
};
```

With GC off it is indistinguishable from the correct compiler: nothing moves, so nothing goes stale. With a collection every 16 allocations it still agrees on both programs, because no collection happens to fall while the forgotten value is live. Only a collection at every safepoint catches it. On the Collatz program it agrees everywhere: that function holds only numbers, its plan has no roots to forget, and the strategy deletes nothing.

## What the table teaches

Three things. A bug in lowering is invisible to the specification, which never lowers, and to any run where the collector stays quiet, so the configuration that provokes the bug matters as much as the comparison. The most aggressive configuration (GC stress) is the only one that catches this bug on these inputs, which is why the workbench's laws use it. And an executor that refuses a program (Wasm on JavaScript) is not a disagreement: the table says so in its own words instead of counting it as a pass or a failure.

> **Try it.** [Ask the agent](lab:ask?q=In%20M-04%2C%20which%20value%20does%20forgetOne%20delete%20in%20each%20function%20of%20counter.js%2C%20and%20where%20is%20the%20first%20stale%20use%3F) which value `forgetOne` deletes in each function of the counter. (The first stale use is in `main`: the closure `f5` for `makeCounter`, freed by the collection at the call that uses it.)

> **Exercise.** Change `forgetOne` to delete the *last* rooted value instead of the first. Do the same cells go stale? Then add [B-01](lab:preset?id=B-01)'s ledger as a fourth program and look for a configuration other than stress that catches the bug.

## Where next

[Chapter 19](lab:book?ch=19) covers differential testing with laws and generators. [L-05](lab:preset?id=L-05) looks at a stale reference in detail, and [W-01](lab:preset?id=W-01) builds the Wasm backend's input by hand.
