# A generated program

The program on the screen was not written by a person. `g.gen.js({ seed: 1 })` assembled it from templates: a shared object `cell`, a getter `r.x` that increments it, a `try`/`catch`, an arrow function, a `try`/`finally`, an array, a queued job and two loops. It prints `2`, `no throw`, `finally 2` and `job 9`. Generated programs are how the workbench tests its own compiler: they are cheap, they combine features in ways nobody thought to try, and they come as a list of statements that can be shrunk when one of them breaks something.

> **Try it.** [Open program.js](lab:open?file=program.js&line=2), then [run it in plan mode with GC stress](lab:run?mode=plan&gc=stress). The output is the same as the specification's, after 71 collections in 127 steps.

## How the generator writes

`g.gen.js` starts every program with the same two statements, the object and the getter, and then draws seven more from a pool of templates with a seeded random generator, so seed 1 always gives this program. The templates are chosen to hit the places where compilers go wrong: a getter with a side effect (is a property read dead code?), `try`/`finally` (does the finally run on every path?), a closure over a mutable object (is the cell shared?), a job (is the order kept?), loops (are block parameters right?). `main.js` regenerates the program from the seed and prints a line if the copy in `program.js` has been edited.

## What the compiler made of it

Four functions: `main`, the getter `get_x`, the arrow `f0` and the job `arrow_2`. `cell` is captured by all three, so it stays a cell, `c_cell2`; the other eight variables are promoted. [Show main](lab:fn?name=main): the first `try` is the block `try3`, whose only operation is the read of `r.x`, and the `try`/`finally` lowers to completion records in `finally4` and its neighbours, as in [J-03](lab:preset?id=J-03).

> **Try it.** [Select the read of r.x in the first try](lab:node?id=main/try3/0). Its result `x11` is never used. Its permissions refuse `erase` all the same: the getter changes `cell.n`, and the next line prints it.

## Two laws on one program

`main.js` returns two refinement checks on this single program. The first, [refines(pipeline plan)](lab:law?name=refines%28pipeline%20plan%29), compiles it with the default pipeline, runs it in plan mode under GC stress, and compares every observation with the specification: it holds. The second, [refines(naive-dce)](lab:law?name=refines%28naive-dce%29), compiles it with the canonical rewrites plus `naive-dce`, which erases any operation whose result is unused, and compares again. It fails. Before the rewrite the program prints `2`, `no throw`, `finally 2`, `job 9`; after it, `0`, `no throw`, `finally 0`, `job 7`, because both reads of `r.x` were deleted and the getter never ran.

That is the whole method in miniature: a program nobody wrote, a property that should hold, and a run that says it does not. [M-02](lab:preset?id=M-02) runs the same check on twenty programs at a time, and [M-03](lab:preset?id=M-03) shrinks this one to the three statements that matter.

## Reading generated code

Generated programs are ugly on purpose. `let k61 = [1, 2, 3].length + cell.n;` computes a value nobody reads, which is exactly the situation dead-code elimination is for; the name `k61` comes from the random generator. When a law fails, read the counterexample as evidence about the compiler, not as a program anyone would write.

> **Exercise.** In `main.js`, change the seed to 4 and copy the new program into `program.js` (`print(g.gen.js({ seed: 4 }).text)` prints it). Does naive DCE still break it? Then try seed 2: the rewrite leaves that program's output alone. Read it and say why.

## Where next

[Chapter 19](lab:book?ch=19) covers laws, generators and shrinking. The doc on [property testing](lab:doc?id=property-testing) explains the method, and [T-02](lab:preset?id=T-02) shows the naive rewrite on a hand-written getter.
