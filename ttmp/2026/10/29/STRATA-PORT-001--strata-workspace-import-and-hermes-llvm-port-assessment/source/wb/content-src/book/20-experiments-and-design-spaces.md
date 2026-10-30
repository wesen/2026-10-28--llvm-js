# Experiments and design spaces

Earlier chapters compared choices one pair at a time: canonical against standard rewrites, `distinct` against `stackReuse` roots. A compiler has many such choices, and they interact, so comparing them one at a time hides the combinations that matter. This chapter treats the set of pipelines as a space to be measured. It defines a **design** as a product of parameters, shows how each point is compiled, run and measured, and then asks the question every experiment eventually asks: which point is best? The answer depends on an **objective**, and the chapter shows three kinds (weighted sums, priorities and the Pareto frontier), where they disagree, and what the disagreement says. It ends with a factorial study of root strategies on five programs, and with the ways a measurement can mislead.

## 20.1 A design is a space of pipelines

Every pipeline slot of [Chapter 11](lab:book?ch=11) takes a value, so a choice of values for several slots is a pipeline. A design names the slots that vary and says how a choice becomes a pipeline:

```js
const d = g.design({
  roots: g.param.choice(['distinct', 'stackReuse', 'arena', 'none']),
  rewrites: g.param.choice(['none', 'canonical', 'standard']),
  exceptions: g.param.choice(['setjmp', 'statusReturn']),
}, p => g.pipeline().roots(p.roots).rewrites(g.rewrites[p.rewrites]()).exceptions(p.exceptions));
```

A **parameter** is a finite list of values (`g.param.choice`) or a stepped range (`g.param.range`), optionally with a default and a condition under which it applies. A **point** is one value per parameter, and the design's points are the Cartesian product of its parameters: here $4 \times 3 \times 2 = 24$. `d.defaults()` is the point the plain pipeline would choose, `d.at(point)` builds that point's pipeline, and `d.size()` reports both the raw product and the number of points that survive the design's constraints.

Not every point is a meaningful compiler. [Chapter 14](lab:book?ch=14) showed that `statusReturn` needs runtime helpers that report errors by returning a status, and the JavaScript operation sets are provided by Hermes, whose helpers throw nonlocally. `d.where(g.constraint.compatible())` keeps only the points whose pipeline passes `.check()`. For this design it halves the space: `size()` goes from `{ raw: 24, points: 24 }` to `{ raw: 24, points: 12 }`, all twelve with `setjmp`. The constraint costs nothing to evaluate, because `.check()` inspects the pipeline without compiling anything, and it removes points that could never be admitted before any time is spent on them.

## 20.2 Measuring a point

A design point is measured on a **corpus**, a list of sources. The workbench's search compiles the point's pipeline on each item, runs the result, and adds the numbers up:

```js
// core.js
function evaluatePoint(pipe, corpus, runOpts = {}) {
  const agg = { admitted: true, correct: true, steps: 0, collections: 0, rootSlots: 0, maxFrameSlots: 0, peakLive: 0, peakRootSlots: 0, rootBytes: 0, compileMs: 0, ops: 0, rewritesFired: 0 };
  for (const item of corpus) {
    const program = compile(pipe, item);
    if (!program.ok) { agg.admitted = false; agg.reason = (program.diagnostics.find(d => d.severity === 'error') || {}).message; continue; }
    const run = program.run({ mode: runOpts.mode || 'plan', gc: runOpts.gc || 'stress' });
    const spec = program.run({ mode: 'spec' });
    if (observeEqual(run, spec).equal !== true) agg.correct = false;
    for (const [k, m] of Object.entries(METRICS)) { const v = m.of({ program, run }); agg[k] = (k === 'maxFrameSlots' || k === 'peakLive' || k === 'peakRootSlots' || k === 'rootBytes') ? Math.max(agg[k] || 0, v) : (agg[k] || 0) + v; }
  }
```

Each line encodes a decision about what the numbers mean. A program that does not compile makes the whole point **not admitted**, with the first error kept as the reason. Each compiled program runs twice: in plan mode with GC stress, which exercises the root plan, and in the interpreter, which is the reference. The point is **correct** only if every pair of runs is equal under `observe.equal`. Note what that compares: the lowered program with the interpreter running the *same* rewritten L1. It checks lowering, not the rewrites; whether the rewrites preserve the source program's behaviour is the refinement law's job ([Chapter 19](lab:book?ch=19)). The last line aggregates **metrics**, each a function of the program and the run with a direction (smaller or larger is better) and a unit. Counts are summed over the corpus; sizes that describe a worst case (the largest frame, the peak of live values, the peak root bytes) take the maximum, because a frame of 8 slots in one program and 20 in another needs 20, not 28.

`g.metric(name, fn, { dir, unit })` adds a metric. The experiments below use one more, a count of rewrite attempts (fired or refused, as recorded in `program.decisions`), as a proxy for how much work the optimiser does:

```js
g.metric('attempts', ({ program }) => program.decisions.filter(d => d.by !== 'promote-cells' && d.by !== 'assume').length,
  { dir: 'min', unit: 'count' });
```

It is a proxy, and it should be called one. `compileMs` measures real time, but it varies from run to run by more than the differences between these pipelines, so an objective built on it would rank noise.

## 20.3 Objectives

An **objective** turns rows of metrics into an order. The workbench's objectives are values like everything else:

| objective | ranks by |
|---|---|
| `g.objective.minimize('collections')` | one metric |
| `g.objective.weighted({ collections: 1, attempts: 1 })` | a weighted sum $\sum_k w_k m_k$, signs flipped for metrics where larger is better |
| `g.objective.lexicographic(['rootSlots', 'collections'])` | the first metric, then the second to break ties |
| `g.objective.pareto(['rootSlots', 'collections', 'attempts'])` | no order: the set of undominated points |
| `g.objective.require('correct', 'admitted').then(o)` | `o`, after moving every infeasible point to the end |

`require` expresses **feasibility**: a point that is not admitted, or not correct, is not a worse compiler but no compiler at all, and no weighting should be able to rank it above a working one. The corpus for this chapter is the ledger and the numeric `fib` from FACTS.md, and the design is the twelve compatible points. A grid search over them took 400 ms:

```js
const r = g.search.grid(d.where(g.constraint.compatible()), { corpus,
  objective: g.objective.require('correct', 'admitted').then(g.objective.weighted({ collections: 1, attempts: 1 })) });
```

> **Try it.** [Load X-01 A design space of pipelines](lab:preset?id=X-01), [open main.js](lab:open?file=main.js) and [show the Experiments](lab:show?view=experiments): a twelve-point design over the ledger with promotion as a third parameter, ranked by root slots.

The three points with `roots: 'none'` are not admitted ("f3 is borrowed by js.call at main/entry/1 but no root assigned") and rank last. The other nine are all correct. Figure 20.1 lays them out.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 250">
  <text x="20" y="20" font-size="10" class="lbl">rewrites →</text>
  <text x="150" y="40" font-size="11" class="b">none</text>
  <text x="320" y="40" font-size="11" class="b">canonical</text>
  <text x="500" y="40" font-size="11" class="b">standard</text>
  <text x="20" y="84" font-size="11" class="b">distinct</text>
  <text x="20" y="144" font-size="11" class="b">stackReuse</text>
  <text x="20" y="204" font-size="11" class="b">arena</text>
  <g font-size="10">
    <rect x="110" y="56" width="150" height="48" class="ink f-fill2" stroke="currentColor"/><text x="120" y="76">55 slots · 192 coll.</text><text x="120" y="94">0 attempts</text>
    <rect x="280" y="56" width="150" height="48" class="ink f-fill2" stroke="currentColor"/><text x="290" y="76">55 slots · 192 coll.</text><text x="290" y="94">3 attempts</text>
    <rect x="450" y="56" width="150" height="48" class="ink f-fill" stroke="currentColor"/><text x="460" y="76">54 slots · 94 coll.</text><text x="460" y="94">40 attempts</text>
    <rect x="110" y="116" width="150" height="48" class="acc f-sel" stroke="currentColor" stroke-width="1.6"/><text x="120" y="136">17 slots · 192 coll.</text><text x="120" y="154">0 attempts</text>
    <rect x="280" y="116" width="150" height="48" class="ink f-fill2" stroke="currentColor"/><text x="290" y="136">17 slots · 192 coll.</text><text x="290" y="154">3 attempts</text>
    <rect x="450" y="116" width="150" height="48" class="acc f-sel" stroke="currentColor" stroke-width="1.6"/><text x="460" y="136">17 slots · 94 coll.</text><text x="460" y="154">40 attempts</text>
    <rect x="110" y="176" width="150" height="48" class="ink f-fill2" stroke="currentColor"/><text x="120" y="196">55 slots · 192 coll.</text><text x="120" y="214">0 attempts</text>
    <rect x="280" y="176" width="150" height="48" class="ink f-fill2" stroke="currentColor"/><text x="290" y="196">55 slots · 192 coll.</text><text x="290" y="214">3 attempts</text>
    <rect x="450" y="176" width="150" height="48" class="ink f-fill" stroke="currentColor"/><text x="460" y="196">54 slots · 94 coll.</text><text x="460" y="214">40 attempts</text>
  </g>
  <text x="20" y="242" font-size="10" class="mut">exceptions: setjmp · roots: none not admitted (3 points, not shown) · corpus: ledger and fib</text>
</svg>
```

**Figure 20.1.** The nine admitted points of the design, measured: root slots summed over the corpus, collections under GC stress, and rewrite attempts. Accented: the two points on the Pareto frontier of section 20.5.

Two things are visible at once. Root slots depend only on the strategy (rewrites change them by one slot at most), and collections and attempts depend only on the rewrites. The standard rewrites cut collections under stress from 192 to 94, because narrowing turns `js.*` operations on known numbers into `num.*` operations, which do not allocate and so are not safepoints. Most of the gain is in `fib`, whose collections fall from 124 to 34; the ledger's fall from 68 to 60.

## 20.4 Where objectives disagree

The weighted objective with weights 1 and 1 scores the standard points $94 + 40 = 134$ and the points without rewrites $192 + 0 = 192$, so a standard point wins. Three points tie at 134 (the root strategy does not enter the sum), and the search keeps the first in the grid's order: `roots=distinct rewrites=standard`. Change the weight of attempts to 10 and the scores become $94 + 400 = 494$ against $192$: now `roots=distinct rewrites=none` wins. `g.rank.disagreement(results, a, b)` reports exactly this, the two winners and `disagree: true`.

Neither answer is wrong. The weights are a statement about how much one rewrite attempt costs compared with one collection, and the two experiments made different statements. A weighted objective hides that statement in two numbers. When the weights are the result of a measurement (attempts cost so many microseconds, collections so many), the sum is a prediction and can be tested; when they are chosen by feel, the ranking inherits the feeling.

The tie deserves notice too. A single weighted sum declared `distinct` as good as `stackReuse` because root slots were not in it. The lexicographic objective `['rootSlots', 'collections']` states a priority instead: first as few root slots as possible, then as few collections. It picks `roots=stackReuse rewrites=standard`, and it would pick it at any weights, because no amount of collections can outweigh one root slot under a lexicographic order.

## 20.5 The Pareto frontier

The honest answer to "which point is best?" when the metrics are not comparable is a set. A point $a$ **dominates** $b$ if it is at least as good on every metric and strictly better on one:

$$
a \succ b \iff \forall k.\; m_k(a) \le m_k(b) \;\wedge\; \exists k.\; m_k(a) < m_k(b)
$$

for metrics where smaller is better (for one where larger is better, the inequalities turn round). The **Pareto frontier** is the set of points no other feasible point dominates. The workbench's ranking computes it by the definition:

```js
// core.js
  if (obj.pareto) {
    const sign = m => (METRICS[m] && METRICS[m].dir === 'max' ? -1 : 1);
    const dom = (a, b) => obj.pareto.every(m => sign(m) * a[m] <= sign(m) * b[m]) && obj.pareto.some(m => sign(m) * a[m] < sign(m) * b[m]);
    const frontier = ok.filter(a => !ok.some(b => dom(b, a)));
    const rest = ok.filter(r => !frontier.includes(r));
    const ranked = [...frontier.map(r => ({ ...r, onFrontier: true })), ...rest.map(r => ({ ...r, onFrontier: false })), ...bad.map(r => ({ ...r, onFrontier: false }))];
    return { ranked, frontier: frontier.map(r => r.point) };
  }
```

`ok` holds the feasible rows and `bad` the infeasible ones. `sign` reads each metric's registered direction, so a metric where larger is better, such as `rewritesFired`, counts with its sign flipped and the definition above applies to every metric as "better or equal". The comparison is quadratic in the number of points, which is fine for a few hundred. Nothing is dropped: the result lists the frontier first, each of its rows marked `onFrontier`, then the dominated points, then the infeasible ones, so the Experiments view shows the whole space with the frontier on top.

Over root slots, collections and attempts the frontier of Figure 20.1 has two points: `stackReuse` with the standard rewrites (17, 94, 40) and `stackReuse` with no rewrites (17, 192, 0). Every other point is dominated by one of them: `distinct` and `arena` have more root slots at the same collections and attempts, and the canonical rewrites cost three attempts and save nothing on this corpus. The frontier does not choose between the two; it shows that the remaining choice is exactly the trade between optimiser work and collections, and that root strategy is not part of it.

## 20.6 A factorial study of root strategies

A design over one corpus answers "which pipeline for these programs". A **factorial study** varies the programs as a factor too and measures every combination, so the effect of the strategy can be seen per program. Five programs, three strategies, default rewrites, plan mode with GC stress; every one of the fifteen runs was correct:

| program | distinct | stackReuse | arena | peak root bytes (distinct, stackReuse, arena) |
|---|---|---|---|---|
| ledger | 52 | 15 | 52 | 304, 120, 248 |
| fib | 3 | 2 | 3 | 80, 72, 24 |
| throwing getter | 6 | 2 | 6 | 96, 64, 48 |
| points (objects in a loop) | 24 | 12 | 24 | 224, 136, 160 |
| word count over a string | 14 | 3 | 14 | 136, 48, 112 |

The first three columns are root slots summed over each program's functions. Figure 20.2 draws the first two.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 230">
  <g font-size="10">
    <text x="20" y="38">ledger</text>
    <text x="20" y="78">fib</text>
    <text x="20" y="118">getter</text>
    <text x="20" y="158">points</text>
    <text x="20" y="198">words</text>
  </g>
  <line x1="100" y1="20" x2="100" y2="210" stroke="currentColor" class="ink"/>
  <g stroke="currentColor" stroke-width="1">
    <rect x="100" y="24" width="468" height="12" class="ink f-fill2"/>
    <rect x="100" y="38" width="135" height="12" class="ink f-ink"/>
    <rect x="100" y="64" width="27" height="12" class="ink f-fill2"/>
    <rect x="100" y="78" width="18" height="12" class="ink f-ink"/>
    <rect x="100" y="104" width="54" height="12" class="ink f-fill2"/>
    <rect x="100" y="118" width="18" height="12" class="ink f-ink"/>
    <rect x="100" y="144" width="216" height="12" class="ink f-fill2"/>
    <rect x="100" y="158" width="108" height="12" class="ink f-ink"/>
    <rect x="100" y="184" width="126" height="12" class="ink f-fill2"/>
    <rect x="100" y="198" width="27" height="12" class="ink f-ink"/>
  </g>
  <g font-size="9" class="mut">
    <text x="574" y="34">52</text><text x="241" y="48">15</text>
    <text x="133" y="74">3</text><text x="124" y="88">2</text>
    <text x="160" y="114">6</text><text x="124" y="128">2</text>
    <text x="322" y="154">24</text><text x="214" y="168">12</text>
    <text x="232" y="194">14</text><text x="133" y="208">3</text>
  </g>
  <rect x="440" y="150" width="12" height="10" class="ink f-fill2" stroke="currentColor"/><text x="458" y="159" font-size="10">distinct</text>
  <rect x="440" y="168" width="12" height="10" class="ink f-ink" stroke="currentColor"/><text x="458" y="177" font-size="10">stackReuse</text>
  <text x="440" y="198" font-size="9" class="mut">root slots, 9 px per slot</text>
</svg>
```

**Figure 20.2.** Root slots per program under `distinct` (upper bar) and `stackReuse` (lower bar), measured with the default rewrites. `arena` plans the same number of slots as `distinct` and is not drawn.

The table says more than "stackReuse wins". The saving depends on the program: 71 % of the ledger's slots and 79 % of the word counter's disappear, two thirds of the getter's, half of the points program's and a third of `fib`'s. Programs with many short-lived objects that are never live at the same safepoint gain most, which is what the colouring of [Chapter 13](lab:book?ch=13) predicts.

The last column is a warning about measurement. By peak root bytes, `arena` beats both other strategies on `fib` (24 B against 72 B) and on the getter. That is not because it needs fewer slots; it plans as many as `distinct`. It is because the metric measures different things for different strategies: on the native stack a frame's bytes include the two fixed slots and the argument slots, while the arena's figure counts only the arena, and the fixed and argument slots still exist somewhere else. The project's own research notes make the same point about a real arena: it does not remove native argument storage or spills. A comparison is only as fair as the metric is uniform across the things compared, and the cure is to read what a metric measures before believing its ranking. [X-06 A factorial study of roots](lab:preset?id=X-06) runs a study of the same design in the page, three strategies across four programs, with its hypotheses and thresholds written down before the run; [X-07 Measuring a corpus](lab:preset?id=X-07) measures the seven J programs with one definition of each metric. [X-04 Constraints and feasibility](lab:preset?id=X-04) separates the three ways a point can fail: removed before compiling, not admitted, and admitted but wrong.

## 20.7 The running example: the ledger in the design

On its own the ledger shows the two axes of Figure 20.1 separately. Its root slots are 52 under `distinct`, 15 under `stackReuse` and 52 under `arena` (FACTS.md); its collections under stress are 68 with the canonical rewrites and 60 with the standard ones, because narrowing turns `total`'s `i++` (a `js.mul` and a `js.add`) into `num.mul` and `num.add`, which removes two safepoints per iteration: two iterations in each of the two calls to `total`, eight collections in all. A grid over the six points of `roots × rewrites` for the ledger alone puts `stackReuse` first under `minimize('rootSlots')`, tied between canonical and standard at 15 slots: the single-metric objective cannot see the collections, and the grid's order breaks the tie. The lexicographic objective `['rootSlots', 'collections']` breaks it on purpose, in favour of the standard rewrites.

> **Try it.** [Load B-01](lab:preset?id=B-01) and [ask the agent to search the design](lab:ask?q=Search%20g.design(%7B%20roots%3A%20g.param.choice(%5B'distinct'%2C'stackReuse'%2C'arena'%5D)%2C%20rewrites%3A%20g.param.choice(%5B'canonical'%2C'standard'%5D)%20%7D)%20over%20program.js%20and%20rank%20it%20two%20ways%3A%20minimize%20rootSlots%2C%20then%20lexicographic%20rootSlots%20then%20collections.) for this program. Then load [X-01 A design space of pipelines](lab:preset?id=X-01), [X-02 Objectives that disagree](lab:preset?id=X-02), [X-03 A Pareto frontier](lab:preset?id=X-03), [X-04 Constraints and feasibility](lab:preset?id=X-04) and [X-05 Your own metric](lab:preset?id=X-05), which take each step of this chapter on its own.

The shelf doc [Design spaces and objectives](lab:doc?id=design-spaces) summarises the vocabulary.

## 20.8 Key points

- A design is a product of parameters; a point is one pipeline, and constraints such as `g.constraint.compatible()` remove points that could never be admitted before any is compiled.
- A point is measured on a corpus: not admitted if any program fails to compile, correct if every lowered run equals the interpreter's, with counts summed and worst cases maximised.
- Objectives turn rows into an order: weighted sums encode a judgement in their weights, lexicographic orders encode priorities, and `require` keeps infeasible points out of contention.
- Two objectives can pick different winners from the same rows; the disagreement is the trade-off, and `g.rank.disagreement` shows it.
- The Pareto frontier is the set of undominated points; on the ledger and `fib` it has two points, which differ only in the trade between optimiser work and collections.
- A metric that measures different things for different points produces a ranking that looks precise and is wrong; arena frames counted without their fixed and argument slots are the example.

## Exercises

1. Add `g.param.choice([true, false])` for `frontend({ promote })` to the design of section 20.1 and rerun the grid. Which metrics does keeping every variable a cell change, and does the frontier move?
2. Find weights for `collections` and `attempts` at which the standard and no-rewrite points tie exactly, and explain what such weights would mean if they were measured.
3. Write a metric that counts root slots plus the fixed and argument slots for native frames and the arena's slots plus the same fixed and argument slots for `arena`, and redo the factorial table's last column with it.
4. Run `g.search.random` on the twelve compatible points with budgets 2, 4 and 6 and three seeds each. How often does it find a frontier point, and how does that compare with the grid's cost?
5. Project: make the corpus the J programs and design a study whose result could change the default root strategy. State, before you run it, what result would make you change it.

[Chapter 21](lab:book?ch=21) takes everything the workbench measures and checks and asks which of it survives contact with a real Hermes and LLVM build.
