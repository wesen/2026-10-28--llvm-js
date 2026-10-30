# Lattices and fixed points

An analysis answers a question about every point of a program at once: which values are still needed here, what type this value has, whether this variable holds a constant. The answers depend on each other around loops, so they cannot be computed in one pass from top to bottom. This chapter builds the mathematics that makes such questions solvable: partial orders and lattices, monotone functions, and the theorem that a monotone function on a lattice of finite height has a least fixed point reached by plain iteration. It then shows the one solver the engine uses for every analysis, runs it step by step on the ledger's `total` loop, and writes two analyses of our own, one of which needs a new idea, widening, to stop at all.

The facts that narrowing used in [Chapter 7](lab:book?ch=7) come from this machinery; [Chapter 9](lab:book?ch=9) applies it to liveness, safepoints and types in detail.

## 8.1 Equations with loops in them

Take **liveness**: a value is live at a point if some path from that point reads it before anything else could. For a block $b$ it gives two sets, the values live on entry, $\mathrm{IN}(b)$, and on exit, $\mathrm{OUT}(b)$, related by

$$\mathrm{IN}(b) = \mathrm{use}(b) \cup \left(\mathrm{OUT}(b) \setminus \mathrm{def}(b)\right), \qquad \mathrm{OUT}(b) = \bigcup_{s \in \mathrm{succ}(b)} \mathrm{IN}(s),$$

where $\mathrm{use}(b)$ are the values $b$ reads before defining them and $\mathrm{def}(b)$ the values it defines. (Block parameters add a substitution on each edge; Chapter 9 gives the exact rule.) Here is the loop of `total` from the running example, as the engine prints it:

```text
fn total(c_log: cell, this: any) -> any {
entry throws unwind:
  jump for1(0, 0)
for1(sum2_1: any, i3_1: any) throws unwind:
  log5 = cell.load_checked(c_log)
  length6 = js.get(log5, "length")
  v7 = js.lt(i3_1, length6)
  branch v7, body2(), endfor4()
body2() throws unwind:
  log9 = cell.load_checked(c_log)
  v11 = js.get(log9, i3_1)
  v12 = js.add(sum2_1, v11)
  jump next3()
next3() throws unwind:
  n14 = js.mul(i3_1, 1)
  v15 = js.add(n14, 1)
  jump for1(v12, v15)
endfor4() throws unwind:
  return sum2_1
}
```

$\mathrm{OUT}(\mathtt{next3})$ depends on $\mathrm{IN}(\mathtt{for1})$, which depends on $\mathrm{OUT}(\mathtt{for1})$, which depends on $\mathrm{IN}(\mathtt{body2})$, which depends on $\mathrm{OUT}(\mathtt{body2}) = \mathrm{IN}(\mathtt{next3})$, which depends on $\mathrm{OUT}(\mathtt{next3})$. The equations are circular, as every loop makes them, and a circular system can have many solutions. Declaring every value live everywhere satisfies these equations and is useless: it would root every object at every safepoint. We want the smallest solution, and we want a guarantee that it exists and that a simple procedure finds it.

## 8.2 Partial orders, joins and lattices

A **partial order** $\sqsubseteq$ on a set is reflexive ($x \sqsubseteq x$), antisymmetric (if $x \sqsubseteq y$ and $y \sqsubseteq x$ then $x = y$) and transitive. Read $x \sqsubseteq y$ as "$x$ says no more than $y$": for liveness, $x \subseteq y$; for types, $x$ admits fewer kinds of value. An **upper bound** of $x$ and $y$ is any $z$ with $x \sqsubseteq z$ and $y \sqsubseteq z$; their **join** $x \sqcup y$ is the least one. A partial order in which every pair has a join and there is a least element $\bot$ is a **join-semilattice**; in this book "lattice" means that. Its **height** is the length of the longest chain $x_0 \sqsubset x_1 \sqsubset \cdots \sqsubset x_h$.

The engine offers six lattices, each with `bottom()`, `join`, `le`, `eq` and `show`:

| lattice | elements | join | height |
|---|---|---|---|
| `g.lattice.powerset()` | sets of names | union | the number of names |
| `g.lattice.flat(values)` | $\bot$, one value, $\top$ | equal values stay, different ones go to $\top$ | 2 |
| `g.lattice.types()` | sets of the 10 value kinds | union of kinds | 10 |
| `g.lattice.map(inner)` | maps from names to inner elements | pointwise | names × inner height |
| `g.lattice.product(a, b, …)` | tuples | componentwise | sum of heights |
| `g.lattice.interval()` | $\bot$ or $[lo, hi]$ | the smallest interval holding both | infinite |

Figure 8.1 draws two of them. The powerset of three names is a cube: every subset sits above the subsets it contains, and the join of two sets is their union, the lowest point above both. The flat lattice is three levels deep and makes constants work: one known value, or "not yet seen" ($\bot$), or "more than one value" ($\top$).

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 250">
  <g class="ink" stroke="currentColor" stroke-width="1" fill="none">
    <line x1="180" y1="212" x2="90" y2="162"/><line x1="180" y1="212" x2="180" y2="162"/><line x1="180" y1="212" x2="270" y2="162"/>
    <line x1="90" y1="138" x2="90" y2="88"/><line x1="90" y1="138" x2="180" y2="88"/>
    <line x1="180" y1="138" x2="90" y2="88"/><line x1="180" y1="138" x2="270" y2="88"/>
    <line x1="270" y1="138" x2="180" y2="88"/><line x1="270" y1="138" x2="270" y2="88"/>
    <line x1="90" y1="64" x2="180" y2="38"/><line x1="180" y1="64" x2="180" y2="38"/><line x1="270" y1="64" x2="180" y2="38"/>
    <line x1="520" y1="212" x2="440" y2="137"/><line x1="520" y1="212" x2="500" y2="137"/><line x1="520" y1="212" x2="560" y2="137"/><line x1="520" y1="212" x2="620" y2="137"/>
    <line x1="440" y1="113" x2="520" y2="38"/><line x1="500" y1="113" x2="520" y2="38"/><line x1="560" y1="113" x2="520" y2="38"/><line x1="620" y1="113" x2="520" y2="38"/>
  </g>
  <g font-size="11" text-anchor="middle" class="f-ink">
    <text x="180" y="226">∅</text>
    <text x="90" y="154">{a}</text><text x="180" y="154">{b}</text><text x="270" y="154">{c}</text>
    <text x="90" y="80">{a, b}</text><text x="180" y="80">{a, c}</text><text x="270" y="80">{b, c}</text>
    <text x="180" y="30">{a, b, c}</text>
    <text x="520" y="226">⊥</text>
    <text x="440" y="129">0</text><text x="500" y="129">5</text><text x="560" y="129">9</text><text x="620" y="129">…</text>
    <text x="520" y="30">⊤</text>
    <text x="180" y="246" class="lbl">powerset of {a, b, c}: height 3</text>
    <text x="520" y="246" class="lbl">flat over numbers: height 2</text>
  </g>
</svg>
```

**Figure 8.1.** Two lattices as Hasse diagrams: an element is joined by a line to the elements just above it. Left, the subsets of three names ordered by inclusion, the lattice of liveness. Right, the flat lattice of constant propagation, where any two different numbers join to ⊤.

Being a lattice is a claim, and claims in this engine are laws. `g.law.lattice(L)` draws 2,000 random triples and checks that the join is commutative, associative and idempotent and that $x \sqsubseteq y$ holds exactly when $x \sqcup y = y$. It passes for the powerset, flat, interval and type lattices. [A-01 Lattices and their laws](lab:preset?id=A-01) runs all of them.

## 8.3 Monotone functions and the least fixed point

Write the whole system of equations as one function $F$ from a lattice $L$ to itself: $F$ takes a guess at every set and returns the right-hand sides computed from it. A solution is a **fixed point**, an $x$ with $F(x) = x$. The function is **monotone** if $x \sqsubseteq y$ implies $F(x) \sqsubseteq F(y)$: a bigger guess never produces a smaller answer. The liveness equations are monotone, because union and "minus a fixed set" both are.

**Theorem** (Kleene). If $L$ has finite height $h$ and $F$ is monotone, the sequence $\bot, F(\bot), F^2(\bot), \ldots$ reaches a fixed point after at most $h$ steps, and that fixed point is the least one.

*Proof.* First, the sequence rises. $\bot \sqsubseteq F(\bot)$ because $\bot$ is below everything. If $F^k(\bot) \sqsubseteq F^{k+1}(\bot)$, monotonicity gives $F^{k+1}(\bot) \sqsubseteq F^{k+2}(\bot)$; by induction every step is at least as large as the one before. Second, it stops. A rising sequence that changes at every step is a strictly increasing chain, and no chain is longer than $h$, so for some $n \le h$ we have $F^{n+1}(\bot) = F^n(\bot)$, a fixed point. Third, it is the least. Let $x$ be any fixed point. $\bot \sqsubseteq x$; if $F^k(\bot) \sqsubseteq x$ then $F^{k+1}(\bot) \sqsubseteq F(x) = x$. So every element of the sequence, the fixed point included, is below $x$. $\blacksquare$

All three parts matter for a compiler. "Least" means the solver finds the most precise answer the equations allow: for liveness, no value is called live that need not be. "At most $h$ steps" means it terminates, with a bound we can compute. And the proof never mentions liveness: the same argument covers every monotone analysis on every lattice of finite height, which is why the engine needs only one solver.

## 8.4 One solver for every analysis

For a function with $B$ blocks the lattice is a map from blocks to pairs $(\mathrm{IN}, \mathrm{OUT})$, a product of $2B$ copies of the per-block lattice, so its height is $2B$ times the per-block height. Recomputing every block on every round would work but wastes time on blocks whose inputs did not change. The engine's solver keeps a **worklist** of blocks whose inputs may have changed and recomputes only those. This is the backward version:

```js
// core.js
  const work = [...fn.blocks].reverse().map(b => b.name), queued = new Set(work);
// …
  while (work.length) {
    if (now() - t0 > budget) return budgetFallback(fn, analysis);
    const name = work.shift(); queued.delete(name); visits++;
    const b = fn.block(name);
    let out = lat.bottom();
    for (const e of termEdges(b.term)) if (fn.block(e.block)) out = lat.join(out, rule(fn, b, e, IN.get(e.block)));
// …
    const changed = !lat.eq(inn, IN.get(name)) || !lat.eq(out, OUT.get(name));
    steps.push({ i: visits, block: name, before: { in: lat.show(IN.get(name)), out: lat.show(OUT.get(name)) }, after: { in: lat.show(inn), out: lat.show(out) }, changed });
    IN.set(name, inn); OUT.set(name, out);
    if (changed) {
      for (const p of preds.get(name) || []) if (!queued.has(p.from)) { work.push(p.from); queued.add(p.from); }
    }
  }
```

Every block starts at $\bot$ and is queued once, in reverse order, because a backward analysis learns from successors. Taking a block off the list, the solver joins what each outgoing edge contributes (the edge `rule` substitutes block parameters), applies the block's transfer function to get $\mathrm{IN}$, and records a **step**. If anything changed, the block's predecessors are queued again, since their $\mathrm{OUT}$ depends on this $\mathrm{IN}$. The loop ends when the list is empty, which is exactly when no block's equations are violated.

Visiting blocks in an arbitrary order instead of all at once does not change the answer. Each visit replaces one block's sets by the right-hand side computed from current values, a monotone update that never overshoots the least fixed point (the same induction as in the proof, applied one block at a time), and each visit that changes something moves up a chain of bounded height. So the worklist ends at the same least fixed point after at most height-many changing visits. The forward solver is the mirror image: it joins over predecessors and queues successors. Every step lands in `program.steps(fn, analysis)`, which is what the Facts view and `lab:analysis` links replay.

## 8.5 The running example: liveness of total in eight visits

The engine solves liveness on `total` in 8 block visits. These are the solver's own steps from [B-01](lab:preset?id=B-01), with the sets after each visit:

| step | block | IN after | OUT after | changed |
|---|---|---|---|---|
| 1 | endfor4 | sum2_1 | (empty) | yes |
| 2 | next3 | i3_1 | (empty) | yes |
| 3 | body2 | c_log, i3_1, sum2_1 | i3_1 | yes |
| 4 | for1 | c_log, i3_1, sum2_1 | c_log, i3_1, sum2_1 | yes |
| 5 | entry | c_log | c_log | yes |
| 6 | next3 | c_log, i3_1, v12 | c_log, v12, v15 | yes |
| 7 | body2 | c_log, i3_1, sum2_1 | c_log, i3_1, v12 | yes |
| 8 | for1 | c_log, i3_1, sum2_1 | c_log, i3_1, sum2_1 | no |

Step 2 is the first guess for `next3`: it knows only that `n14 = js.mul(i3_1, 1)` reads `i3_1`, because `for1` has not been visited and contributes nothing. Step 4 visits `for1`, whose parameters `sum2_1` and `i3_1` are live on entry; when step 6 revisits `next3`, the edge `jump for1(v12, v15)` turns those parameters into its arguments, so `v12` and `v15` become live on exit, and `c_log` comes along because `for1` reads it. Step 8 changes nothing and queues nothing: the fixed point. Figure 8.2 lays the eight steps out by block.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 290">
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <line x1="16" y1="40" x2="664" y2="40" class="hair"/>
    <rect x="586" y="48" width="60" height="20" class="f-fill"/>
    <rect x="474" y="78" width="44" height="20" class="f-fill"/>
    <rect x="310" y="108" width="112" height="20" class="f-fill"/>
    <rect x="180" y="138" width="112" height="20" class="f-fill"/>
    <rect x="94" y="168" width="52" height="20" class="f-fill"/>
    <rect x="446" y="198" width="100" height="20" class="f-sel" stroke-width="1.6"/>
    <rect x="310" y="228" width="112" height="20" class="f-fill"/>
    <rect x="184" y="258" width="104" height="20" class="dash" stroke-dasharray="4 3"/>
  </g>
  <g font-size="10" text-anchor="middle" class="f-ink">
    <text x="30" y="30" class="lbl">step</text><text x="120" y="30" class="lbl">entry</text><text x="236" y="30" class="lbl">for1</text><text x="366" y="30" class="lbl">body2</text><text x="496" y="30" class="lbl">next3</text><text x="616" y="30" class="lbl">endfor4</text>
    <text x="616" y="62">sum2_1</text>
    <text x="30" y="62">1</text>
    <text x="496" y="92">i3_1</text>
    <text x="30" y="92">2</text>
    <text x="366" y="122">c_log i3_1 sum2_1</text>
    <text x="30" y="122">3</text>
    <text x="236" y="152">c_log i3_1 sum2_1</text>
    <text x="30" y="152">4</text>
    <text x="120" y="182">c_log</text>
    <text x="30" y="182">5</text>
    <text x="496" y="212">c_log i3_1 v12</text>
    <text x="30" y="212">6</text>
    <text x="366" y="242">c_log i3_1 sum2_1</text>
    <text x="30" y="242">7</text>
    <text x="236" y="272" class="f-mut">unchanged: done</text>
    <text x="30" y="272">8</text>
  </g>
</svg>
```

**Figure 8.2.** The solver's eight visits for liveness on `total`, one row per visit, with the IN set it computed in the column of the block it visited. Step 6, highlighted, is the one where the loop's back edge first carries information: `next3` learns that the arguments of `jump for1(v12, v15)` are needed. The dashed last visit changes nothing.

How does 8 compare with the bound? `total` has 12 values and 5 blocks, so the product lattice of IN and OUT sets has height $2 \times 5 \times 12 = 120$. The bound is loose by design: it limits the number of changing visits in the worst case, and real loops settle far sooner because each set only gains the few values that matter. [A-02 Liveness, one step at a time](lab:preset?id=A-02) replays the steps on the Stage; [load it](lab:preset?id=A-02) and [step to visit 6](lab:analysis?name=liveness&i=6) to see the back edge at work.

> **Try it.** [Load B-01](lab:preset?id=B-01), [show total on the Stage](lab:fn?name=total), [show the Facts](lab:show?view=facts) and [jump to step 6](lab:analysis?name=liveness&i=6): the iteration overlay draws the previous step in grey under the current one.

## 8.6 Writing an analysis: constants, and why intervals need widening

An analysis is a value built from a lattice, a direction and a transfer function. Constant propagation over the flat lattice, one entry per value, fits in a few lines (the sketch is ours, written against the engine's API):

```js
const flat = g.lattice.flat();
const constants = g.analysis('constants').forward().lattice(g.lattice.map(flat))
  .transfer((op, state) => {
    if (!op.result) return state;
    const out = new Map(state);
    const val = a => (typeof a === 'string' ? (state.has(a) ? state.get(a) : flat.TOP) : a.lit);
    const [x, y] = op.args.map(val);
    out.set(op.result, op.op === 'num.add' && typeof x === 'number' && typeof y === 'number' ? x + y : flat.TOP);
    return out;
  });
```

On a function computing `v1 = num.add(2, 3)`, `v2 = num.add(v1, 4)`, `v3 = num.add(v2, a)` with `a` a parameter, `g.solve(constants, fn)` returns `v1: 5`, `v2: 9`, `v3: ⊤` in one visit. [A-04 Your own analysis: constants](lab:preset?id=A-04) adds an edge rule for block parameters and uses the facts in a rewrite of its own.

The interval lattice is the interesting failure. Track each number as a range $[lo, hi]$ through this counting loop:

```text
fn count(n: number) -> number {
entry:
  jump head(0)
head(i: number):
  v1 = num.lt(i, 100)
  branch v1, body(), exit()
body():
  v2 = num.add(i, 1)
  jump head(v2)
exit():
  return i
}
```

The ranges for `i` at `head` rise $[0,0], [0,1], [0,2], \ldots$, one step per turn of the loop, because the interval lattice has infinite height and Kleene's theorem no longer applies. The engine's forward solver gives up after 100,000 block visits with the message `intervals did not converge; the lattice needs a widening`. A **widening** is an operator that jumps ahead: after a few visits, instead of joining, it moves each bound that is still growing to the next of a fixed set of thresholds. With `g.widen.thresholds([0, 10, 100, 1000])` the same analysis stops after 17 visits, the upper bound of `i` climbing $0, 10, 100, 1000, \infty$. The result, $i \in [0, \infty]$, is sound but loose: the analysis never used the branch `i < 100` to cut the range on the edge into `body`, so nothing stopped the bound at 100. Refining facts on branch edges is what the type analysis of [Chapter 9](lab:book?ch=9) does; [A-05 Intervals and widening](lab:preset?id=A-05) shows both halves.

## 8.7 The same solver on any graph, and checking monotonicity

Nothing in the fixed-point argument needs basic blocks. `g.solve(analysis, { kind: 'graph', nodes, edges })` runs the same worklist over any directed graph, and `g.graph.scc(graph)` finds its **strongly connected components**, the groups of nodes that reach each other, which is where iteration is needed at all. On a four-node graph $a \to b \to c \to b$, $c \to d$, a forward analysis that adds each node's name to the set it receives finishes in 9 visits with $b$ and $c$ both knowing $\{a, b, c\}$, and the components are $\{d\}$, $\{b, c\}$ and $\{a\}$. [A-06 The solver on any graph](lab:preset?id=A-06) is the preset for this section.

The theorem's other assumption, monotonicity, is a law. `g.law.monotone(analysis)` draws sets $x \subseteq y$ of values in generated IR, applies the analysis's block transfer to both, and checks $f(x) \subseteq f(y)$. Liveness passes on 300 samples. A transfer that "forgets" when a set grows past two names (returning the empty set) fails on its ninth sample: in block `gen2/left`, $x = \{acc1, i1\}$ gives $f(x) = \{acc1, i1, x\}$ while a larger $y$ gives $f(y) = \emptyset$. A non-monotone transfer function can make the worklist oscillate or stop at a non-solution, and the law finds it before the solver does. The law samples sets of names, so it applies to set-valued analyses such as liveness; [A-07 Monotone or not](lab:preset?id=A-07) is the preset.

## 8.8 Key points

Dataflow questions become systems of equations that loops make circular. A lattice orders possible answers so that every pair has a least upper bound; its height bounds how often an answer can grow. Kleene's theorem says a monotone function on a lattice of finite height reaches its least fixed point by iterating from $\bot$, in at most height-many steps, and the proof works for every analysis at once. The engine's one solver is a worklist version of that iteration, recording every step; on the ledger's `total` it reaches liveness's fixed point in 8 visits against a bound of 120. An analysis is a lattice, a direction and a transfer function; lattices of infinite height, such as intervals, need a widening to terminate, and lose precision unless branches refine the facts. Monotonicity is a law the engine can test.

## Exercises

1. In [A-01](lab:preset?id=A-01), run `g.law.lattice(g.lattice.product(g.lattice.flat([1, 2]), g.lattice.powerset({ universe: ['a', 'b'] })))`. The law refuses, because it does not know how to draw elements of a product. Spread the product into a new object with a `sample(rng)` function that returns a pair (use `rng.pick`), and run the law again. What is the height of this product?
2. Compute by hand the first four liveness steps of Section 8.5 using the equations of Section 8.1, and compare with the table. Where does the edge `jump for1(v12, v15)` need a rule that the equations of Section 8.1 do not state?
3. Change the constant-propagation sketch so that `num.mul` is folded too, and run it on a function with a diamond (`branch` to two blocks that each define a block argument). What does the flat lattice give at the join when both arms pass 7, and when one passes 7 and the other 8?
4. Run the interval analysis of Section 8.6 with thresholds `[0, 100]` and with `[0, 50, 100]` (the engine takes 11 and 14 visits). Why does each extra threshold cost three visits, and why do all of them still end at $[0, \infty]$?
5. A project: give the interval analysis a branch rule. Use `.edge((fn, from, e, out) => …)` to intersect `i` with $[-\infty, 99]$ on the true edge of `branch v1` when `v1 = num.lt(i, 100)`. Does widening still overshoot, and where?

[Chapter 9](lab:book?ch=9) puts this solver to work on the three analyses the lowering depends on.
