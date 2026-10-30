# What counts as the same

A compiler is correct when the program it produces behaves the same as the source. This preset pins down "the same" for the workbench. Six pairs of tiny programs each print the same characters; [the Experiments view](lab:show?view=experiments) shows which pairs `g.observe.equal` accepts and the rule it applied to the others.

> **Try it.** [Show the table](lab:show?view=experiments). Four of the six pairs print identical text and are still different behaviours. Then [open main.js](lab:open?file=main.js&line=3) and read the pairs.

## Observations, not text

A run records an **observation** for everything the outside world could see: each `print` with the values it printed (not just their text), the outcome (normal, throw, diverge) and the thrown value. The printed line is derived from the values, and two different values can print the same line. [Open the Events view](lab:show?view=events) after a run of this preset's program: the trace holds `{ type: 'print', values: [-0, NaN] }`, while the output line is `0 NaN`.

## Numbers compare by SameValue

`0 * -1` is negative zero. It prints as `0`, but it is a different number: `1 / -0` is `-Infinity`, and a program can tell. So numbers in observations are compared with **SameValue**, the comparison JavaScript uses in `Object.is`:

| left | right | `===` | SameValue |
|---|---|---|---|
| `-0` | `0` | true | false |
| `NaN` | `NaN` | false | true |

The first row is why a rewrite that turns `x * -1` into `0 - x` must be careful: for `x = 0` the first gives `-0` and the second `+0`. The second row is why a check that uses `===` would call two identical runs different. `observe.equal` reports the first pair with the rule `SameValue distinguishes -0 and +0`; any other pair of different values is reported as `values differ`.

## Objects compare up to a renaming

An object has no printable value, only an identity. The trace records it as a reference `{ ref: 9 }`, where 9 is the object's identity number in that run. Identity numbers are an accident of allocation order, so comparing them directly would make two runs that allocate in a different order look different. Instead `observe.equal` builds a **bijection** as it goes: the first time it meets object 9 on the left and object 12 on the right it pairs them, and from then on 9 must always meet 12 and 12 must always meet 9.

> **Try it.** [Select the print of a, a](lab:node?id=main/entry/2) in this preset's program. On the left of pair three it prints one object twice; on the right, `print({}, {})` prints two objects. The text is the same; the bijection fails at the second value with `identity: one object on the left is two on the right`.

Pair four is the reverse case: the objects are made in a different order, so their numbers differ, but the pairing is consistent and the runs are equal.

## Types and outcomes are observed too

`print("1")` and `print(1)` print the same line, but one value is a string and the other a number, and a later `+ 1` would tell them apart (`"11"` against `2`): the rule is `values differ`. A program that throws `Error: stop` and a program that prints `Error: stop` differ in the number and kind of observations: one has an uncaught throw as its outcome, the other a print and a normal outcome.

## Why this definition

Every later check in the workbench is built on this comparison. `g.law.refines` compiles a program with and without a rewrite and calls `observe.equal` on the two runs; the plan executor's runs under GC stress are compared with the specification's the same way. A definition that ignored `-0` would accept a wrong rewrite; one that compared identity numbers would reject correct ones.

> **Exercise.** Add a pair to main.js that tells `-0` from `0` by printing `1 / x`. Is it still a SameValue difference, or now a difference of text? Then add a pair whose only difference is the order of two prints, and read the rule.

## Where next

[Chapter 2](lab:book?ch=2) uses this definition to state what correctness means. [S-03](lab:preset?id=S-03) restricts the observations by profile, and [M-04](lab:preset?id=M-04) uses `observe.equal` to test three backends against each other.
