# Recursion

On the screen are three recursive functions: `fib`, the doubly recursive Fibonacci; `depthSum`, which sums the numbers in a nested tree of `{ children: [...] }` objects; and `countDown`, which calls itself 1,000 deep inside a `try`. The program prints `fib(12) = 144`, `sum = 15` and then `RangeError: maximum call stack size exceeded`. Recursion is where the frame a compiler plans for one call gets multiplied by the depth of the call stack, and the last line is the workbench's own limit showing.

> **Try it.** [Open program.js](lab:open?file=program.js&line=2), [show fib](lab:fn?name=fib) and [run in plan mode](lab:run?mode=plan&gc=off). The run takes 4,832 steps and 773 calls; the [Machine view](lab:show?view=machine) shows the depth of each step.

## A function that calls itself through a cell

`fib` refers to itself by name, and the name belongs to the script's scope, so `fib` captures it: the function takes a cell `c_fib` as its first parameter and each recursive call begins by loading it.

```text
else2() throws unwind:
  fib7 = cell.load(c_fib)
  v9 = js.sub(n, 1)
  r10 = js.call(fib7, undefined, v9)
  fib11 = cell.load(c_fib)
  v13 = js.sub(n, 2)
  r14 = js.call(fib11, undefined, v13)
  v15 = js.add(r10, r14)
  jump endif3(v15)
```

The cell is loaded twice, once per call, because the first call could have assigned a new function to `fib`. Nothing in this program does, but the compiler cannot know that from `fib` alone. [Select the second load](lab:node?id=fib/else2/3) and the first call before it: the call's contract is `callsUser`, which includes writing cells.

## What one frame costs, and what the stack costs

[The Plan view](lab:show?view=plan) gives `fib` 3 root slots and a 7-slot frame (56 B): the cell and `n` must survive the first recursive call, and `r10`, its result, must survive the second. Values that are never needed at the same call share a slot: `c_fib`, `fib11` and `r14` take turns in slot 0. That is one activation. At the deepest point of `fib(12)` 13 frames are on the stack, and plan mode reports a peak of 89 rooted slots across all of them. A single frame's plan is a local decision; its cost is paid once per frame on the stack, which is why [Chapter 13](lab:book?ch=13) cares about frame size even when a function looks small.

## Recursion over objects

`depthSum` mixes recursion with a `for … of` loop. The loop variable and the running sum are block parameters of `forof3`, the array of children is read once into `children9`, and each child is passed to a recursive call. Because `tree` is an object while the loop runs, the array stays in a root slot across every call, so a collection in the middle of the recursion moves it and the loop goes on reading the moved array.

> **Try it.** [Run with GC stress](lab:run?mode=plan&gc=stress). The collector runs 2,301 times and moves 37,463 objects in total; the three lines of output do not change.

## The stack limit

`countDown(1000)` is correct JavaScript, and a real engine would run it. The workbench's interpreter stops at 300 frames (the machine's `maxDepth`) and throws a RangeError, which the `try` in `main` catches and prints. At that point plan mode counts 1,805 rooted slots on the stack, 14,440 B: 300 frames of `countDown` at 6 slots each, plus `main`. The limit is a property of this interpreter, not of the program, and it is low on purpose so that runaway recursion stops quickly.

> **Exercise.** Change `countDown(1000)` to `countDown(250)` and rerun: what does the program print now, and what is the peak of rooted slots in plan mode? Then write an iterative `countDown` with a `while` loop and compare its frame with the recursive one.

## Where next

[Chapter 2](lab:book?ch=2) describes the interpreter's steps, frames and budgets. [S-05](lab:preset?id=S-05) runs a program that never stops, and [L-07](lab:preset?id=L-07) looks at the 1,024-slot limit on a single native frame.
