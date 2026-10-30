---
Title: Strata first native compiler design and intern implementation guide
Ticket: STRATA-PORT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T20:34:23.932784603-04:00
WhatFor: ""
WhenToUse: ""
---

# Strata-first native compilation: design and intern guide

## 1. Objective and ownership

Strata will compile its supported JavaScript subset directly to LLVM IR and run the resulting native program on the existing Hermes managed runtime. Strata owns parsing integration, scope resolution, its intermediate representation, transformations, root allocation, and emission. LLVM owns native code generation. Hermes supplies values, objects, environments, garbage collection, JavaScript calls, exception machinery, and the console job loop. The Hermes compiler is a comparison implementation; the Strata path must not invoke it to translate source.

This guide supersedes the implementation direction in textbook Chapter 21 of the imported workspace. That chapter first changes the Hermes emitter. Our chosen direction instead builds an independent Strata emitter against the existing runtime ABI. The original export remains in the preserved ZIP; the registered guide receives corrections and points here for current decisions.

The first deliverable is a useful native subset: arithmetic, branching, loops, strings, objects and arrays, captured cells and closures, property calls, exceptions and finally, and jobs using runtime globals. It includes command-line compilation, LLVM verification, native execution, reproducible evidence, and representative differential tests. Full JavaScript parsing/lowering, a replacement collector, runtime ABI replacement, speculative optimization, and deoptimization remain later projects. This scope supports substantial programs without requiring a new runtime before any result can execute.

The reference import is `source/` inside this ticket. It includes the documents, workbench source, examples-only API, and session records. It is reproduced from the preserved ZIP and is not the working source tree. Development occurs in the repository's `strata/` directory. Copy the needed source with provenance; do not edit the reference import to repair local behavior.

## 2. Concepts in dependency order

A JavaScript frontend resolves names and translates source constructs into explicit operations. Strata uses Acorn to parse source and its own frontend to produce functions containing basic blocks. A basic block is a sequence of operations followed by a terminator. A branch selects a successor block and passes arguments to its parameters. A value has a unique definition in this representation, while mutable variables can live in cells.

A runtime value is represented by an eight-byte tagged word. Numbers and managed references share that representation, but their bit patterns do not have interchangeable meaning. Hermes's `SHLegacyValue` representation is part of the runtime boundary. Generate constants through the bridge; do not invent tag encodings in the compiler. Strings require a unit string table with exact UTF-16 code units, including surrogate code units.

A root is a location the collector knows how to visit. A live object held only in an ordinary machine register or unregistered stack slot can be lost or moved without that copy being updated. A helper may trigger collection or call user code. The first native emitter therefore keeps every value home in registered root storage. Later reuse may assign nonoverlapping value lifetimes to the same home, but must preserve both ordinary execution and collecting calls.

An ABI specifies how generated code calls runtime functions and how those functions find execution state. C prototypes specify argument and result types. They do not specify collection, exception, borrowing, or aliasing behavior. Treat runtime helpers conservatively until their implementations justify narrower contracts. Native compilation does not use the workbench's illustrative helper signatures.

```text
JavaScript source
    -> Acorn syntax tree
    -> Strata frontend: scopes, cells, blocks, exception targets
    -> Strata cell promotion and structural verification
    -> native root allocation and operation lowering
    -> LLVM IR + unit metadata
    -> llvm-as + opt verification + clang
    -> executable
         -> shllvm runtime bridge
         -> Hermes objects, GC, calls, exceptions and job queue
```

The native path does not run the workbench interpreter as a substitute for generated code. The interpreter remains a useful comparison for its admitted subset; Node and the existing compiler provide additional observations. No single differential reference establishes correctness for every JavaScript behavior.

## 3. Code organization and API

The working tree should have a small command surface and separate semantic work from process orchestration:

| Path | Responsibility |
|---|---|
| `strata/src/core/` | Imported Strata IR, interpreter, analyses, transformations and educational pipeline |
| `strata/src/frontend.js` | Imported frontend, with reviewed corrections as needed |
| `strata/vendor/` | Pinned Acorn source and its license |
| `strata/tools/build-engine.js` | Assemble the imported source parts into a Node-loadable engine |
| `strata/native/abi.js` | Exact helper signatures and enum values from the actual bridge header |
| `strata/native/emitter.js` | Native CFG lowering, rooted value homes, calls, exceptions, unit data |
| `strata/tools/strata-native.js` | Explicit paths/options, LLVM verification, linking and execution |
| `strata/test/` | Small semantic fixtures and the native differential runner |
| `strata/README.md` | Supported profile, commands, boundaries and provenance |

The proposed native API is deliberately small:

```javascript
compileNative(sourceText, { filename, roots, unitName })
// -> { llvm, metadata }
// throws a diagnostic before publishing output on unsupported input
```

The driver accepts `emit`, `build`, and `run`, an input path, an output path, a Hermes build directory, an LLVM tool directory, and an optimization level. Defaults derive from the repository layout, not ambient environment variables. Each tool invocation uses an argument array. A failed compile or verification must not publish a successful artifact record.

A manifest records source identity, compiler inputs, runtime library identity, optimization level, root counts, commands and tool versions. Source acceptance and executable success are distinct. An expected compiler rejection should remain visible as a rejection rather than a passing native execution.

## 4. Following a small program

Consider `let x = 1; print(x + 2);`. The frontend initially creates a cell, stores the initializer, reads the cell, adds the values, and prints. Cell promotion can remove storage that does not escape and replace those reads with direct SSA values. Native emission then materializes the two constants, calls the binary helper with the actual addition enum, loads the global `print` function, and calls it with the computed result.

```text
entry:
  a = constant number 1
  b = constant number 2
  sum = js.add(a, b)
  host.print(sum)
  return undefined
```

The generated LLVM function has signature `i64 function(ptr runtime)`. Its JavaScript parameters are read from the managed call frame rather than added to this LLVM signature. The unit constructor registers string/function metadata; `main` calls `shllvm_run` with that constructor. This is enough to execute source compiled by Strata while reusing the existing console host.

The numerical helper performs JavaScript arithmetic and canonicalizes the resulting runtime value. Starting with helpers avoids prematurely relying on incomplete type facts or reproducing NaN-boxing rules. Proven numeric specialization can be added later with dedicated tests for NaN, negative zero, infinities and coercions.

## 5. Runtime ABI and module data

Use `hermes/lib/BCGen/SH/LLVMNative/runtime.h` as the prototype authority and `runtime.c` plus `eval_extensions.*` as implementation evidence. Use `LLVMBackend.cpp` as an example of calling sequences, not as a source translation service. Its `ModuleEmitter::emitData` and `ModuleEmitter::generate` specify unit construction and string layout.

The initial ABI reader extracts declarations and operation enums from the checked-in header. The emitter calls helpers through a single checked call builder that validates argument counts and supplies LLVM parameter types. Unknown names fail compilation. A header digest belongs in the output metadata. This removes duplicated handwritten prototypes while keeping operation semantics explicit in the emitter. A generated prototype compatibility check can catch drift against the C header; it does not prove collection contracts.

Important signatures include:

```text
shllvm_constant(out, kind:u32, bits:u64)
shllvm_frame_size(root_count:u32) -> u64
shllvm_enter(runtime, storage, root_count:u32, max_args:u32, unit_index:u32)
shllvm_call(out, runtime, frame, callee, this_value, new_target, argc:u32, argv)
shllvm_env_create(out, runtime, parent, size:u32)
shllvm_env_load(out, environment, index:u32)
shllvm_env_store(runtime, environment, value, index:u32)
shllvm_catch_prepare(runtime, locals, frame, max_args:u32)
```

Strings are serialized into ASCII or UTF-16 pools with offset/length/hash triples. The hash is Hermes's character-wise Jenkins update from `Support/JenkinsHash.h`; do not append a final mixing step from a different Jenkins algorithm. Function descriptors contain name index, parameter count, function kind, and invocation restrictions. Their C bridge structure consists of four 32-bit fields. Unit names and native symbols must use generated identifiers, not raw source text.

## 6. Root storage and calls

The first correct policy assigns each SSA value and literal a separate root home. Additional scratch homes support operations that expand into several helpers. The storage count plus outgoing argument storage stays within the existing 1,024-slot admission bound. The bound is not a total stack-memory bound: native spills, headers, recursion and runtime frames still consume stack.

For reuse, compute interference over the full execution lifetime, not just co-occurrence at safepoints. Two values needed in a sequence of noncollecting operations still cannot overwrite one another. Likewise, an operation's result must not overwrite a borrowed operand while the helper is reading it. Block-argument assignments are parallel transfers: read all sources before writing any destination.

```text
for each function:
  collect definitions and all uses, including exceptional successors
  solve backward liveness until no set changes
  add conflicts for simultaneously live values and operation inputs/results
  assign homes in deterministic order
  independently check the assignment against every required conflict
  reject if roots + scratch + outgoing arguments exceed the bound
```

Do not use inferred primitive types to omit roots in the initial implementation. The workbench verifier does not yet establish every type property a native backend would need. A conservative all-tagged storage policy is simpler and gives liveness-based reuse a clear, reviewable meaning.

For a call, keep the callee, receiver and arguments rooted while evaluating properties or allocating closure state. Copy arguments into contiguous outgoing storage only immediately before `shllvm_call`. Inspect the bridge to establish when it copies those words into the managed stack. No collecting helper may intervene between the copy and the call. Returned values are written to rooted destinations before subsequent helpers run.

## 7. Captures, cells and closures

Strata represents captured variables as explicit cells and passes capture cells as leading IR parameters. Hermes instead associates a closure with an environment. Map each Strata cell to a one-slot Hermes environment. A closure receives an environment containing its captured cells. The native function obtains that environment from its managed call frame and loads capture slots into the homes corresponding to the leading Strata parameters.

The remaining parameters are the JavaScript receiver and ordinary arguments. `shllvm_param` index zero reads the receiver; following indexes read arguments. Arrow functions carry their lexical receiver through captures established by the frontend. Do not coerce every receiver indiscriminately: strict/sloppy receiver semantics need an explicit frontend/profile decision and tests.

A cell created without an initializer contains the runtime's uninitialized sentinel. Checked loads use the actual TDZ helper; ordinary loads preserve the frontend's promise that initialization has occurred. Mutation updates the same environment slot so native closures share the cell. Avoid copying a captured value when a mutable cell is required.

## 8. Exceptions and finally

Hermes helpers transfer exceptions through setjmp/longjmp. A generated function with local handlers allocates jump storage, registers it, calls `_setjmp` with `returns_twice`, and maintains a volatile handler index. Every block selects its active exception destination; blocks outside protected regions select propagation. The catch dispatch first restores the managed frame and local roots with `shllvm_catch_prepare`.

```text
normal entry -> setjmp returns 0 -> ordinary blocks
helper throws -> setjmp returns nonzero -> restore runtime execution state
             -> select handler -> load thrown value -> handler block
             -> no handler: unregister jump storage and rethrow
normal return -> unregister jump storage -> leave root frame -> return word
```

Values needed by handlers must be in homes that remain valid after longjmp. Returning from a function must remove its registered jump state before destroying its local frame. A throw from a handler must select the enclosing handler, not reenter the handler that already caught it.

The imported guide proposes splitting completion records into kind/value pairs. That is a reasonable future optimization, but it requires systematic block-parameter and operation rewriting. The initial implementation can represent the internal record as a two-slot Hermes environment holding a numeric kind and a value. This reuses managed storage, keeps records rooted, and directly implements the existing IR. It is an explicit representation decision, not a compatibility layer. Pair lowering is worthwhile only after measurements justify removing these allocations.

Tests must include mutation before a throw, nested handlers, return through finally, finally overriding a pending return, and exceptions while cleanup runs. The heap reflects effects already performed before a throw; there is no rollback.

## 9. Host operations and the language profile

Resolve `print`, `queueMicrotask`, `setTimeout`, `Promise.resolve`, and error constructors through the actual runtime globals and ordinary calls. Do not assign private builtin indexes based on the workbench's names. The host's job loop runs after the entry function and retains the native unit while scheduled closures remain callable.

The initial frontend remains a subset. Classes, full iteration protocols, generators, async syntax, destructuring and dynamic evaluation are not implied by a working native backend. Unsupported syntax must fail with a source location. A runtime that implements a standard library does not automatically supply frontend lowering for its associated syntax.

The imported frontend's approximations require attention: `for...of` currently lowers array-like indexing rather than arbitrary iterator semantics; property assignment, top-level `this`, and unknown global behavior must be tested against the declared profile. If a behavior cannot yet be represented faithfully, reject it or document a narrow admitted form. Do not silently label the entire JavaScript language supported.

## 10. Driver and validation

The driver uses explicit tool/build paths and inspects `CMakeCache.txt` for sanitizer configuration. Link flags must include the enabled runtime sanitizers. `llvm-as` and `opt -passes=verify` validate the actual emitted module before linking. These tools prove structural validity only; execution tests check selected behavior.

The differential runner compares normalized printed values and completion categories across Node and Strata native at LLVM O0 and O2. The existing Hermes compiler is an additional baseline when investigating disagreements. Tests should print explicit scalar observations rather than rely on engine-specific object formatting. Negative zero, NaN and identity need dedicated observations; an overly broad normalizer can hide their differences.

Run representative programs for numbers/strings, branches and loops, arrays and objects, getters/setters, capture mutation, recursion, caught and uncaught exceptions, finally, and jobs. Include a wider generated function to compare distinct and reused storage, malformed/unsupported source, and repeated runs. When a checker rejects a root plan, do not assume every execution must fail: conservative analysis and unexecuted paths can explain nonfailure.

Real GC-stress validation is a separate configuration. `HERMESVM_SANITIZE_HANDLES` is the fork's intended aggressive handle-sanitizing mode. Record the actual successful build and execution configuration before making any claim about moving-GC behavior. Use targeted negative controls that actually retain a reference across a collecting operation. Passing normal-runtime tests is not a substitute for that evidence.

## 11. Milestones and review order

1. Preserve the reference source, correct the imported guide, deliver this document, and establish working source provenance.
2. Implement and verify real unit data, constants, function frames, arithmetic, calls and output. Commit the first native execution milestone.
3. Add closures, object operations, exception dispatch, completion records and runtime jobs. Add regressions for each cross-boundary behavior and commit the coherent native subset.
4. Add full-lifetime root reuse with independent checks and compare with distinct homes. Exercise wide functions and capture/unwind cases.
5. Complete the CLI, differential evidence, documentation, and boundary audit. Record any stress-build limitation explicitly rather than treating normal execution as equivalent evidence.

Review the runtime call builder and module data first, then root/call lifetime, then exception dispatch, and finally frontend corrections. Keeping those responsibilities in small modules makes the code inspectable and allows the runtime boundary or code generator to change later without redesigning the source language at the same time.

## 12. References and future expansion

Read `hermes/lib/BCGen/SH/LLVMNative/runtime.h`, `runtime.c`, `LLVMBackend.cpp`, `hermes/include/hermes/VM/static_h.h`, `hermes/lib/VM/StaticH.cpp`, and `hermes/utils/shllvm.py` for current ABI and lifetime behavior. Read `source/wb/src/frontend.js`, `src/core/30-ir.js`, `50-analysis.js`, `60-rewrite.js`, and `70-lower.js` inside this ticket for the imported compiler model. The assessment document explains differences between the model and native implementation.

Future work can extend the supported source profile, optimize proven numeric operations, replace completion environments with pairs, integrate generated units into the existing in-process JIT, or replace runtime services behind a versioned contract. None requires a speculative JIT immediately: eager runtime compilation is already JIT compilation. Guarded specialization and deoptimization are a later execution tier with their own frame-reconstruction requirements.
