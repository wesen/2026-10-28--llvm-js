# Lattices and their laws

Every analysis in the engine computes facts, and facts need an order: "`x` is a number" says more than "`x` is a number or a string". A **lattice** is a set of facts with such an order `⊑` and a **join** `⊔`, the least fact above two others. This preset builds the lattices the engine ships, prints a few joins, and checks the join laws on each, including one structure that is not a lattice at all.

> **Try it.** [Show the Laws](lab:show?view=laws): four lattices pass on 2,000 samples, and `lattice(sum)` fails on its first. Then [show Events](lab:show?view=events) for the joins.

## Order and join

A partial order `⊑` is reflexive, antisymmetric and transitive, and it need not compare everything: `{a}` and `{b}` are incomparable sets. The join `a ⊔ b` is the least upper bound: above both, and below every other upper bound. In a **join-semilattice** every pair has one. The bottom element `⊥` is below everything and stands for "no information yet" (an analysis starts there).

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 270">
  <line x1="200" y1="220" x2="90" y2="173" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="200" y1="220" x2="200" y2="173" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="200" y1="220" x2="310" y2="173" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="90" y1="153" x2="90" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="90" y1="153" x2="200" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="200" y1="153" x2="90" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="200" y1="153" x2="310" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="310" y1="153" x2="200" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="310" y1="153" x2="310" y2="103" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="90" y1="83" x2="200" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="200" y1="83" x2="200" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="310" y1="83" x2="200" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <text x="200" y="232" font-size="12" text-anchor="middle">∅</text>
  <text x="90" y="165" font-size="12" text-anchor="middle">{a}</text>
  <text x="200" y="165" font-size="12" text-anchor="middle">{b}</text>
  <text x="310" y="165" font-size="12" text-anchor="middle">{c}</text>
  <text x="90" y="95" font-size="12" text-anchor="middle" class="b">{a,b}</text>
  <text x="200" y="95" font-size="12" text-anchor="middle">{a,c}</text>
  <text x="310" y="95" font-size="12" text-anchor="middle">{b,c}</text>
  <text x="200" y="28" font-size="12" text-anchor="middle">{a,b,c}</text>
  <rect x="62" y="80" width="56" height="22" fill="none" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <line x1="470" y1="118" x2="540" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="470" y1="136" x2="540" y2="218" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="540" y1="118" x2="540" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="540" y1="136" x2="540" y2="218" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="610" y1="118" x2="540" y2="36" stroke="currentColor" class="mut" stroke-width="1"/>
  <line x1="610" y1="136" x2="540" y2="218" stroke="currentColor" class="mut" stroke-width="1"/>
  <text x="540" y="28" font-size="12" text-anchor="middle">⊤</text>
  <text x="470" y="130" font-size="12" text-anchor="middle">1</text>
  <text x="540" y="130" font-size="12" text-anchor="middle">2</text>
  <text x="610" y="130" font-size="12" text-anchor="middle">3</text>
  <text x="540" y="232" font-size="12" text-anchor="middle">⊥</text>
  <text x="200" y="262" font-size="10" text-anchor="middle" class="lbl">powerset of {a, b, c}</text>
  <text x="540" y="262" font-size="10" text-anchor="middle" class="lbl">flat over 1, 2, 3</text>
</svg>
```

**Figure 1.** Two lattices drawn as Hasse diagrams, with larger facts higher. Left: sets of names ordered by inclusion; the join of `{a}` and `{b}` is `{a,b}` (outlined). Right: the flat lattice used for constants; any two different constants join to `⊤`, "not a constant".

## The engine's lattices

[Open main.js](lab:open?file=main.js) and read Events:

- **types**: the type lattice. `number ⊔ string` is `number|string` and `int32 ⊑ number` holds. Type facts ([A-03](lab:preset?id=A-03)) live here.
- **powerset**: sets, joined by union. `{a} ⊔ {b, c}` is `a,b,c`. Liveness ([A-02](lab:preset?id=A-02)) uses it.
- **flat**: `⊥`, the values, `⊤`. `1 ⊔ 1 = 1`, `1 ⊔ 2 = ⊤`, `⊥ ⊔ 3 = 3`. Constant propagation ([A-04](lab:preset?id=A-04)) uses it, one per variable through `g.lattice.map`.
- **interval**: `[lo, hi]`, joined by taking the hull: `[0, 2] ⊔ [5, 9] = [0, 9]`. It has infinite height, which [A-05](lab:preset?id=A-05) deals with by widening.

## The laws

`g.law.lattice(L)` samples triples `a, b, c` and checks that join is commutative (`a ⊔ b = b ⊔ a`), associative, idempotent (`a ⊔ a = a`), and that the order agrees with it: `a ⊑ b` exactly when `a ⊔ b = b`. For the type lattice, which also has a meet, it checks that meet absorbs join: `a ⊓ (a ⊔ b) = a`.

These laws are what the solver relies on. Commutativity and associativity let it combine the facts from a block's predecessors in any order. Idempotence lets it revisit a block without double counting. The agreement of order and join lets it test "did anything change?" with equality.

## A structure that fails

The last entry joins numbers by adding them. Addition is commutative and associative, so a quick look might accept it. `g.law.lattice` rejects it on the first sample: idempotence fails at `a = 3`, since `3 + 3` is 6, not 3. An analysis over this "lattice" would grow a fact every time it revisited a block, and the solver would never stop.

> **Try it.** In main.js, change the broken join to `(a, b) => Math.max(a, b)` and [rerun](lab:build). It is now a lattice (a chain, ordered by `≤`), and the law passes.

## Height and termination

The **height** of a lattice is the length of its longest strictly increasing chain. The powerset of four names has height 4; the flat lattice has height 2 (`⊥ ⊑ 1 ⊑ ⊤`); the type lattice has as many steps as kinds. A monotone analysis over a lattice of finite height can only move up, so it reaches a fixed point after at most height steps per block. Intervals have no finite height (`[0, 0] ⊑ [0, 1] ⊑ [0, 2] ⊑ …`), which is why they need widening.

> **Exercise.** Build `g.lattice.product(g.lattice.flat([1, 2]), g.lattice.powerset({ universe: ['x'] }))` in main.js and join `[1, new Set()]` with `[2, new Set(['x'])]`. Predict the result, print it with the product's `show`, and work out the product's height.

## Where next

[Chapter 8](lab:book?ch=8) develops lattices and the fixed-point theorem; the doc [Lattices and the fixed-point theorem](lab:doc?id=lattices) is the short version. [A-07](lab:preset?id=A-07) checks the other half of the bargain, that transfer functions are monotone.
