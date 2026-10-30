# Behaviours and their join

On the screen are six small functions, each doing one kind of thing: `add` uses `+`, `same` uses `===`, `make` builds an object, `read` reads a property, `reset` writes a variable that `main` shares, and `bump` does both of the last two with `+`. `main.js` computes one **behaviour summary** per function, the join of the behaviours of its operations, and shows them as a table in Experiments. The point is that a summary is an upper bound on what code may do, and that upper bounds combine by join.

> **Try it.** [Show the table](lab:show?view=experiments), then [select the js.add in add](lab:node?id=add/entry/0) and compare its contract in the Inspector with [the js.strict_eq in same](lab:node?id=same/entry/0).

## What a behaviour records

Every operation in the engine carries a behaviour: which resources it may read and write (`heap`, `cells`, `jobs`, `timers`, `globals`), whether it may create a fresh identity, throw, diverge, run user code, or talk to the host. `js.strict_eq` records nothing, so its behaviour prints as `none`. `obj.new` records `fresh`. `cell.store` records `reads+writes(cells)`. `js.add` records `callsUser`, because `a + b` on objects calls `valueOf` or `toString`, and that code may do anything a program can do. The engine expands `callsUser` to every user resource, plus throwing, diverging, fresh identities and the host.

The table's rows follow from this. `same` is `none`. `make` is `reads+writes(heap), fresh`: one allocation joined with one `js.define`. `reset` is `reads+writes(cells)`. `add`, `read` and `bump` are all `callsUser`, and `main` is `callsUser` because it calls them.

## Join is a union of bounds

The join of two behaviours may do whatever either may do: it unions the resource sets and ors the flags. That makes join **associative**, **commutative** and **idempotent**, with `fx.none` as the unit and `fx.unknown` as the top. These are the laws of a join-semilattice, and `main.js` checks them on 2,000 generated pairs and triples:

```js
laws: g.laws([g.law.join()]),
```

[The Laws view](lab:show?view=laws) shows `join(fx)` passing. The order that goes with the join is `a ⊑ b` exactly when `a ⊔ b = b`; `summary.le(fx.callsUser)` tests it. The script also prints that `callsUser ⊑ unknown` holds and `unknown ⊑ callsUser` does not: `unknown` additionally writes the `engine` resource (roots, code memory), which user code cannot reach.

> **Try it.** [Open main.js at the join](lab:open?file=main.js&find=fx.join) and change it to `fx.join(...defs.map(d => d.behaviour), fx.throws)`. [Rerun](lab:build): `same` becomes `throws`, and its last column turns false.

## Why a summary loses precision

A summary is sound if it is above everything the code can do, and it is useful only if it is not far above. Two places in the table show the cost of joining.

`bump` is `callsUser` although it only adds 1 to a counter: the engine does not know `count` is a number, so `count + 1` might call `valueOf` on an object. [Select bump's js.add](lab:node?id=bump/entry/1). Narrowing it to `num.add` needs a type fact ([C-06](lab:preset?id=C-06) and [T-04](lab:preset?id=T-04)).

`make` has `erase an unused call: false` because `js.define` writes the heap. The write goes to the object `make` has just created, which nobody else can see, but the join keeps only "writes heap" and forgets which object. Recovering that needs a finer resource (this object, not the heap) or an analysis of escaping identities; the workbench keeps resources coarse.

> **Exercise.** Add `function both(o) { return same(1, 2) || read(o); }` to program.js and call it from `main`. Predict its summary before you rerun. Then replace `read(o)` with `o === null` and predict again.

## How the summaries are used

Behaviours are the input to everything in Part III of the book. Permissions (may this operation be erased, moved, merged, hoisted?) are derived from them in [C-03](lab:preset?id=C-03); the last column of the table is one such permission applied to a whole function. Obligations, which say what lowering must provide around an operation rather than what it may do, are a separate summary in [C-02](lab:preset?id=C-02).

## Where next

[Chapter 6](lab:book?ch=6) develops behaviours and contracts; the doc [Behaviours, obligations, permissions](lab:doc?id=effects) is the short version. [C-05](lab:preset?id=C-05) writes an operation with its own behaviour, and shows what happens when the behaviour lies.
