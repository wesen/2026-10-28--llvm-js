# Intervals and widening

An **interval** `[lo, hi]` bounds a number: the loop counter `i` in `program.ir` stays in `[0, 100]`, and an analysis that proved so could remove bounds checks or pick a 32-bit representation. The interval lattice has a problem the lattices of [A-01](lab:preset?id=A-01) do not: it has infinite height. `[0, 0] ⊑ [0, 1] ⊑ [0, 2] ⊑ …` never ends, so a loop can make the solver climb forever. This preset runs one interval analysis in three versions and shows how **widening** forces it to stop.

> **Try it.** [Show the table](lab:show?view=experiments). The plain version gives up after 100,000 block visits; refining on the branch converges in 308; widening converges in 11.

## The program

[Open program.ir](lab:open?file=program.ir):

```text
loop(i: number):
  c = num.lt(i, 100)
  branch c, body(i), exit(i)
body(j: number):
  n = num.add(j, 1)
  jump loop(n)
```

The [run](lab:show?view=machine) prints 100. The question for the analysis is what `i` can be at `loop` and what `r` can be at `exit`, for every run, without running it.

## Plain: no end

The transfer function adds intervals (`[a, b] + [c, d] = [a + c, b + d]`) and the edge rule copies argument intervals to parameters. On the first visit `i` is `[0, 0]`; the back edge brings `n = [1, 1]`, so `i` becomes `[0, 1]`; then `[0, 2]`, and so on. Nothing in the analysis knows that the branch stops the loop at 100, so every visit raises `hi` by one. The solver's guard stops it at 100,000 visits with `intervals did not converge; the lattice needs a widening`, which the table reports.

## Refined: slow but exact

The second version refines on the branch, the way type facts refine on `typeof` ([A-03](lab:preset?id=A-03)): on the true edge of `num.lt(i, 100)` the argument `i` is clipped to `hi ≤ 100`, on the false edge to `lo ≥ 100`. Now the climb stops: `j` reaches `[0, 100]`, `n` reaches `[1, 101]`, and `i` settles at `[0, 101]`, after 308 visits. The bound is one too wide because a closed interval over the reals cannot say "less than 100", only "at most 100". `r` at the exit is `[100, 101]`.

308 visits for a four-block function is the cost of climbing one step per turn: the number of visits grows with the loop bound, so a loop to a million would take millions.

## Widened: fast, less precise

A **widening** operator `∇` replaces the join at a block that is being revisited, and jumps instead of climbing. `g.widen.thresholds([0, 100, 1000])` widens a growing bound to the next threshold, and to infinity past the last:

```js
const w = g.widen.thresholds([0, 100, 1000]);
a = a.widen((prev, next) => new Map([...next].map(([k, v]) => [k, w(prev && prev.get(k), v)])));
```

The map wrapper applies it to every value's interval. With widening the solver finishes in 11 visits: `i` is `[0, 1000]` at the loop and `r` is `[100, 1000]` at the exit. The answer is sound (every run's values are inside) and less precise than the refined one, because the first widening jumped past 101 to the threshold 1000. Choosing thresholds is choosing which bounds the analysis can still express; the constants that appear in the program, such as 100, are the usual candidates.

> **Try it.** In main.js, change the thresholds to `[0, 101, 1000]` and [rerun](lab:build): still `[0, 1000]`. The solver widens at every block it revisits, not only at the loop head, so `j` in `body` is widened from `[0, 2]` past the refinement's bound 100 to 101, `n` reaches 102, and the loop head jumps to 1000. Now try `[0, 100, 101, 1000]`: the widened version agrees with the refined one, `[0, 101]`, in 11 visits.

## Why widening is sound

The solver computes a fixed point of the transfer functions. Widening gives up the least fixed point for a larger one: it only ever moves states up, so whatever it reaches is still above every state a real run produces, and any post-fixed point is a sound answer. What it guarantees is termination: each threshold step is a finite jump, and there are finitely many thresholds before infinity. [Chapter 8](lab:book?ch=8) states the conditions; the classic reference is Cousot and Cousot (1977).

> **Exercise.** Change the program to count down: start at `100`, test `num.lt(0, i)`, and subtract 1. Adjust the refinement (the tested value is now the second operand) and the thresholds, and check that the widened answer still contains every value a run takes.

## Where next

[Chapter 8](lab:book?ch=8) has the theory and [the lattices doc](lab:doc?id=lattices) the short version. [A-04](lab:preset?id=A-04) is the same kind of analysis over a finite lattice, and [A-07](lab:preset?id=A-07) checks monotonicity, which widening also needs.
