# Passes and their requirements

A **pass** is a step of the compiler: a function from the compilation state to a new one, at a stated level (`L0` source, `L1` core IR, `L2` bound to helpers, `L3` with the root plan). Each pass declares what it **requires** (facts an earlier pass must have provided) and what it **provides**, and a pass may **invalidate** facts it makes stale. A **pipeline** is a list of passes plus strategies, and `pipeline.check()` follows the declarations from the first pass to the last before anything runs. On the screen, `main.js` inserts a pass of its own into the default list and builds two pipelines that `check()` refuses.

> **Try it.** [Show the table](lab:show?view=experiments): ten passes, with what each requires and provides, and the note each wrote into the trace. Then [show Events](lab:show?view=events) for the two refusals.

## The default list

`frontend` turns source into core IR and provides `core-ir`. `promote-cells` builds SSA (9 cells promoted here). `verify` checks the IR and provides `verified`. `rewrite` runs the rewrite set and invalidates `analyses`: rewriting changes the IR, so any liveness or types computed earlier would describe a different program. `analyze` computes liveness, safepoints, types and dominators once, after rewriting. `lower-runtime` requires `types` (it chooses representations from them) and provides `runtime-bound`. `plan-roots` requires the binding, liveness and safepoints and provides the root and unwind plans, which `check-plan` and `emit-llvm` require.

## A pass of our own

```js
const countOps = g.pass('count-ops').from('L1').to('L1').requires('verified')
  .run(st => {
    let n = 0;
    for (const fn of st.module.functions.values()) for (const b of fn.blocks) n += b.ops.length;
    return `${n} operations after rewriting`;
  });
const pipe = g.pipeline().insert(countOps, { after: 'rewrite' });
```

The body receives the state (`st.module`, `st.diagnostics`, `st.decisions`, `st.facts`, `st.plans`) and returns a note for the trace. It only reads, so it provides nothing and invalidates nothing. `insert` returns a new pipeline; `g.pipeline()` itself is unchanged. The table's fifth row shows it ran, with the note `14 operations after rewriting`.

> **Try it.** [Open main.js](lab:open?file=main.js&find=after%3A%20'rewrite') and change `after: 'rewrite'` to `after: 'emit-llvm'`. [Rerun](lab:build): the pass still checks (everything it needs was provided long before) and now runs last.

## Two refusals

The first pipeline lists the passes by hand and leaves out `analyze`. `check()` reports both consequences: `lower-runtime needs types, which no earlier pass provides; plan-roots needs liveness, safepoints, which no earlier pass provides`. The second inserts `count-ops` before `verify`, and is refused because nothing has provided `verified` yet. Both are found by reading declarations, not by running passes, so a malformed pipeline costs nothing.

`stopAfter('L1')` keeps only the passes up to that level: Events lists `frontend, promote-cells, verify, rewrite, analyze`. That is how a preset shows a program before lowering.

## Why declarations

Declared requirements make the pass list data that can be checked, reordered and searched: a design space of pipelines ([X-01](lab:preset?id=X-01)) can include different pass orders, and `check()` removes the impossible ones before any compile. The declarations are promises, as behaviours are: a pass that reads liveness without requiring it would work by accident in the default order and break in another. The invalidation of `analyses` by `rewrite` is what prevents the most common such accident, using facts about a program that has since changed.

> **Exercise.** Write a pass `report-safepoints` that requires `safepoints` and returns the number of safepoints in each function (from `st.facts[name].safepoints`). Insert it where it checks, then try to insert it right after `rewrite` and read the refusal.

## Where next

[Chapter 11](lab:book?ch=11) covers passes and pipelines and why correct passes compose. [T-07](lab:preset?id=T-07) treats pipelines as values; the doc [Refinement and why passes compose](lab:doc?id=refinement) has the argument.
