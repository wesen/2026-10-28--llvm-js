---
id: property-testing
title: Property testing and shrinking
group: Method
about: Laws as executable properties, generators of IR and JavaScript, refinement checked on generated programs, shrinking, and differential runs.
order: 19
---
# Property testing and shrinking

A **property test** states something that should hold for every input, draws many inputs, and checks it on each. The workbench uses property tests for itself: every claim of the form "this lattice is a lattice", "this analysis terminates", "this rewrite does not change behaviour" or "this root plan is complete" is a **law**, a function that samples inputs and returns a report. This doc covers what a law is, where its inputs come from, what a failure gives you, how a failure is made small, and what passing does and does not mean. [M-01](lab:preset?id=M-01) runs the engine's own laws, [M-02](lab:preset?id=M-02) fuzzes pipelines, [M-03](lab:preset?id=M-03) shrinks a counterexample and [M-04](lab:preset?id=M-04) compares executors.

## A law is a report, not a boolean

Every law returns the same shape: `{ name, ok, samples, counterexample?, minimized?, note? }`. `samples` says how many inputs were checked before the law stopped, so a law that fails at sample 1 and a law that fails at sample 1,900 read differently. The counterexample is the input that failed, in a form that can be replayed; for refinement it is the source of a program and the two outputs it produced. `g.laws([...])` collects reports into the LawReport that the Laws view shows, and a report built by hand, `{ name, ok, samples, note }`, sits next to the engine's own: [X-06](lab:preset?id=X-06) writes the hypotheses of a study that way.

The engine's laws fall into three groups. **Algebraic** laws check structure: `g.law.lattice(L)` that join is commutative, associative and idempotent and agrees with the order, `g.law.join()` the same for behaviours, `g.law.algebra(op, 'associative')` an operation's declared algebra. **Analysis** laws check the conditions the solver's correctness depends on: `g.law.monotone(analysis)` that a transfer function never maps a larger fact to a smaller one, `g.law.antitone()` that more behaviour never grants a permission. **Refinement** laws check whole programs: `g.law.refines(target)` that a rewrite, a pipeline or a root strategy preserves what the specification observes.

## Where inputs come from

For algebraic laws the inputs are values: types drawn as random bit patterns over the ten kinds, sets over a small universe, intervals around zero, numbers from pools that include `-0`, `NaN`, `Infinity`, `2³¹ − 1` and `1e-300` (the variant law) or `0.1` and `±1e16` (the algebra law) next to ordinary values. The pool matters more than the count. `g.law.algebra(g.ops['num.add'], 'associative')` fails on its first sample because the pool contains both `0.1` and `-1e16`, whose sum loses the `0.1`; a pool of small integers would pass it forever.

For laws over programs the inputs are generated programs. `g.gen.coreIR({ seed })` writes numeric core IR with a diamond and a bounded loop; `g.gen.js({ seed })` writes JavaScript from templates: a shared object `cell`, a getter `r.x` that increments it and sometimes throws, `try`/`catch`, `try`/`finally`, arrow functions, loops, array literals and queued jobs. The templates are chosen to hit the places compilers get wrong. Every generated program defines a getter with a side effect and most of them read it, so any rewrite that treats an unused property read as dead code fails on the first program that does.

Generators are seeded. `g.gen.js({ seed: 1 })` is the same program every time, so a failure can be reported by its seed, and a law run with the same seed sees the same programs. [J-08](lab:preset?id=J-08) shows the seed-1 program and what the compiler makes of it.

## Refinement on generated programs

`g.law.refines(target, { corpus, samples, seed })` compiles each program twice: once with no rewrites, run in the specification (the **reference**), and once with the target. A rewrite is run in the specification, so the law isolates what the rewrite did to the IR. A pipeline or a root strategy is run in plan mode under GC stress, so the law covers lowering, the root plan and the collector at once. `g.observe.equal` compares the two runs: printed values in order, the outcome, thrown values, object identity up to renaming, numbers by SameValue.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -12 640 202">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="10" y="70" width="110" height="44" fill="none" stroke="currentColor" class="ink"/>
  <text x="65" y="88" font-size="11" text-anchor="middle" class="b">generator</text>
  <text x="65" y="104" font-size="10" text-anchor="middle" class="mut">g.gen.js({ seed })</text>
  <line x1="120" y1="84" x2="190" y2="44" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="120" y1="100" x2="190" y2="140" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <rect x="190" y="22" width="170" height="44" fill="none" stroke="currentColor" class="ink"/>
  <text x="275" y="40" font-size="11" text-anchor="middle" class="b">reference</text>
  <text x="275" y="56" font-size="10" text-anchor="middle" class="mut">no rewrites · spec mode</text>
  <rect x="190" y="118" width="170" height="44" fill="none" stroke="currentColor" class="acc"/>
  <text x="275" y="136" font-size="11" text-anchor="middle" class="b">target</text>
  <text x="275" y="152" font-size="10" text-anchor="middle" class="mut">rewrite · pipeline · strategy</text>
  <line x1="360" y1="44" x2="420" y2="84" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="360" y1="140" x2="420" y2="100" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <rect x="420" y="70" width="100" height="44" fill="none" stroke="currentColor" class="ink f-fill"/>
  <text x="470" y="88" font-size="11" text-anchor="middle" class="b">compare</text>
  <text x="470" y="104" font-size="10" text-anchor="middle" class="mut">observe.equal</text>
  <line x1="520" y1="92" x2="560" y2="92" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="566" y="84" font-size="10" class="lbl">differ</text>
  <text x="566" y="100" font-size="10" class="mut">shrink</text>
  <path d="M470,70 L470,10 L65,10 L65,70" fill="none" stroke="currentColor" class="hair dash" marker-end="url(#arrow)"/>
  <text x="268" y="7" font-size="10" text-anchor="middle" class="mut">equal: next seed</text>
</svg>
```

**Figure 19.1.** The refinement loop of `g.law.refines`: each generated program is compiled as the reference and with the target, and the two runs are compared; equal runs move on to the next program, a difference is shrunk and reported. A schematic, not data.

When a pipeline law fails, the difference is often not a different output but a run that stopped: plan mode reports a stale reference, which counts as a difference. That is the most common way a lowering bug shows up, and the reason pipeline laws use GC stress: a collection at every safepoint gives a missing root the most chances to matter. [M-04](lab:preset?id=M-04) has a root strategy that forgets a value; plan mode with collections every 16 allocations does not catch it on two programs, GC stress catches it on both.

## Shrinking

A generated counterexample carries noise: of the nine statements in the seed-1 program, most have nothing to do with the bug. **Shrinking** deletes parts of a failing input for as long as it keeps failing. `g.shrink(items, fails)` tries deleting each item in turn, keeps any deletion after which `fails(items)` is still true, and starts again until no single deletion keeps the failure, a simple form of Zeller's delta debugging. Generated JavaScript is kept as a list of statements for this reason (`g.gen.js(...).statements`, rebuilt with `g.gen.fromStatements`), and `g.law.refines` shrinks its counterexample before reporting it as `minimized`.

The predicate decides what is kept, and a loose predicate keeps the wrong thing. In [M-03](lab:preset?id=M-03), shrinking the seed-1 program with "the runs differ" ends at a single statement that fails for a different reason (it reads an undeclared `r`), while "the reference finishes normally and the runs differ" ends at the three statements that show the real bug: a getter with a side effect, read for nothing. The minimized counterexample that `g.law.refines` reports for this law is the loose one. A shrunk input should be read with the question: does it fail for the same reason as the original?

## Differential testing

A property test needs a property; **differential testing** takes the property from a second implementation. The workbench has several executors for the same program: the specification on L1, the L3 plan executor at three GC settings, and WebAssembly for the core profile. Any of them disagreeing with the specification is a bug in the one that disagrees, with no expected output written by hand. The executors also differ in what they accept: Wasm refuses JavaScript that is outside the core profile, and that refusal is reported as such, not counted as a pass.

## What passing means

A law that holds on 2,000 samples has not been proved. It has been checked on 2,000 inputs from a particular distribution, and its strength is the strength of that distribution: a bug that breaks one input in ten is almost certainly found in twenty samples, a bug that needs a combination the generator never produces is never found. Two habits follow. Raise the sample count when a law guards something important and the time allows (the four laws of M-02, 80 programs in all, take about two seconds in Node; ten times the programs take about ten times as long). And when a bug is found by other means, ask why the generators missed it and add a template that would have found it.

A counterexample, by contrast, is certain. It is an input, and the failure can be replayed and read by hand. That asymmetry is the reason laws are worth having: they cost little when they pass and they hand over evidence when they fail. [Chapter 19](lab:book?ch=19) develops the method with the workbench's own generators, citing Claessen and Hughes's QuickCheck (2000), where this style of testing began.
