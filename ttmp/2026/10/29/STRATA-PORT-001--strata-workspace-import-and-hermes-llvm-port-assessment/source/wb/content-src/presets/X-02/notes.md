# Objectives that disagree

On the screen are six compilations of the same two numeric loops, `mean` and `scale`, and two objectives that rank them differently. The design has two parameters: the rewrite set (`canonical` or `standard`) and how many parameter types to **assume** (none; `scale`'s `k` and `n`; or those plus `mean`'s `n`). An assumption is what a JIT would guess from watching the program run: it lets narrowing turn `js.*` operations into `num.*` ones, which never run user code and never collect. It is also unchecked, so it is a cost. The two objectives weigh that cost differently, and the [Experiments view](lab:show?view=experiments) shows both verdicts in its note.

> **Try it.** [Run main.js](lab:build) and read the first line in [Events](lab:show?view=events): the weighted objective picks `rewrites=standard assume=scale`, the lexicographic one `rewrites=standard assume=none`.

## What an assumption buys

[Show scale](lab:fn?name=scale). With the standard rewrites and no assumptions, the facts already know `acc` and `i` are numbers after one step of the loop, so `num.add` and `num.mul` appear for them, but `js.lt(i5_1, n)` and `js.mul(k, i5_1)` stay general: `k` and `n` could be anything. With `assume: { scale: { k: 'number', n: 'number' } }` every operation in the loop is a `num.*` operation, and none of them is a safepoint. Under GC stress the whole program collects 62 times without assumptions, 21 times with `scale`'s two, and 16 times with all three. With the canonical rewrites assumptions do not change collections at all (130 every time), because nothing narrows; they only shrink the root plan, from 9 slots to 7 to 6, since a value known to be a number needs no root.

## Counting the risk

The custom metric at the top of `main.js` counts assumptions:

```js
g.metric('assumptions', ({ program }) => program.summary().assume.length,
  { dir: 'min', unit: 'count', about: 'unchecked parameter-type assumptions' });
```

After `g.metric` registers it, every row of the search has an `assumptions` column, and objectives can use it like any built-in metric. ([X-05](lab:preset?id=X-05) writes metrics of its own.)

## Two objectives, two winners

```js
const weighted = g.objective.weighted({ collections: 1, assumptions: 10 });
const lexico = g.objective.lexicographic(['assumptions', 'collections']);
```

The **weighted** objective adds up a score: one point per collection, ten per assumption. `assume=none` scores 62, `assume=scale` 21 + 20 = 41, `assume=both` 16 + 30 = 46, so the middle point wins: two assumptions buy 41 fewer collections, the third buys only 5. The **lexicographic** objective compares assumptions first and looks at collections only to break ties, so any assumption loses to none, and among the points with none the standard rewrites win with 62 against 130.

Neither objective is wrong. They encode different positions: one says an assumption is worth ten collections, the other says no number of collections justifies an unchecked guess. `g.rank.disagreement(results, weighted, lexico)` returns both rankings and whether their winners differ; when they do, the trade-off is real and the choice belongs in a decision record ([M-05](lab:preset?id=M-05)), not in an objective.

> **Exercise.** Change the weight of an assumption from 10 to 30 and rerun. At what weight does the weighted objective agree with the lexicographic one? Then add `steps` to the weighted objective: why does it change nothing here?

## Where next

[Chapter 20](lab:book?ch=20) treats objectives and where they disagree. [X-03](lab:preset?id=X-03) keeps all three metrics and asks which points no other point beats, and [W-02](lab:preset?id=W-02) uses the same assumptions to reach WebAssembly.
