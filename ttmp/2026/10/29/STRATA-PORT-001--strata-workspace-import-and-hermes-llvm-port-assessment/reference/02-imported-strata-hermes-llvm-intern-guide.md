---
Title: Imported Strata Hermes LLVM intern guide
Ticket: STRATA-PORT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T20:27:56.374484311-04:00
WhatFor: ""
WhenToUse: ""
---

> Working revision of the imported guide. The unchanged original is preserved in source/exports and the ZIP. The Strata-first direction is selected. The current native implementation decisions and milestone scope are in ../design-doc/01-strata-first-native-compiler-design-and-intern-implementation-guide.md.

# Strata on the real Hermes and LLVM: an intern's guide

Oct 29, 2026 · @Manuel


## Current implementation decisions

The working native compiler is now under the repository's `strata/` directory; reference source and original documents are under this ticket's `source/`. Follow the separate detailed design guide for the selected initial scope. The longer roadmap below remains useful context, but replacement of Hermes/LLVM, expanded frontend syntax, ABI-version admission, speculative JIT tiers, and a generated contract database remain future work.

The initial compiler uses managed two-slot completion environments, full-lifetime root reuse with a distinct-home comparison, exact header-derived helper prototypes, and build-dependent sanitizer link flags. It does not use the workbench's illustrative LLVM output as executable code. Published test results belong in the implementation diary and evidence directory; imported historical counts are not new native evidence.

## 1. What this guide is for

This guide takes you from two separate codebases to one working setup, where the Strata workbench's ideas run against the real Hermes runtime and real LLVM on your machine. Read sections 2 to 4 first: they introduce the concepts and the code. Then do the steps in order; each one says why it exists, what to build, where in the code to work, and how you know it is done.

**The two codebases.**

- **Strata** is the workbench: a compiler framework written in JavaScript that runs in a browser page or in Node. It has a JavaScript-subset frontend, a core IR, a reference interpreter (the *specification*), analyses, rewrites, a root plan for the garbage collector, a simulated moving collector, LLVM IR printed as text, and a real WebAssembly backend. It is small and every part can be inspected, but nothing in it is native.
- **The Hermes fork** is the real thing: Meta's Hermes engine, branch `static_h`, base commit `f837b9dd8396ebf5c4e8115412417d273565f0fe`, extended with a *direct LLVM backend*. Static source follows JavaScript → Hermes SSA → LLVM IR → LLVM, linked against the real Hermes managed runtime through a small C/C++ bridge (`shllvm_runtime`). The recorded toolchain is LLVM/Clang 18.1.3 on Linux x86-64.

**"The real stuff"** in this guide means that fork, LLVM 18 and Node. Node is a differential reference. ECMAScript semantics and the admitted host profile determine correctness; disagreements require investigation.

**Which fork release you have matters.** The original release is a 40-file patch; generators and direct eval are rejected there. The extension release is a 124-file patch with generators, async functions, eval and more, validated at 53/53 source contracts. Check `IMPORT.md` and `EXTENSIONS-IMPORT.md` at the top of your checkout before you trust any result in this guide, and never apply the patch to a tree that already contains it.

**The aim.** The long-term goal is an engine built from Strata's own parts, with Hermes and LLVM replaced. This guide gets there in a way that works for real at every stage. Strata does as much of the compiling as it can from the start: the frontend, the core IR, the analyses, the root plans and the emitter. Two parts are borrowed until they are replaced: the **Hermes runtime** (object model, standard library, collector), reached through the bridge's helper ABI, and **LLVM**, which turns Strata's LLVM IR into machine code. The fork's own compiler stays as a yardstick, not as the product.

**What you will have at the end:** the fork built and its gates reproduced; Strata running in Node; one runner comparing Node, Hermes and Strata on the same programs; Strata compiling JavaScript to native executables that run on the real Hermes runtime; the runtime ABI written down as a versioned contract; Strata's native root plans tested under aggressive collection; a language subset grown by real programs; measurements against the fork's compiler; and a roadmap for replacing each borrowed part.

## 2. The big picture

The starting line is a working native path in which Strata does the compiling. Its frontend, core IR, analyses, root plans and LLVM emitter are its own; LLVM turns the IR into machine code; the program runs on the Hermes runtime through the fork's helper bridge. Two **seams** separate what Strata owns from what it borrows: the LLVM IR text it hands to LLVM, and the runtime ABI its code calls. Each borrowed part is later replaced by changing what sits behind one seam, while everything in front of it stays put.

&#91;embedded content: The starting line · Strata owns the compiler, borrows LLVM and the Hermes runtime\]

Solid boxes are Strata's; dashed boxes are borrowed (LLVM, the bridge, the Hermes runtime) or kept only as a yardstick (the fork's own compiler). The differential runner judges every step: Node supplies a differential reference for the admitted profile, and the fork's compiler shows what the starting line has to match. The fork matters in two ways: its bridge and runtime are what Strata's code links against, and its emitter is the reference for how to call them.

What each side brings to the starting line:

| Concern | Strata | Hermes fork |
| --- | --- | --- |
| Language | a subset: no classes, prototypes or standard library | most of JavaScript; the Hermes runtime implements the rest |
| What counts as correct | its own reference interpreter, for the subset | Node, with Hermes's bytecode interpreter as a second opinion |
| Root slots | liveness-based reuse (`stackReuse`) and an independent checker | one slot per used value, plus scratch and discard; at most 1,024 |
| Collector | a simulation that moves every object at every safepoint | Hades; `HERMESVM_SANITIZE_HANDLES` moves the heap after every allocation |
| Exceptions | the setjmp plan, printed as text | setjmp with `shllvm_try_begin`, a volatile `try_state` and `shllvm_catch_prepare` |
| Backend | LLVM text checked structurally; real Wasm | real LLVM 18 through `utils/shllvm.py` (emit, build, run, jit) and the in-process `shllvm-jit` |

## 3. Concepts to learn first

Eight ideas carry the whole project. Learn each one in Strata first, where you can watch it happen, then find it in the fork. The Strata book chapter for each is named in brackets.

### 3.1 SSA: phi nodes and block parameters (Chapters 3 and 4)

In **static single assignment** form every value is defined exactly once, so facts about a value never change along the program. Where control paths meet, a value can come from either path. Hermes, like LLVM, writes that with a **phi node**: `%x = phi [a, left], [b, right]`. Strata writes it as a **block parameter**: the block declares `x`, and every edge into it passes an argument.

They are the same idea written two ways. The fork's emitter must turn Hermes phis into LLVM phis, including the case where several phis on one edge swap values (its ARCHITECTURE.md, section 5, "simultaneous phi assignments"). Strata's `promote-cells` pass shows how a compiler builds SSA from ordinary variables.

### 3.2 Values are tagged words

A JavaScript value can be a number, a string, an object, `undefined` and more. Both systems store each value in one 64-bit word with a **tag** that says which kind it is. In Hermes this word is an `SHLegacyValue`; doubles are stored as themselves and everything else hides in the unused NaN bit patterns (**NaN-boxing**). The emitted functions return `i64`, which is these bits, not an integer.

### 3.3 Runtime helpers and the C ABI (Chapter 12)

Generated code does not implement JavaScript semantics itself. For a property read, an addition that might concatenate strings, or a call, it calls a **runtime helper** such as `shllvm_get` or `shllvm_binary`. The helper is C code in `runtime.c` that calls the real Hermes implementation. Helpers take pointers to value slots and write their result through an **out pointer**: `shllvm_binary(out, shr, op, a, b)`.

The set of helpers, with their signatures, is an **ABI** (application binary interface): the contract between generated code and the runtime. Declarations live in `runtime.h`. Only values already known to be numbers are handled inline, as LLVM `double` arithmetic.

### 3.4 The frame and root slots (Chapter 13)

On entry, a generated function asks `shllvm_frame_size` how much stack to reserve, allocates it, and calls `shllvm_enter`, which links that storage into the runtime as a **root frame**. `shllvm_roots` returns the address of its array of **root slots**: places the collector knows about. Two slots are fixed: **scratch** for temporaries and **discard** for results nobody uses. The emitter refuses a function needing more than 1,024 slots in total (roots plus argument storage), which is about 8 KiB of values.

### 3.5 Safepoints and the moving collector (Chapters 9 and 13)

A **garbage collector** frees objects nothing can reach. A **moving** collector also relocates live objects and updates every reference it knows about. It knows about root slots; it does not know about a machine register. Any operation that may allocate may trigger a collection; such an operation is a **safepoint**.

The rule that follows: a value needed after a safepoint must live in a root slot and be reloaded from it afterwards. A copy held in a register across the call is a **stale reference** once the object moves. The bug is silent until the old memory is reused. Strata's simulated collector and Hermes's `HERMESVM_SANITIZE_HANDLES` build both move everything early so the bug shows up at once.

### 3.6 Liveness: what must be rooted when (Chapters 8 and 9)

A value is **live** at a point if some later operation may still read it. Only values live across a safepoint, or passed into it, need a root there. The fork currently gives every used value its own slot for the whole function, which is simple and safe but wastes slots. Strata computes liveness and lets values that are never needed at the same safepoint share a slot (`stackReuse`). An independent **plan checker** then confirms that every safepoint roots what it needs. Step 4 puts it into Strata's own emitter, and step 6 proves it under the real collector.

### 3.7 Exceptions with setjmp (Chapter 14)

Hermes helpers report a JavaScript exception by `longjmp`: they jump straight back to the most recent `setjmp` instead of returning. A function with a `try` therefore calls `_setjmp` itself on entry, keeps a volatile **try state** naming the active region, and on the second return runs a **catch dispatch** that picks the handler. Values the handler needs must be in memory, because a long jump does not restore registers. The fork's ARCHITECTURE.md section 10 describes the exact protocol.

### 3.8 Contracts, the oracle and refinement (Chapters 2, 6, 7 and 10)

A **contract** says what an operation may do: read or write the heap, allocate, throw, run user code (its **behaviour**), and what the lowering owes it, such as roots or an unwinding path (its **obligations**). Optimisations are allowed only when the contract permits them. An unused property read cannot be deleted, because a getter may print or throw.

A compiler is correct when the compiled program **refines** the source: everything it is observed to do (output, uncaught exceptions, job order), the source could do too. For admitted JavaScript programs, Node is a differential reference; specification-directed disagreements require investigation. For the subset it is Strata's reference interpreter. The differential runner of step 3 applies this definition to every program you care about.

## 4. Map of the code

You will work in two trees. Read the files marked *start* first; the rest you open when a step sends you there.

### 4.1 The Strata tree (`strata-workbench-src.zip`, folder `wb/`)

| Path | What it is | When you need it |
| --- | --- | --- |
| `src/core/00-prelude.js` | helpers, YAML printer, units, the type lattice | *start*: types and units appear everywhere |
| `src/core/10-effects.js` | behaviours, obligations, derived permissions | step 5 (contracts) |
| `src/core/20-ops.js` | every operation: operands, contract, reference step, lowering hint | *start*; step 5 |
| `src/core/30-ir.js` | core IR: builder, printer, parser, JSON, verifier, dominators | *start*; step 4 |
| `src/core/40-machine.js` | reference interpreter, simulated moving collector, `observeEqual` | step 3 |
| `src/core/50-analysis.js` | lattices, the worklist solver, liveness, type facts | step 6 |
| `src/core/60-rewrite.js` | rewrites with side conditions; `promote-cells` (mem2reg) | background |
| `src/core/70-lower.js` | helper bindings, root strategies, the plan checker, LLVM text, Wasm | steps 4 and 6: the emitter you make exact |
| `src/core/80-pipeline.js` | passes, pipelines, `compile`, the `Program` object | *start* |
| `src/core/90-engine.js` | engines, state machines, laws, generators, designs | steps 3 and 9 |
| `src/frontend.js` | acorn syntax tree to core IR for the subset | step 7 |
| `content-src/` | 90 presets, 20 docs, the book, the API reference (`reference.md`) | when learning a concept |
| `tools/` | build, test and check scripts (section 15 lists them) | every step |
| `site/` | the page: shell, agent, stage, vendored acorn and KaTeX | only for UI work |

The engine is one file in the page: `tools/build-engine.sh` concatenates `src/core/*.js` in order into `site/js/core.js`. Edit the parts, never `core.js`.

### 4.2 The Hermes fork (`hermes/`)

| Path | What it is | When you need it |
| --- | --- | --- |
| `README.md`, `IMPORT.md`, `EXTENSIONS-IMPORT.md`, `PROVENANCE.json` (top level) | which release you have, its base commit, toolchain and recorded gates | *start* |
| `docs/llvm/ARCHITECTURE.md` | how the direct backend works, section by section | *start*: read sections 1 to 4 and 10 before any code |
| `docs/llvm/DRIVER.md`, `JIT.md`, `MODULES.md`, `TEST262.md` | the driver, the in-process JIT, modules, Test262 runs | steps 1 and 3 |
| `tools/shermes/compile.cpp` | the `-emit-llvm` choice in the Static Hermes compiler | step 8 |
| `lib/BCGen/SH/SH.cpp` | `lowerForLLVM`: the shared lowering before the emitter | step 8 |
| `lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | the emitter: functions, slots, phis, helper calls, try regions (about 1,200 lines) | step 4 (how to call each helper) and step 8 |
| `lib/BCGen/SH/LLVMNative/runtime.h`, `runtime.c` | the bridge: helper declarations and their C implementations | steps 4 and 5: the ABI Strata targets |
| `lib/BCGen/SH/LLVMNative/*_extensions.*` | bridges for values, eval and Test262 hooks | when a feature needs them |
| `tools/shllvm-jit/` | the in-process LLVM JIT (eager, per unit) | step 9 |
| `utils/shllvm.py` | the driver: `emit`, `build`, `run`, `jit` | every step |
| `utils/test_shllvm*.py` | the gates: core, extensions, driver, defaults, JIT, modules, Test262, apps | steps 1 and 3 |
| `test/LLVMNative/`, `LLVMNativeExtensions/`, `LLVMJIT/`, `LLVMModules/`, `LLVMTest262/` | fixtures the gates run | step 3 corpus |
| `lib/VM/`, `include/hermes/VM/` | the Hermes runtime and collector (`GCBase.h`, Hades) | step 6 |
| `docs/llvm/evidence/`, `feature-work/` | recorded validation runs | when comparing results |

The upstream base is `facebook/hermes`, branch `static_h`, commit `f837b9dd8396ebf5c4e8115412417d273565f0fe`; the patch is already applied in the archive. The engineering diary (`Direct-LLVM-Engineering-Diary.md`, top level) explains why each decision was made; search it before changing a mechanism.

## 5. Step 0: set up the machine

Match the recorded toolchain exactly; most early failures are version drift. The fork's `PROVENANCE.json` records Linux x86-64 with glibc 2.39 (Ubuntu 24.04), Clang and LLVM 18.1.3, CMake 4.4, Ninja 1.13, Python 3.12 and Node 24.22.

**Why it matters.** The emitter writes LLVM 18 textual IR, and `utils/shllvm.py` calls LLVM 18 tools (`llvm-as`, `opt`, `llc`, `lli`). Textual IR changes between LLVM versions, so another version can reject modules for reasons that have nothing to do with your work. The runtime bridge also asserts a 64-bit host, so a 32-bit or non-x86 host is out of scope.

**What to install** (Ubuntu 24.04 package names):

```sh
sudo apt install clang-18 llvm-18 llvm-18-dev lld-18 cmake ninja-build python3 git
# Node 24 from nodejs.org or your version manager; the gates compare against it
node --version            # v24.x
clang-18 --version        # 18.1.3
llvm-config-18 --version  # 18.1.3
ld.lld-18 --version
```

`llvm-18-dev` is needed only for the in-process JIT (`shllvm-jit`); `lld` is needed for the RV32 lane and some link paths. If CMake 4.x is not in your distribution, install it from cmake.org or with `pip install cmake`.

**Lay out the two trees side by side**, for example `~/work/strata` (unzipped `wb/`) and `~/work/hermes-llvm` (the fork). The fork archive omits Git history, so start one before you change anything:

```sh
cd ~/work/hermes-llvm && git init && git add -A && git commit -m "direct LLVM release as received"
cd ~/work/strata && git init && git add -A && git commit -m "Strata workbench as received"
```

Every change of yours is then a reviewable diff against what you were given.

**Known traps** (from the fork's `IMPORT.md`): Clang 18 can pick an incomplete GCC installation and fail C++ configuration; pass `-DCMAKE_CXX_FLAGS=--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13` (adjust the version to the GCC you have). If `ld.lld` is missing, install `lld-18` rather than copying binaries around.

**Done when** all five version commands print the versions above and both trees are committed.

## 6. Step 1: build the fork and reproduce its gates

Before you change anything, prove that your machine reproduces the fork's recorded results. If you skip this, every later failure is ambiguous: your change, or your build?

**1. Configure and build** (from the fork's `README.md`; add the `--gcc-install-dir` flag from step 0 if needed):

```sh
cd ~/work/hermes-llvm/hermes
cmake -S . -B build-llvm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang-18 -DCMAKE_CXX_COMPILER=clang++-18 \
  -DHERMES_ENABLE_ADDRESS_SANITIZER=ON
cmake --build build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4
```

The three targets are the pieces of the native path:

- `shermes` is the Static Hermes compiler: Hermes's frontend and optimiser plus the direct emitter. `shermes -emit-llvm file.js` writes LLVM IR.
- `shllvm_runtime` is the bridge (`runtime.c` and friends) as a static archive, linked into every native program together with the Hermes VM libraries.
- `shllvm_runtime_shared` is the same bridge as a shared library, loaded by `lli` for the `jit` path.

AddressSanitizer (ASan) checks the C and C++ runtime for memory errors; generated LLVM bodies are not instrumented. If your environment reports leaks from build tools, set `ASAN_OPTIONS=detect_leaks=0`, as the recorded runs did. A second build without ASan (`build-llvm-plain`) is useful later for timing.

**2. Run one program four ways**, and read each artifact:

```sh
python3 utils/shllvm.py emit  test/LLVMNative/closures.js -o out/closures.ll   # LLVM text + verified bitcode
python3 utils/shllvm.py build test/LLVMNative/closures.js -o out/closures      # native executable
./out/closures
python3 utils/shllvm.py run   --hermes-opt O0 --llvm-opt 0 test/LLVMNative/exceptions.js
python3 utils/shllvm.py jit   test/LLVMNative/gc_closures.js                     # lli with the shared bridge
```

Open `out/closures.ll` beside ARCHITECTURE.md sections 3 and 4 and find `shllvm_frame_size`, `shllvm_enter`, `shllvm_roots`, the scratch and discard slots, and one helper call with its out pointer. The `.build.json` next to each output records the source and IR hashes, the commands and the optimisation levels; keep it with any result you report.

**3. Reproduce the gates:**

```sh
python3 utils/test_shllvm.py --jobs 2              # core: 22/22 source contracts recorded
python3 utils/test_shllvm_extensions.py --jobs 2   # extensions: 53/53 recorded
python3 utils/test_shllvm_driver.py                # driver publication: 6/6
python3 utils/test_shllvm_defaults.py              # lexical defaults: 5/5
```

Each gate compiles fixtures, runs them natively (and through `lli` for some), and compares with Node and with the existing C backend. A *source contract* is one fixture with its expected behaviour, which may be success, a language error, a deliberate runtime boundary or a compile error.

**4. Optional: the in-process JIT** (needs `llvm-18-dev`):

```sh
cmake -S . -B build-llvm -DHERMES_BUILD_LLVM_JIT=ON -DSHLLVM_CONFIG=/usr/lib/llvm-18/bin/llvm-config
cmake --build build-llvm --target shllvm-jit shllvm-jit-test shermes shllvm_runtime --parallel 4
```

**Done when** the gates pass against the selected current source revision. Historical counts identify the old release and may differ after later fixtures are added. Write the counts, your tool versions and the commit of your tree into a file `docs/llvm/evidence/local-baseline.md`; it is your reference for every later step. If a gate differs, stop and resolve it first (section 15 lists the usual causes).

## 7. Step 2: run Strata locally in Node

Strata is your laboratory: a place to try an idea in minutes before it costs a day in C++. Get it running from the command line, not only in the browser, because the later bridges call it from scripts.

**1. Install the Node dependencies** in `~/work/strata`:

```sh
pnpm add acorn@8.18.0 sax playwright
pnpm exec playwright install chromium
```

**2. Fix three hard-coded paths.** `tools/harness.js`, `tools/check-common.js` and `tools/preset-check.js` load acorn and sax from `/opt/npm-tools/node_modules/`, the machine they were written on. Point them at your install:

```sh
sed -i "s#/opt/npm-tools/node_modules/##" tools/harness.js tools/check-common.js tools/preset-check.js
```

**3. Build and check everything:**

```sh
tools/build-engine.sh             # src/core/*.js -> site/js/core.js, syntax-checked
node tools/harness.js             # 28 JS samples: spec vs plan with GC stress -> "all passing"
node tools/preset-check.js --quiet --final   # 90 presets, 0 errors
node tools/book-check.js --quiet --final     # 24 chapters, 0 errors
node tools/build-content.js       # content-src -> site/content/*.js
node tools/tour.js                # loads all 90 presets in Chromium, no page errors
```

**4. Open the workbench** with any static server: `python3 -m http.server -d site 8000`, then `http://localhost:8000`. The agent stays off locally, because it needs the claude.ai `sample` capability; presets you save go to the browser's local storage.

**5. Use the engine from your own script.** This is the shape every bridge script in the later steps starts from:

```js
global.acorn = require('acorn');
const strata = require('./site/js/core.js'); require('./site/js/frontend.js');
const { g } = strata;
const src = require('fs').readFileSync(process.argv[2], 'utf8');
const p = g.compile(g.pipeline(), g.source.text(src));
console.log(p.ok, p.functions());
console.log(p.ir('L3'));                                   // the root plan as text
console.log(p.run({ mode: 'plan', gc: 'stress' }).output);  // lowered code under GC stress
```

`content-src/reference.md` is the whole API; `tools/facts.js` is a longer example that measures the running example and writes `content-src/book/FACTS.md`.

**Done when** the harness says "all passing", both checkers report 0 errors and the tour loads 90 presets without page errors. Then read the workbench's Chapter 1 with preset B-01 open: it walks one program through every level you will meet in the fork.

## 8. Step 3: one differential runner for every engine

Build one command that runs a program in every engine you have and reports where they disagree. It is the judge for every later step: a change is done when the runner says nothing changed except what you meant to change.

**The idea.** You cannot prove a JavaScript compiler correct against the whole language, but you can check, program by program, that it **refines** an engine you trust. The fork's gates already do this for their fixtures; this step makes it one tool that also includes Strata and that you can point at any program.

**Engines and how to call them:**

| Engine | Command | Notes |
| --- | --- | --- |
| Node (oracle) | `node --expose-gc -e "globalThis.print = (...a) => console.log(...a); require(process.argv[1]);" prog.js` | exactly the fork's oracle (`utils/test_shllvm.py`, line 67) |
| Hermes bytecode interpreter | `build-llvm/bin/hermes prog.js` | add `hermes` to the build targets; a second opinion with Hermes's own semantics |
| Hermes native | `python3 utils/shllvm.py run --hermes-opt O0 --llvm-opt 0 prog.js`, and again with `O` / `2` | the real compiled code |
| Hermes JIT | `python3 utils/shllvm.py jit prog.js`, or `build-llvm/bin/shllvm-jit prog.js` | the same code under `lli` or in-process ORC |
| Strata specification | `p.run({ mode: 'spec' })` | only for programs inside the subset; outside it the result is *skipped*, not a failure |
| Strata lowered | `p.run({ mode: 'plan', gc: 'stress' })` | Strata's own plan under its simulated collector |

**The observation relation.** Decide precisely what "the same" means and write it down in the tool:

- Compare printed lines in order, after converting each printed value with `String(v)`. `console.log(-0)` prints `-0` while `String(-0)` is `0`, and Node formats objects differently from Hermes, so make the Node shim `print = (...a) => console.log(a.map(String).join(' '))` and keep corpus programs printing strings and numbers.
- Compare the outcome: normal exit, or an uncaught exception reduced to `Name: message`. Exit codes and stderr layouts differ between engines; parse, then compare.
- Job order is covered by print order, because jobs print.
- Timing is never an observation.

**Known disagreements** go in a checked-in file with one reason each, never into silence. Two are known today: Strata's promise adoption takes one job fewer than ECMAScript (Strata Chapter 17), and the fork records a typed-array receiver case where its Node version differs from the specification.

**The corpus**, in order of value:

1. The fork's fixtures: `test/LLVMNative` (22), `test/LLVMNativeExtensions`, `test/LLVMJIT`, `test/LLVMModules`.
2. Strata's programs: the ledger (`content-src/presets/B-01/program.js`), the eight J presets and the 28 samples in `tools/harness.js`.
3. Generated programs: `g.gen.js({ seed })` from Strata, written to files, many seeds. It covers getters that throw, loops, closures and jobs, which is where compilers break.
4. Later, a Test262 slice through `utils/test_shllvm_test262.py` (see `docs/llvm/TEST262.md`).

**What to build:** `tools/diff-run.js` in the Strata tree. It takes corpus files or folders and a list of engines, runs each engine as a subprocess with a timeout (Strata in-process), normalises, compares every engine with Node, and writes a JSON record per program (engine, command, normalised output, verdict, tool versions) plus a one-line summary. Exit non-zero on any disagreement not in the known list.

**Done when** the runner passes on the fork's core fixtures with the same verdicts as `utils/test_shllvm.py`, and on Strata's programs Node, the Hermes interpreter, Hermes native and the Strata specification agree on every program in the subset.

## 9. Step 4: Strata emits real LLVM IR against the Hermes runtime ABI

This is the step that makes Strata the compiler. Today Strata prints LLVM IR in the *shape* of the fork's output, but with invented helper signatures, so nothing can link it. Here you change the emitter so its output is exact: the same helpers, signatures, frame protocol and module data that the fork's emitter produces. Then a Strata-compiled program links against the fork's bridge and the Hermes VM and runs natively.

**Learn the target from golden files.** Do not guess an ABI. For each feature, write a tiny program, compile it with the fork, and read what it emits:

```sh
python3 utils/shllvm.py emit --hermes-opt O0 --llvm-opt 0 probe.js -o out/probe.ll
```

Read `out/probe.ll` beside `runtime.h` and the matching part of `LLVMBackend.cpp`. That gives you, per helper, the exact argument order, the operation codes (`shllvm_binary`'s `op`), and how constants, strings and units are set up. Keep each probe and its `.ll` in `strata/tests/golden/` as the record of what you matched.

**Operation by operation.** Strata already binds each core operation to a helper at L2 (`bindOps` in `src/core/70-lower.js`). Replace the invented names with the real ones. The helpers below exist in `runtime.h`; confirm each signature there before you use it.

| Strata operation | Real helper(s) | Notes |
| --- | --- | --- |
| `num.*` on known numbers | inline `fadd`, `fmul`, `fcmp` on `double`, then `shllvm_number` | as the fork does for proven numbers |
| `js.add`, `js.sub`, `js.lt`, … | `shllvm_binary(out, shr, op, lhs, rhs)` | take the `op` codes from the fork, not from Strata's `OPCODES` |
| `js.neg`, `js.not`, `js.typeof` | `shllvm_unary`, `shllvm_typeof_is` |  |
| branch condition | `shllvm_truthy` | returns an `i32` |
| constants | `shllvm_constant(out, kind, bits)`, strings through the unit's string table | Strata's `shllvm_constant(out, shr, index)` is wrong |
| `obj.new`, `arr.new` | `shllvm_object`, `shllvm_array` |  |
| `js.define`, getters and setters | `shllvm_define`, `shllvm_define_index`, `shllvm_define_accessor` |  |
| `js.get`, `js.put` | `shllvm_get`, `shllvm_set`; `shllvm_get_id`, `shllvm_set_id` for constant names |  |
| `js.call`, `js.call_method` | `shllvm_call(out, shr, frame, callee, this, new_target, argc, argv)` | a method call reads the property first |
| function parameters | `shllvm_param(out, frame, index)` |  |
| `cell.new`, `cell.load`, `cell.store`, `cell.load_checked` | `shllvm_env_create`, `shllvm_env_load`, `shllvm_env_store`, `shllvm_check_tdz` | see decision 1 below |
| `js.closure` | `shllvm_closure` with an environment; the callee reads it with `shllvm_env_from_closure` | see decision 1 |
| `js.global_get`, `js.global_put`, `host.print` | `shllvm_global`, `shllvm_declare_global`; `print` is a global called with `shllvm_call` | `shllvm_run` installs the console bindings |
| `throw`, protected blocks | `shllvm_throw`, `shllvm_try_size`, `shllvm_try_begin`, `_setjmp`, `shllvm_catch_prepare`, `shllvm_catch_value`, `shllvm_try_end`, `shllvm_rethrow` | follow the fork's ARCHITECTURE.md section 10 exactly |
| `job.enqueue`, `timer.set`, `promise.resolve` | call the globals `queueMicrotask`, `setTimeout`, `Promise.resolve` | the event loop is Hermes's |

**Three design decisions** come with this mapping. Write each one down as a decision record before you code it.

1. **Cells become Hermes environments.** Strata passes captured cells as a closure's first parameters; Hermes gives a closure one environment and the callee reads captures from it. The simplest faithful mapping: each Strata cell is a one-slot environment, and each closure gets an environment whose slots hold its captured cells. Promoted variables (most of them) need no environment at all.
2. **Completion records need a native form.** `try`/`finally` in Strata uses `completion.*` operations that have no helper. Add a Strata pass that lowers a completion to a pair of values (a kind number and a value) carried on block parameters, before emission.
3. **Module data.** A runnable module needs more than functions: string pools, function descriptors (`%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }`), the `sh_export_<unit>` constructor and a `main` that calls `shllvm_run`. Port this from `ModuleEmitter` in `LLVMBackend.cpp`, using the golden files to check every field.

**Current source layout.** `strata/native/abi.js` reads the actual bridge declarations and enums; `strata/native/emitter.js` emits native functions and module data. The imported textual emitter remains a separate educational implementation. Use the native full-lifetime `reuse` allocation described in the current design guide, not the workbench's safepoint-only coloring for permanent homes. Preserve the runtime frame layout: the frame size you pass to `shllvm_frame_size` and `shllvm_enter` is your plan's slot count plus scratch and discard.

The link example below assumes the ASan build configured earlier; derive actual sanitizer flags from CMakeCache.txt, as the existing driver does.

**A driver**, `tools/strata-native.js prog.js -o prog`, that compiles with Strata, writes `prog.ll`, checks it with `llvm-as` and `opt -passes=verify`, then links exactly as the fork's driver does (`utils/shllvm.py`, line 222):

```sh
clang-18 prog.bc -O2 -Wno-override-module -fsanitize=address \
  -L$B/lib -L$B/tools/shermes -L$B/jsi -Wl,-rpath,$B/lib -Wl,-rpath,$B/tools/shermes -Wl,-rpath,$B/jsi \
  $B/lib/libshllvm_runtime.a -lshermes_console -lhermesvm -lm -o prog     # B = the fork's build-llvm
```

Add it as an engine in the differential runner (`strata-native`, at `-O0` and `-O2`).

**Milestones, in order**, each checked by the runner against Node:

1. `print(1 + 2)` links and prints `3`.
2. A numeric loop (`fib`) with inline doubles.
3. Objects, properties, a getter that throws.
4. Closures with shared variables (environments).
5. `try`/`catch`/`finally`, including a throw inside a handler.
6. Jobs, timers and promises through Hermes's event loop.
7. The ledger, then the eight J programs.

**Done when** the ledger and all J programs compile with Strata, link, and match Node at LLVM `-O0` and `-O2`, with no ASan reports. From here on, Strata is a real compiler with two borrowed parts.

## 10. Step 5: make the runtime ABI an explicit, versioned seam

The runtime ABI is the line behind which the Hermes runtime will one day be replaced, so it has to be written down as data, not left implicit in `runtime.h` and the emitter. This step produces one **contract table** for every helper Strata calls, generates both the C declarations and Strata's data from it, and tests each claim it makes.

**Why a table and not just the header.** A C prototype says how to call a helper. It does not say what the helper may do, and that is what the compiler needs: whether it may allocate (so it is a safepoint and needs roots), whether it may long-jump (so it needs the try protocol), whether it may run user code (so nothing may move across it), and which operands it reads after it may have collected (so they must stay rooted). Strata already has this vocabulary: behaviours, obligations and derived permissions (Strata Chapters 6 and 7).

**The format.** One file, `abi/strata-abi.json` in the Strata tree, with an ABI version and one entry per helper:

```json
{ "abi": 1,
  "helpers": [
    { "name": "shllvm_get",
      "args": ["out", "shr", "value object", "value key"],
      "behaviour": "callsUser",
      "obligations": ["mayCollect", "nonlocalThrow"],
      "borrows": [2, 3],
      "evidence": "getters run user code; see probe get_getter.js" } ] }
```

Argument roles are fixed words: `out` (a root slot written), `shr` (the runtime), `frame`, `value` (a pointer to a rooted value), `u32`, `i32`, `double`, `ptr`.

**Generate two things from it.**

- `strata_abi.h`, the C declarations. A small compile test includes it together with the fork's `runtime.h`; any mismatch is a compile error, so the table cannot drift from the bridge.
- `src/core/abi-table.js`, the same entries as Strata data. `bindOps` takes helper names from it, and the safepoint analysis takes `mayCollect` from it, so root plans follow the table.

**Start conservative, narrow with evidence.** Initially classify helpers conservatively as potentially collecting, throwing, and calling user code, while preserving their actual signatures and control-flow contracts. This can add roots and exception handling and inhibit transformations; metadata alone cannot repair incorrect lifetime handling. A helper loses an obligation only after source-level review establishes the property and targeted tests support it. Absence of allocation in a test does not prove absence of collection or establish a universal contract. This is the antitone law in practice: removing behaviour can only add permissions, so every removal must be justified.

**Tests for each kind of claim**, built as debug-only wrappers generated from the table:

- **Does not collect:** the wrapper reads the heap's allocation count before and after the call and fails if it changed. Run it under the handle-sanitising build of step 6, where every allocation moves the heap.
- **Does not throw:** the wrapper runs the helper inside a jump buffer of its own and fails if it is ever long-jumped to.
- **Borrows operand *i*:** GC stress catches a violation as a stale value; the table records which operands each helper reads after it may allocate.

**Versioning.** Put the ABI version into the unit descriptor Strata emits, and make the bridge refuse a unit built for another version before any code runs. This is the admission check of Strata Chapter 18, applied to real code. Bump the version on any change of signature or meaning.

**Done when** every helper Strata emits has an entry with evidence, the generated header compiles against `runtime.h`, the wrapper tests pass on the corpus, and Strata's safepoints and bindings come only from the table.

## 11. Step 6: Strata's root plans under the real moving collector

In the workbench, a simulated collector moves every object at every safepoint, and the checker confirms each plan. Now the same plans run against Hermes's real collector, made as aggressive as it can be. This is the first real test of Strata's central idea: that root slots can be planned from liveness, shared between values, checked independently, and trusted.

**Build the stress runtime.** Hermes has a build option made for this, `HERMESVM_SANITIZE_HANDLES` (its CMake description: "moving the heap after every alloc"). Build it in its own directory so the normal build stays fast:

```sh
cmake -S . -B build-llvm-gcstress -G Ninja -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_COMPILER=clang-18 -DCMAKE_CXX_COMPILER=clang++-18 \
  -DHERMES_ENABLE_ADDRESS_SANITIZER=ON -DHERMESVM_SANITIZE_HANDLES=ON
cmake --build build-llvm-gcstress --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4
```

Add `strata-native-gcstress` to the differential runner: the same Strata output linked against this build.

**What can go wrong, and how it shows.** Strata's emitter keeps a value either in a root slot or in an unrooted local (`%r.x` in its LLVM text). If the plan leaves an object in an unrooted local across a helper that collects, the local still holds the old address after the object moved. Natively the symptom is a crash, an ASan report or wrong output; the runner counts all three as failures. Unlike the workbench, nothing names the stale value for you, so keep the plan dump (`program.ir('L3')`) next to every failing run.

**Run three experiments:**

1. **The corpus under stress** with the default `stackReuse` plans and with `distinct` (one slot per value). Both must pass. Record frame sizes per function for both; the difference is what liveness-based sharing saves on real code.
2. **A negative control.** Compile with a plan that is known to be wrong and must fail: `g.pipeline().roots('none').checks({ gcSafety: false })`, or Strata's L-06 lambda strategy that drops one value. If this control is not detected, establish whether the relevant path and collection occurred before drawing conclusions about the detector.
3. **The checker's agreement.** Accepted plans must pass the selected stress corpus. Rejected plans are not required to fail every execution: rejection can be conservative and the relevant path may not run. Use targeted negative controls with known live references and actual collection; investigate mismatches without treating test agreement as a proof.

**The frame limit.** Strata applies the fork's rule: root slots plus 2 plus the larger of 1 and the outgoing argument count must not exceed 1,024 (the fork's `LLVMBackend.cpp` line 955; Strata's `NATIVE_FRAME_LIMIT`). Generate wide functions as Strata's L-07 does and confirm that Strata and the bridge refuse at the same size. Measuring the fflate factory with Strata waits for step 7, because fflate uses features outside today's subset; until then the fork's own numbers stand (1,084 roots plus 3 argument slots at `-O0`).

**Done when** the corpus passes under the stress build with `stackReuse`, the negative controls fail as predicted, and the checker and the stress runs agree on every function.

## 12. Step 7: grow Strata's frontend until real programs run

Strata's frontend accepts a teaching subset. On the native path, most of what remains is cheaper than it looks, because the standard library comes with the borrowed runtime: `a.push(x)`, `JSON.stringify(o)` and `Math.max(...)` are ordinary method calls, and the Hermes objects behind them already implement them. What Strata must add is **syntax** (the frontend) and, where it wants a specification, **meaning** (the interpreter).

**Let the corpus choose the order.** The frontend throws `Unsupported` with a reason and a location. Run it over a corpus of real code (the fork's fixtures, its application set in `utils/test_shllvm_apps.py`, libraries you care about, a Test262 slice) and count the reasons. Fix the most frequent first, and re-count after each feature. The count is your progress measure.

**Two ways to add a feature.** Prefer the first when it is faithful.

- **Desugar** it in the frontend into constructs Strata already has. Default and rest parameters, destructuring, spread in array literals, `switch`, optional chaining and compound logical assignment all become blocks, branches, temporaries and existing operations. Nothing changes downstream.
- **Add an operation** with a contract from step 5's table and a real helper behind it. Examples: `new` through `shllvm_create_this`, the call, then `shllvm_constructed_object`; prototype access through `shllvm_object_parent` and `shllvm_get_parent`; `delete` through `shllvm_delete`; `for…in` through `shllvm_pnames` and `shllvm_pname_next`; iteration through `shllvm_iterator_begin`, `shllvm_iterator_next` and `shllvm_iterator_close`. Check each in a golden file first, as in step 4.

**Decide, per feature, who says what correct means.** Either extend Strata's interpreter so it stays a specification for the feature (prototypes, for example, are worth modelling), or declare the operation **delegated**: the interpreter skips programs that use it, through a profile, and Node alone judges them. Record the choice in the feature's decision record. A delegated operation still needs a contract, because the optimiser and the root planner rely on it.

**A suggested order**, which the corpus may overrule:

1. `new`, prototypes and `class`: most libraries need them.
2. Parameter and binding forms: defaults, rest, destructuring, spread.
3. Control flow: `switch`, labels, `break` and `continue` through `finally`.
4. The remaining operators: `==`, `!=`, `in`, `instanceof`, `delete`, `void`, bitwise and shift operators (through `shllvm_binary` and `shllvm_unary`).
5. Iteration protocols: `for…of` over any iterable, `for…in`.
6. Generators and `async` functions, last: they need either a frontend transform to state machines or the fork's generator support (`shllvm_generator`); read the fork's LANGUAGE\_EXTENSIONS.md before choosing.

**A milestone to aim for:** compile the fflate module factory with Strata and measure its frame against the 1,024-slot limit with `stackReuse`. The fork's own emitter needed 1,084 roots plus 3 argument slots there; Strata's number answers the question the whole project started from.

**Done when** the chosen application set compiles with Strata and matches Node under the differential runner, including the stress build of step 6, and the `Unsupported` count on it is zero.

## 13. Step 8: measure the starting line against the fork's compiler

Before you replace anything, know how good the starting line is. The fork's own compiler (Hermes frontend, Hermes optimiser, direct emitter) compiles the same programs to the same runtime, which makes it the fair yardstick. Strata does not need to beat it yet, but every gap should be measured and written down, so later work starts from facts.

**What to compare, per program and per function:**

| Measure | How | What it tells you |
| --- | --- | --- |
| Correctness | the differential runner, both compilers against Node | must be equal; any Strata-only failure is a bug |
| Root slots and frame size | the fork's slot table (patch below) against `program.plan(fn)` | what liveness-based sharing saves |
| Run time | native builds without ASan, LLVM `-O2`, timed several times (for example with `hyperfine`) | what Hermes's optimiser buys: type inference, inlining |
| Code size | size of the linked program and of each object file | the cost of Strata's code shape |
| Compile time | wall time of each compiler on each program | matters later, for a JIT |

**The plan-dump patch.** Teach the fork's emitter to print its slot assignment, so the two plans can be compared and the workbench can show the real one. In `LLVMBackend.cpp`, `FunctionEmitter` already holds everything needed: `slots_` (value to slot), `scratch_`, `maxArgs_` and `tries_`. Add a debug option (an environment variable is enough) that writes, per function, JSON in Strata's plan shape: function name, slots with the Hermes instruction each holds, fixed and argument slots, and the try regions. A small `tools/import-plan.js` in Strata turns that file into a preset, so the Plan view and the Stage show the real compiler's plan beside Strata's.

**Expect Strata to be slower at first.** Hermes's optimiser infers types and inlines; Strata's rewrites are few, and its type facts stop at today's subset (`!==` does not narrow yet, Strata Chapter 9). For each gap, decide whether to bring the idea into Strata (the long-term direction, since Hermes's compiler is being replaced) or to accept it for now, and record the decision. Do not call Hermes's optimiser from Strata: that would make the compiler you mean to own depend on the one you mean to replace.

**Keep the results** in `strata/results/starting-line.md`: one row per program with both compilers' numbers, the date, both commits and the tool versions. Rerun it after every step that changes code generation.

**Done when** the table exists for the whole corpus, every correctness difference is fixed, and every performance gap has an owner or a decision.

## 14. Step 9 onward: replacing Hermes and LLVM piece by piece

With the starting line measured, each borrowed part is replaced behind its seam, one at a time, while everything else stays fixed. The differential runner, the stress build and the starting-line table are what make a replacement safe: they tell you at once whether the new part behaves like the old one.

&#91;embedded content: Replacement roadmap · three tracks, each part behind a gate; not to scale\]

The three tracks are independent until the last JIT stage, which needs the runtime track's own interpreter and frames. Each diamond is a gate, passed only with a decision record that compares options, cites the measurements, says what counterexample was sought and what would overturn the choice (`g.decision(…).check()` in Strata enforces exactly these).

**Runtime track (behind the runtime ABI).**

- **Runtime core.** A new runtime in C or Rust that implements step 5's ABI for the subset: NaN-boxed values, objects with prototypes, environments, strings and a simple moving collector with a stress mode from the first day. Strata's output does not change: the same `.ll` links against either runtime, and the runner runs both.
- **Standard library.** Most of `Array`, `Object` and `String` can be written in JavaScript and compiled by Strata itself, over a small native core for string storage, number formatting and regular expressions (existing libraries are fine there). This is also how you decide which helpers must stay native.
- **Own collector.** Generational and moving, with the stress mode kept. Hermes leaves the build when every corpus passes on the new runtime under stress and the starting-line table shows no regression you have not accepted.

**Code generation track (behind the LLVM IR seam).** Strata already has a WebAssembly backend for the numeric core; extend it, or write a direct emitter for one machine target (x86-64, or RV32 for the fork's PicoCalc lane). The plans, contracts and checker carry over unchanged, because they sit in front of the seam. Keep LLVM for optimised ahead-of-time builds for as long as measurements say it wins.

**Execution track.** The fork already has an eager, in-process JIT on LLVM's ORC (`shllvm-jit`) with no speculation and no deoptimisation (its JIT.md). A future speculative optimizing tier could add three things on top: an interpreter it can fall back to (your own, running core IR natively), profiling to choose what to compile, and speculation with guards from type facts plus **deoptimisation**, which rebuilds the interpreter's frame when a guard fails. This is the largest piece of the whole project; start it only after the runtime core exists, because deoptimised frames belong to the runtime.

**Two rules for every replacement.** Change one part per step, so a failure has one suspect. Never change the ABI and the part behind it in the same change: first version the ABI (step 5), then swap the part.

## 15. Troubleshooting and command cheat sheet

**When something breaks**, find the symptom first; most problems are environment, not code.

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| C++ configuration fails with Clang 18 | Clang picked an incomplete GCC installation | add `-DCMAKE_CXX_FLAGS=--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13` |
| `llvm-as` or `opt` rejects a module the fork emitted | LLVM tools of another version | point `LLVM_BIN` (or `--llvm-bin`) at LLVM 18.1.3 |
| `Required tool ... was not found` from `shllvm.py` | LLVM tools not on `PATH` | set `LLVM_BIN` |
| Gate counts differ from the recorded ones | other release (40-file vs 124-file patch), other Node version, or ASan leak reports from build tools | check `EXTENSIONS-IMPORT.md`, use Node 24, set `ASAN_OPTIONS=detect_leaks=0` |
| Strata's `.ll` fails to link: undefined or mismatched `shllvm_*` | Strata's binding differs from `runtime.h` | compare with the golden file; regenerate `strata_abi.h` (step 5) |
| A Strata program fails only on the stress build | a wrong root plan, or a helper contract that understates what it does | dump the plan (`program.ir('L3')`), run the checker, review the helper's table entry |
| Outputs differ only on `-0` or on printed objects | the observation relation, not the compiler | use the `String(v)` print shim and print primitives |
| Strata says `Unsupported: ...` | a feature outside today's subset | count it and schedule it (step 7) |
| `acorn is not loaded` in a Node script | the script did not set `global.acorn` before loading the engine | `global.acorn = require('acorn')` first |
| `exceeds 1024 combined root/argument-slot admission limit` | a very wide function | compare `stackReuse` with `distinct`; split the function if both exceed it |
| Promise output order differs between Strata's interpreter and Node | Strata's adoption takes one job fewer (a known disagreement) | expected; listed in the runner's known-disagreements file |

**Commands you will use daily.** Fork commands run in `~/work/hermes-llvm/hermes`, Strata commands in `~/work/strata`.

```sh
# fork: build, compile, run
cmake --build build-llvm --target shermes shllvm_runtime shllvm_runtime_shared hermes --parallel 4
python3 utils/shllvm.py emit  prog.js -o out/prog.ll          # LLVM text + bitcode + .build.json
python3 utils/shllvm.py run   --hermes-opt O0 --llvm-opt 0 prog.js
python3 utils/shllvm.py jit   prog.js
# fork: gates
python3 utils/test_shllvm.py --jobs 2 && python3 utils/test_shllvm_extensions.py --jobs 2

# strata: engine and checks
tools/build-engine.sh && node tools/harness.js
node tools/preset-check.js --quiet --final && node tools/book-check.js --quiet --final
node tools/facts.js && node tools/build-content.js && node tools/tour.js

# strata: tools you write in this guide
node tools/diff-run.js corpus/ --engines node,hermes,shllvm,strata-spec,strata-native   # step 3
node tools/strata-native.js prog.js -o out/prog --build-dir ../hermes-llvm/hermes/build-llvm   # step 4
node tools/import-plan.js out/plan.json                                                      # step 8
```

## 16. Glossary

| Term | Meaning | Where it matters |
| --- | --- | --- |
| ABI | the binary contract between generated code and the runtime: helper names, argument order and types | steps 4 and 5 |
| Behaviour | what an operation may do: read, write, allocate, throw, diverge, run user code | 3.8, step 5 |
| Block parameter | Strata's way of joining values where control paths meet; the same idea as a phi node | 3.1 |
| Contract table | the data file describing every runtime helper's behaviour and obligations | step 5 |
| Decision record | a written choice with options, evidence, the counterexample sought and what would overturn it | steps 4, 7, 9 |
| Delegated operation | an operation whose meaning Strata's interpreter does not model; Node alone judges it | step 7 |
| Deoptimisation | leaving speculatively compiled code for the interpreter when a guard fails | step 9 |
| Differential runner | the tool that runs one program in every engine and compares observations | step 3 |
| Discard slot, scratch slot | the two fixed root slots: results nobody uses, and temporaries | 3.4 |
| Golden file | a fork-compiled `.ll` kept as the reference for how to call a helper | step 4 |
| Helper | a C function in the bridge (`runtime.c`) that generated code calls for JavaScript semantics | 3.3 |
| Liveness | whether a value may still be read later; decides what needs a root | 3.6 |
| Moving collector | a garbage collector that relocates live objects and updates the references it knows | 3.5 |
| NaN-boxing | storing every JavaScript value in one 64-bit word, non-numbers inside unused NaN patterns | 3.2 |
| Obligation | what lowering owes an operation: roots, an unwinding path, a write barrier | 3.8, step 5 |
| Oracle | the engine that decides correct behaviour: Node for full JavaScript | 3.8, step 3 |
| Phi node | Hermes's and LLVM's notation for joining values at a block entry | 3.1 |
| Plan checker | Strata's independent check that every safepoint roots what it needs | 3.6, step 6 |
| Profile | the set of operations a program may use and the observations a claim about it preserves | step 7 |
| Refinement | everything the compiled program is observed to do, the source could do too | 3.8 |
| Root slot, root frame | a stack location the collector traces and updates; the frame that holds them | 3.4 |
| Safepoint | an operation that may allocate and so may run the collector | 3.5 |
| Seam | a boundary behind which a part can be replaced: the LLVM IR text and the runtime ABI | section 2, step 9 |
| SSA | static single assignment: every value defined exactly once | 3.1 |
| Stale reference | an object address held across a collection that moved the object | 3.5, step 6 |
| `stackReuse` | Strata's root strategy: values never needed at the same safepoint share a slot | 3.6, step 6 |
| Try state | the volatile number naming the active protected region for setjmp dispatch | 3.7 |
| Unit | the compiled module as the runtime sees it: functions, strings and descriptors | step 4 |
