# A factorial study of roots

On the screen is a small experiment run the way experiments should be: the question, the factors and the hypotheses are written in `main.js` before any number is computed, and the verdicts come out of the data. Two factors are crossed: the root strategy (`distinct`, `stackReuse`, `arena`) and the program (the ledger, the counter of [J-01](lab:preset?id=J-01), the tokenizer of [J-04](lab:preset?id=J-04), the invoice of [J-07](lab:preset?id=J-07)). That makes 12 cells, each measured once, because the engine is deterministic and a repeated run would give the same numbers.

> **Try it.** [Run main.js](lab:build), then read [Laws](lab:show?view=laws) for the three verdicts and [Experiments](lab:show?view=experiments) for the twelve rows they were computed from.

## The hypotheses, stated first

```text
H1  stackReuse never needs more root slots than distinct, on any program;
H2  no strategy changes what a program observably does (plan mode under GC stress = spec);
H3  over the corpus, stackReuse needs at most half the root slots of distinct.
```

Each one says what would refute it. H1 is refuted by one program, H2 by one cell, H3 by a ratio above 0.5. Writing the threshold down before the run is what keeps a study honest: after the numbers are in, it is easy to decide that 0.6 would also have been a good result. In `main.js` each hypothesis becomes an entry of a LawReport, `{ name, ok, samples, note }`, so the Laws view shows it with its evidence.

## The measurements

For each cell `main.js` compiles the program with the strategy, runs it in the specification and in plan mode with GC stress, and records root slots, the largest frame, collections, objects moved and whether the two runs agree. `g.table(rows, { title, columns })` turns the rows into Results for the Experiments view.

| program | distinct | stackReuse | arena |
|---|---|---|---|
| ledger.js | 52 | 15 | 52 |
| counter.js | 29 | 11 | 29 |
| tokenizer.js | 44 | 12 | 44 |
| errors.js | 47 | 18 | 47 |

The table above gives root slots. `arena` reserves as many slots as `distinct`, since it makes one slot per value too, in a runtime-owned record instead of the frame. Collections and objects moved depend only on the program: the ledger collects 68 times whatever the strategy, the tokenizer 223 times. That is the strongest evidence for H2 short of a proof: the strategy decides where values wait during a collection, never whether the collection happens.

## The verdicts

All three hypotheses are supported. H1 holds on all four programs. H2 holds on all 12 cells. H3 holds with room to spare: `stackReuse` needs 56 slots over the corpus against 172 for `distinct`, a ratio of 0.33. The ratio is not a property of the strategy alone. It depends on how many managed values a function has and how few of them are needed at the same safepoint, which is why the counter (29 to 11) and the invoice (47 to 18) save less than the tokenizer (44 to 12).

> **Try it.** [Ask the agent](lab:ask?q=Which%20function%20of%20tokenizer.js%20gains%20most%20from%20stackReuse%2C%20and%20why%3F) which function of the tokenizer gains most from slot sharing. It can compile the file and compare `plan(fn).slots` under both strategies.

## What this study does not show

Four programs written for this workbench are not a sample of JavaScript. The study shows that `stackReuse` behaves as claimed on them, and gives a number to compare with a larger corpus later. Execution time is not measured at all: the engine counts steps, and a slot shared between two values costs no extra steps here, while on real hardware it could change register allocation. A study states its limits next to its verdicts.

> **Exercise.** Add `'none'` as a fourth strategy. Which hypotheses can still be evaluated, and how should the table record a cell that does not compile? Then paste the program of [J-05](lab:preset?id=J-05) into `counter.js` (or ask the agent to write it as a new file and add it to `programs`) and check whether H3 still holds.

## Where next

[Chapter 20](lab:book?ch=20) treats experiments and design spaces. [L-03](lab:preset?id=L-03) explains the strategies themselves, and [M-05](lab:preset?id=M-05) turns a study like this into a decision record.
