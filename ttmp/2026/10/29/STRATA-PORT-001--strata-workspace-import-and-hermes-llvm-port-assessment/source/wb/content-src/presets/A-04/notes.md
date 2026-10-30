# Your own analysis: constants

The engine's solver is not tied to its own analyses. An **analysis** is a lattice, a direction, a transfer function for operations and, for block parameters, an edge rule; `g.solve` does the rest. This preset writes constant propagation in about twenty lines of `main.js`, runs it on `calc` from `program.ir`, shows the constants it finds, and then uses them in a rewrite of its own that folds `calc` down to `return 5`.

> **Try it.** [Show the table](lab:show?view=experiments) of constants, then [look at calc in L1](lab:fn?name=calc): only the comparison with the unknown `a` is left.

## The lattice

Each value is `⊥` (not seen yet), one number, or `⊤` (not a constant). That is `g.lattice.flat()`. The analysis state maps every value name to such an element, so the lattice is `g.lattice.map(flat)`, joined pointwise: where two paths meet, a value that is 20 on both stays 20, and one that is 0 on one path and 1 on the other becomes `⊤`. [A-01](lab:preset?id=A-01) checks the laws of both.

## The transfer function

```js
.transfer((op, state) => {
  if (!op.result) return state;
  const out = new Map(state), args = op.args.map(a => valueOf(state, a));
  if (args.includes(flat.BOT)) out.set(op.result, flat.BOT);
  else if (ARITH[op.op] && args.every(x => typeof x === 'number')) out.set(op.result, ARITH[op.op](...args));
  else out.set(op.result, flat.TOP);
  return out;
})
```

An operand is a value name or a literal `{ lit }`; `valueOf` looks names up in the state and reads literals directly. If any operand is `⊥` the result is `⊥` too (nothing is known yet, so nothing is claimed). If every operand is a number and the operation is one of four pure ones, the result is computed. Anything else is `⊤`. The function is monotone: raising an operand from `⊥` to a number to `⊤` never lowers the result.

## The edge rule and the boundary

Block parameters get their facts from edges, not from operations. The edge rule copies the value of each argument into the target's parameter:

```js
.edge((fn, from, e, state) => {
  const out = new Map(state);
  fn.block(e.block).params.forEach((p, i) => out.set(p.id, valueOf(state, e.args[i])));
  return out;
});
```

`.init` sets the function's own parameters to `⊤`: `a` could be anything a caller passes. Without it they would start at `⊥` and the analysis would claim knowledge it does not have.

## What it finds

[Open program.ir](lab:open?file=program.ir&find=fn%20calc). The solver needs 4 block visits. `v1` is 5 and `v2` is 20 in `entry`; `v3 = num.lt(a, 10)` is `⊤` because `a` is. Both arms receive `v2`, so `s` and `l` are 20. In `small`, `v4 = 20 - 20 = 0`; in `large`, `v5 = 20 + a` is `⊤`, but `large` passes the literal `0` to `done`, not `v5`. So `r` is 0 on both incoming edges, `k` is 5, and `v6 = r + k` is 5: the function returns 5 whichever way the branch goes, which no single path shows by itself.

> **Try it.** In program.ir, change `jump done(0, v1)` in `large` to `jump done(v5, v1)` and [rerun](lab:build). `r` and `v6` become `⊤`, and the fold keeps the addition.

## Using the facts

`fold-by-constants` matches every operation in `calc` whose result the analysis found constant and replaces its uses by the literal. `erase-dead-result` then deletes `v5`, which nothing uses any more. [Events](lab:show?view=events) lists five decisions, all fired. The output of `main` is still `5 5`. What remains, [the num.lt in entry](lab:node?id=calc/entry/0), is a comparison whose result decides between two blocks that do the same thing: removing it needs a rewrite that merges identical successors, which the standard set does not have.

> **Exercise.** Add `g.rewrites.copyProp` and `'simplify-branch'` to the rewrite set in main.js. Does anything more disappear? Then extend `ARITH` with `num.div` and write a program.ir edit where the analysis proves a division by zero, and decide what the transfer function should say about its result.

## Where next

[Chapter 8](lab:book?ch=8) builds this analysis step by step and proves that the solver finds the least fixed point. The doc [Lattices and the fixed-point theorem](lab:doc?id=lattices) has the theory; [A-05](lab:preset?id=A-05) moves to a lattice of infinite height; [T-03](lab:preset?id=T-03) writes rewrites with side conditions.
