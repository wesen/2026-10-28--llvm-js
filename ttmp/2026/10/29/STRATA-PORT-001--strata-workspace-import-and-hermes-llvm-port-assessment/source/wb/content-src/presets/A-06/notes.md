# The solver on any graph

The fixed-point solver behind liveness and type facts does not care that its nodes are blocks. Given any graph `{ kind: 'graph', nodes, edges }`, a lattice and a transfer function, `g.solve` iterates a worklist until nothing changes. This preset builds the **reference graph** of a small program (an edge from one function to another when the first refers to the second), computes what each function can reach, and finds the recursive group with `g.graph.scc`.

> **Try it.** [Show the table](lab:show?view=experiments): `isEven` and `isOdd` form one recursive group, and `unused` reaches three functions but is not reachable from `main`.

## The graph

[Open program.js](lab:open?file=program.js). `isEven` and `isOdd` call each other, `report` calls `isEven`, `unused` calls `report`, and `main` calls `report`. The frontend records which variables each function captures in `fn.meta.captures`, and every function here refers to the others through the variables that hold them, so the edges come straight from that list; for `main`, which declares those variables, `main.js` looks at the cells it loads instead.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 200">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="80" width="90" height="34" fill="none" stroke="currentColor" class="ink" stroke-width="1"/>
  <text x="65" y="102" font-size="12" text-anchor="middle" class="b">main</text>
  <rect x="160" y="80" width="90" height="34" fill="none" stroke="currentColor" class="ink" stroke-width="1"/>
  <text x="205" y="102" font-size="12" text-anchor="middle">report</text>
  <rect x="160" y="150" width="90" height="34" fill="none" stroke="currentColor" class="mut dash" stroke-width="1"/>
  <text x="205" y="172" font-size="12" text-anchor="middle" class="mut">unused</text>
  <rect x="300" y="20" width="300" height="160" fill="none" stroke="currentColor" class="acc" stroke-width="1.6"/>
  <text x="310" y="38" font-size="10" class="lbl acc">strongly connected component</text>
  <rect x="330" y="80" width="90" height="34" fill="none" stroke="currentColor" class="ink" stroke-width="1"/>
  <text x="375" y="102" font-size="12" text-anchor="middle">isEven</text>
  <rect x="490" y="80" width="90" height="34" fill="none" stroke="currentColor" class="ink" stroke-width="1"/>
  <text x="535" y="102" font-size="12" text-anchor="middle">isOdd</text>
  <line x1="110" y1="97" x2="158" y2="97" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="250" y1="97" x2="328" y2="97" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="205" y1="150" x2="205" y2="116" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <path d="M420,88 C445,60 465,60 488,88" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M490,106 C465,134 445,134 422,106" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
</svg>
```

**Figure 1.** The reference graph of program.js as main.js builds it. `isEven` and `isOdd` form a cycle, a strongly connected component; `unused` (dashed) has an edge out, to `report`, and none in.

## Reach as a backward analysis

The set of functions `f` can reach is `f` itself plus whatever its callees reach:

$$\mathrm{reach}(f) = \{f\} \cup \bigcup_{f \to h} \mathrm{reach}(h).$$

Facts flow from callees to callers, against the edges, so the analysis is **backward**, over the powerset lattice:

```js
const reach = g.analysis('reach').backward().lattice(g.lattice.powerset())
  .transfer((node, s) => new Set([...s, node.id]));
```

The solver starts every node at `∅` and needs 14 visits on five nodes; the cycle costs the extra visits, because `isEven` and `isOdd` each change when the other does, until both hold `isEven, isOdd`. `main` reaches `isEven, isOdd, main, report`, which is exactly the set of functions a whole-program compiler must keep.

## Components

A **strongly connected component** is a maximal set of nodes that can all reach each other. `g.graph.scc` (Tarjan's algorithm) returns them as `{isOdd, isEven} {report} {main} {unused}`, a component before anything that refers to it, so callees come first. Compilers use the components to order work bottom-up: analyse a callee before its callers, and treat each recursive group as a unit that needs its own fixed point. That is the same iteration as the solver's, one level up.

## Dead functions

`unused` is not in `reach(main)`. A whole-program compiler could drop it. The engine already dropped something: [main in L1](lab:fn?name=main) creates closures for `isEven`, `isOdd` and `report` but not for `unused`, because `erase-dead-result` erased that `js.closure` (an allocation whose result nothing used, with its fresh identity never observed). The function `unused` itself stays in the module, since rewrites work inside one function at a time.

> **Try it.** Add `print(unused());` at the end of program.js and [rerun](lab:build): `unused` becomes reachable from `main`, and its closure comes back in L1.

> **Exercise.** Make the analysis compute, for each function, the functions that can reach it (its callers, transitively). Which direction is that, and what does `main`'s row show? Then add a function that calls itself and check that `g.graph.scc` reports it as a component of one node with a self-edge, which the table's last-but-one column does not count.

## Where next

[Chapter 8](lab:book?ch=8) proves that the worklist finds the least fixed point on any graph with a monotone transfer function. [A-02](lab:preset?id=A-02) is the same solver on blocks; the doc [Lattices and the fixed-point theorem](lab:doc?id=lattices) has the general statement.
