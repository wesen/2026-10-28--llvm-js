# Idempotent canonical form

The rewrite pass runs its set in rounds until a round changes nothing. The result should be a **canonical form**: running the set on it again changes nothing (the set is **idempotent**), and, for the set to be predictable, the form should not depend on the order the rules are listed in. This preset checks both on a small function, and shows a pair of rules that never reach a fixed point, with a law that misses it and a check that does not.

> **Try it.** [Show the table](lab:show?view=experiments): three orders of the five canonical rules give the same `size`, hash `74924dc2`, 9 operations, 4 rewrites fired. Then [show the Laws](lab:show?view=laws).

## One form, three orders

[Open program.js](lab:open?file=program.js). `size` folds `2 * 4` to 8, simplifies the branch `8 > 5` to a jump, removes the unreachable block, and keeps `n * unit`:

```text
fn size(this: any, n: any) -> any {
entry throws unwind:
  v8 = js.mul(n, 8)
  jump then1()
then1() throws unwind:
  v13 = js.add(n, 8)
  return v13
}
```

The `spare` multiplication survives although nothing uses it: `n` has type `any`, so `n * 8` may call `valueOf`, and `erase-dead-result` is refused. The `reversed` and `fold last` orders reach the same function by different routes: the rounds repeat until nothing fires, so an early rule that had nothing to do in round one gets another chance after the others have run.

## The idempotence law

`g.law.idempotent(set)` rewrites each function to the set's fixed point, rewrites the result again, and compares hashes. It passes for the canonical set on 60 generated functions and for the standard set on program.js.

## Two rules that undo each other

```js
const toAdd = g.rewrite('double-as-add')...to(s => g.act.replaceOp('num.add', [s.op.args[0], s.op.args[0]]));
const toMul = g.rewrite('add-as-double')...to(s => g.act.replaceOp('num.mul', [s.op.args[0], g.lit(2)]));
```

Each rule is correct on its own: `x * 2` and `x + x` are the same number for every `x`, `-0` and `NaN` included. Together, on [double.ir](lab:open?file=double.ir), each round turns `num.mul(a, 2)` into `num.add(a, a)` and back. The round always changes something, so the pass stops only at its cap of 8 rounds, after 16 firings.

The third law, `g.law.idempotent` on this pair, **passes**: after 8 rounds the operation is `num.mul` again, and rewriting that for another 8 rounds ends at `num.mul` too, so the two hashes agree. Idempotence of the result says nothing about whether the rewriting stopped by itself.

## A check that catches it

`settles` in main.js asks the stronger question: compile, print L1, compile that text again with the same set, and count the rewrites that fire the second time. At a true fixed point the answer is zero. For the canonical set on program.js it is zero. For the pair it is 16, starting with `double-as-add at twice/entry/0`, and the law fails.

> **Try it.** Remove `toMul` from the pair (`R(toAdd)`) and [rerun](lab:build). The pair settles after one round: `num.add(a, a)`, and the second compile fires nothing.

## Why canonical forms matter

Other rewrites and analyses match on shapes. If folding could leave either `x + x` or `x * 2`, every later rule that looks for a doubling would need both patterns, and two equivalent programs could be optimised differently. A rule set is useful as a normaliser only if it terminates (each rule makes the program smaller by some measure, as folding and erasing do) and is confluent (the order of application does not change the result). The workbench checks these properties by example; [Chapter 10](lab:book?ch=10) explains the general theory and when it applies.

> **Exercise.** Give the pair a measure that decreases: keep `double-as-add` only, and add `add-zero` (`x + 0 → x` when `x` is a number). Does the set settle on `num.mul(num.add(a, 0), 2)`? Write that function in double.ir and check with `settles`.

## Where next

[Chapter 10](lab:book?ch=10) covers rewriting and canonical forms. [T-01](lab:preset?id=T-01) shows the canonical rules one by one; [T-03](lab:preset?id=T-03) writes a rule with a side condition. The doc [Rewriting with side conditions](lab:doc?id=rewriting) is the reference.
