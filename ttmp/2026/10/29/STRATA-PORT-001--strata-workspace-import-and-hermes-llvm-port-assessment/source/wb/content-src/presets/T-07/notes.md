# Pipelines as values

A pipeline in the workbench is an immutable value. `p.roots('distinct')` does not change `p`; it returns a new pipeline that differs in one slot, so a variant is a branch, not an edit. That makes pipelines easy to compare, store, hash and search over. `main.js` builds seven pipelines from one base, compiles the ledger with each, and lists their hashes, resolved strategies and results.

> **Try it.** [Show the table](lab:show?view=experiments), then [show Events](lab:show?view=events): the base pipeline's hash is the same before and after all seven variants were made from it.

## Branching

```js
const base = g.pipeline();
const before = base.hash();
// …
'base.roots(distinct)': base.roots('distinct'),
```

Each method of a pipeline returns a new pipeline with one slot changed: `profile`, `assume`, `provide`, `rewrites`, `roots`, `exceptions`, `representation`, `checks`, `passes`, `insert`, `stopAfter`. Because none of them mutates, `base` can be shared freely: by two presets, by a design space with forty points, by the agent trying an idea. The table's first two rows differ only in the root strategy, and the plan shows the cost: 15 root slots with `stackReuse` against 52 with `distinct`, for the same output.

## Presets are functions

A **preset** is a function from pipeline to pipeline:

```js
const optimised = p => p.rewrites(g.rewrites.standard());
const lean = p => p.roots('stackReuse');
const spacious = p => p.roots('distinct');
```

`base.use(optimised, spacious)` applies them in order. Presets compose by function composition, a later one overriding an earlier one's slot. `use(optimised)` gives 7 rewrite rules and 77 operations, one fewer than the canonical 78; adding `spacious` takes the root slots to 51. `with(f)` applies a single local function and `set(key, value)` is the raw escape hatch for a key no method covers; `set` changes the hash but nothing the compiler reads, as the last row shows.

## Hashes

`p.hash()` hashes what the pipeline will do: its resolved summary (every slot, defaults filled in), the hashes of its passes, and the source text of any lambda strategy. Two pipelines that resolve to the same configuration hash equally even if built differently: `use(optimised, lean)` and `use(optimised)` both print `cbe33fa7`, because `stackReuse` is the default. A hash is what a cache keys on, and what an experiment records so that a result can be traced to the exact configuration that produced it.

> **Try it.** Add `'base.roots(stackReuse)': base.roots('stackReuse'),` to the variants and [rerun](lab:build). Its hash equals the base's: the default made explicit is still the default.

## summary() shows every default

`p.summary()` resolves every slot: profile, frontend options, providers per operation set, rewrite names, strategies, materialiser and target, checks, the pass list. [Ask the agent](lab:ask?q=Show%20me%20g.pipeline().summary()%20and%20explain%20each%20default) for the base pipeline's summary, or read it in the Inspector's Pipeline panel on the Stage. Nothing is implicit: a default the summary does not show would be one the hash could not see.

## Why this matters for correctness

If passes refine programs, a pipeline built from them refines too, whatever the order its presets set the slots in ([the refinement doc](lab:doc?id=refinement)). The output column shows it on one input: seven pipelines, one observable result. The hash shows which configuration a counterexample came from, should one appear.

> **Exercise.** Write a preset `debug` that turns off the GC-safety check (`.checks({ gcSafety: false })`) and stops after L3 (`.stopAfter('L3')`). Apply `base.use(debug, optimised)` and `base.use(optimised, debug)`. Do they hash the same? Should they?

## Where next

[Chapter 11](lab:book?ch=11) develops pipelines as values. [B-02](lab:preset?id=B-02) changes one default at a time on the ledger; [T-06](lab:preset?id=T-06) covers passes; [X-01](lab:preset?id=X-01) searches a space of pipelines.
