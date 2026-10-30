# Core IR by hand

Core IR is the language every other part of the workbench reads and writes. This preset writes three functions in it directly, with the builder `g.fn`, instead of getting them from the JavaScript frontend: `fib` with a loop, `choose` with a branch and a merge, and `main`, which calls both and prints `55 20`.

> **Try it.** [Open main.js](lab:open?file=main.js&line=6) next to [fib on the Stage](lab:fn?name=fib). Every block in the drawing is one `f.block` call in the file; every labelled edge is one `f.to`.

## A function is blocks

`g.fn(name, params, result, body)` makes a function. The body receives a builder `f` and the parameters by name, and adds blocks:

```js
const fib = g.fn('fib', { n: t.number }, t.number, (f, { n }) => {
  f.entry($ => $.jump(f.to('head', $.const(0), $.const(0), $.const(1))));
  f.block('head', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.branch($.op('num.lt', i, n), f.to('body', i, a, b), f.to('exit', a)));
```

Each block's callback gets a cursor `$` that appends operations (`$.op`, `$.call`, `$.const`) and ends the block with exactly one **terminator** (`$.jump`, `$.branch`, `$.ret`, `$.throw`). `f.to(block, ...args)` makes an **edge**: a target block and the arguments it passes. `$.op` returns the name of its result, `v1`, `v2` and so on, so values are passed around as strings.

## Block parameters instead of phi nodes

The loop in `fib` keeps three values, `i`, `a` and `b`, that change every turn. In core IR they are the parameters of the block `head`, and every edge into `head` must pass three arguments: `jump head(0, 0, 1)` from `entry`, `jump head(v2, b1, v3)` from `body`. [Select the back edge's block](lab:node?id=fib/body) to see it pass the new values. A value defined once and never assigned again is **static single assignment** (SSA); block parameters are how SSA joins values from several predecessors without a special phi operation.

The names `body` uses are `i1`, `a1` and `b1`, not `i`, `a` and `b`: a function has one namespace, so the builder freshens a repeated parameter name. That is why the callback hands the names back (`($, { i, a, b }) => …`); use the names it gives you, never the strings you asked for.

> **Try it.** [Show the IR view](lab:show?view=ir) at [L1](lab:level?l=L1): the printed text is exactly what the builder made, `fib` in 13 lines.

## A merge is a parameter too

`choose(c)` branches to `left` or `right`, and each jumps to `join` with its own constant. `join(v)` receives whichever was sent. [Select join](lab:node?id=choose/join): one parameter, two incoming edges, no operation that "picks" between them.

## A call needs somewhere to throw

`main` calls `fib` and `choose` with `$.call`, which emits `core.call(@fib, 10)`, a direct call. The verifier cannot see into the callee, so it treats a call as an operation that may throw, and every block with such an operation must say where a throw goes. Without the last argument of `f.entry` the program fails `verify` with `core.call may throw but entry has no exceptional exit`; with `{ onThrow: 'unwind' }` the block is headed `entry throws unwind:` and a throw leaves `main`.

> **Exercise.** Delete `, { onThrow: 'unwind' }` from main.js and rerun: read the diagnostic in [Events](lab:show?view=events). Then add a fourth parameter to `body`'s edge (`f.to('head', …, $.const(0))`) and read what `verify` says about arity.

## What the facts make of it

All of `fib` is in the core set, so it binds to inline instructions at L2 and needs no root slots. `main` needs none either: the type facts give the result of a direct call the callee's declared result type, so `v1` is a `number` because `fib` is declared `-> number`, and `v2` a `number` because `choose` is. Nothing managed is live across the three safepoints, and [the L3 plan](lab:level?l=L3) reads `0 root slots + 2 fixed + 1 argument = 3 slots, 24 B`. The whole module is also in the core profile, so [running it as Wasm](lab:run?mode=wasm) prints the same `55 20`.

> **Exercise.** Change `fib`'s declared result in main.js from `t.number` to `t.any` and rerun. How many root slots does `main` get now, and what does the WAT view say about `main`?

## Where next

[Chapter 3](lab:book?ch=3) defines core IR and the verifier's rules. [I-02](lab:preset?id=I-02) prints and parses the same functions as text, [I-03](lab:preset?id=I-03) gets a loop from JavaScript, and [I-04](lab:preset?id=I-04) breaks the rules on purpose.
