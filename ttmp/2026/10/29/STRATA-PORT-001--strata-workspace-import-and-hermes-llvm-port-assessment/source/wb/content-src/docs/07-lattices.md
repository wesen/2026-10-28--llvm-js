---
id: lattices
title: Lattices and the fixed-point theorem
group: Analysis
about: Partial orders, joins, height, monotone functions, and why the worklist solver stops at the least fixed point.
order: 7
---
# Lattices and the fixed-point theorem

Every analysis in the workbench (liveness, type facts, safepoints, the constants and intervals of the A presets) is solved by one function, `g.solve`, and the reason one function suffices is a theorem about lattices. This doc states the definitions the engine relies on, the theorem, the worklist algorithm that implements it, and widening for lattices where the theorem's condition fails. [Chapter 8](lab:book?ch=8) develops all of it with proofs.

## Partial orders

A **partial order** `⊑` on a set of facts is reflexive (`a ⊑ a`), antisymmetric (`a ⊑ b` and `b ⊑ a` give `a = b`) and transitive. Read `a ⊑ b` as "`b` says no more than `a` claims": for liveness, a smaller set of live values; for types, a smaller set of kinds; for constants, a known value below "not a constant". Partial means some pairs are incomparable: `{i}` and `{log}` are two different sets, neither contains the other.

## Joins and lattices

The **join** `a ⊔ b` is the least upper bound of `a` and `b`: above both, below every other upper bound. A **join-semilattice** has a join for every pair, and the analyses here also have a least element `⊥`, "nothing known yet", where they start. The engine's lattices (`g.lattice.*`):

| lattice | elements | join |
|---|---|---|
| `powerset({ universe })` | sets | union |
| `flat(values)` | `⊥`, one value, `⊤` | equal values stay, different ones become `⊤` |
| `types()` | sets of kinds | union of kinds |
| `map(inner)` | maps from names to inner elements | pointwise |
| `product(a, b, …)` | tuples | componentwise |
| `interval()` | `[lo, hi]` | the hull |

Each value has `bottom()`, `join`, `le`, `eq` and `show`, and `g.law.lattice(L)` checks that join is commutative, associative and idempotent and that `a ⊑ b` exactly when `a ⊔ b = b` ([A-01](lab:preset?id=A-01)). The solver depends on each law: commutativity and associativity let it combine predecessors in any order, idempotence lets it revisit a block, and the agreement of order and join lets it detect "no change" with `eq`.

## Height

The **height** of a lattice is the length of the longest strictly increasing chain `x₀ ⊏ x₁ ⊏ … ⊏ xₙ`. The powerset of `n` values has height `n`; the flat lattice has height 2; a map over `k` names of a lattice of height `h` has height `k·h`. Intervals have infinite height: `[0, 0] ⊏ [0, 1] ⊏ [0, 2] ⊏ …` never ends.

## Monotone functions and the theorem

A transfer function `f` is **monotone** if `x ⊑ y` implies `f(x) ⊑ f(y)`. The liveness rule `in = use ∪ (out ∖ def)` is monotone: a larger `out` gives a larger `in`. A rule like "if more than two values are live, forget them all" is not ([A-07](lab:preset?id=A-07)).

**Theorem** (Kleene, as used for dataflow by Kildall 1973). If `f` is monotone on a lattice of finite height, the sequence `⊥, f(⊥), f(f(⊥)), …` is increasing and reaches a fixed point `x = f(x)` after at most height steps, and that fixed point is the least one: `x ⊑ y` for every `y` with `f(y) = y`.

The proof is two lines. Monotonicity and `⊥ ⊑ f(⊥)` give `fⁿ(⊥) ⊑ fⁿ⁺¹(⊥)` by induction, so the sequence climbs and must stop within the height. And if `y = f(y)`, then `⊥ ⊑ y` gives `fⁿ(⊥) ⊑ fⁿ(y) = y` for every `n`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 270">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <line x1="200" y1="219" x2="90" y2="172" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="200" y1="219" x2="200" y2="172" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <line x1="200" y1="219" x2="310" y2="172" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="90" y1="152" x2="90" y2="102" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="90" y1="152" x2="200" y2="102" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="200" y1="152" x2="90" y2="102" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="200" y1="152" x2="310" y2="102" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <line x1="310" y1="152" x2="200" y2="102" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="310" y1="152" x2="310" y2="102" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="90" y1="82" x2="200" y2="35" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="200" y1="82" x2="200" y2="35" stroke="currentColor" class="mut" stroke-width="0.8"/>
  <line x1="310" y1="82" x2="200" y2="35" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <text x="200" y="232" font-size="12" text-anchor="middle">∅</text>
  <text x="90" y="165" font-size="12" text-anchor="middle">{i}</text>
  <text x="200" y="165" font-size="12" text-anchor="middle">{s}</text>
  <text x="310" y="165" font-size="12" text-anchor="middle">{log}</text>
  <text x="90" y="95" font-size="12" text-anchor="middle">{i,s}</text>
  <text x="200" y="95" font-size="12" text-anchor="middle">{i,log}</text>
  <text x="310" y="95" font-size="12" text-anchor="middle">{s,log}</text>
  <text x="200" y="28" font-size="12" text-anchor="middle">{i,s,log}</text>
  <text x="400" y="40" font-size="10" class="lbl">Kleene iteration</text>
  <text x="400" y="70" font-size="12" class="it">⊥</text>
  <text x="460" y="70" font-size="12">∅</text>
  <text x="400" y="106" font-size="12" class="it">f(⊥)</text>
  <text x="460" y="106" font-size="12">{s}</text>
  <text x="400" y="142" font-size="12" class="it">f²(⊥)</text>
  <text x="460" y="142" font-size="12">{s,log}</text>
  <text x="400" y="178" font-size="12" class="it">f³(⊥)</text>
  <text x="460" y="178" font-size="12">{i,s,log}</text>
  <text x="400" y="214" font-size="12" class="it">f⁴(⊥)</text>
  <text x="460" y="214" font-size="12">{i,s,log}  = f³(⊥)</text>
</svg>
```

**Figure 7.1.** Kleene iteration drawn on the powerset of three values. Each application of the transfer function moves up the diagram (red), and the iteration stops when an application changes nothing. Schematic: the values are named after the ledger's loop, not measured.

"Least" matters. For liveness, a larger fixed point would also be consistent (claim every value live everywhere), and sound, and useless. The least fixed point is the most precise answer the equations allow.

## Products and maps keep the theorem

Analyses are rarely one fact per program. Constant propagation keeps one flat element per value, which is a map lattice; running liveness and types together is a product. Both constructions preserve what the theorem needs: the join of a map or a product is computed pointwise, so its laws follow from the parts' laws, and its height is the sum of the parts' heights, so it is finite when they are. A transfer function that is monotone in each component is monotone on the whole. That is why the engine can offer `g.lattice.map` and `g.lattice.product` as building blocks without a new proof for each analysis built from them: check the parts with `g.law.lattice`, check the transfer function with `g.law.monotone`, and the solver's guarantee holds.

A worked count, for the constants analysis of [A-04](lab:preset?id=A-04): `calc` defines 10 values besides its parameter, each in a flat lattice of height 2, so the map over them has height 20, and no block's fact can change more than 20 times. The solver needed 4 visits, one per block, because the function has no loop and the blocks were visited in an order where every predecessor came first.

## The worklist algorithm

An analysis over a function has one unknown per block and one equation per block. The engine solves them with a worklist: put every block on it, take one off, recompute its fact from its neighbours' facts (`join` over predecessors forward, over successors backward), and if the fact changed, put the neighbours whose equations read it back on the list. When the list is empty, every equation holds. This is chaotic iteration, and for monotone functions it reaches the same least fixed point as computing `fⁿ(⊥)` for the whole function at once, usually with far fewer evaluations. `g.solve` records every visit in `steps`, and the Facts view and the Stage replay them ([A-02](lab:preset?id=A-02)): liveness on the ledger's `total` takes 8 visits for 5 blocks.

The same code solves analyses on any graph, `g.solve(analysis, { kind: 'graph', nodes, edges })`, which [A-06](lab:preset?id=A-06) uses on a reference graph between functions.

## Writing an analysis

```js
const live = g.analysis('live').backward().lattice(g.lattice.powerset())
  .transfer((op, s) => { const r = new Set(s); if (op.result) r.delete(op.result); for (const a of op.args) if (typeof a === 'string') r.add(a); return r; });
```

`.forward()` or `.backward()`, `.lattice(L)`, `.transfer((op, state, { fn, block }) => state)`, `.edge(rule)` for block parameters (`g.edge.substituteBlockArgs()` maps a target's parameters to an edge's arguments), `.init(fn => state)` for the boundary, `.widen(w)`. [A-04](lab:preset?id=A-04) writes constant propagation this way and uses its result in a rewrite.

## Widening

When the height is infinite, or finite but large, a **widening** operator `∇` replaces the join at revisited blocks and jumps instead of climbing: `g.widen.thresholds([0, 100, 1000])` widens a growing bound to the next threshold and past the last one to infinity. The result is a post-fixed point, above the least one, so still sound, and reached in finitely many steps. On a loop to 100, an interval analysis without widening gives up after 100,000 visits, with branch refinement it converges in 308, and with widening in 11 ([A-05](lab:preset?id=A-05)). Cousot and Cousot (1977) introduced the framework.

## What the theorem does not say

It says the solver finds the least solution of the equations, not that the equations describe the program. Soundness is a separate property of the transfer functions: each must be above what the operation really does. A monotone, unsound function (one that forgets a use) passes `g.law.monotone` and yields a precise wrong answer. The workbench checks soundness where it matters by running: a root plan from wrong liveness shows a stale reference under GC stress ([L-05](lab:preset?id=L-05)).
