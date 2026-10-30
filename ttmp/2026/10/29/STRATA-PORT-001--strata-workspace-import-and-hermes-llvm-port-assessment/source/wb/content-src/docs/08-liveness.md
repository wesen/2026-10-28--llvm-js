---
id: liveness
title: Liveness
group: Analysis
about: Which values are still needed at each point: the equations with block parameters, exceptional edges, and how root plans use the answer.
order: 8
---
# Liveness

A value is **live** at a point of a function if some path from that point reaches a use of the value. Liveness is the analysis behind every root plan in the workbench: a managed value live across a safepoint must be in a root slot there. This doc gives the equations the engine solves, including the two places SSA with block parameters and exceptional edges change them, and the per-operation sets the plan reads. [A-02](lab:preset?id=A-02) replays the solve visit by visit; [Chapter 9](lab:book?ch=9) develops it.

## Per block

Let `use(b)` be the values block `b` reads before defining them (in its operations, its terminator and its edge arguments) and `def(b)` the values it defines (its parameters and its operations' results). Liveness at the start and end of a block satisfies

$$\mathrm{in}(b) = \mathrm{use}(b) \cup \big(\mathrm{out}(b) \setminus \mathrm{def}(b)\big), \qquad \mathrm{out}(b) = \bigcup_{s \in \mathrm{succ}(b)} \sigma_{b \to s}\big(\mathrm{in}(s)\big).$$

Facts flow from uses back to definitions, so the analysis is **backward**, over the powerset lattice of the function's values, from `∅` everywhere. The transfer function is monotone (a larger `out` gives a larger `in`), so the solver reaches the least fixed point ([lattices doc](lab:doc?id=lattices)).

## Block parameters: the edge rule

In SSA with block parameters a loop does not reassign `i`; the loop head has a parameter `i`, and each edge into it passes an argument. A parameter is defined by the block it belongs to, not by the predecessor, so the predecessor must not see it. The map `σ` (the engine's `g.edge.substituteBlockArgs()`) translates a successor's live set across the edge: a live parameter is replaced by the argument this edge passes for it, and every other value passes through unchanged. A literal argument contributes nothing.

On the ledger's loop as [A-02](lab:preset?id=A-02) compiles it on its own, `for1(sum3_1, i4_1)` has both parameters live on entry, and the back edge from `next3` is `jump for1(v13, v16)`, so `σ` turns `{i4_1, log, sum3_1}` into `{log, v13, v16}` at the end of `next3`. Without the substitution, `next3` would appear to need `i4_1` and `sum3_1` at its end, which it does not define, and liveness would leak around the loop.

## Exceptional edges

A block declared `throws to H(args)` may leave from any operation that throws, and the handler `H` receives the thrown value followed by `args`, evaluated at the head of the block. So whatever the handler needs is live at the head of the protected block and across every operation in it that may throw. In

```text
catch1(e4: any) throws unwind:
  return k
try3() throws to catch1:
  x6 = js.get(o, "x")
  return x6
```

`k` is not used in `try3`, yet the engine reports it live across `js.get(o, "x")` (`facts('f').live.across['f/try3/0']` is `k`): if the getter throws, `catch1` returns `k`. The plan roots `k` there. An analysis that ignored exceptional edges would let a collection during a throwing getter invalidate the value the handler is about to return.

The handler's own first parameter, the thrown value, is defined by the edge itself and is never live in the protected block; the engine calls such parameters implicit, as it does the result parameter of an `invoke`'s normal target.

## Per operation: live across

The plan needs more than block boundaries: it needs the set of values live after each operation that may collect, excluding the operation's own result. The engine computes it in the same backward walk and stores it in `facts(fn).live.across`, keyed by operation id. For the `js.add` in that loop's body, `v13 = js.add(sum3_1, v12)`, the set is `i4_1, log`: `sum3_1` is used by the addition and dies there, `v13` is born there, and `i4_1` and `log` are needed on the next turn. `program.facts(fn)` returns these sets; the Stage's live overlay draws them; `why(opId)` explains a value's membership with the use that keeps it live.

## Solving it

The solver starts every block at `∅` and visits blocks from a worklist, last block first, since facts flow backward. A visit recomputes `out` from the successors' current `in` sets, then `in` from `out`; if either changed, the block's predecessors go back on the list. On a loop-free function one pass in reverse order suffices. A loop needs a second look at its body after the head's set has grown: in A-02's `total`, the back-edge block `next3` is visited first with the loop head still empty, and again after the head has acquired its parameters, which is where the 8 visits for 5 blocks come from. Each visit is recorded (`program.steps(fn, 'liveness')`) with the sets before and after, and `lab:analysis?name=liveness&i=6` shows step 6 on the Stage.

## Liveness and dead code

A definition whose result is not live immediately after it is **dead**: nothing will read it. In SSA every value has one definition, so for an operation's result "not live after it" is the same as "has no uses", and the engine's `erase-dead-result` uses the simpler test (and then asks the operation's permissions, because an unused `js.get` may still run a getter). Block parameters are different: a parameter can have uses that are only arguments passed on to other parameters that nothing reads. `promote-cells` places parameters generously and then removes such dead ones with a small liveness computation of its own over the parameter graph, which is why promoted loops carry only the variables they really need.

## What the plan does with it

A safepoint's **required** set is the managed values live across it plus the managed values it borrows as operands (which the helper reads while the collector may run). The root strategy assigns slots so that no two values required at the same safepoint share one, and the plan checker verifies every safepoint against the required set ([A-08](lab:preset?id=A-08)). Values whose type facts say "number" or "boolean" are never required: they do not move.

## Numbers from the running example

For the ledger as compiled by default: liveness on `total` takes 8 block visits for 5 blocks; on all six functions together, 20. `total` has 6 safepoints, and the widest live-across set among them has 3 values. [Chapter 1](lab:book?ch=1) and the ledger preset [B-01](lab:preset?id=B-01) give the rest.

## What this analysis leaves out

Liveness here is about SSA values. The contents of cells and objects are memory, and a value stored in a cell is reachable through the cell, not live as a value; the collector traces cells and objects from the roots, so the plan only needs the cell itself rooted. The analysis is also intraprocedural: a closure's captured cells are parameters of the closure and live like any other parameter. Real register allocators refine liveness further, splitting live ranges and distinguishing values that need a register from those that can stay in memory; the workbench stops at the sets a root plan needs.
