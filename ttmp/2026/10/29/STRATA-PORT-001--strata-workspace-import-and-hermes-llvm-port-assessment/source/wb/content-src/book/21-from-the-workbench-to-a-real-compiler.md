# From the workbench to a real compiler

The workbench compiles a subset of JavaScript in a web page, checks every stage, and prints LLVM IR it never compiles. The project it prepares for compiles real JavaScript with Hermes's frontend and runtime and LLVM's code generator, and runs the result natively. This chapter says what crosses that gap and what does not. It lists what the workbench has established and what each piece becomes in a native build, names the parts that have no counterpart in the page and must be built or borrowed, and lays out a staged plan whose first step changes one function of the existing emitter and whose later steps are decisions to be taken on evidence rather than commitments. By the end you will be able to say, for any claim in this book, whether it is a property of JavaScript, of the workbench's model, or of a design that still has to be tested on the real system.

## 21.1 What the workbench established

Every part of the workbench was built to answer a question the native system cannot answer cheaply. Figure 21.1 pairs each part with its counterpart in a Hermes and LLVM build.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 330">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="20" font-size="10" class="lbl">in the workbench</text>
  <text x="420" y="20" font-size="10" class="lbl">in a native build</text>
  <g font-size="10">
    <rect x="20" y="32" width="250" height="28" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="28" y="50">reference interpreter and observations</text>
    <rect x="20" y="68" width="250" height="28" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="28" y="86">contracts: behaviour, obligations</text>
    <rect x="20" y="104" width="250" height="28" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="28" y="122">liveness, root plan and plan checker</text>
    <rect x="20" y="140" width="250" height="28" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="28" y="158">laws, generators, shrinking</text>
    <rect x="20" y="176" width="250" height="28" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="28" y="194">lifecycle machines and their checker</text>
    <rect x="20" y="212" width="250" height="28" class="ink f-fill2" stroke="currentColor"/><text x="28" y="230">JavaScript subset frontend, core IR</text>
    <rect x="20" y="248" width="250" height="28" class="ink f-fill2" stroke="currentColor"/><text x="28" y="266">shllvm_* helper names, LLVM text</text>
    <rect x="20" y="284" width="250" height="28" class="ink f-fill2" stroke="currentColor"/><text x="28" y="302">simulated moving collector</text>
    <rect x="420" y="32" width="260" height="28" class="ink" fill="none" stroke="currentColor"/><text x="428" y="50">oracle for differential tests</text>
    <rect x="420" y="68" width="260" height="28" class="ink" fill="none" stroke="currentColor"/><text x="428" y="86">a reviewed table per runtime helper</text>
    <rect x="420" y="104" width="260" height="28" class="ink" fill="none" stroke="currentColor"/><text x="428" y="122">slot assignment in the emitter, an assertion</text>
    <rect x="420" y="140" width="260" height="28" class="ink" fill="none" stroke="currentColor"/><text x="428" y="158">property tests in the build's test suite</text>
    <rect x="420" y="176" width="260" height="28" class="ink" fill="none" stroke="currentColor"/><text x="428" y="194">models of engine shutdown and failure</text>
    <rect x="420" y="212" width="260" height="28" class="acc" fill="none" stroke="currentColor"/><text x="428" y="230">Hermes parser and IR (replaced)</text>
    <rect x="420" y="248" width="260" height="28" class="acc" fill="none" stroke="currentColor"/><text x="428" y="266">real helpers and LLVM itself (replaced)</text>
    <rect x="420" y="284" width="260" height="28" class="acc" fill="none" stroke="currentColor"/><text x="428" y="302">Hermes's collector (replaced)</text>
  </g>
  <g stroke="currentColor" class="ink" stroke-width="1">
    <line x1="270" y1="46" x2="418" y2="46" marker-end="url(#arrow)"/><line x1="270" y1="82" x2="418" y2="82" marker-end="url(#arrow)"/>
    <line x1="270" y1="118" x2="418" y2="118" marker-end="url(#arrow)"/><line x1="270" y1="154" x2="418" y2="154" marker-end="url(#arrow)"/>
    <line x1="270" y1="190" x2="418" y2="190" marker-end="url(#arrow)"/>
  </g>
  <g stroke="currentColor" class="acc dash" stroke-width="1">
    <line x1="270" y1="226" x2="418" y2="226"/><line x1="270" y1="262" x2="418" y2="262"/><line x1="270" y1="298" x2="418" y2="298"/>
  </g>
  <text x="290" y="40" font-size="9" class="mut">carries over</text>
  <text x="296" y="220" font-size="9" class="mut">replaced</text>
</svg>
```

**Figure 21.1.** The workbench's parts and their counterparts. Upper five (solid arrows): artefacts that carry over as they are or as a direct translation. Lower three (dashed): parts that model something the native build already has, and are replaced by it. A schematic.

The upper half is the reason the workbench exists. Each of those five parts is a definition with a checker, and a definition does not care which machine runs it. The lower half is scaffolding: it exists so the upper half has something to run against in a browser.

## 21.2 What carries over

**The specification.** The interpreter of [Chapter 2](lab:book?ch=2) and the observation relation `observe.equal` are the parts most worth keeping, because every other check is a comparison with them. In a native build they become an **oracle**: a slow, simple implementation whose output the fast one must match on every test program. The project already has a second oracle, Hermes's own interpreter, and an independent third, any other conforming engine. [Chapter 17](lab:book?ch=17) showed why the oracle needs oracles of its own: comparing the workbench with Node found that it adopts a returned promise one job early. A port should keep the interpreter, keep the comparison, and treat every disagreement as a question about the specification first.

**Contracts as data.** The behaviour and obligations of every operation ([Chapter 6](lab:book?ch=6)) form a table, and permissions are derived from the table, never written by hand ([Chapter 7](lab:book?ch=7)). In a native build the operations that matter are the runtime helpers the emitter calls. Their contracts can be written as the same kind of table, one row per helper, and reviewed against the helper's source. The laws of [Chapter 19](lab:book?ch=19) run on such a table unchanged: `g.law.antitone()` does not know where the rows came from.

**The plan and its checker.** A root plan is a map from values to slots, and the checker of [Chapter 13](lab:book?ch=13) verifies one property: at every collecting point, every managed value that is live across it or borrowed by it has a slot, and no two such values share one. That property does not depend on how the plan was made, so it can sit beside any slot assignment as an assertion. The workbench sizes a native frame the way the Hermes emitter does:

```js
// core.js
const FIXED_SLOTS = 2;                             // scratch and discard, as in the Hermes emitter
const NATIVE_FRAME_LIMIT = 1024;                   // the emitter's admission limit, in slots
```

Two fixed slots, the root slots, and the argument slots of the largest call, against a limit of 1,024 slots. The same arithmetic in the native emitter is what refused the module that started this project (section 21.4).

Laws and generators become property tests, and decision records (section 21.6) become documents with the same fields. Lifecycle machines stay as models: the shutdown order of [Chapter 18](lab:book?ch=18) is a statement about the native engine's `close`, and its two-event counterexample is a test case to write against it.

## 21.3 What does not carry over

**The helpers.** The LLVM text of [Chapter 16](lab:book?ch=16) calls functions named `shllvm_get`, `shllvm_call` and so on, with an out pointer first. The names and the shape mirror the existing emitter's, but in the workbench they are only text: nothing implements them, and the structural checker verifies only that each is declared. The real helpers wrap runtime functions with their own argument conventions, and their exact behaviour (which ones may collect, which ones throw, which ones read the frame) is the content of the contract table above. That table has to be written from the runtime's source; the workbench's table describes the workbench's operations.

**LLVM.** The workbench never runs LLVM's verifier, optimiser or code generator. Its emitted text keeps every root in memory, passes slots to helpers by pointer, and marks the try state `volatile`, so that the code generator cannot keep a root in a register across a call or lose the try state across `setjmp`. Whether a real LLVM pipeline preserves those assumptions at every optimisation level is a question the page cannot answer. LLVM also offers statepoints, a different contract for telling a collector about live references; the project's research notes list them as an alternative to compare, not a drop-in replacement for the existing protocol.

**The collector.** The simulated collector moves every reachable object at every safepoint and frees the rest, which makes a missing root fail immediately and deterministically. A production collector moves objects only sometimes, may be generational, and needs **write barriers** on stores into older objects. The workbench records `writeBarrier` as an obligation of `js.put`, `js.define`, `cell.store` and `js.global_put` and then does nothing with it: no part of the page checks that a barrier is emitted. A native port must either find a collector configuration that collects at every opportunity and poisons the old copies, or build one, to get the stress testing that plan mode gives for free.

**The language.** The subset has no classes, prototypes, `eval`, modules, generators, BigInt, proxies or UTF-16 string semantics, and its promises have no rejection handlers. Each is a source of contracts the workbench has not written: lexical `eval` shares binding cells across a dynamic boundary, generators suspend a frame with live roots, and module bindings are cells shared between units. The research notes list these as integration constraints even where a formal core omits them.

**Performance.** No number in this book is a running time of compiled code. Steps, collections and slots are counts in a model; they predict where cost goes, not how much.

## 21.4 The evidence that started the project

The handoff for this project records an application campaign of 96 successful executions with nine known admission boundaries, all in unoptimised archive-library code. The concrete case is the unoptimised fflate module factory, which requested 1,084 root slots and three argument slots against the combined limit of 1,024. The notes are careful about what that shows: the current emitter assigns separate slots by IR use rather than by peak liveness, so slot count is not live-value count, and the evidence does not establish that a heap arena is the remedy or that raising the limit is safe.

The workbench measures the same distinction on small programs. Its `distinct` strategy assigns one slot per managed value, as the emitter does today; `stackReuse` shares slots between values never needed at the same safepoint. On the ledger the difference is 52 slots against 15, and across the five programs of [Chapter 20](lab:book?ch=20) the saving ranges from a third to four fifths, with the plan checker clean and every run under GC stress equal to the specification. Those numbers are a reason to try liveness-based slot reuse in the emitter first. They are not a prediction for fflate: a module factory is far larger than anything in this book, and its peak liveness is unknown until someone measures it.

## 21.5 A porting plan in stages

The plan below is ordered so that each stage is useful on its own and each later stage is a decision taken on the earlier stages' evidence. It follows the replacement stages of the project's research notes (semantic core, frontend boundary, analyses and lowering, execution ownership, managed runtime, an optional independent backend), and starts with the smallest change that tests the largest claim.

| stage | change | acceptance |
|---|---|---|
| 0. Freeze the contract | the profile, the observation relation and a corpus (the ledger, the J programs, the generated programs) as tests run against the existing engine | the native engine passes the corpus or each difference is explained |
| 1. Slot reuse in the emitter | liveness over Hermes's lowered IR and greedy colouring in the existing slot assignment; the plan checker as a debug-build assertion | the fflate factory measured: admitted, or its peak liveness reported; no stale use under the most aggressive collection available |
| 2. Helper contracts | a table of behaviour and obligations for every helper the emitter calls, reviewed against the runtime source; permissions derived from it | the laws pass on the table; every optimisation the emitter performs is justified by a derived permission |
| 3. An IR boundary, if needed | a core IR between Hermes's IR and LLVM, or analyses over Hermes's IR directly | a decision record comparing the two on stages 1 and 2's evidence |
| 4. Execution ownership | engine, code and runtime lifecycles as state machines, then as tests of the native engine's admission, failure and shutdown | the counterexamples of [Chapter 18](lab:book?ch=18) written as tests and passing |
| 5. Replacements | frontend, runtime or collector, one at a time | each with its own decision record and differential evidence |

Figure 21.2 draws the stages with their gates.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 190">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g font-size="10">
    <rect x="10" y="40" width="96" height="56" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="18" y="60" class="b">0 contract</text><text x="18" y="78">corpus, oracle</text>
    <rect x="124" y="40" width="96" height="56" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="132" y="60" class="b">1 slot reuse</text><text x="132" y="78">emitter, checker</text>
    <rect x="238" y="40" width="96" height="56" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="246" y="60" class="b">2 contracts</text><text x="246" y="78">helper table</text>
    <rect x="352" y="40" width="96" height="56" class="ink f-fill2" stroke="currentColor"/><text x="360" y="60" class="b">3 IR boundary</text><text x="360" y="78">if needed</text>
    <rect x="466" y="40" width="96" height="56" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/><text x="474" y="60" class="b">4 lifecycles</text><text x="474" y="78">engine tests</text>
    <rect x="580" y="40" width="110" height="56" class="ink f-fill2" stroke="currentColor"/><text x="588" y="60" class="b">5 replacements</text><text x="588" y="78">one at a time</text>
  </g>
  <g stroke="currentColor" class="ink">
    <line x1="106" y1="68" x2="122" y2="68" marker-end="url(#arrow)"/><line x1="220" y1="68" x2="236" y2="68" marker-end="url(#arrow)"/>
    <line x1="334" y1="68" x2="350" y2="68" marker-end="url(#arrow)"/><line x1="448" y1="68" x2="464" y2="68" marker-end="url(#arrow)"/>
    <line x1="562" y1="68" x2="578" y2="68" marker-end="url(#arrow)"/>
  </g>
  <g stroke="currentColor" class="acc" stroke-width="1.6">
    <line x1="342" y1="30" x2="342" y2="110"/><line x1="570" y1="30" x2="570" y2="110"/>
  </g>
  <text x="300" y="126" font-size="10" class="it">decision gate</text>
  <text x="528" y="126" font-size="10" class="it">decision gate</text>
  <text x="10" y="150" font-size="10" class="mut">stages 0 to 2 change the existing system in place; stages 3 and 5 happen only if a decision record says so</text>
  <text x="10" y="168" font-size="10" class="mut">stage 4 can start after stage 0 and run beside the others</text>
</svg>
```

**Figure 21.2.** The porting plan. Heavy outlines: stages that improve or test the existing Hermes and LLVM path directly. Shaded: stages 3 and 5, each behind a decision gate and taken only on evidence from the stages before. A schematic.

Stage 1 is first because it tests the claim this book returns to most often: that a root plan can be computed from liveness, checked independently, and trusted. It touches one function's slot assignment in the emitter and the checker can run beside the old assignment for comparison. If stage 1 fails, by producing a stale reference the checker accepted, the failure is precise: either the liveness was wrong (an analysis bug, found by the laws of [Chapter 8](lab:book?ch=8)) or the obligations of some helper were wrong (a contract bug, found by stage 2's review). Either way the next step is clear.

Stage 3 is a gate rather than a step because the book's core IR is a teaching device as much as a design. It made SSA, exceptional edges and promotion visible. A native build may get the same benefits from analyses over Hermes's existing IR at a fraction of the cost, and only stages 1 and 2 can show whether it does.

## 21.6 Keeping the port honest

Each gate is a decision, and the workbench treats decisions as values with a checker, so that a decision that skipped a step is visible:

```js
// core.js
  check() {
    const issues = [];
    if (this.opts.length < 2) issues.push('fewer than two options compared');
    if (!this.ev.length) issues.push('no evidence');
    if (!this.sought) issues.push('no counterexample sought');
    if (!this.chosen) issues.push('nothing chosen');
    if (!this.overturn) issues.push('nothing would overturn it');
    return { ok: !issues.length, issues };
  }
```

Five checks, and each one names a way decisions go wrong: one option considered, a choice with no evidence, evidence gathered only in favour (no counterexample sought), no choice recorded, and no statement of what would change the decision. The last is the one most often missing. A decision for stage 1 written with `g.decision` passes the check when it states its options (`distinct`, `stackReuse`, `arena`), its evidence (the measurements of section 21.4), the counterexample it looked for (a stale value let through by shared slots: none in 100 generated programs under GC stress, [Chapter 19](lab:book?ch=19)), its choice, and what would overturn it (a stale reference in the native build that the checker accepted, or the fflate factory still over the limit). The same record with one option fails all five checks at once.

`g.process` does the same for a sequence of steps. A process that diverges into options must converge, and every required output must be produced by some step: a process with a `diverge('options')` and no matching `converge`, required to produce a decision it never makes, reports both problems. > **Try it.** [Load M-05 Decision records](lab:preset?id=M-05), [open main.js](lab:open?file=main.js) and [show the Experiments](lab:show?view=experiments): a complete record about root strategies beside a hasty one, each with what its `check()` found missing. Then [load M-06 The process as a value](lab:preset?id=M-06), which checks two plans for porting the ledger against the same required outputs.

[M-07 The capstone](lab:preset?id=M-07) runs every check of the book on the ledger at once.

## 21.7 The running example: the ledger as the first acceptance test

The ledger should be the first program the port runs, because every chapter has measured it and every check has a recorded result. Each check becomes a native test:

| workbench check | measured here | native test |
|---|---|---|
| output and job order equal the specification | `rejected: amount must be a number`, `main 42 42`, `audit 42` | the same three lines, in order |
| plan mode under GC stress equals spec | 68 collections, equal on 3 observations | the native build under the most aggressive collection available, output unchanged |
| plan checker clean | 15 root slots in 6 functions with `stackReuse` | the emitter's slots pass the assertion of stage 1 |
| naive DCE fails refinement | prints `main 0 0`, `audit 0` | an optimiser that deletes an unused call must fail the corpus |
| `erase` of `main/entry/5` refused | five reasons, from `callsUser` | the helper table derives the same refusal for the call helper |
| engine close order checked | destroy before release, 3 states | a test that a job queued before close never runs after it |

> **Try it.** [Load B-01](lab:preset?id=B-01), [open program.js](lab:open?file=program.js&line=22) and [ask the agent to write the acceptance list](lab:ask?q=For%20each%20check%20this%20book%20runs%20on%20the%20ledger%2C%20run%20it%20now%20and%20give%20me%20a%20table%3A%20check%2C%20result%2C%20and%20what%20the%20equivalent%20test%20in%20a%20native%20Hermes%20and%20LLVM%20build%20would%20assert.) with every number measured fresh.

A port that passes this table has not proved much about JavaScript in general. It has shown that the parts of the design this book argued for (a specification, contracts, a checked plan, laws) survived contact with the real system on one program whose every step is understood, which is the right first thing to show.

## 21.8 Key points

- The specification, the contract tables, the plan checker, the laws and the lifecycle models carry over: each is a definition with a checker, independent of the machine that runs it.
- The frontend, the helper names, the LLVM text and the simulated collector are scaffolding; the native build replaces them with Hermes's parser and runtime, real helpers and LLVM.
- The workbench does not run LLVM, does not check write barriers, does not model most of JavaScript and measures no running time; every claim about those needs evidence from the native system.
- The evidence that started the project, a module factory over the 1,024-slot limit, motivates trying liveness-based slot reuse in the existing emitter first, with the plan checker as an assertion.
- Later stages are decisions taken behind gates, recorded with options, evidence, a counterexample sought and what would overturn them.

## Exercises

1. Pick three claims from earlier chapters and classify each as a property of JavaScript, of the workbench's model, or of a design to be tested natively. Justify each classification in a sentence.
2. Write the contract row for one helper you would expect a native emitter to call for property reads: behaviour, obligations, and the permissions they derive. Check the row with `g.perm` on an operation built with `g.op`.
3. Write the decision record for stage 3 with `g.decision`, with at least two options and the evidence you would need from stages 1 and 2. Make `check()` pass without inventing evidence: say what is still to be gathered.
4. List the integration constraints of section 21.3 that the ledger does not exercise, and for each, write a program of five lines or fewer that would (inside the subset where possible, outside it where not).
5. Project: turn the table of section 21.7 into a test plan for the native build, with for each row the command it would run, the output it would compare, and the decision it would feed.
