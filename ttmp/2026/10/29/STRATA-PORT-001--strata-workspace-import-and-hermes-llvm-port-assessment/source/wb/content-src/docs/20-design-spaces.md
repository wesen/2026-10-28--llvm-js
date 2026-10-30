---
id: design-spaces
title: Design spaces and objectives
group: Method
about: Designs as product spaces of pipelines, metrics, objectives and where they disagree, feasibility, frontiers, search and studies.
order: 20
---
# Design spaces and objectives

A compiler is a bundle of choices: which root strategy, which rewrites, which exception protocol, whether to trust a guess about types. The workbench treats the set of choices as a value, a **design space**, and comparing compilers as an experiment over it. This doc covers designs and parameters, metrics, objectives and what to do when they disagree, feasibility, frontiers, and studies with hypotheses. [X-01](lab:preset?id=X-01) to [X-07](lab:preset?id=X-07) are the presets; [Chapter 20](lab:book?ch=20) goes deeper.

## A design maps points to pipelines

`g.design(params, point => pipeline)` takes a set of **parameters** and a function from a **point** (one value per parameter) to a pipeline. `g.param.choice(values, { default })` is a parameter with a finite list of values; `g.param.range(lo, hi, { step })` is a numeric one. The space is the product of the parameters, so three root strategies, two rewrite sets and two frontend settings make 12 points, which is X-01's design. `design.size()` reports the raw product and the points that remain, `design.defaults()` the point made of every default, `design.at(point)` one pipeline, and `design.where(pred)` a restricted space.

Two properties of pipelines make this cheap. They are immutable, so a design can hand out twelve pipelines without any of them affecting another, and they are complete descriptions: `pipeline.summary()` and `pipeline.hash()` say exactly what will run, so a point's row in a results table can always be reproduced.

## Metrics are definitions

A **metric** is a named function of a compiled program and its run, with a direction. The built-in ones read the plan (`rootSlots`, `maxFrameSlots`, `peakLive`), the run in plan mode under GC stress (`collections`, `peakRootSlots`, `rootBytes`), the specification run (`steps`) or the compilation (`ops`, `rewritesFired`, `compileMs`). `g.metric(name, ({ program, run }) => number, { dir, unit })` adds one, and from then on every search row has a column for it. X-05 writes two, `safepoints` and `frameBytes`; X-02 writes `assumptions`, the number of unchecked type guesses a pipeline makes.

A metric is only as meaningful as its definition. X-05's `frameBytes` adds up what each plan reports as its frame: on the native stack the root slots, two fixed slots and the argument area; for the arena strategy a record header and slots in runtime memory. Ranking the two kinds against each other compares different things, and the definition is where that is visible. `compileMs` is measured time and varies from run to run; every other built-in metric is a deterministic count, which is why the presets rank by counts.

## Objectives, and where they disagree

An **objective** turns rows into a ranking. `g.objective.minimize(m)` and `maximize(m)` rank by one metric, `weighted({ m1: w1, m2: w2 })` by a weighted sum, `lexicographic([m1, m2])` by the first metric with the second breaking ties. On one metric, ties are real: in X-01 two points need 15 root slots and `minimize('rootSlots')` cannot tell them apart, because it was not asked to.

When two metrics trade against each other, weighted and lexicographic objectives can pick different winners from the same table. In X-02, assuming parameter types removes safepoints: the program collects 62 times under stress with no assumptions, 21 times with two and 16 times with three. `weighted({ collections: 1, assumptions: 10 })` picks two assumptions (21 + 20 = 41 points, against 62 and 46); `lexicographic(['assumptions', 'collections'])` picks none. `g.rank.disagreement(results, a, b)` reports both rankings and whether the winners differ. A disagreement is not an error in either objective: it is the trade-off made visible, and the choice between positions belongs in a decision record ([M-05](lab:preset?id=M-05)).

## Feasibility comes before ranking

Some points are not compilers worth ranking. The workbench separates three cases, all in [X-04](lab:preset?id=X-04). A point whose pipeline fails `check()` (for example `statusReturn` exceptions with Hermes providers) is removed from the space by `design.where(g.constraint.compatible())` and never compiled. A point that compiles with errors (no roots, with the GC-safety check on) is not **admitted**. A point that is admitted but whose plan-mode run differs from the specification (no roots, with the check off) is not **correct**.

`g.objective.require('admitted', 'correct')` makes the last two feasibility conditions, and `.then(objective)` ranks the feasible points; infeasible points rank last whatever their numbers. That is the only safe way to treat correctness. A wrong compiler with zero root slots has the best number in X-04's table; in a weighted sum, a large enough saving would outvote any penalty for being wrong.

## Frontiers need no weights

A point **dominates** another when it is at least as good on every metric and strictly better on one. The **Pareto frontier** is the set of points nothing dominates: the points that could be best under some weighting. `g.rank(results, g.objective.pareto([...]))` computes it, reading "good" in each metric's own direction (`rewritesFired` is better larger), and a search with a Pareto objective keeps every row: the frontier first, marked `onFrontier`, then the dominated points.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 250">
  <line x1="80" y1="200" x2="590" y2="200" stroke="currentColor" class="ink"/>
  <line x1="80" y1="200" x2="80" y2="20" stroke="currentColor" class="ink"/>
  <text x="335" y="238" font-size="11" text-anchor="middle" class="lbl">assumptions</text>
  <text x="80" y="216" font-size="10" text-anchor="middle">0</text>
  <text x="240" y="216" font-size="10" text-anchor="middle">1</text>
  <text x="400" y="216" font-size="10" text-anchor="middle">2</text>
  <text x="560" y="216" font-size="10" text-anchor="middle">3</text>
  <text x="70" y="204" font-size="10" text-anchor="end">0</text>
  <text x="70" y="143" font-size="10" text-anchor="end">50</text>
  <text x="70" y="82" font-size="10" text-anchor="end">100</text>
  <line x1="76" y1="139" x2="590" y2="139" stroke="currentColor" class="hair dot"/>
  <line x1="76" y1="79" x2="590" y2="79" stroke="currentColor" class="hair dot"/>
  <text x="20" y="110" font-size="11" class="lbl" transform="rotate(-90 20 110)" text-anchor="middle">collections</text>
  <polyline points="80,124.7 400,174.5 560,180.6" fill="none" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <circle cx="80" cy="124.7" r="4.5" class="f-acc"/>
  <circle cx="400" cy="174.5" r="4.5" class="f-acc"/>
  <circle cx="560" cy="180.6" r="4.5" class="f-acc"/>
  <circle cx="80" cy="42.1" r="4.5" class="f-mut"/>
  <circle cx="400" cy="42.1" r="4.5" class="f-mut"/>
  <circle cx="560" cy="42.1" r="4.5" class="f-mut"/>
  <text x="92" y="121" font-size="10">standard · 62</text>
  <text x="412" y="168" font-size="10">21</text>
  <text x="548" y="170" font-size="10" text-anchor="end">16</text>
  <text x="92" y="38" font-size="10" class="mut">canonical · 130 at every level</text>
</svg>
```

**Figure 20.1.** Collections under GC stress against assumptions for X-03's two loops, with `stackReuse` roots: the standard rewrites (accent, the frontier) and the canonical ones (grey, dominated). Measured; the `distinct` points have the same collections and more root slots, so they are dominated too and not drawn.

In X-03 nine of twelve points fall away: every `distinct` point is dominated by its `stackReuse` twin (same collections, more root slots), and every `canonical` point by its `standard` twin (same root slots, more collections, because nothing narrows). Three points remain, and they are the real choices: none, two or three assumptions. The frontier also says which parameters matter: the root strategy and the rewrite set each have a clear winner, and only the assumptions are a trade-off.

## Search

`g.search.grid(design, { corpus, objective })` evaluates every point; `g.search.random(design, { budget, seed })` evaluates a sample. For each point and corpus item, the search compiles, records whether the program was admitted, runs it in plan mode under GC stress and in the specification, marks it correct when the two runs are equal, and fills a row with every registered metric (summed over the corpus, or the maximum for frame sizes). The result is a value with `rows`, `columns`, `best`, `frontier` and a `note`, which the Experiments view shows; its rows can be extended before returning, as X-03 does with an `on the frontier` column.

A grid is exhaustive and small spaces should use it. The workbench's spaces are a few dozen points and a search takes well under a second in the page; a space of thousands of points calls for sampling, and a sampled best point is a claim about the sample.

## Studies

A comparison becomes a **study** when its question, factors and hypotheses are written down before it is run. [X-06](lab:preset?id=X-06) crosses three root strategies with four programs and states three hypotheses with thresholds: `stackReuse` never needs more slots than `distinct`; no strategy changes observations; over the corpus `stackReuse` needs at most half the slots of `distinct`. Each hypothesis is evaluated from the rows and reported as a law, so the verdict sits next to its evidence: here all three are supported, with a ratio of 0.33.

Writing hypotheses first is what keeps a study from being reinterpreted after the fact. Stating its limits keeps it honest in the other direction: four programs written for this workbench are not a sample of JavaScript, and a study's verdicts are claims about its corpus. [X-07](lab:preset?id=X-07) defines a corpus measurement once, over operation contracts, so the same question can be asked of a larger corpus later.
