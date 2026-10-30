# Preface

This book explains how a compiler for JavaScript works by building one in front of you. The compiler is Strata, and every part of it is a value you can open in the workbench beside the text: the program as it arrives, the intermediate representation after each pass, the facts an analysis computed, the plan that tells a garbage collector where references live, the LLVM IR a native backend would receive, and a WebAssembly module that really runs. Each chapter explains one piece, says why a compiler needs it, and links into the workbench so you can watch it happen and then change it.

## Who it is for

You write JavaScript and you have met recursion, hash maps and trees. You have not studied compilers. The book introduces everything else where it is first needed: dominance in [Chapter 3](lab:book?ch=3), lattices and fixed points in [Chapter 8](lab:book?ch=8), refinement in [Chapter 10](lab:book?ch=10), labelled transition systems in [Chapter 18](lab:book?ch=18). A later chapter that uses an earlier idea links back to it instead of teaching it again, so the chapters can be read in order or picked up where a question leads.

## How to read it

Read with the workbench open. The left side holds the reading views (Notes for the loaded preset, the Book, the Docs shelf, the Reference) and the agent; the right side holds the program views: the **Stage**, which draws the control-flow graph of one function as a technical drawing, and below it the IR, Facts, Plan, Machine, Events, Laws and Experiments views. A **preset** is a small folder of files (a `main.js` that builds something, usually a `program.js` it compiles, and notes) that loads into all of these views at once.

Links in the text act on the workbench. [Load the running example](lab:preset?id=B-01) loads a preset; [show the Plan](lab:show?view=plan) brings a view forward; [run it with the collector at every safepoint](lab:run?mode=plan&gc=stress) reruns the program in a different mode. A paragraph that begins **Try it** is an invitation to stop reading and do something; most chapters have several. Each chapter ends with exercises, from a two-minute edit to a preset to a short project, and the agent in the left tile can read the same program you are looking at and answer questions about it.

When the book quotes the compiler's own source, the code block's first line names the file (`// core.js` or `// frontend.js`), and every line in the block is a real line of that file, checked when the book is built. IR shown in the text is what the engine printed, pasted from a run. Numbers about the running example come from measurements recorded with the tool that produced them, so you can reproduce each one.

## The running example

One program runs through the book. It is a ledger: `makeLedger("main")` returns an object with a `name`, a `deposit` method that throws a TypeError for anything that is not a number, a `balance` getter and a `total` method that sums the deposits. The script deposits 10 and 32, tries to deposit `"five"` and catches the error, prints the name, balance and total, and queues a job that prints an audit line. Its output is three lines:

```text
rejected: amount must be a number
main 42 42
audit 42
```

The ledger is small, but it exercises most of what makes JavaScript hard to compile: variables shared between closures, a getter that runs code when a property is read, an exception thrown in one function and caught in another, a loop over an array, and a job that runs after the script ends. Compiled with every default it becomes six functions, and most chapters look at two of them: `deposit`, which has the throw, and `total`, which has the loop.

## What the workbench is, and what it is not

Everything runs in the page, in JavaScript. The frontend parses a subset of JavaScript with the acorn parser and lowers it to core IR; the reference interpreter runs that IR and is the specification every other mode is compared with; the analyses, rewrites and lowering passes are real code operating on real IR. The garbage collector is a simulation: in plan mode the lowered program runs on an interpreter that moves every reachable object at each collection, so a reference the plan forgot to root points at freed memory and the run stops with the name of the value and the place it went stale.

Two backends close the pipeline. One prints LLVM IR text in the shape of the existing Hermes LLVM backend, with its frame, root slots and runtime helper calls; a structural checker confirms the text is well-formed, but no LLVM is in the page and the text is never compiled. The other compiles the numeric core of the language to a real WebAssembly binary, which the browser instantiates and runs. [Chapter 16](lab:book?ch=16) and [Chapter 21](lab:book?ch=21) say what changes when the same plans meet a real Hermes runtime and a real LLVM.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 230" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="10" y="40" width="80" height="44" class="ink"/>
    <rect x="130" y="40" width="80" height="44" class="ink"/>
    <rect x="250" y="40" width="80" height="44" class="ink"/>
    <rect x="370" y="40" width="80" height="44" class="ink"/>
    <rect x="490" y="40" width="80" height="44" class="ink"/>
    <rect x="610" y="40" width="80" height="44" class="ink dash"/>
    <rect x="610" y="108" width="80" height="44" class="ink"/>
    <line x1="90" y1="62" x2="128" y2="62" class="ink" marker-end="url(#arrow)"/>
    <line x1="210" y1="62" x2="248" y2="62" class="ink" marker-end="url(#arrow)"/>
    <line x1="330" y1="62" x2="368" y2="62" class="ink" marker-end="url(#arrow)"/>
    <line x1="450" y1="62" x2="488" y2="62" class="ink" marker-end="url(#arrow)"/>
    <line x1="570" y1="62" x2="608" y2="62" class="ink" marker-end="url(#arrow)"/>
    <path d="M170 84 V130 H608" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="50" y="58" text-anchor="middle" class="b">L0</text><text x="50" y="74" text-anchor="middle">source</text>
    <text x="170" y="58" text-anchor="middle" class="b">L1</text><text x="170" y="74" text-anchor="middle">core IR</text>
    <text x="290" y="58" text-anchor="middle" class="b">L2</text><text x="290" y="74" text-anchor="middle">helpers</text>
    <text x="410" y="58" text-anchor="middle" class="b">L3</text><text x="410" y="74" text-anchor="middle">root plan</text>
    <text x="530" y="58" text-anchor="middle" class="b">LLVM</text><text x="530" y="74" text-anchor="middle">text</text>
    <text x="650" y="58" text-anchor="middle">structural</text><text x="650" y="74" text-anchor="middle">check only</text>
    <text x="650" y="126" text-anchor="middle" class="b">Wasm</text><text x="650" y="142" text-anchor="middle">binary, runs</text>
    <text x="390" y="124" text-anchor="middle" class="mut" font-size="10">numeric core only</text>
  </g>
  <g class="mut" font-size="10">
    <text x="50" y="30" text-anchor="middle">Part I</text>
    <text x="170" y="30" text-anchor="middle">Parts II to V</text>
    <text x="290" y="30" text-anchor="middle">Part VI</text>
    <text x="410" y="30" text-anchor="middle">Part VI</text>
    <text x="530" y="30" text-anchor="middle">Part VII</text>
    <text x="650" y="30" text-anchor="middle">Part VII</text>
    <text x="10" y="186">Part VIII runs what this produces; Part IX checks and measures all of it.</text>
  </g>
  <text x="10" y="214" class="lbl mut">spec runs L1 in the interpreter · plan mode runs L3 with a moving collector</text>
</svg>
```

**Figure P.1.** The levels a program passes through in the workbench, and the parts of the book that explain each one. Core IR (L1) feeds both backends: the LLVM text is checked structurally, and the numeric core compiles to WebAssembly that the page runs.

## The idea underneath

Most compilers grow by accretion: a new optimisation here, a new special case there, until nobody can say which parts may be changed without breaking something else. Strata is organised around one rule instead. The meaning of a program is fixed first, by a small interpreter that is easy to read; every other part of the compiler is a value whose correctness is stated against that meaning. An operation carries a **contract** (what it may read, write, allocate, throw or run, and what lowering owes it); an optimisation fires only when the contract permits it, and says why in a log; a lowering strategy produces a plan that a checker verifies; a correctness claim is a law that the workbench can test on generated programs. Because each part is a value, parts can be swapped, compared and measured, which is what the last part of the book does.

## The parts

Part I shows the whole compiler at once and then fixes what programs mean. Part II is representation: blocks, edges and static single assignment, how source becomes that form, and exceptions as edges. Part III is contracts: behaviours, obligations and the permissions derived from them. Part IV is analysis as least fixed points. Part V is transformation: rewrites, refinement, passes and pipelines. Part VI is lowering: representations, garbage-collection roots and unwinding. Part VII builds the two backends. Part VIII is the runtime: jobs, promises and engines as state machines. Part IX is method: laws, fuzzing and shrinking, experiments over design spaces, and the road from the workbench to a compiler built on Hermes and LLVM. Two appendices list the core IR's operations and every term the book defines.

Start with [Chapter 1](lab:book?ch=1), which reads the ledger view by view.
