# A Pareto frontier

On the screen are twelve compilations of two numeric loops, measured on three metrics that pull against each other: collections under GC stress, root slots, and the number of unchecked type assumptions. [X-02](lab:preset?id=X-02) collapsed such metrics into one score and got an answer that depended on the weights. This preset asks a weaker question that needs no weights: which points could be the right answer for *some* weighting?

> **Try it.** [Run main.js](lab:build) and [open Experiments](lab:show?view=experiments). The last column says whether each point is on the frontier; 3 of the 12 are, all with `roots=stackReuse` and `rewrites=standard`.

## Domination

A point **dominates** another when it is at least as good on every metric and strictly better on at least one. A dominated point is never the best choice, whatever the weights: the point that dominates it wins on every weighting with positive weights. The **Pareto frontier** is the set of points nothing dominates. `g.objective.pareto(['collections', 'rootSlots', 'assumptions'])` computes it:

```js
const metrics = ['collections', 'rootSlots', 'assumptions'];
const frontier = g.rank(results, g.objective.pareto(metrics)).frontier;
for (const row of results.rows) row.frontier = frontier.includes(row.point);
```

The search itself ranks by collections only, so the table has one readable order; the frontier is computed afterwards and added as a column. Searching with the Pareto objective directly (`objective: g.objective.pareto(metrics)`) also keeps all twelve rows, with the frontier first and each of its rows marked `onFrontier: true`.

## Reading the table

Nine points fall away, in two families. Every `distinct` point is dominated by its `stackReuse` twin: the same collections and assumptions, three more root slots (12 against 9 with no assumptions, for example), because the strategy changes only the plan. Every `canonical` point is dominated by its `standard` twin: the same root slots and assumptions, but 130 collections against 62, 21 or 16, because without narrowing the assumptions cannot remove a single safepoint.

The three survivors are the real choices:

| point | collections | root slots | assumptions |
|---|---|---|---|
| assume none | 62 | 9 | 0 |
| assume scale | 21 | 7 | 2 |
| assume both | 16 | 6 | 3 |

Each one buys fewer collections and fewer root slots with more assumptions. Which of them is right depends on how much an unchecked guess costs, which is a question about the system the compiler runs in (can it deoptimise when a guess fails?), not about the numbers.

> **Try it.** [Show scale](lab:fn?name=scale) at [L1](lab:level?l=L1): the program on the screen is the `assume both` point, and every operation in the loop is a `num.*` operation.

## Why the frontier is worth computing

A frontier turns a search of twelve points into a choice among three, and it does so without anyone having to agree on weights first. It also shows which parameters matter: here the root strategy and the rewrite set have a clear winner each, and only the assumptions are a genuine trade-off. That is a finding worth writing down before arguing about weights.

> **Exercise.** Add `steps` to the frontier's metrics and rerun. Does the frontier change? Then add `g.param.choice(['canonical', 'standard', 'none'])` for the rewrites (with `g.rewrites.none()`): where do the new points land?

## Where next

[Chapter 20](lab:book?ch=20) covers objectives and frontiers. [X-04](lab:preset?id=X-04) adds points that are not allowed at all, and the doc on [design spaces](lab:doc?id=design-spaces) summarises the objectives.
