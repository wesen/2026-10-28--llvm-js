# The interpreter, step by step

The **specification** of the workbench is an interpreter over core IR: it runs one operation at a time, keeps a stack of frames and a heap of objects, and writes down what it did. Every other way of running a program (the lowered plan with a moving collector, the WebAssembly backend) is checked against what this interpreter does. This preset runs a recursive factorial and lets you replay it step by step in [the Machine view](lab:show?view=machine).

> **Try it.** [Show the Machine view](lab:show?view=machine) and [jump to step 17](lab:step?n=17): the fourth call of `fact` is at depth 5, comparing `n <= 1` with `n` equal to 1. The output is `24` after 31 steps.

## A step is one operation

The interpreter takes a function's first block, binds its parameters, and runs the operations in order. Each operation has a **step** function in its definition, and the interpreter calls it with the values of the operands:

```text
fn fact(c_fact: cell, this: any, n: any) -> any {
entry throws unwind:
  v4 = js.le(n, 1)
  branch v4, then1(), endif2()
then1() throws unwind:
  return 1
endif2() throws unwind:
  fact6 = cell.load(c_fact)
  v8 = js.sub(n, 1)
  r9 = js.call(fact6, undefined, v8)
  v10 = js.mul(n, r9)
  return v10
}
```

After each operation it records `{ n, fn, block, op, text, value, depth }`: the step number, where it was, the operation's text, the value it produced and how many frames were on the stack. A terminator is a step too: [the branch at step 6](lab:step?n=6) records `false` and goes to `endif2`.

## A call is a frame

`js.call` looks up the callee, a closure for `fact`, and runs its body in a new **frame** with its own environment. The closure carries the cell `c_fact` it captured, so the callee's parameters are `c_fact`, then `this` (here `undefined`), then `n`. [Select the call](lab:node?id=fact/endif2/2) to see its contract: `callsUser`, because the callee can be any function.

Records are written when an operation finishes, so the record of a call comes after every step of the callee. Steps 9 to 25 are the inner calls; [step 26](lab:step?n=26) is the outermost `fact` receiving 6 from its call, and step 27 multiplies it by 4.

| step | depth | at | value |
|---|---|---|---|
| 5 | 2 | `fact/entry/0` `js.le(n, 1)` | false |
| 17 | 5 | `fact/entry/0` `js.le(n, 1)` | true |
| 19 | 5 | `fact/then1/term` `return 1` | 1 |
| 21 | 4 | `fact/endif2/3` `js.mul(n, r9)` | 2 |
| 27 | 2 | `fact/endif2/3` `js.mul(n, r9)` | 24 |
| 29 | 1 | `main/entry/4` `js.call(fact4, undefined, 4)` | 24 |

## Outcomes

A run ends in one of four **outcomes**: `normal` (main returned), `throw` (an exception left main), `diverge` (the step budget ran out) or `error` (the engine itself could not go on, such as a stale reference in plan mode). This one is `normal`. The outcome, the printed lines and the order of observable events are what the rest of the compiler must preserve; [S-02](lab:preset?id=S-02) says exactly what "the same" means.

> **Try it.** [Open program.js](lab:open?file=program.js&line=7), change `fact(4)` to `fact(-3)`, [rerun](lab:build) and count the steps: 10 in all, and `fact` itself takes only three (its comparison, its branch and `return 1`).

## What the interpreter does not do

It does not optimise, and it does not collect garbage: objects stay at their addresses for the whole run (`collections: 0`). It is slow on purpose, because its job is to be easy to check against the JavaScript rules it implements: one `step` function per operation (in `20-ops.js`) and a machine of about 550 lines (`40-machine.js`). After main returns it runs the job queues ([E-01](lab:preset?id=E-01)); this program queues nothing.

> **Exercise.** Write `fact` as a loop instead of recursion, rerun, and compare the number of steps, calls and the deepest frame printed in [Events](lab:show?view=events). Which version would need more root slots in a lowered plan, and why?

## Where next

[Chapter 2](lab:book?ch=2) builds the argument that the interpreter is the specification. [S-02](lab:preset?id=S-02) compares runs observation by observation, and [S-05](lab:preset?id=S-05) runs out of steps on purpose.
