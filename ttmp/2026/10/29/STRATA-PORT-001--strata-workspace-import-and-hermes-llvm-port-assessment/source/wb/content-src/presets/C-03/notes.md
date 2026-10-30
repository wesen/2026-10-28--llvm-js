# Derived permissions

A transformation needs to know what it may do with an operation: delete it, merge two copies of it, move it, run it twice, lift it out of a loop, or run it where the program would not have. The engine never declares these **permissions**. `g.perm(op)` derives each one from the operation's behaviour, as `true`, `false` or a condition, with the reasons. The table in Experiments lists nine standard operations; the program is a scaler whose inner loop reads a captured variable.

> **Try it.** [Show the table](lab:show?view=experiments). Then [select the cell.load in the loop](lab:node?id=arrow/body2/1): the Inspector lists the same six answers for this one site, with the reasons under each.

## The six questions

- **erase**: delete it when its result is unused.
- **merge**: replace a second evaluation by the first one's result.
- **move**: reorder it with its neighbours.
- **duplicate**: evaluate it twice where it ran once (in both arms of a split).
- **hoist**: evaluate it once before a loop instead of on every turn.
- **speculate**: evaluate it on a path where the program would not have.

The derivation looks at what could make each one visible. Writing a resource, throwing, diverging, running user code and talking to the host are all visible, so any of them refuses erase, duplicate, hoist and speculate. Reading a resource is invisible by itself, but the value read can change, so merge, move and hoist become conditions on writes to that resource. A fresh identity is visible only if something compares it, so `obj.new` gets `erase: if its new identity is never observed` and refuses merge and duplicate: two allocations are two objects.

## Reading the table

`num.add` and `js.strict_eq` have behaviour `none` and every permission. `cell.load` reads `cells`, so it may be erased and duplicated, and the others become conditions:

```js
print('cell.load, hoist:', JSON.stringify(g.perm.explain('cell.load', 'hoist')));
```

[Events](lab:show?view=events) shows the answer: `"if nothing in the loop writes cells"`. `cell.store` writes `cells` and refuses everything except a condition on moving. `cell.load_checked` throws in the temporal dead zone, which is enough to refuse erase, merge, duplicate, hoist and speculate. `host.print` and `js.get` refuse all six: one talks to the host, the other may run a getter.

## A condition meets a real loop

[Open program.js](lab:open?file=program.js&line=5). The loop reads `k` on every turn, and `k` never changes, so moving `k12 = cell.load(c_k)` before the loop looks safe. The permission says it is safe only if nothing in the loop writes `cells`. [Select the js.mul next to it](lab:node?id=arrow/body2/2): it is `callsUser`, and user code may assign to any variable it can reach, so the loop does write `cells` as far as the engine can tell. The hoist is refused, and correctly: if `xs[i]` were an object whose `valueOf` called a function that reassigned `k`, the hoisted read would see the old value.

> **Try it.** In main.js, add `print('js.mul, move:', JSON.stringify(g.perm.explain('js.mul', 'move')));` and [rerun](lab:build). The reason is the same `may run user code` that blocks the hoist.

## Why derive instead of declare

Declaring permissions per operation would make every new operation a list of six promises to keep consistent with its behaviour by hand. Deriving them means one source of truth: change a behaviour and every permission follows. It also makes a law possible: more behaviour must never grant more permissions. [C-07](lab:preset?id=C-07) checks that law on thousands of generated behaviours.

The derivation is deliberately coarse. It does not know that the object `obj.new` returns is never compared, or that a loop's `js.mul` only ever sees numbers. Those are facts, and facts come from analyses: with a type fact, `js.mul` narrows to `num.mul`, whose behaviour is `none` ([C-06](lab:preset?id=C-06)).

> **Exercise.** Add `.rewrites(g.rewrites.standard())` to the pipeline in main.js and rerun. Which operations in the loop narrow to `num.*` and gain every permission, and which stay `callsUser` because `xs[i]` is a `js.get` whose result type is unknown?

## Where next

[Chapter 7](lab:book?ch=7) derives these rules and follows them to the throwing getter ([C-04](lab:preset?id=C-04)). The doc [Behaviours, obligations, permissions](lab:doc?id=effects) is the compact version.
