# Your own metric

On the screen is a search ranked by two metrics that the workbench does not ship: the number of **safepoints** in the compiled program, and the bytes its root plans reserve per call. Both are a few lines in `main.js`. A metric is a name, a function that reads a compiled program (and its run) and returns a number, and a direction; once registered, every search row has a column for it and every objective can use it.

> **Try it.** [Open main.js](lab:open?file=main.js&line=8) and [run it](lab:build). The [Experiments view](lab:show?view=experiments) has two new columns, `safepoints` and `frame bytes`, and the winner is `roots=stackReuse rewrites=standard` with 41 safepoints and 280 B.

## Writing one

```js
g.metric('safepoints', ({ program }) =>
  fnNames(program).reduce((n, f) => n + Object.keys(program.plan(f).safepoints).length, 0),
  { dir: 'min', unit: 'count', about: 'operations that may collect, over all functions' });
```

The function receives `{ program, run }`: the Program compiled at one design point for one corpus item, and its run in plan mode under GC stress. It can read anything the Program offers (`plan`, `facts`, `cfg`, `metrics`, `decisions`); here it counts the keys of each function's `safepoints` map, which holds one entry per operation that may collect. Search sums a metric over the corpus. `dir: 'min'` says smaller is better, which matters to `weighted` and `lexicographic` objectives; `unit` labels the column.

## Why count safepoints

Every safepoint is a call into the runtime that may move objects. It costs the call, and it constrains the root plan, because every managed value live across it needs a slot. Fewer safepoints mean cheaper code and a smaller plan, which makes the count a fair proxy for how much a pipeline left for the runtime to do. On the ledger the standard rewrites remove two of 43: in `total`, the increment `i++` lowers to `js.mul(i, 1)` and `js.add(n, 1)`, and once the facts show `i` is a number both narrow to `num.mul` and `num.add`, which never collect.

> **Try it.** [Show total](lab:fn?name=total) with [the safepoints overlay](lab:overlay?name=safepoints&on=1): the block `next3` has no markers, while the `js.get` and `js.lt` in `for1` keep theirs, since `log` is still an unknown value.

## The second metric

`frameBytes` adds up what each function's plan reports as its frame in bytes. On the native stack that is the root slots, the two fixed slots and the argument area, eight bytes each: 280 B for the six functions of the ledger under `stackReuse`, 568 B under `distinct`. For `arena` the number is a different thing, a 32 B record header plus 8 B per slot in runtime-owned memory, so 600 B there is not native stack at all. A metric is only as meaningful as its definition, and this one is worth reading twice before it decides anything.

## Ranking with it

The objective is `g.objective.lexicographic(['safepoints', 'frameBytes'])`: fewest safepoints first, then the smallest frames. The rewrite set decides the first comparison (41 against 43), the root strategy the second (280 B against 568 B and 600 B). Changing the root strategy never changes the safepoint count, because the strategy decides where values are kept, not which operations collect.

> **Exercise.** Write a metric `cellLoads` that counts `cell.load` and `cell.load_checked` operations over all functions (use `program.cfg(f).blocks` and each block's `ops`). Add a `promote` parameter to the design and rank by it: how many loads does promotion save on the ledger?

## Where next

[Chapter 20](lab:book?ch=20) treats metrics and objectives. [X-07](lab:preset?id=X-07) measures a corpus with metrics like these, and [L-03](lab:preset?id=L-03) explains why the root strategies differ by so much.
