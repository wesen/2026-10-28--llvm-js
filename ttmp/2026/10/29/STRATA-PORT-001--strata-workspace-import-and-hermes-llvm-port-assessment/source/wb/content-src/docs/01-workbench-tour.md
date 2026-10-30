---
id: workbench-tour
title: A tour of the workbench
group: Start here
about: What each view shows, what the header controls, how presets and the agent work, and what runs in the page.
order: 1
---
# A tour of the workbench

The Strata workbench is a JavaScript compiler you can watch. It takes a small JavaScript program (or core IR you write yourself), compiles it through every stage of a real compiler design, and shows each stage in a view of its own: the control-flow graph on a drawing sheet, the IR at every level, the analyses and their iterations, the root plan, a step-by-step interpreter, laws and experiments. This doc is the map. [B-01](lab:preset?id=B-01) is a good first preset to have open while reading it.

## What runs, and what does not

Everything runs in the page, in JavaScript: the frontend (built on the acorn parser), the core IR and its verifier, the reference interpreter, the analyses, the rewrites, the lowering to runtime helpers, the root planner and its checker, a simulated moving garbage collector, an LLVM IR printer and a WebAssembly encoder. Two things are not in the page. LLVM is not: the LLVM text the workbench prints is in the shape of the Hermes LLVM backend and is checked for structure (labels, terminators, definitions, declarations), but nothing compiles it. Hermes is not: where the workbench says a set of operations is "provided by Hermes", it means the plan uses the helper names and protocols of the Hermes backend, not that Hermes code runs. WebAssembly is real: the numeric core of a program is encoded to a binary and run by the browser.

## The views

The dock holds fourteen views in tiles. Each tab has a name and a one-line about:

| view | shows |
|---|---|
| **Notes** | the guide to the loaded preset, with links that act on the workbench |
| **Code** | the preset's files, editable; `main.js` is the script that builds what the views show |
| **Agent** | a coding agent with one tool, `eval`, that can read and change the preset |
| **Docs** | the shelf of topic docs, this one included |
| **Book** | *Compilers from First Principles*, the textbook |
| **Reference** | the whole API on one page |
| **Stage** | one function as a drawing: blocks, edges and overlays |
| **IR** | every level of the program as text or JSON: L0 to L3, LLVM, WAT |
| **Facts** | analysis results and the solver's steps |
| **Plan** | root slots, safepoints and unwinding for each function |
| **Machine** | the reference interpreter's run, step by step |
| **Events** | output, diagnostics, decisions and the pass trace |
| **Laws** | properties checked by sampling, with counterexamples |
| **Experiments** | tables of results: design spaces, comparisons |

**Layout ▾** in the header offers five arrangements: code beside the stage (the default), the program in three columns, reading the book, experiments and laws, and everything in one tile. Tabs can be dragged between tiles.

> **Try it.** [Load B-04](lab:preset?id=B-04), which is built to show the Stage at work, and [bring the Plan view forward](lab:show?view=plan).

## The header

From left to right: the preset menu (with "edited" when you have changed a file), **Run** (Ctrl or ⌘ and Enter) which reruns `main.js`, the run mode (**Spec**, **Plan**, **Wasm**), the collector setting for plan mode (**Off**, **Alloc**, **Stress**), the function picker, a status pill (`ok · 6 functions · 15 blocks · 78 ops`, or the number of errors) and an outcome pill (the outcome of the last run, `normal`, `throw`, `diverge` or `error`, with its mode and step count). The mode decides how the program `main.js` returned is run for the Machine view:

- **Spec** runs the core IR in the reference interpreter, the specification everything else is compared with ([S-01](lab:preset?id=S-01)).
- **Plan** runs the lowered program with its root plan, and with **Stress** a moving collection before every operation that may collect. A value the plan failed to root is then caught as a stale reference ([L-05](lab:preset?id=L-05)).
- **Wasm** runs the functions that are in the numeric core profile as a real WebAssembly module ([W-01](lab:preset?id=W-01)).

## Presets and main.js

A **preset** is a folder of files plus notes. `main.js` is the body of an async function with `g` (the API), `source(name)`, `files`, `print` and the unit constructors in scope, and whatever it returns is what the views show: a Program from `g.compile`, a run, a law report, a results table, or an object holding several. The smallest useful script is:

```js
const program = g.compile(g.pipeline(), source('program.js'));
return program;
```

You can edit any file and rerun; the preset menu marks it edited and **Revert all edits** restores it. **Save as** copies the current files and notes into a preset of your own, with an id `U-01`, `U-02` and so on, kept in the artifact's storage for you. The [Reference](lab:show?view=reference) lists the whole API.

## Levels

The compiler keeps every stage:

| level | is |
|---|---|
| L0 | the source text |
| L1.cells | core IR as the frontend wrote it: every variable a cell |
| L1 | core IR after promotion and rewrites |
| L2 | L1 with each operation bound to an inline instruction, a runtime helper or a direct call |
| L3 | L2 with the root plan: which value is in which slot at each safepoint |
| LLVM | LLVM IR text in the Hermes backend's shape |
| WAT | the WebAssembly text of the functions in the core profile |

The Stage draws L1, L2 or L3. [B-03](lab:preset?id=B-03) prints one function at every level.

## Links

Notes, docs, the book and the agent's answers contain links that act on the workbench: load a preset, open a file at a line, select an operation, switch a level, toggle an overlay, run in a mode, step the Machine view, show an iteration of the solver. They look like ordinary links with a small marker. In this doc, [this link shows the Facts view](lab:show?view=facts) and [this one turns on the live overlay](lab:overlay?name=live&on=1).

## The agent

The Agent view is a coding agent with a single tool, `eval`, which runs JavaScript against the same API as `main.js` plus the workbench itself: read and edit the preset's files, rerun, inspect the program (`ir`, `facts`, `plan`, `perm`, `why`), select operations, show views, and save or edit presets of your own. Each step shows the code it ran and its result; files are snapshotted before every step, so any step can be reverted. **Mode** sets how far it may go: **Auto**, **Ask** (approve each step) or **Read-only** (edits throw). **Model** and **Thinking** trade speed for depth. Each preset suggests a few questions to start with.

> **Try it.** [Put a question in the composer](lab:ask?q=Which%20operations%20in%20this%20program%20may%20collect%2C%20and%20why%3F) and send it from the Agent view.

## Where to go next

Read [Chapter 1](lab:book?ch=1) with B-01 loaded: it follows the running example through every view. The shelf docs [Semantics and observations](lab:doc?id=semantics) and [SSA with block parameters](lab:doc?id=ssa) are the two ideas every other part of the workbench builds on.
