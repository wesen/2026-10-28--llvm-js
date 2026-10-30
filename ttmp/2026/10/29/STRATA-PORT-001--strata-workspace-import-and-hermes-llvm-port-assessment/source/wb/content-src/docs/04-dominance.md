---
id: dominance
title: Dominance and dominance frontiers
group: Representation
about: Dominators, the dominator tree and how the workbench computes it, the verifier's dominance rule, exceptional edges, and frontiers.
order: 4
---
# Dominance and dominance frontiers

**Dominance** is the relation that makes SSA checkable: a block A dominates a block B when every path from the function's entry to B passes through A. The workbench uses it in three places: the verifier refuses a use its definition does not dominate, `promote-cells` places block parameters at dominance frontiers, and renaming walks the dominator tree. This doc defines the relation, shows how the engine computes it, and explains how exceptional edges fit in. [I-05](lab:preset?id=I-05) computes everything here on one function.

## The relation

Every block dominates itself; the entry dominates every reachable block; and if A dominates B and B dominates C, then A dominates C. A **strict** dominator of B is one other than B. Among the strict dominators of a block exactly one is closest to it, its **immediate dominator** (idom), and drawing an edge from each block's idom to the block gives a tree rooted at the entry, the **dominator tree**.

In I-05's `parity`, a loop whose body is a diamond (`test` branches to `yes` or `no`, which meet at `merge`), the idoms are:

| block | idom |
|---|---|
| `head` | `entry` |
| `test`, `exit` | `head` |
| `yes`, `no`, `merge` | `test` |

`merge` hangs from `test`, not from either arm, because each arm can be bypassed by the other.

## Computing it

The engine computes dominators with the iterative algorithm of Cooper, Harvey and Kennedy ("A Simple, Fast Dominance Algorithm", 2001). Blocks are numbered in reverse postorder of a depth-first search, so a block's dominators come before it. Each block's idom starts unknown, except the entry's; then, repeatedly, each block's idom is set to the common ancestor of its already-processed predecessors in the current tree, until a round changes nothing. The common ancestor is found by walking two fingers up the tree:

```js
// core.js
  const intersect = (a, b) => {
    while (a !== b) {
      while (index.get(a) > index.get(b)) a = idom.get(a);
      while (index.get(b) > index.get(a)) b = idom.get(b);
    }
    return a;
  };
```

`index` is the reverse-postorder number. The finger with the larger number is deeper, so it moves to its idom until the two meet. For reducible control flow, which is all the JavaScript frontend produces, the algorithm settles in two or three rounds; `parity` takes two (the second only confirms that nothing changed). `g.dominators(fn)` returns `{ idom, dominates(a, b), reachable, rounds }`.

## The rule the verifier checks

SSA's rule is that a value's definition dominates every use. Within a block, the definition must come earlier; across blocks, the defining block must dominate the using one. When the rule fails, the verifier gives a **counter-path**, a path from the entry to the use that avoids the definition:

```text
y is defined in left but used in join, which left does not dominate (path entry → join)
```

The path is the evidence: it is a run of the program in which `y` would be read before it was computed. The fix is always a block parameter at the meeting point ([I-04](lab:preset?id=I-04)).

## Exceptional edges and the head of a block

A block-level exceptional exit, `throws to H(args)`, sends control to `H` from any operation of the block that throws, including the first. So the handler may be entered before any operation of the block has run, and the arguments `args` can only be values available at the block's head. The engine makes this exact by splitting every block into two nodes for the dominance computation, its **head** and its **body**: normal edges leave from the body, exceptional edges leave from the head. A handler is then dominated by the head of the protected block, never by its body.

The consequence is visible in the verifier:

```text
fn p(o: any) -> any {
entry throws to h(v):
  v = js.get(o, "a")
  w = js.get(o, "b")
  return w
h(e: any, x: any):
  return x
}
```

is refused with `v is used in entry before it is defined`: `v` is defined in the body of `entry`, and the throw argument is evaluated at its head. If `v` is computed in an earlier block that jumps to a protected one, the same handler may receive it. This is also why the frontend keeps a variable as a cell when it is written inside a `try` and read after the `catch` ([Exceptional control flow](lab:doc?id=exceptions)).

## Dominance frontiers

The **dominance frontier** of A is the set of blocks B such that A dominates a predecessor of B but does not strictly dominate B. Intuitively it is where A's influence ends: the first blocks that can also be reached some other way. A value defined in A, and a different value of the same variable from elsewhere, can meet exactly there.

Cytron and colleagues (1991) compute frontiers from the dominator tree: for every block B with two or more predecessors, walk up the tree from each predecessor until reaching B's idom, adding B to the frontier of every block passed. For `parity` the frontiers are `{merge}` for `yes` and `no`, and `{head}` for `merge`, `test` and `head` itself (the back edge).

A block can be in its own frontier. `head` dominates `merge`, a predecessor of `head`, but does not strictly dominate itself, so `head` is in the frontier of `head`. That is the formal version of "a loop header is where the value from before the loop meets the value from the last turn".

Promotion places a parameter for a variable at the **iterated** frontier of the blocks that store it: the frontier, then the frontier of those blocks, until nothing new appears. A store in `yes` puts a parameter at `merge`; that parameter is a new definition in `merge`, which puts one at `head`. That is exactly where [I-07](lab:preset?id=I-07) finds the parameters of `pos`, `other` and `last`.

## Loops

A **back edge** is an edge whose target dominates its source: `merge → head` in `parity`. Every loop the frontend produces has one, and its target is the loop header. The Stage draws back edges around the left of the sheet. The workbench does not need a separate loop analysis, because the type and liveness analyses iterate to a fixed point over back edges anyway ([Lattices and the fixed-point theorem](lab:doc?id=lattices)); a loop-invariant code motion pass would need one, and dominance is where it would start.

## What this leaves out

The engine computes dominators, not post-dominators (the same relation on the reversed graph, which control-dependence analysis needs), and it does not maintain the tree incrementally: a pass that changes the control flow recomputes it. For the function sizes of the workbench both are cheap.

[Chapter 3](lab:book?ch=3) introduces dominance with the verifier, and [Chapter 4](lab:book?ch=4) uses frontiers to build SSA.
