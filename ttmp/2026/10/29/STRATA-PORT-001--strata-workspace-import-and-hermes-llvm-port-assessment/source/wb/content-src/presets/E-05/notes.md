# Admission refuses

An engine runs only code it has admitted, and admission is a check that happens before any of that code runs. This preset hands one engine five things in turn. Four are refused, each with an `AdmissionError` that names the reason; the fifth is admitted and runs. The engine's output stays empty until the fifth: the program prints `ran: box.n = 1` as its first act, so any code that slipped through would show.

> **Try it.** [Open the Experiments view](lab:show?view=experiments) and read the `reason` and `output` columns. Then [open main.js](lab:open?file=main.js&find=strategies) to see what this engine requires.

## The five cases

| case | admitted | reason | output |
|---|---|---|---|
| not a program | no | not an artifact | (empty) |
| does not compile (verifier) | no | compile errors | (empty) |
| does not compile (missing roots) | no | compile errors | (empty) |
| strategy mismatch (stackReuse) | no | strategy mismatch | (empty) |
| admitted (distinct) | yes | | ran: box.n = 1 |

**Not a program.** `admit` takes a compiled Program or its artifact, never a source: compiling is the compiler's job, and an engine that compiled on admission would have two places where code enters it.

**Does not compile.** The second case is core IR that uses `v1` after a join where only one path defined it. The verifier refuses it with a counter-path, and admission passes the first error on:

```text
broken.ir did not compile: v1 is defined in left but used in join, which left does not dominate (path entry → right → join)
```

The third case compiles the program with the `none` root strategy, and the plan checker's first missing root becomes the reason. Both refusals carry `ranCode: false`, which the engine sets when it is certain nothing ran.

**Strategy mismatch.** This engine was created with `g.engine({ strategies: { roots: 'distinct' } })`: its runtime expects every frame laid out with one slot per managed value. A program compiled with the default `stackReuse` is correct on its own terms, but the engine cannot run it, because the frames would not match what the runtime scans:

```text
strategy mismatch: roots is stackReuse in the artifact and distinct in the engine
```

The artifact records its strategies (`program.artifact.requires`), and admission compares them field by field.

> **Try it.** Change `'distinct'` to `'stackReuse'` in the engine's options in [main.js](lab:open?file=main.js&line=4) and rerun. Which rows change, and why does the last one now fail?

## Why refuse early

Every refusal here is a fact about the code, not about an input, so it can be decided before running. Deciding it before running means a refused program cannot have done anything: no output, no heap changes, no queued jobs, no timers. An engine that discovered the mismatch halfway through a script would leave the domain in a state no one planned for. The `ranCode` field makes the promise explicit; the first case does not report it, because nothing was even compiled for that call.

> **Exercise.** Add a sixth case: a program that compiles but throws at run time (`throw new Error("late")` after the print). Is it admitted? What does `evaluateScript` report, and what is in the output? Write down the difference between a refusal and a failure.

## Where next

[Chapter 18](lab:book?ch=18) covers admission and the engine's lifecycle. [E-04](lab:preset?id=E-04) is a normal lifecycle, [I-04](lab:preset?id=I-04) the verifier and [L-04](lab:preset?id=L-04) the plan checker whose errors appear here.
