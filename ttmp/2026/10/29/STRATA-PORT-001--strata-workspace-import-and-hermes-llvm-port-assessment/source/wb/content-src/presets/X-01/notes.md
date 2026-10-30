# A design space of pipelines

On the screen is a search over twelve compilers. `main.js` defines a **design**: a function from a point (one value for each of three parameters) to a pipeline. The parameters are the root strategy (`distinct`, `stackReuse`, `arena`), the rewrite set (`canonical`, `standard`) and whether the frontend promotes cells to SSA values (`true`, `false`). A grid search compiles the ledger at every point, runs each compiled program in plan mode under GC stress and in the specification, and writes one row per point in the [Experiments view](lab:show?view=experiments).

> **Try it.** [Open main.js](lab:open?file=main.js&line=4) and [run it](lab:build). The table has twelve rows, every one admitted and correct, ranked by root slots; the default point, which the other views show, is first.

## A design is a value

```js
const design = g.design({
  roots: g.param.choice(['distinct', 'stackReuse', 'arena'], { default: 'stackReuse' }),
  rewrites: g.param.choice(['canonical', 'standard'], { default: 'canonical' }),
  promote: g.param.choice([true, false], { default: true }),
}, p => g.pipeline()
  .roots(p.roots)
  .rewrites(g.rewrites[p.rewrites]())
  .frontend({ promote: p.promote }));
```

Nothing runs when this is written. `design.size()` is `{ raw: 12, points: 12 }` (the Events view prints it), `design.defaults()` is the point made of every parameter's default, `design.at(point)` is the pipeline for one point, and `design.where(pred)` restricts the space without changing the parameters. Because pipelines are immutable values, the design can hand out twelve of them without any of them affecting another.

## What a row holds

For each point and each corpus item, `g.search.grid` compiles, checks that the program was **admitted** (no compile errors), runs it in plan mode with GC stress and in the specification, and marks it **correct** when the two runs are observably equal. Then it reads the metrics: `rootSlots`, `maxFrameSlots`, `peakLive`, `collections`, `steps`, `compileMs`. Every number in the table comes from those runs, so a row is evidence, not an estimate.

## What the table says about the ledger

Three things stand out. First, the root strategy changes the plan and nothing else: `distinct` needs 52 root slots where `stackReuse` needs 15, but the steps, the collections and the output are the same, because the strategy only decides where values are kept. Second, `arena` reserves as many slots as `distinct` (52) but its largest frame is smaller, 20 slots against 24, because the plan counts an arena function's frame as its slots in a runtime-owned record, without the two fixed slots and the argument area of a native frame. Third, turning promotion off costs everywhere: with `stackReuse` the ledger needs 19 root slots instead of 15, 187 steps instead of 134 and 100 operations instead of 78, because every variable stays a cell and every use is a load or a store.

> **Try it.** Find the two rows with 15 root slots. They differ only in the rewrite set: `standard` takes 133 steps and 60 collections against 134 and 68. The objective, `minimize('rootSlots')`, cannot tell them apart and keeps the first.

## Ties and what to do about them

A single metric ranks by one number, and two points with the same number are equal to it. That is not a flaw of the search: it is the objective saying it does not care. If collections should break the tie, say so with `g.objective.lexicographic(['rootSlots', 'collections'])`; if two metrics trade against each other, [X-02](lab:preset?id=X-02) and [X-03](lab:preset?id=X-03) show what to do instead of picking one.

> **Exercise.** Add a fourth parameter, `assume: g.param.choice([{}, { total: { this: 'object' } }])`, pass it to `.assume(...)`, and rerun. How many points does the design have now, and does any row change? Then restrict the design with `design.where(p => p.roots !== 'arena')` and compare the sizes.

## Where next

[Chapter 20](lab:book?ch=20) covers designs, metrics and search. The doc on [design spaces](lab:doc?id=design-spaces) explains objectives in general, and [X-06](lab:preset?id=X-06) turns a comparison like this one into a study with hypotheses.
