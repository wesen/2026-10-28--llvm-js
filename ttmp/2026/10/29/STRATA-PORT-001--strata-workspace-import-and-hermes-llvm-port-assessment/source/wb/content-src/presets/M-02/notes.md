# Fuzzing a pipeline

On the screen are four refinement laws, each checked on 20 programs that nobody wrote. `g.gen.js` assembles a program from templates (a shared object, a getter that changes it, `try`/`catch`, `try`/`finally`, closures, loops, jobs), and `g.law.refines` compiles each one with a reference pipeline and with the pipeline under test, runs both, and compares what they print, throw and leave in the job queue. Three laws hold on all 20 programs. The fourth, for the deliberately wrong `naive-dce` rewrite, fails on the first.

> **Try it.** [Run main.js](lab:build) and open [the failing law](lab:law?name=naive%20DCE%2C%20spec%20mode) in Laws. The counterexample is the seed-1 program of [J-08](lab:preset?id=J-08); before the rewrite it prints `2`, `no throw`, `finally 2`, `job 9`, after it `0`, `no throw`, `finally 0`, `job 7`.

## What refinement means here

The reference is the program compiled with no rewrites and run in the specification. A target **refines** it when every observation of the target is one the reference allows; since the workbench's programs are deterministic, that means the same observations: the same printed values in the same order, the same outcome, the same thrown value, the same object identities up to renaming. `g.observe.equal` does the comparison and reports the first difference: for the naive rewrite, `trace[0] argument 0`, a `0` where the reference printed `2`.

## The four laws

```js
named('default pipeline, plan mode, GC stress', g.law.refines(g.pipeline(), { samples: N, seed: 1 })),
named('standard rewrites, plan mode, GC stress', g.law.refines(g.pipeline().rewrites(g.rewrites.standard()), { samples: N, seed: 1 })),
named('roots distinct, plan mode, GC stress', g.law.refines(g.roots.distinct(), { samples: N, seed: 1 })),
named('naive DCE, spec mode', g.law.refines(g.rewrites.naiveDce, { samples: N, seed: 1 })),
```

A pipeline or a root strategy is run in plan mode under GC stress, so its law covers the rewrites, the lowering, the root plan and the collector at once: a missing root shows up as a stale reference and the run differs. A rewrite on its own is run in the specification, so its law covers only what the rewrite did to the IR. `named` gives each report a readable name; the engine would otherwise call the first two both `refines(pipeline plan)`.

## Why the fuzzer finds the bug at once

The generator was written to hit the places compilers get wrong, and every program it writes starts with a getter that increments `cell.n`. Any program that then reads `r.x` without using the result is a counterexample to an erasure rule that ignores behaviour, and the first program does exactly that. A fuzzer is only as good as its templates: one that never generated a getter would pass `naive-dce` on any number of programs.

> **Try it.** Change the seed of the last law to 2 and rerun: it still fails, at the second program, because the first one never reads `r.x`. [Ask the agent](lab:ask?q=Which%20templates%20in%20g.gen.js%20would%20catch%20a%20rewrite%20that%20moves%20a%20host.print%20past%20a%20job.enqueue%3F) which templates would catch a rewrite that reorders output and jobs.

## What passing means

Twenty programs passing is evidence, not proof, and the right reading is quantitative: a bug that breaks one program in ten would almost surely show up in twenty; a bug that needs a rare combination might not. Raising `N` to 200 takes about ten times as long and buys that much more confidence. The counterexample of a failure, on the other hand, is certain: it is a program, and the two outputs can be checked by hand.

> **Exercise.** Write a broken root strategy (start from [L-06](lab:preset?id=L-06): a lambda that deletes one value from `ctx.default().slotOf`), turn off `gcSafety` in its pipeline, and fuzz it with `g.law.refines`. How many programs does the fuzzer need to catch it?

## Where next

[Chapter 19](lab:book?ch=19) covers fuzzing and refinement. [M-03](lab:preset?id=M-03) shrinks the counterexample, and the doc on [refinement](lab:doc?id=refinement) explains why passes that each refine their input compose.
