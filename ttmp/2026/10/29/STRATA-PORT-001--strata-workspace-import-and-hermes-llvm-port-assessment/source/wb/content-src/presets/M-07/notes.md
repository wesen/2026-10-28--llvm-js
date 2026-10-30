# The capstone

On the screen is the ledger taken through every check in the workbench, in the order a team would run them before trusting a compiler: the specification, a pipeline with every slot stated, an engine run, a small design search, a decision record, and ten laws. All ten hold. The [Laws view](lab:show?view=laws) is the report a reviewer would read; [Experiments](lab:show?view=experiments) is the search behind the decision; the Stage shows the program that was shipped.

> **Try it.** [Run main.js](lab:build), then read the laws from the top. Each one names what it checked and, in its note, the number it checked it with: `41 safepoints checked`, `8 slots of 1024 slots (64 B)`, `440 lines`.

## 1. Meaning first

`g.semantics().run(src)` runs the source in the reference interpreter: `rejected: amount must be a number`, `main 42 42`, `audit 42`. Nothing else in the file defines what the ledger does; every later check compares against this run.

## 2. The pipeline, stated in full

```js
const pipe = g.pipeline().profile('js').rewrites(g.rewrites.standard())
  .roots('stackReuse').exceptions('setjmp').checks({ verify: true, gcSafety: true, llvm: true });
```

Most of these are defaults. Stating them makes the program's provenance readable without knowing the defaults, and makes a later change of default visible as a difference here. The first law, `the pipeline is well formed`, is `pipe.check()`: every pass finds what it requires, and the strategy pair `stackReuse` with `setjmp` is declared compatible.

## 3. The static checks

Four laws read the compiled program without running it. Every function verifies (`g.verify` on all six). Every safepoint roots what it needs: all 41 entries of the plans' `safepoints` maps have nothing in `missing`. The largest frame fits the native limit: `g.limit('native frame', …)` measures 8 slots against 1,024, 64 B. The LLVM text passes the structural checker: no `llvm-check` diagnostic in a module of 440 lines.

> **Try it.** [Show deposit](lab:fn?name=deposit) at [L3](lab:level?l=L3) to see one of the plans the third law checked, then [the LLVM text](lab:level?l=LLVM) the fifth law checked.

## 4. The dynamic checks

`g.law.refines(pipe, { corpus: [src], samples: 10, seed: 2 })` runs the ledger and ten generated programs through the pipeline in plan mode under GC stress and compares each with the specification: 11 programs, no difference. The engine run admits the program, evaluates it, drains its jobs and closes, and its output equals the specification's line for line. `antitone(perm)` and `monotone(liveness)` check two promises the optimiser and the solver rely on.

## 5. A search and a decision

The search crosses two root strategies with two rewrite sets, requires every point to be admitted and correct, and ranks by root slots, then collections. `roots=stackReuse rewrites=standard` wins with 15 root slots and 60 collections. The decision record takes its options and evidence straight from the table, chooses the winner, and passes `check()`: two or more options, evidence, a counterexample sought, a choice, and a condition that would overturn it ("any law below failing after an engine change").

## Why this order

Meaning comes first because every other check is a comparison with it. Static checks come before dynamic ones because they are cheap and point at a place in the program. The search and the decision come last because they compare compilers that have already passed everything else. Nothing in this file defines a behaviour twice, and replacing any strategy, rewrite or provider later is a one-line change that the same file then rechecks.

> **Exercise.** Change `.roots('stackReuse')` to a lambda that forgets one value (see [L-06](lab:preset?id=L-06)) and set `gcSafety: false`. Which laws fail, in what order would you read them, and does the engine run still agree with the specification?

## Where next

[Chapter 21](lab:book?ch=21) carries this file over to a native build. [M-06](lab:preset?id=M-06) is the process it belongs to, and [B-01](lab:preset?id=B-01) is where the ledger started.
