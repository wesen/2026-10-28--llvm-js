# Measuring a corpus

On the screen is one row per program for the seven JavaScript scenarios [J-01](lab:preset?id=J-01) to [J-07](lab:preset?id=J-07), copied into this preset's files, each compiled with the default pipeline and measured. The question is the one a compiler team asks before building an optimisation: in ordinary code, how many operations is the optimiser allowed to touch at all? Over the corpus the answer is printed in [Events](lab:show?view=events): 347 operations, 156 of which may run user code (45 %), and 16 that are pure.

> **Try it.** [Run main.js](lab:build) and [open Experiments](lab:show?view=experiments). Sort by eye: the tokenizer has the highest share of operations that may run user code, 60 %, and the resource handler the lowest, 36 %.

## Classifying by contract

Every operation has a contract, and its behaviour says what it may do. `main.js` sorts operations into three classes by reading `g.ops[name].behaviour`:

```js
const classOf = name => {
  const b = g.ops[name].behaviour;
  if (b.callsUser) return 'user';
  return String(b) === 'none' ? 'pure' : 'other';
};
```

**Pure** operations (`js.typeof`, `js.strict_eq`, `js.truthy`, `completion.is`) may be erased, merged, moved or duplicated freely. **User** operations (`js.add`, `js.get`, `js.call`, `js.lt`, `js.put`) may run a getter, a `valueOf` or a whole function, so every permission is refused. **Other** operations allocate, touch cells or talk to the host (`obj.new`, `cell.load`, `js.closure`, `host.print`): some permissions survive, depending on what exactly they do. In this corpus `js.add` alone accounts for 45 of the 156 user operations, `js.call` and `js.get` for 34 each.

## What the numbers mean for an optimiser

Nearly half of the operations block every transformation until something proves more about their operands. That is the measurement behind narrowing: `js.add` becomes `num.add` once both operands are known numbers, and with it the operation moves from the user class to the pure one. [T-04](lab:preset?id=T-04) shows narrowing working on one function; this table shows how much there is to win across several. The 16 pure operations, by contrast, are almost all comparisons and type tests that were cheap to begin with.

## The other columns

`cellsPromoted` and `cellsKept` count variables: promotion turned 74 cells into SSA values across the corpus, and 15 stay cells because a closure captures them or a handler needs them (J-07's `sum`). `safepoints` counts operations that may collect, and `rootSlots` what the plans reserve for them. `steps` and `collections` come from runs: the recursion scenario dominates both with 4,832 steps and 2,301 collections under stress, more than the other six programs together. Every row ends with `plan = spec: true`, the check that the compiled programs still do what their source says.

> **Try it.** [Ask the agent](lab:ask?q=Which%20operation%20would%20most%20reward%20better%20type%20facts%20in%20this%20corpus%3F) which operation would most reward better type facts. It can run `main.js`'s classification itself and count by operation name.

## Limits of a corpus like this

Seven programs written to show compiler features are not a sample of JavaScript as people write it; a corpus for a real decision would be applications and test suites, measured the same way. The measurement itself carries over unchanged: it is defined once, over contracts, and any program the frontend accepts can be fed to it. The useful habit is to write the measurement before the optimisation, so the optimisation is judged against a number.

> **Exercise.** Compile the corpus with `g.pipeline().rewrites(g.rewrites.standard())` and add a column for the share of user operations after narrowing. Which program changes most? Then add the ledger (copy [B-01](lab:preset?id=B-01)'s `program.js` into a new file and list it in `corpus`).

## Where next

[Chapter 20](lab:book?ch=20) covers measurement and experiments. [X-06](lab:preset?id=X-06) runs a study with hypotheses on part of this corpus, and [C-03](lab:preset?id=C-03) lists the permissions each behaviour leaves.
