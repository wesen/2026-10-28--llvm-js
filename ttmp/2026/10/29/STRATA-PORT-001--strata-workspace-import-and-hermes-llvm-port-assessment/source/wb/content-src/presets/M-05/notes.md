# Decision records

On the screen are two answers to design questions, written as values and checked. The first, *Which root strategy should the pipeline use by default?*, compares three options with evidence that `main.js` measures as it runs: root slots, frame sizes and a fuzzing law for each strategy on the ledger and the tokenizer. The second, *Should the frontend keep every variable a cell?*, is the same kind of question answered in a hurry. `check()` accepts the first and lists four things missing from the second.

> **Try it.** [Run main.js](lab:build). [Experiments](lab:show?view=experiments) shows both records with their checks; [Events](lab:show?view=events) prints the first one in full as YAML.

## The parts of a record

```text
const roots = g.decision('Which root strategy should the pipeline use by default?')
  .context('Every safepoint needs the managed values live across it in root slots; …')
  .options([...three options...])
  .evidence([...evidence, `${fuzz.name} on ${fuzz.samples} generated programs: …`])
  .counterexampleSought('a program whose plan/stress run differs from the spec under stackReuse …')
  .choose('stackReuse')
  .overturnIf('a counterexample to refines(stackReuse), or a corpus where slot sharing costs …')
  .status('accepted');
```

(The excerpt shortens the long strings, so it is shown as text; `main.js` has them in full.) A **decision record** has the question, the context that makes it a question, at least two options, evidence, the counterexample that was looked for, the choice, and the observation that would overturn it. Each part answers a question a reviewer would ask: what else did you consider, how do you know, did you try to prove yourself wrong, and when should we revisit this?

## Evidence that is measured, not typed

The evidence lines are computed. For each strategy `main.js` compiles both programs, reads `metrics()`, and compares the specification with plan mode under GC stress:

```text
distinct · program.js: 52 root slots, largest frame 24 slots, plan = spec under stress: true
stackReuse · program.js: 15 root slots, largest frame 8 slots, plan = spec under stress: true
arena · program.js: 52 root slots, largest frame 20 slots, plan = spec under stress: true
stackReuse · tokenizer.js: 12 root slots, largest frame 11 slots, plan = spec under stress: true
```

plus a fuzzing law, `refines(stackReuse)`, on 15 generated programs with no counterexample. If the engine changes, rerunning the preset recomputes the evidence, and a record whose evidence no longer supports its choice shows it at once. A record with numbers typed in by hand would keep saying what was true on the day it was written.

## What check() asks for

`check()` is deliberately simple. It reports fewer than two options compared, no evidence, no counterexample sought, nothing chosen, and nothing that would overturn the choice. The hurried record fails four of the five: one option (`yes`), no evidence, no counterexample sought, no condition for revisiting. It still has a choice, which is what makes such records dangerous: they look decided.

> **Try it.** In `main.js`, give the hurried record a second option, `'no: promote what no closure captures'`, and evidence from [I-07](lab:preset?id=I-07), and rerun. Which issues remain?

## Why record decisions at all

A compiler accumulates choices (which root strategy, which exception protocol, which rewrites are on by default) that later readers cannot reconstruct from the code. A record keeps the reasons next to the choice and says what would change it, so a later engine change can be checked against it instead of argued about. The workbench's own default, `stackReuse`, is the choice recorded here.

> **Exercise.** Write a record for *Which exception strategy should the first native build use?* with `setjmp` and `statusReturn` as options. Use `g.pipeline().exceptions('statusReturn').check()` as evidence, and make the overturn condition concrete.

## Where next

[Chapter 21](lab:book?ch=21) uses records to plan the port to a real compiler. [M-06](lab:preset?id=M-06) puts records inside a process, and [X-06](lab:preset?id=X-06) is the kind of study that feeds one.
