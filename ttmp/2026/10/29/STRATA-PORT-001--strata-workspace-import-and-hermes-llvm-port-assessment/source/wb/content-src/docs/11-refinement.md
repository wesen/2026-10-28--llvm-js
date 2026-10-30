---
id: refinement
title: Refinement and why passes compose
group: Transformation
about: What it means for a compiled program to be correct, how g.law.refines checks it, and why correct passes stay correct in any pipeline.
order: 11
---
# Refinement and why passes compose

A compiler is correct when the program it produces does nothing the source program could not do. The workbench makes that precise as **refinement**, checks it with one law, `g.law.refines`, and relies on one property of it, transitivity, to treat passes, rewrites and strategies as parts that can be combined freely. This doc defines the terms, describes exactly what the law compares, and lists what passing it does and does not establish. [Chapter 10](lab:book?ch=10) introduces refinement; [Chapter 11](lab:book?ch=11) uses it for pipelines.

## Observations

What a program "does" is what can be observed from outside it. The workbench's **observations** are the values printed, in order, and how the run ended: normally, with a thrown exception (compared by what it prints as), or by running out of its step budget. Printed values are compared by SameValue, so `-0` differs from `0` and `NaN` equals `NaN`; objects are compared by identity up to a consistent renaming, so two runs that print the same object twice must both print one object, not two that look alike. Everything else is not observed: the number of steps, the number of collections, which helper ran, how many root slots a frame has. That is what leaves room for optimisation. A profile can widen the set; `js-async` adds the order of jobs, which matters once promises are involved.

## Refinement

A target program **refines** a source program, `T ⊑ S`, if every behaviour of `T` is a behaviour of `S`: every sequence of observations `T` can produce, `S` can produce too. For a nondeterministic language this is inclusion of sets of behaviours, and it lets a compiler pick one of several allowed outcomes (an evaluation order the language leaves open, say). The workbench's interpreter is deterministic, so each program has exactly one behaviour, and refinement reduces to equality of observations, which `g.observe.equal(runT, runS)` decides.

The **specification** is the reference interpreter running the source's core IR with no rewrites. A rewrite, a pass, a root strategy or a whole pipeline is correct if, for every program, its output refines the specification's.

## The law

`g.law.refines(target, { corpus, samples, seed })` checks that claim on a finite set of programs: the corpus you give, plus `samples` programs from `g.gen.js` (JavaScript built from templates around a getter with side effects, loops, closures, `try`/`finally` and jobs). For each program it compiles a baseline with no rewrites and runs it in the specification, then:

| target | compared against the baseline |
|---|---|
| a rewrite or rewrite set | the program compiled with only that set, run in the specification |
| a pipeline | the program compiled with that pipeline, run in plan mode with GC stress |
| a root strategy | the default pipeline with that strategy, run in plan mode with GC stress |

The first failing program is reported with its observations before and after, and, for generated programs, shrunk: statements are deleted one at a time while the failure persists. A run that stops with an engine error (a stale reference, for example) counts as a failure, since the comparison cannot say it is equal.

Some results from the presets: `naive-dce` fails on its first generated program, printing `0` where the specification prints `2` ([T-02](lab:preset?id=T-02)); `mul-one` with its type condition passes on 31 programs and without it fails on one, turning `"5" * 1 + 1` into `"51"` ([T-03](lab:preset?id=T-03)); `erase-dead-result` passes on 41; a correct rule declared on an operation whose contract lies fails, which shows the law checks contracts as well as rules ([C-05](lab:preset?id=C-05)).

## Why passes compose

Refinement is reflexive (a program refines itself) and transitive: if `T ⊑ M` and `M ⊑ S` then `T ⊑ S`, because every behaviour of `T` is one of `M`, each of which is one of `S`. A pipeline is a sequence of passes, each of which refines its input; by transitivity the last output refines the source. So correctness is checked once per pass, not once per pipeline, and a new pass, a new order or a new combination of strategies inherits correctness from its parts. This is the property that lets the workbench treat pipelines as values to branch, combine and search over ([T-07](lab:preset?id=T-07), [X-01](lab:preset?id=X-01)): a design space of correct parts contains only correct pipelines.

Two conditions make the argument work. Each pass must refine on every input it can be given, not only on the outputs of the passes that happen to precede it in the default order; and the observations must be the same at every stage. The second is why lowering is checked in plan mode with GC stress: the root plan must preserve the observations even when the collector runs at every safepoint.

## Contracts are refinements too

An operation's contract is a claim about its reference step: the behaviour is an upper bound on what the step does. A provider (Hermes's helpers, or the reference implementation) must refine the reference step of every operation in its set. A rewrite's side condition is proved against the contract, so a rewrite is correct only relative to honest contracts. When a refinement law fails, the counterexample says which of the two is wrong only after you read it: [C-05](lab:preset?id=C-05)'s failure is the contract's fault, [T-02](lab:preset?id=T-02)'s the rule's.

## Testing, not proof

A law that passes on a corpus and 40 generated programs is evidence, not a proof. Its strength depends on the generator: a rule that only fires on `x * 0` is never exercised by programs that never multiply by zero, and passes vacuously. Write a corpus that reaches the rule's edge cases (`-0`, `NaN`, strings, getters, exceptions) and check that the rule fired at all (the decision log says so). A proof of refinement, as in verified compilers such as CompCert, establishes the claim for all programs; the workbench's laws are the cheaper, executable approximation that catches most wrong rules in seconds.

## What refinement leaves out

It ignores everything unobserved, so it says nothing about speed, memory or code size; those are metrics, compared in experiments ([X-02](lab:preset?id=X-02)). It assumes the specification is right: if the interpreter disagrees with JavaScript, every pass that refines it inherits the disagreement. And the workbench's observations stop at printed values, the kind of outcome and an uncaught value: a pass that changed only the return value of `main` without printing it would pass. An escaping exception is compared by what it prints as (`TypeError: amount must be a number`), so a pass that changed which exception escapes fails the law, but one that changed only a property the message does not show would not. Widening the observations (object contents at the end, job order) makes the law stricter and the room for optimisation smaller; choosing them is part of designing the compiler.
