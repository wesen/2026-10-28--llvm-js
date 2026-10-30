# More behaviour, fewer permissions

If an operation may do more, a transformation may do less with it. That sentence is a law: the derivation of permissions is **antitone**, meaning that if behaviour `a ⊑ b` then every permission `b` has is at most the one `a` has (`true` above a condition above `false`). The law is what makes behaviours safe to over-approximate: rounding a behaviour up can only cost permissions, never grant a wrong one. This preset checks the engine's derivation against the law, shows a plausible rule of our own failing it, and asks which neighbouring operations in a small function may be swapped.

> **Try it.** [Show the Laws](lab:show?view=laws): `antitone(perm)` passes on 5,000 generated pairs, and `antitone(myErase)` fails on its 67th.

## The law, stated

Behaviours are ordered by `⊑` (C-01: `a ⊑ b` when `a ⊔ b = b`). Permissions are ordered `false < condition < true`. The derivation `perm` is antitone when

$$a \sqsubseteq b \implies \mathrm{perm}(b)_k \le \mathrm{perm}(a)_k \quad \text{for every permission } k.$$

`g.law.antitone()` generates a behaviour `a`, joins it with another to get `b ⊒ a`, derives both, and looks for a permission that `b` ranks higher than `a`.

## A rule that looks right

C-01 noticed that `make`, which allocates an object and defines a property on it, cannot be erased: `js.define` writes the heap, and the join forgets that the write goes to a new object. A tempting fix is a rule that excuses writes when the operation also allocates:

```js
const myErase = b => !b.throws && !b.callsUser && b.host.size === 0 && (b.writes.size === 0 || b.fresh);
```

`main.js` checks it the same way the engine's law does, and finds the counterexample: `reads+writes(heap, cells)` may not be erased, but `reads+writes(heap, cells), fresh`, which is strictly more behaviour, may. The rule assumes the writes go to the fresh object, and a behaviour does not say where its writes go. An operation that allocates a new object and also overwrites a global variable would be erased by this rule, losing the write. The fix belongs in the vocabulary (a resource for "the object just made"), not in the derivation.

> **Try it.** [Open main.js at the rule](lab:open?file=main.js&find=myErase%20%3D) and delete `|| b.fresh`. [Rerun](lab:build): the rule becomes antitone, and `make` is no longer erasable by it either.

## Commuting operations

Swapping two operations is the permission a scheduler needs. `g.perm.commute(a, b)` says whether their behaviours conflict: never if either may run user code, never if one writes what the other reads or writes, never if both may throw (swapping would change which error escapes). [Look at step](lab:fn?name=step), compiled with `n` assumed a number and the standard rewrites, and [show the table](lab:show?view=experiments):

```text
  count8 = js.get(state, "count")
  v10 = num.mul(n, 2)
  v13 = num.eq(n, v10)
  v15 = js.add(count8, 1)
  js.put(state, "count", v15)
  host.print(v13)
```

Only one adjacent pair may commute by behaviour: [num.mul](lab:node?id=step/entry/1) and [num.eq](lab:node?id=step/entry/2), both `none`. Every other pair contains an operation that may run user code. That pair still cannot be swapped, because `v13` uses `v10`: `commute` answers the effect half of the question, and data dependence is the other half, which a scheduler checks separately from the IR.

## Why antitone matters to the rest of the compiler

Every analysis and every contract in the workbench over-approximates: when in doubt, it says the operation may do more. Antitonicity turns that habit into a guarantee. A conservative behaviour costs optimisation, and nothing else. Without the law, a coarse summary could grant an optimisation that a precise one would refuse, and making the compiler more careful could make it wrong.

> **Exercise.** Write `myMerge(b)`, a rule for "two evaluations may share one result", that is antitone and allows `cell.load` when nothing between them writes `cells`. Check it with the same loop as `myErase`, then compare its answers with `g.perm(op).merge` for the operations in C-03's table.

## Where next

[Chapter 7](lab:book?ch=7) derives each permission and proves the law for the engine's rules. [C-03](lab:preset?id=C-03) lists the permissions; [C-01](lab:preset?id=C-01) has the join and order of behaviours. The doc [Behaviours, obligations, permissions](lab:doc?id=effects) summarises all three.
