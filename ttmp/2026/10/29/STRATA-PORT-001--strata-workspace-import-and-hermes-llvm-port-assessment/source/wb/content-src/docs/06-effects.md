---
id: effects
title: Behaviours, obligations, permissions
group: Contracts
about: The three facts every operation carries: what it may do, what lowering owes it, and what transformations may do with it.
order: 6
---
# Behaviours, obligations, permissions

Every operation in the workbench carries a **contract** with two parts, a behaviour and obligations, and every transformation consults a third fact derived from the first, its permissions. This doc defines the three, shows how the engine computes with them, and lists what the model leaves out. The operations' own table is `g.contract.table(Object.keys(g.ops))`; [C-03](lab:preset?id=C-03) prints the permissions for nine of them.

## Behaviour: what an operation may do

A **behaviour** is an upper bound on the observable things an operation may do:

| field | meaning |
|---|---|
| `reads`, `writes` | resources it may read or write: `heap`, `cells`, `jobs`, `timers`, `globals`, and `engine` for the runtime's own state |
| `fresh` | it may create an object with a new identity |
| `throws`, `diverges` | it may throw, or not return at all |
| `callsUser` | it may run arbitrary user code |
| `host` | it may talk to the host (`print`) |

The constructors are `g.fx.none`, `g.fx.reads(r)`, `g.fx.writes(r)` (which also reads), `g.fx.fresh`, `g.fx.throws`, `g.fx.diverges`, `g.fx.callsUser`, `g.fx.host(name)` and `g.fx.unknown`. `callsUser` expands at construction to every user resource read and written, plus fresh, throws, diverges and the host: user code can do anything a program can. `unknown` additionally writes `engine`, which user code cannot reach, so `callsUser ⊑ unknown` and not the other way round.

The standard operations fall into a few classes. Pure arithmetic and comparisons on known types (`num.add`, `i32.lt`, `js.strict_eq`, `js.typeof`) are `none`. Allocations (`obj.new`, `arr.new`, `js.closure`, `cell.new`) are `fresh`. Cell and global access reads or writes `cells` or `globals`; `cell.load_checked` and `js.global_get` may also throw. Everything that may meet a getter, a setter, `valueOf` or a call (`js.get`, `js.put`, `js.add` and the other general arithmetic, `js.call`) is `callsUser`.

## Join and order

The join of two behaviours unions the resource sets and ors the flags. It is associative, commutative and idempotent, with `fx.none` as unit and `fx.unknown` as top: a join-semilattice. `g.law.join()` checks this on generated behaviours. The order is `a ⊑ b` when `a ⊔ b = b`, tested by `a.le(b)`.

The join is how summaries are built. A block, a loop body or a whole function has the join of its operations' behaviours ([C-01](lab:preset?id=C-01) computes one per function). Joining loses information: the join of `obj.new` and `js.define` says "fresh, reads and writes heap" and no longer says the write went to the new object.

## Obligations: what lowering owes

An **obligation** states what the generated code must provide around an operation, independent of what the operation does:

- `mayCollect`: the helper may allocate and so run a moving collector. Every managed value the code still needs, and every managed operand the helper borrows, must be in a root slot ([Chapter 13](lab:book?ch=13)).
- `nonlocalThrow`: an exception may leave the helper without returning, as Hermes's helpers do with `longjmp`. The code must have a landing place: a handler or an unwinding path ([Chapter 14](lab:book?ch=14)).
- `writeBarrier`: the operation stores a reference where a generational collector needs to be told.
- `protectsResult`, `sharesBindingCells` and `needsHost(cap)` complete the set for operations with special needs.

Obligations never influence permissions, and behaviours never influence root plans. [C-02](lab:preset?id=C-02) lists both for a small program and shows that `cell.store` has a write barrier but is not a safepoint.

## Permissions, derived

A **permission** answers one question a transformation asks: may this operation be erased (if unused), merged with an earlier identical one, moved past neighbours, duplicated, hoisted out of a loop, or speculated onto a path where it would not have run? `g.perm(op)` derives each answer from the behaviour as `true`, `false` or a condition, with reasons. The rules, from `derivePermissions` in the engine:

| permission | granted when |
|---|---|
| erase | no writes, no throw or divergence, no user code, no host; a fresh identity only if it is never observed |
| merge | as erase, no fresh identity, and no reads (with reads: if nothing writes them between) |
| move | no user code or host; with throws, not across other throwing or writing operations; with writes or reads, not across conflicting operations |
| duplicate | as erase, and no fresh identity |
| hoist | as erase, no fresh identity; with reads, if nothing in the loop writes them |
| speculate | as erase; with reads, given facts that make it total |

So `cell.load` (`reads(cells)`) may be erased and duplicated, and may be merged, moved or hoisted only if no cell is written in between. `js.get` refuses all six, even with an unused result: [C-04](lab:preset?id=C-04) follows that refusal through a getter that prints and throws. `g.perm.commute(a, b)` answers the related question for a pair: no if either may run user code, if they conflict on a resource, or if both may throw.

## The antitone law

More behaviour must never mean more permissions: if `a ⊑ b` then every permission of `b` is at most the one of `a`, with `false < condition < true`. This is what makes over-approximation safe. A behaviour rounded up costs optimisations and never grants a wrong one. `g.law.antitone()` checks the derivation on generated pairs; [C-07](lab:preset?id=C-07) shows a plausible rule of our own that breaks the law, and why.

## Earning permissions with variants

A general operation can lend its result to a **variant** with a smaller contract whenever a fact proves the variant's condition. `js.add` is `callsUser`; its variant `num.add`, selected when both operand types are numbers, is `none` and has every permission and no obligations. The standard rewrites perform this narrowing from type facts ([C-06](lab:preset?id=C-06), [T-04](lab:preset?id=T-04)), and `g.law.variant(variant, general)` checks that the two agree on the variant's domain. Narrowing is the main way a JavaScript compiler earns the freedom it needs: not by assuming operations are pure, but by proving which ones are.

## Contracts are promises

The engine believes a contract. An operation whose step does more than its behaviour declares makes correct rewrites produce wrong programs: [C-05](lab:preset?id=C-05) declares a printing operation as `none`, and `erase-dead-result` deletes it. Contracts are therefore checked the same way passes are, against the reference interpreter with `g.law.refines`.

## What this model leaves out

Resources are coarse: one `cells` for all cells and one `heap` for all objects, so a store to one cell blocks forwarding a load of another ([T-05](lab:preset?id=T-05)), and an allocation followed by a write to it cannot be erased. A finer model would name regions (this object, this cell) and track which values may alias. There is no escape analysis, so `fresh` objects are treated as possibly observed unless a fact says otherwise. And behaviours describe single operations: a loop whose body is `none` may still diverge, which is a property of control flow, not of any operation in it. [Chapter 6](lab:book?ch=6) and [Chapter 7](lab:book?ch=7) develop the model and its choices.
