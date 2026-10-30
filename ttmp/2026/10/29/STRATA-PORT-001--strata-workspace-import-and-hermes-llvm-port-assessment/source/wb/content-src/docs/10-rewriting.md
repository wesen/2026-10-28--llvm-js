---
id: rewriting
title: Rewriting with side conditions
group: Transformation
about: Rewrites as match, side condition and action; the context a condition can read; the decision log; the standard set and how the pass runs it.
order: 10
---
# Rewriting with side conditions

Every optimisation in the workbench is a **rewrite**: a rule that finds operations of a certain shape and replaces them, but only when a side condition proves the replacement preserves behaviour. Rewrites are values built with `g.rewrite(name)`, collected into sets, and run by the `rewrite` pass to a fixed point; every attempt, fired or refused, is logged with its reason. This doc describes the parts, the standard rules and how they run. [Chapter 10](lab:book?ch=10) treats rewriting and refinement together.

## Match, when, to

```js
const mulOne = g.rewrite('mul-one')
  .match((m, site) => site.op.op === 'num.mul' && site.op.args[1] && site.op.args[1].lit === 1)
  .when((site, ctx) => ({ ok: ctx.typeAt(site, site.op.args[0]).le(t.number), because: 'the operand is a number' }))
  .to(site => g.act.replaceWith(site.op.args[0]));
```

**match** selects candidates cheaply, by shape. It receives a small pattern language `m` (`m.op('js.*').resultUnused()`, `.inLoop()`, `.hasVariants()`, `.noResult()`) and the site, and returns a boolean or a pattern. **when** is the side condition: it returns `{ ok, because }`, and the rule fires only if `ok` is `true`. **to** returns the action. Splitting the rule this way keeps the expensive and important part, the condition, separate and visible, and lets the log say exactly which condition failed.

## The site and the context

A **site** is one operation in place: `fn`, `block`, `index`, `op` (with `op`, `args`, `result`, `attrs`), `id` (`fn/block/index`), `def` (the operation's definition, with its contract) and `unused` (no use of its result). Operands are value names (strings) or literals (`{ lit }`).

The context `ctx` gives the condition what the engine knows:

| member | gives |
|---|---|
| `ctx.perm(op, facts)` | the derived permissions of an operation, with reasons |
| `ctx.typeAt(site, operand)` | the type of an operand just before the site, from type facts |
| `ctx.variantFor(site)` | the variant the facts select, if any |
| `ctx.noWritesBetween(resource, block, i, j)` | whether any operation between two positions writes a resource |
| `ctx.facts` | the type facts themselves |

Permissions answer the general questions (may this be erased, moved, merged?) from the operation's behaviour; facts answer the specific ones (is this operand a number here?). Most conditions combine one of each.

## Actions

`g.act.erase()` deletes the operation. `g.act.replaceWith(operand)` replaces every use of the result with an operand (a value or a literal, `g.lit(5)`) and deletes the operation. `g.act.replaceOp(name, args?)` changes the operation in place, keeping its result name, which is how narrowing turns `js.add` into `num.add`. A `to` that returns nothing does nothing.

## The decision log

Each attempt appends to `program.decisions` an entry `{ by, at, op, fired, because }`. A refused `erase-dead-result` on the ledger reads `perm.erase = false: may run user code; may throw; may diverge; writes heap, cells, jobs, timers, globals; talks to the host`. `program.why(opId)` collects every decision about one operation with its contract and liveness, and the Events view lists them. The log is what lets a reader, or the agent, answer "why was this not optimised?" without rerunning anything.

## The standard rules

| rule | fires when | action |
|---|---|---|
| `copy-propagation` | an operation is `core.copy(x)` | uses read `x` |
| `const-fold` | every operand is a literal and the operation is pure, or a `js.*` arithmetic on primitive literals | the computed literal |
| `simplify-branch` | a branch's condition is a literal | a jump |
| `remove-unreachable` | no path from the entry reaches a block | the block is deleted |
| `erase-dead-result` | the result is unused and `perm.erase` is `true` | erase |
| `narrow-by-facts` | the facts' operand types select a variant | the variant |
| `forward-store-to-load` | a `cell.load` follows a store to the same cell with no operation between that may write cells | the stored value |
| `naive-dce` | the result is unused (no condition: unsound on purpose) | erase |

`g.rewrites.canonical()` is the first five; `g.rewrites.standard()` adds narrowing and forwarding; `g.rewrites.none()` is empty; `set.with(rule)` adds one; `g.rewrites(r1, r2, …)` builds a set in a given order. [T-01](lab:preset?id=T-01) shows the canonical five on one program, [T-04](lab:preset?id=T-04) and [T-05](lab:preset?id=T-05) the two standard additions, and [T-02](lab:preset?id=T-02) `naive-dce` deleting a getter.

## How the pass runs a set

The `rewrite` pass takes each function and applies every rule of the set in order, visiting sites from the end of the function backwards, then repeats the whole set in rounds until a round fires nothing, at most 8 rounds. Type facts are recomputed between rounds, so a fold that turns an operand into a literal can enable a narrowing in the next round, and a forwarded load can enable a fold ([T-05](lab:preset?id=T-05) shows three such rounds). The pass invalidates the analyses, and `analyze` recomputes liveness, safepoints and types once, after it.

## One decision, end to end

In [T-03](lab:preset?id=T-03), `asNumber(x)` returns `x * 1`. The frontend emits `v4 = js.mul(x, 1)`. `mul-one` matches it (the second operand is the literal 1), and its condition asks `ctx.typeAt(site, x)`: the parameter `x` is `any`, which is not below `number`, so `ok` is `false` and the log records `mul-one at asNumber/entry/0 refused: the operand is any, and x * 1 converts it`. In `count`, the same rule meets `js.mul(i4_1, 1)` from `i++`, the facts say `number`, and it fires. Two sites, one rule, two answers, each with its reason, and the program's output is `10 6` either way. Remove the condition and the output becomes `10 51`.

## What the pass does not check

The `rewrite` pass runs after `verify`, and nothing verifies again before lowering. A custom action that breaks the IR's rules (replacing a value with one that does not dominate its uses, say) produces IR the later passes may mishandle. When writing a rule, run `g.verify(program.module.fn(name))` on its output in a test, as well as the refinement law: verification checks that the result is well formed, refinement that it means the same thing.

## Canonical forms

A set used as a normaliser should **terminate** (every rule makes the program smaller by some measure: fewer operations, fewer blocks, a more specific operation) and be **confluent** (the order of application does not change the final form). The canonical rules have both properties on the programs the workbench generates: three orders of them give the same function in [T-08](lab:preset?id=T-08), and `g.law.idempotent` passes on generated functions. Two correct rules can still loop: `x * 2 → x + x` and `x + x → x * 2` fire forever, and only the round cap stops them.

## Writing a condition

State what the rewrite assumes, in terms the engine can check. `x * 1 → x` assumes `x` is a number, because `"5" * 1` is 5 ([T-03](lab:preset?id=T-03)). Store-to-load forwarding assumes nothing writes the cell in between, and because resources are coarse, any write to any cell counts. A condition that is too weak gives a wrong compiler; one that is too strong costs optimisations. Then check the rule with `g.law.refines` on generated programs and on a corpus that exercises its edge cases ([the refinement doc](lab:doc?id=refinement)).

## What these rewrites leave out

They are local: one operation at a time, inside one block or one function. There is no block merging (a block that only jumps stays), no global value numbering, no loop-invariant code motion (the `hoist` permission exists, no rule uses it), no inlining. Each is a rule, or a pass, that the framework can express with the same parts; the standard set is deliberately small so that every decision it makes can be read.
