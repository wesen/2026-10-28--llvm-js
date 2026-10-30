# Loops and block arguments

A loop changes variables, and SSA does not let a value change. The two meet at the loop's header block: every variable the loop changes becomes a **parameter** of the header, the edge into the loop passes the starting values, and the back edge passes the next ones. This preset compiles Euclid's algorithm and two nested loops from JavaScript and shows where each variable went.

> **Try it.** [Show gcd on the Stage](lab:fn?name=gcd) and [select its loop header](lab:node?id=gcd/while1). The header is `while1(a2_1, b3_1)`; the edge from `entry` passes `(a, b)` and the back edge from `body2` passes `(b3_1, v9)`. The program prints `21 10`.

## Euclid's algorithm

```js
while (b !== 0) {
  const r = a % b;
  a = b;
  b = r;
}
```

becomes

```text
fn gcd(this: any, a: any, b: any) -> any {
entry throws unwind:
  jump while1(a, b)
while1(a2_1: any, b3_1: any) throws unwind:
  v5 = js.strict_ne(b3_1, 0)
  branch v5, body2(), endwhile3()
body2() throws unwind:
  v9 = js.mod(a2_1, b3_1)
  jump while1(b3_1, v9)
endwhile3() throws unwind:
  return a2_1
}
```

The temporary `r` has disappeared: it was only ever the value `v9`. The two assignments `a = b; b = r` are the two arguments of one edge, `jump while1(b3_1, v9)`, and an edge passes all its arguments at once. That matters: done one at a time, `a = b` would overwrite the `a` that `a % b` still needs, which is exactly the bug a hand-written swap invites. The names say where each value came from: `a2_1` is the first parameter made for `c_a2`, the cell the frontend created for `a` (the 2 is the frontend's running count of names).

## Nested loops

`triangle(4)` counts the pairs `j < i` for `i` from 1 to 4, which is 1 + 2 + 3 + 4 = 10. It has two headers:

| header | parameters | carries |
|---|---|---|
| `for1` | `count3_2`, `i4_1` | the count and `i` across the outer loop |
| `for5` | `count3_1`, `j8_1` | the count and `j` across the inner loop |

`count` changes in both loops, so it is a parameter of both headers. The inner loop starts with `jump for5(count3_2, 0)`, taking the outer loop's current count and a fresh `j`. When it ends, `next3` continues the outer loop with `jump for1(count3_1, v19)`: the count as the inner loop left it. [Select next3](lab:node?id=triangle/next3) to see that edge. It may use `count3_1`, a parameter of another block, because every path to `next3` passes through `for5`.

> **Try it.** [Turn on the live overlay](lab:overlay?name=live&on=1) on `triangle`: `i4_1` and `n` are live all through the inner loop, because the outer loop needs them afterwards.

## Back edges on the Stage

A **back edge** goes from a block to one that comes before it in the loop: `body2 → while1` in `gcd`, `next7 → for5` and `next3 → for1` in `triangle`. The Stage routes back edges around the left of the sheet, so a loop reads as a box with a line returning to its top. Two back edges into two headers mean two loops.

## Where the cells went

[Look at gcd before promotion](lab:level?l=L1.cells): there `a` and `b` are cells, with a `cell.load` for every read and a `cell.store` for every write, and the header has no parameters. `promote-cells` finds that nothing outside `gcd` sees those cells, places a parameter for each at the header, and rewrites every load to the value that reaches it. [Chapter 4](lab:book?ch=4) explains how it decides where parameters go.

> **Exercise.** Add a `break` to the inner loop of `triangle` when `j === 2`, rerun, and find the new edge on the Stage. Which arguments does it pass, and to which block? Check the output against your own count.

## Where next

[Chapter 3](lab:book?ch=3) defines blocks and edges. [I-01](lab:preset?id=I-01) writes the same kind of loop by hand, and [I-07](lab:preset?id=I-07) watches promotion place the parameters.
