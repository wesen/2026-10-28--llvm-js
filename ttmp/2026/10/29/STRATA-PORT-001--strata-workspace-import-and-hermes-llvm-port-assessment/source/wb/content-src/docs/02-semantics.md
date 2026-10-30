---
id: semantics
title: Semantics and observations
group: Meaning
about: The reference interpreter as the specification, outcomes and observations, SameValue and identity, profiles and refinement.
order: 2
---
# Semantics and observations

Every claim the workbench makes about a compiled program has the same form: it behaves the same as the source. This doc says what "behaves" and "the same" mean there. The meaning of a program is given by one interpreter over core IR, the **specification**; a run of it produces a list of **observations** and an **outcome**; and two runs are the same when their observations agree under the comparison described below. The laws, the plan executor's checks and the experiments all rest on this.

## The interpreter is the specification

The interpreter in `40-machine.js` runs core IR one operation at a time. Its state is a stack of frames (each a function, an environment from value names to values, and the current block), a heap of objects, cells, closures and promises, the global object, and two queues: microtasks and timers. Each operation's definition carries a `step` function, and the interpreter's whole job is to look up the operands, call the step and move on. JavaScript's rules live in those steps and in a few helpers (`toPrimitive`, `toNumber`, `getProperty` with getters, `setProperty` with setters, `strictEquals`).

Why an interpreter and not a written description? Because it can be run. A rewrite can be checked by compiling a program with and without it and comparing the two runs; a lowering can be checked by running its result beside the interpreter. A written specification cannot answer "is this run right?"; an executable one can. The price is that the interpreter must be simple enough to trust, so it has no optimisations and no collector, and every run of it is deterministic. [S-01](lab:preset?id=S-01) replays one step by step.

## Outcomes

A run ends in one of four outcomes:

| outcome | when |
|---|---|
| `normal` | main returned, and the job queues ran to empty |
| `throw` | an exception left main (or a job), with the thrown value |
| `diverge` | the step budget ran out (200,000 steps by default) |
| `error` | the engine itself could not continue: for example, a stale reference in plan mode |

`diverge` and `error` are not meanings of the program but limits of the machine, and comparisons treat them that way: two runs that both diverged are compared on what they observed before stopping, and a run that diverged against one that did not is `unknown`, never `false`. [S-05](lab:preset?id=S-05) shows the budget at work.

## Observations

An **observation** is something the outside world could see. In the workbench that is every call of `print` with the values it printed, the outcome, and the thrown value of an uncaught exception. The printed text is derived from the values, and it is the values that are compared: `print(-0)` and `print(0)` both print `0`, and they are different observations.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 150">
  <g font-size="11">
    <text x="10" y="20" class="lbl">run A</text>
    <rect x="70" y="8" width="120" height="22" fill="none" stroke="currentColor" class="ink"/><text x="80" y="23">print(#9, #9)</text>
    <rect x="210" y="8" width="120" height="22" fill="none" stroke="currentColor" class="ink"/><text x="220" y="23">print(-0)</text>
    <rect x="350" y="8" width="120" height="22" fill="none" stroke="currentColor" class="ink"/><text x="360" y="23">normal</text>
    <text x="10" y="120" class="lbl">run B</text>
    <rect x="70" y="108" width="120" height="22" fill="none" stroke="currentColor" class="ink"/><text x="80" y="123">print(#4, #4)</text>
    <rect x="210" y="108" width="120" height="22" fill="none" stroke="currentColor" class="acc"/><text x="220" y="123">print(0)</text>
    <rect x="350" y="108" width="120" height="22" fill="none" stroke="currentColor" class="ink"/><text x="360" y="123">normal</text>
  </g>
  <g fill="none" stroke="currentColor" stroke-width="0.6" class="mut">
    <line x1="130" y1="30" x2="130" y2="108" class="dash"/>
    <line x1="270" y1="30" x2="270" y2="108" class="dash"/>
    <line x1="410" y1="30" x2="410" y2="108" class="dash"/>
  </g>
  <g font-size="10">
    <text x="136" y="72" class="mut">#9 ↔ #4: a renaming</text>
    <text x="276" y="72" class="acc">−0 ≠ 0 by SameValue</text>
    <text x="416" y="72" class="mut">same outcome</text>
    <text x="490" y="62" class="b">not equal:</text>
    <text x="490" y="78">the second</text>
    <text x="490" y="94">observation differs</text>
  </g>
</svg>
```

**Figure 2.1.** Comparing two runs observation by observation. Object references are matched up to a consistent renaming; numbers are compared by SameValue. Schematic.

## SameValue

Numbers are compared with **SameValue**, the comparison of `Object.is`. It differs from `===` in exactly two places: `-0` and `+0` are different, and `NaN` equals `NaN`. Both matter to a compiler. A rewrite that turns `x * -1` into `0 - x` changes `-0` into `0` when `x` is 0, and a program can tell (`1 / x`). A check that compared `NaN` with `===` would call two identical runs different. Strings, booleans, `null` and `undefined` compare by value and type: `print("1")` and `print(1)` differ.

## Identity up to renaming

Objects are observed by identity, not by content, and the interpreter numbers them in allocation order. Those numbers are an accident: a correct compiler may allocate in a different order. So the comparison builds a **bijection** between the objects of the two runs as it goes. The first time object 9 on the left meets object 4 on the right, they are paired; from then on 9 must always meet 4 and 4 must always meet 9. One object printed twice against two objects printed once each fails (`identity: one object on the left is two on the right`); two objects made in another order passes. [S-02](lab:preset?id=S-02) has six pairs to compare.

## Profiles

A **profile** names which operation sets a program may use and which observations a claim must preserve. The built-in ones are `core` (numbers, booleans, direct calls, print; observes output and outcome), `js-sync` (adds values, objects and functions; observes thrown values, identity and heap mutation) and `js-async`, also called `js` (adds jobs, timers and promises; observes job order). `g.profile(name).check(module)` lists the operations a module uses outside a profile, so admission is decided before anything runs. [S-03](lab:preset?id=S-03) runs three programs under the three profiles.

## Refinement

With observations defined, correctness can be stated. A compiled program **refines** its source when, for every input the profile admits, every behaviour of the compiled program is a behaviour of the source: the same observations in the same order and the same outcome. The workbench's engine is deterministic, so each program has one behaviour per input and refinement reduces to equality of runs. `g.law.refines(target, { corpus, samples })` checks it on a corpus and on generated programs, and returns the first counterexample with both runs. Refinement composes: if each pass refines its input, the pipeline refines the source, which is why passes can be checked one at a time ([Chapter 10](lab:book?ch=10)).

$$
\mathrm{source} \sqsupseteq p_1(\mathrm{source}) \sqsupseteq p_2(p_1(\mathrm{source})) \implies \mathrm{source} \sqsupseteq (p_2 \circ p_1)(\mathrm{source})
$$

## What this model leaves out

The specification covers the JavaScript subset the frontend accepts, not the whole language: no classes, no `==`, no modules, no `eval`, no generators or `async` functions, no typed arrays. Time is virtual (timers fire in order of their deadlines, at once), there is one thread, and the heap never runs out. Garbage collection is not part of the meaning at all; it appears only in plan mode, where a run that touches a moved object stops with an engine error rather than a different observation. Each of these is a choice about what the compiler is promised to preserve, and a real port would have to make it again with its own profile.

[Chapter 2](lab:book?ch=2) develops all of this from the beginning.
