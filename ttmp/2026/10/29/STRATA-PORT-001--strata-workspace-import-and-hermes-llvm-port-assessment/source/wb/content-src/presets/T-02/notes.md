# Dead code that is not dead

A rewrite is wrong if it changes what some program does. `naive-dce` is wrong on purpose: it erases every operation whose result is unused and asks nothing else. On the screen the program reads `counter.next`, a getter that increments a counter, and ignores the value; `main.js` compiles it with `naive-dce` added, so the Machine runs the broken program. The point of the preset is that a law, not a reader, catches the bug, both on this program and on programs nobody wrote.

> **Try it.** [Show Events](lab:show?view=events): with the canonical set the program prints `reads: 1`, with `naive-dce` it prints `reads: 0`. Then [show the Laws](lab:show?view=laws).

## What naive-dce deleted

[Look at main in L1](lab:fn?name=main). The getter is defined, and then nothing reads it: the `js.get(o5, "next")` that `const ignored = counter.next` produced is gone, and the next operation loads `reads` directly. The rewrite is three lines:

```js
naiveDce: rewrite('naive-dce')                    // unsound on purpose: no side condition
  .match(m => m.op('*').resultUnused())
  .to(() => act.erase()),
```

Compare `erase-dead-result`, the canonical rewrite, which matches the same operations and then requires `perm.erase` to be `true`. For `js.get` it is `false` ("may run user code; may throw; …"), so the canonical set keeps the read. [C-04](lab:preset?id=C-04) follows that refusal in detail.

## The law

`g.law.refines(rewrite, { corpus, samples })` compiles each program twice, without rewrites and with only the rewrite under test, runs both in the specification, and compares their observations: printed output, the outcome, thrown values, object identity up to renaming. A rewrite **refines** the program if every observation is preserved. The three laws in `main.js`:

```js
g.law.refines(g.rewrites.naiveDce, { corpus: [source()] }),
g.law.refines(g.rewrites.naiveDce, { samples: 40, seed: 1 }),
g.law.refines(g.rewrites.eraseDead, { corpus: [source()], samples: 40, seed: 1 }),
```

The first fails on program.js at once: before `reads: 1`, after `reads: 0`. The third passes on program.js and 40 generated programs: the sound rewrite preserves everything.

## Finding the bug without a hint

The second law uses no corpus. `g.gen.js` writes random programs from templates built around a getter that changes a shared object, loops, closures, `try`/`finally` and jobs, and the first one already breaks `naive-dce`: before it prints `2`, `no throw`, `finally 2`, `job 9`; after, `0`, `no throw`, `finally 0`, `job 7`. The law then **shrinks** the counterexample, deleting statements one at a time while the failure persists, and ends with one line:

```js
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
```

The shrinker deleted the declarations of `r` and `cell`, so this program fails differently: `r` is now an undeclared global, reading it throws a ReferenceError before `no throw` can print, and `naive-dce` erases that throwing read as well. Before, the output is empty; after, it is `no throw`. Shrinking keeps any failure of the same law, not necessarily the one you started with. The small program is still a correct witness that the rewrite is unsound, and a sharper one: it shows that `naive-dce` also deletes operations that throw.

> **Try it.** In main.js, change `seed: 1` to `seed: 5` and [rerun](lab:build). A different generated program fails first, and shrinking it ends at the same one-line witness: every generated program draws on the same few templates, and that line is the smallest failing combination of them.

## Why the specification is the judge

Reading the two programs side by side is not how the question is settled; the reference interpreter decides. `observe.equal` compares outputs in order and values by SameValue, so a single changed number, a missing line or a different exception is a difference. That makes the law strict enough to catch a rewrite that only changes a count from 1 to 0, and general enough to apply to any rewrite, pass or pipeline ([the refinement doc](lab:doc?id=refinement)).

> **Exercise.** Write a rewrite `erase-pure-only` that erases an unused result only when the operation's behaviour is `none` (use `g.ops[site.op.op].behaviour.isNone` in `when`). Check it with the same three laws. Does it erase anything in program.js?

## Where next

[Chapter 10](lab:book?ch=10) defines refinement and uses this example; [Chapter 19](lab:book?ch=19) covers generators and shrinking. [T-03](lab:preset?id=T-03) writes a rewrite with a side condition; [M-03](lab:preset?id=M-03) looks at shrinking on its own.
