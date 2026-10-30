# One default at a time

A pipeline is a value with slots, and every slot has a default. This preset compiles one small program four times, changing one thing each time, and puts the four results side by side in [the Experiments view](lab:show?view=experiments). The program on the Stage is the last of the four.

> **Try it.** [Open main.js](lab:open?file=main.js&line=5), [show the table](lab:show?view=experiments) and compare the `rootSlots` column: 9, 16, 15, 15. The output column never changes: `3 12 / 55`.

## The program

`program.js` defines `sum(a, b)` and a loop `sumTo(n)` that calls it ten times. `sum(1, 2)` is 3 and `sum("1", 2)` is the string `"12"`, so `js.add` in `sum` must handle both numbers and strings. [Select it](lab:node?id=sum/entry/0) and the Inspector shows why the compiler can do little with it: its contract is `callsUser`, because adding an object calls its `valueOf`.

## Step 1: zero configuration

`g.pipeline()` with no calls is the opinionated default: the canonical rewrite set, `stackReuse` roots, `setjmp` exceptions, tagged values. `program.summary()` lists every resolved choice, so the defaults are never hidden:

```js
const base = g.pipeline();
```

With every default the three functions need 9 root slots in all (`main` 3, `sum` 2, `sumTo` 4).

## Step 2: partial parameters

A slot accepts partial parameters. `roots({ reuse: false })` keeps the roots slot but turns off slot sharing, which resolves to the `distinct` strategy: one slot per managed value, as the Hermes LLVM backend does today. The same program now needs 16 slots, because values that are never needed at the same safepoint no longer share one.

## Step 3: a named strategy

`rewrites(g.rewrites.standard())` swaps in a library rewrite set that adds narrowing by type facts and store-to-load forwarding. Three rewrites fire. In `main`, the first `cell.load` of `sum` is replaced by the closure just stored in the cell, so `main` loses a value and a root slot (16 becomes 15). The second load stays, because the call between them may write cells. In `sumTo` the loop counter `i` is known to be a number, so the increment `i++` becomes [num.mul](lab:node?id=sumTo/next3/0) and [num.add](lab:node?id=sumTo/next3/1), which cannot collect. The comparison [js.le](lab:node?id=sumTo/for1/0) stays a `js` operation: `n` is a parameter of unknown type, and the decision log says so (`operand types number, any select no variant`).

> **Try it.** [Turn on the safepoints overlay](lab:overlay?name=safepoints&on=1) on `sumTo` and count the marked operations: the two in `next3` are gone.

## Step 4: a lambda that wraps the default

Every slot also accepts a function. Its context offers `ctx.default()`, the plan the default strategy would make, so a lambda can wrap the opinion instead of replacing it:

```js
const wrapped = named.roots((fn, ctx) => {
  const plan = ctx.default();
  print(`${fn.name}: ${plan.rootSlots} root slots`);
  return plan;
});
```

Here the lambda only reports what it saw; the lines appear in [the Events view](lab:show?view=events). Because it wraps `distinct` (the strategy from step 2), the summary calls it `lambda(distinct)`. Whatever a lambda returns, the plan checker verifies it exactly as it verifies a built-in strategy.

## Why values, not settings

Each step is a new pipeline; `base`, `tweaked`, `named` and `wrapped` all exist at once and can all be compiled. That is what lets a study compare four pipelines on one source, and what lets a design space ([X-01](lab:preset?id=X-01)) enumerate hundreds.

> **Exercise.** Add a fifth step that keeps `wrapped` but changes `print` into a check: return `ctx.run('arena')` when `fn.name === 'sumTo'`. Rerun, read the table, and explain the `rootSlots` for that row.

## Where next

[Chapter 11](lab:book?ch=11) explains pipelines as values and why correct passes compose. [T-07](lab:preset?id=T-07) branches pipelines further with `use`, `with` and `set`, and [L-06](lab:preset?id=L-06) writes a root strategy of its own.
