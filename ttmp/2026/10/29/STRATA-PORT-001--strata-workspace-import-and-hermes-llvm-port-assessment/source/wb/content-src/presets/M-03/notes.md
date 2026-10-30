# Shrinking a counterexample

On the screen is a nine-statement program that the deliberately wrong rewrite `naive-dce` breaks, shrunk twice, and the two results disagree in an instructive way. **Shrinking** takes a failing input and removes parts of it for as long as it still fails, so that what is left is the smallest input that shows the bug. `g.shrink(items, fails)` does it one item at a time: it tries deleting each statement, keeps any deletion after which `fails` is still true, and stops when no single deletion keeps the failure.

> **Try it.** [Run main.js](lab:build) and [open Experiments](lab:show?view=experiments). Three rows: the generated program with 9 statements, a shrink to 1 statement, and a shrink to 3. Only the last one is the bug you were looking for.

## Two predicates

The failure is a difference between two compilations of the same program: the reference (the default pipeline) and the broken one (the canonical rewrites plus `naive-dce`). The first predicate says only that the runs differ:

```js
const differs = statements => { calls1++; const { before, after } = runBoth(statements);
  return before.outcome.kind !== 'error' && g.observe.equal(before, after).equal !== true; };
```

The second also demands that the reference run finishes normally:

```js
const sameFailure = statements => { calls2++; const { before, after } = runBoth(statements);
  return before.outcome.kind === 'normal' && g.observe.equal(before, after).equal !== true; };
```

## The loose shrink finds a different bug

With `differs`, the shrinker ends at one statement: `try { r.x; print('no throw'); } finally { print('finally', cell.n); }`. It has deleted the declarations of `r` and `cell`. In the reference this program throws a ReferenceError (the read of `r` fails, then the `finally` fails reading `cell`, and the second error replaces the first); with naive DCE the read of `r.x` and the lookup of `r` are erased because their results are unused, so the program prints `no throw` before throwing. The runs differ, so the predicate is satisfied, but the difference is about erasing a read of an undefined global, not about the getter the original program exercised. A shrinker preserves whatever the predicate says, and "the runs differ" admits more failures than the one that was found.

## The strict shrink keeps the bug

With `sameFailure` the result is three statements:

```text
let cell = { n: 0 };
const r = { get x() { cell.n += 1; return cell.n; } };
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
```

The reference prints `no throw` and `finally 1`; with naive DCE, `no throw` and `finally 0`. That is the original bug in its smallest form: a getter with a side effect, read for nothing. The shrink took 25 predicate calls, each compiling and running the program twice, against 15 for the loose one.

> **Try it.** The Stage shows the three-statement program compiled with the broken rewrite. [Select the first operation of the protected block](lab:node?id=main/try4/0): it is the `host.print("no throw")`; the `js.get(o5, "x")` that should precede it is gone, and the [decisions in Events](lab:show?view=events) record `naive-dce` firing at `main/try4/0` with reason `matched`.

## Why it matters

A counterexample of 9 statements takes minutes to understand; one of 3 takes seconds. But a shrinker is a search, and it finds whatever its predicate rewards. The habit worth keeping: write the predicate to name the failure you saw (same outcome kind, same kind of difference), not just "something is different", and check that the shrunk input fails for the same reason as the original.

> **Exercise.** Make the predicate stricter still: require that the difference is in a line starting with `finally`. Does the result change? Then shrink seed 4's program (`g.gen.js({ seed: 4 })`) with `sameFailure` and compare.

## Where next

[Chapter 19](lab:book?ch=19) covers shrinking and delta debugging. [M-02](lab:preset?id=M-02) finds the counterexample, [T-02](lab:preset?id=T-02) explains why the rewrite is wrong, and the doc on [property testing](lab:doc?id=property-testing) gives the method.
