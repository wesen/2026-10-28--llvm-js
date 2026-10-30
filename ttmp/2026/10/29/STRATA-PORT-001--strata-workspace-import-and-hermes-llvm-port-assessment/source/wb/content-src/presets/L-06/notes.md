# Your own root strategy

A root strategy is a slot of the pipeline, and like every slot it accepts a lambda. This preset writes two: one that chooses a strategy per function, and one that forgets a value so the checker can refuse it. The ledger from [B-01](lab:preset?id=B-01) is the program; the [Experiments view](lab:show?view=experiments) compares the chosen plans with the two built-in strategies function by function.

> **Try it.** [Open main.js](lab:open?file=main.js&find=const chooser), then [show arrow's plan](lab:fn?name=arrow) at [L3](lab:level?l=L3): the header says `distinct`, while `total`'s says `stackReuse`.

## The shape of a strategy

The lambda receives the function being planned and a context:

```js
const chooser = (fn, ctx) => {
  const plain = ctx.run('distinct');
  return plain.rootSlots <= 4 ? plain : ctx.default();
};
const program = g.compile(g.pipeline().roots(chooser), source());
```

`ctx.default()` is the plan of the strategy the lambda wraps, here the default `stackReuse`. `ctx.run(name)` runs another named strategy. `ctx.sites` lists the function's safepoints and `ctx.required(site)` the values each one needs, which is enough to write an allocator from scratch. A plan is an object with `slotOf` (value to slot number), `rootSlots` and `storage`; a lambda may also return a strategy value such as `ctx.strategies.arena()`.

The chooser keeps one slot per value where that needs at most four slots (simple to read in a debugger: every value has its own home) and packs the rest:

| fn | chosen | slots | stackReuse | distinct |
|---|---|---|---|---|
| main | stackReuse | 3 | 3 | 20 |
| makeLedger | stackReuse | 4 | 4 | 8 |
| deposit | stackReuse | 4 | 4 | 11 |
| get_balance | distinct | 2 | 0 | 2 |
| total | stackReuse | 3 | 3 | 7 |
| arrow | distinct | 4 | 1 | 4 |

The program needs 20 root slots in total, against 15 for `stackReuse` and 52 for `distinct`, and it still prints what the specification prints under a stress collector.

## The checker does not trust the lambda

A lambda strategy inherits the declared compatibility of the strategy it wraps (so `stackReuse` with `setjmp` stays a declared pair), but its plans get no credit for that. Every plan passes the same checker as the built-in ones. The second lambda in `main.js` removes `sum2_1`, the loop's running sum, from `total`'s plan:

```js
const forgetful = (fn, ctx) => {
  const plan = ctx.default();
  if (fn.name === 'total') delete plan.slotOf.sum2_1;
  return plan;
};
```

The compile fails with four errors, which `main.js` prints to the [Events view](lab:show?view=events):

```text
sum2_1 is live across js.get at total/for1/1 but no root assigned
sum2_1 is live across js.lt at total/for1/2 but no root assigned
sum2_1 is live across js.get at total/body2/1 but no root assigned
sum2_1 is borrowed by js.add at total/body2/2 but no root assigned
```

`sum2_1` is a block parameter of the loop head `for1`. Its type is `number|string` (the sum of `any` values may be a string), so it may be a heap reference, and it is needed after every collecting operation of the loop.

> **Try it.** [Select total's loop header](lab:node?id=total/for1) on the Stage with the [live overlay](lab:overlay?name=live&on=1) on, and find `sum2_1` in each live set.

## Why strategies are values

Because the strategy is a value, the same comparison can be run on any program, or put in a design space and searched ([X-06](lab:preset?id=X-06)). Because the checker is separate, a strategy author can be wrong without the program being wrong: a mistake becomes a compile error, never a stale pointer in production.

> **Exercise.** Write a strategy that gives `total` one slot more than it needs (copy `ctx.default()`, add a fresh value-free slot by raising `rootSlots`) and confirm the checker accepts it. Then write one that puts `c_log` and `sum2_1` in the same slot. Which safepoint does the checker name, and why that one first?

## Where next

[Chapter 13](lab:book?ch=13) covers the strategies and the checker. [L-03](lab:preset?id=L-03) compares the built-in strategies and [L-05](lab:preset?id=L-05) shows what a run does with a plan the checker would refuse.
