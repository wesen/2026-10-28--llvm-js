---
Title: Baseline execution and dynamic evaluation implementation plan
Ticket: LLVM-ECMA-002
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
      Note: Native eval descriptor emission
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/eval_extensions.cpp
      Note: Native lexical evaluation and metadata ownership
    - Path: repo://hermes/lib/VM/Interpreter-slowpaths.cpp
      Note: Nested bytecode evaluation
    - Path: repo://hermes/utils/test_shllvm_test262.py
      Note: Runner pipeline and result contracts
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T19:53:27.626976004-04:00
WhatFor: ""
WhenToUse: ""
---

# Direct LLVM conformance measurement and dynamic evaluation

## 1. Purpose and prerequisites

This guide explains how to measure the JavaScript implementation in this repository and how to extend its evaluation semantics without invalidating existing native compilation. It is written for an intern who can read Python and C++ but has not worked on a JavaScript compiler. The starting source revision is `9985945`. Sections describing proposed interfaces are design work; they must not be mistaken for already implemented behavior.

A compiler translates source into an executable representation. Here, the static compiler reads a JavaScript file, resolves declarations, creates an intermediate representation, and emits LLVM IR. LLVM then produces native machine code. A runtime is the collection of services that the executable calls to implement managed values, objects, functions, exceptions, and garbage collection. Hermes supplies those services. Consequently, native compilation does not remove the managed runtime from this system.

Dynamic evaluation adds a second source input. The string passed to `eval` can arrive after native compilation has finished. This implementation compiles that string into Hermes bytecode and executes it in the same managed runtime. A binding is the association between an identifier and its storage and rules. An environment contains bindings or the storage used to implement them. A closure is a callable object that retains access to an environment after its creating function has returned.

The essential engineering problem is that native code and dynamically compiled code must observe the same binding. Copying a local variable into an object before eval and copying it back afterward is insufficient: an escaped closure can read or modify the variable later, and eval can invoke native closures during evaluation. The existing implementation therefore maps dynamic references onto native environment slots.

```text
Static JavaScript -> Hermes frontend -> Hermes IR -> LLVM IR
                                                    |
                                             native executable
                                                    |
                                                    v
                                               Hermes runtime
                                                    ^
                                                    |
eval string -> runtime frontend -> Hermes bytecode --+
                                                    |
                                  shared environments and objects
```

This diagram describes two compilation paths and one runtime. The dynamic path is not an LLVM JIT. The `lli` command used in regression testing is a separate way of executing already emitted LLVM IR.

## 2. Follow one binding through evaluation

Consider this representative program. Its expected output is a semantic example, not a new test execution receipt.

```javascript
function makeCounter() {
  "use strict";
  let count = 1;
  const nativeRead = () => count;
  const dynamicIncrement = eval("() => ++count");
  return [nativeRead, dynamicIncrement];
}
const pair = makeCounter();
print(pair[1]()); // 2
print(pair[0]()); // 2
```

The frontend recognizes that eval may refer to declarations which do not otherwise appear in its string as static operands. It retains scope metadata and materializes accessible values in environments. The LLVM emitter describes the visible `count` declaration using its name, physical environment slot, and binding flags. The runtime compiler reconstructs a parent scope for resolving the supplied source and assigns the reconstructed variable the native slot index. Both closures subsequently access the same cell.

The returned pair also creates a lifetime requirement. Once `makeCounter` returns, its native stack frame is gone. The environment must remain reachable from the closures, and the compiler metadata required by nested dynamic evaluation must remain owned by a live provider. The regression fixtures `eval_closure_gc.js`, `eval_tdz_closure.js`, and `function_eval_parent_gc.js` exercise relevant lifetime cases. Read these fixtures before changing ownership.

## 3. What the existing evidence establishes

LLVM-ECMA-001 introduced the pinned runner and several semantic fixes. At this ticket's starting revision, the targeted core gate passes 22 source contracts and the extension gate passes 56. A previous complete Function-family selection had 893 variants: 721 passed, 146 failed semantically, and 26 were unsupported. A later focused toString run improved its own 160-variant subset from 44 passes to 154. The complete Function family has not thereby been requalified; combining results from different builds would obscure the actual experiment.

The pinned inventory contains 53,615 test files and 102,992 variants, plus 294 fixture files. Inventory means metadata was examined. It does not mean the tests executed. The central deliverable of the baseline phase is to connect every selected variant to an actual terminal result or an explicit infrastructure failure.

A source contract and a variant are different counting units. A Test262 source without a strictness restriction commonly produces both a sloppy variant and a strict variant. An extension source contract can produce four native optimization executions and one lli execution. Reports must state which unit each number counts.

## 4. Test262 execution from metadata to result

The runner is `hermes/utils/test_shllvm_test262.py`. Its input is a clean Test262 checkout at the revision specified by `hermes/test/LLVMTest262/suite-lock.json`. The lock also records the interpretation-document digest and a specification artifact digest. Pinning these inputs prevents changes in tests or execution rules from being confused with engine changes.

`metadata(source, name)` parses the frontmatter through the inherited Test262 parser and checks its basic shape. `variants(meta)` determines the required source modes. `prepare_source(source, meta, variant, suite)` assembles the appropriate harness and strict directive. Raw tests preserve source bytes and omit the ordinary harness. Ordinary tests run as script source rather than inside a function wrapper, because wrapping changes top-level declarations and scope.

The runner uses a fresh process for each executable variant. Parse-negative tests stop at frontend parsing and semantic validation. Other tests pass through LLVM emission, assembly, verification, linking, and runtime execution. A compiler rejection cannot satisfy a runtime-negative contract. The required type and phase must match the observed failure.

```text
Selected source
      |
      v
Metadata -> variant expansion -> explicit host boundary?
                                   | yes: unsupported record
                                   | no
                                   v
                           prepare source and harness
                                   |
                 +-----------------+-------------------+
                 | parse-negative                      | other
                 v                                     v
        frontend validation                  emit / assemble / verify / link
                 |                                     |
                 v                                     v
        phase/type classification                  native execution
                                                       |
                                                       v
                                             completion/error classification
```

`classify(record, phase, expected, asynchronous)` is the main classification API. Runtime negatives use the opt-in `SHLLVM_TEST262_EXCEPTION` protocol emitted by `test262_extensions.cpp`. This avoids treating a thrown string containing “TypeError” as a real TypeError. Async tests additionally require the completion protocol used by the harness. Uncaught asynchronous exceptions still lack equivalent structured identity; the report explicitly records that limitation.

The initial classifier calls compile-stage failures unsupported. That is deliberately conservative but too coarse for an actionable baseline. The next reporting layer should retain the original status and separately group diagnostics into parser rejection, admitted-subset rejection, unresolved symbol, runtime assertion failure, and infrastructure categories. Unknown diagnostics must remain unknown instead of being assigned an invented cause.

## 5. Making a broad baseline practical

The initial runner executes sequentially and rewrites its entire JSON report after each result. That is manageable for hundreds of tests but becomes costly for roughly one hundred thousand variants. The next implementation should introduce bounded process concurrency, deterministic selection partitions, and less frequent report publication. Each test must keep its own temporary directory and executable. Sharing a mutable JavaScript runtime between variants would break isolation.

Proposed runner options are `--jobs N`, `--shard-count N`, `--shard-index I`, and `--checkpoint-every N`. A shard is a deterministic subset of selected source paths. Assign a source to one shard using a stable hash of its suite-relative path, then keep all of that source's variants in the same shard. Record the full pre-partition selection count as well as the shard count. An aggregate must reject missing shards, duplicate test/variant identities, mismatched builds, and incompatible optimization settings.

```text
plan = sorted(unique(selected_source_paths))
selected = paths whose stable_hash(relative_path) modulo shard_count == shard_index
jobs = expand metadata and variants for selected

while jobs remain and workers are available:
    execute a variant in an independent temporary directory
    store its terminal result under (relative_path, variant)
    periodically publish an atomic partial report

verify suite cleanliness and all input fingerprints
sort final records by (relative_path, variant)
publish completion and counts
```

This pseudocode is a proposed scheduling contract. It does not authorize claiming completion from a partial report. A timeout is a result for the affected execution, but interrupted scheduling leaves the overall selection incomplete. Native nonzero exits are expected for many negative tests; a baseline command can finish its work and return nonzero because semantic failures remain.

### Decision: bounded workers and explicit partitions

- **Context:** The suite is too large for repeated whole-report writes and sequential execution to remain convenient.
- **Options considered:** One runtime process for all tests, independent bounded workers, or external shell partitioning.
- **Decision:** Use independent workers with explicit deterministic partition metadata.
- **Rationale:** This retains isolation while making ownership and aggregation inspectable.
- **Consequences:** The runner must constrain memory, manage child processes, and test serial/parallel equivalence.
- **Status:** Proposed for this ticket's first implementation milestone.

Before writing output, reject destinations that would replace a compiler, harness file, suite lock, runner source, or another fingerprinted input. Temporary publication paths need the same protection. This is both data preservation and experimental integrity: reporting must not modify the experiment it is reporting.

## 6. Baseline profiles and attribution

Begin with frontend O0 and LLVM O0 on the existing Linux host toolchain. This profile makes emitted code and diagnostics easier to inspect. It is a measurement profile, not the final deployment profile. Once failures are classified, rerun corrected families under both frontend settings and both LLVM optimization settings. Physical device qualification remains a later deliverable.

Run the evaluation families first to obtain a before-change baseline. Then expand to the full pinned `test` selection in explicit partitions. Keep modules, realms, shared memory, and unavailable host helpers visible in the inventory. The baseline must not inherit a skip list that silently removes difficult tests. An unsupported record is not a pass.

An edition profile also needs a feature ledger. Test262 feature labels are not a complete edition mapping: absence of a proposal label does not prove a test belongs to the selected edition. Record reviewed inclusion decisions with references, keep unknown membership explicit, and distinguish the exploratory pinned-suite result from an edition-qualified result.

For each failure group, retain at least one representative test, its strictness variant, exact command, relevant diagnostic, source hash, and suspected owner. Rank groups by affected variants and architectural dependency. A hundred failures caused by one missing host object should be investigated as one cause, while their individual results remain available.

## 7. Direct eval, indirect eval, and Function

A direct eval call is recognized through the language's call semantics and the identity of the intrinsic eval function. An alias or comma-expression call uses indirect evaluation. Direct evaluation can access the caller's lexical context. Indirect evaluation and the Function constructor use their respective global contexts. The existing frontend and runtime already distinguish these paths; never replace a direct call with an indirect call merely to make a test pass.

The relevant specification algorithms are [PerformEval and EvalDeclarationInstantiation](https://tc39.es/ecma262/2026/multipage/global-object.html#sec-performeval). For this ticket, their central design consequence is that strict evaluation keeps its declarations local to evaluation, while non-strict direct evaluation can affect the caller's variable environment. The original source context also controls whether constructs such as `new.target` are legal.

At the starting revision, the native bridge accepts non-string inputs unchanged, accepts direct string eval from strict callers, and rejects all direct string eval from sloppy callers. It does not distinguish a strict directive inside a string from a genuinely non-strict evaluated program. This creates an incremental opportunity: admit strings with a real strict directive while retaining rejection of non-strict source until dynamic declaration storage exists.

A strictness detector must use the real parser. Searching for the substring `use strict` would misclassify comments, escaped strings, parenthesized expressions, nested functions, and strings that appear after the directive prologue. The parser should determine strictness without executing source. The final eval compilation still performs semantic validation in the caller's reconstructed context; a standalone global semantic check would incorrectly reject constructor `new.target`.

## 8. Current native eval implementation

`FunctionEmitter::emitEval` in `LLVMBackend.cpp` emits the bridge call. It walks physical variable scopes from outermost to innermost, associates visible declarations with their physical slots, and encodes TDZ and constness flags. TDZ, the temporal dead zone, is the interval in which a lexical binding exists but has not been initialized; reads and writes must throw rather than observe a default value.

The ABI is declared in `eval_extensions.h`. `SHLLVMEvalBinding` contains a UTF-8 name, slot index, and flags. `SHLLVMEvalScope` contains an array of bindings and physical slot count. On this host64 implementation both descriptor structures have static size assertions. The descriptors themselves contain no garbage-collected pointers. Value arguments point into rooted native slots.

```c
void shllvm_eval_direct(
    void *out, void *runtime, void *source, void *environment,
    void *this_value, void *new_target,
    const SHLLVMEvalScope *scopes,
    uint32_t scope_count, uint32_t caller_flags);
```

`evaluate` checks the input, converts source text, configures compile flags, and invokes compilation through the runtime's stack executor. `compileInNativeEnvironment` builds non-executed parent functions, resolves their declarations, and replaces their variable storage indices with the native indices. It restores constness and TDZ properties that a synthetic `var` declaration alone would not express. `hbc::compileEvalModule` then compiles the actual source in that parent context.

The scaffold must never execute. Its purpose is to provide compiler structures, not runtime declarations. Executing it would allocate unrelated variables and destroy shared-cell identity. Its retained Function and Module ownership also matters when dynamic closures escape. The code explicitly transfers ownership of non-executed parent Function nodes; removing that transfer can invalidate subsequent nested eval.

## 9. Why general sloppy eval is a larger change

Consider this proposed regression:

```javascript
function outer() {
  const read = () => introduced;
  eval("var introduced = 7");
  return read();
}
```

A statically unresolved name may have been compiled as a global lookup. After evaluation introduces a local variable, the already-created native closure must instead observe that local binding. Removing the strict-caller rejection cannot change the previously emitted lookup. This is the central reason general sloppy eval needs coordinated compiler and runtime work.

The proposed model attaches an extensible binding record to eval-capable variable environments. Existing statically known bindings keep their physical cells. New declarations occupy dynamic cells. Reads and writes whose resolution can be changed by eval search the relevant dynamic records in scope order before continuing to the outer environment. Deletion and declaration conflicts must use binding operations rather than arbitrary ordinary-object property behavior.

```text
native closure ----> function environment
                         | static cells: known locals
                         | dynamic cells: eval-introduced vars
                         v
                    outer environment
                         v
                    global environment

eval closure ------> the same function environment
```

The dynamic record must be traced by garbage collection. A raw C++ map of movable HermesValue objects without tracing is not acceptable. Adding the record also affects environment layouts, interpreter loads, native helper calls, and optimization assumptions. Before choosing a concrete representation, inspect Environment allocation and tracing and document the memory cost for functions that never perform eval.

Proposed semantic operations, not existing APIs:

```text
ResolveEvalSensitiveName(environment, name)
    for each relevant environment from inner to outer:
        if its binding record has name:
            return a reference to that binding
    return the ordinary outer/global resolution result

InstantiateEvalVar(variable_environment, intervening_scopes, name)
    validate conflicts with intervening lexical declarations
    reuse an existing permitted variable binding, if present
    otherwise create a dynamic mutable binding
```

These sketches intentionally omit normative details. Implementing them requires a clause-by-clause design for declaration conflicts, strictness, parameter environments, `with`, Annex B functions, deletion, and global properties. Keep that design review separate from the narrow strict-source improvement.

### Decision: preserve explicit rejection until storage exists

- **Context:** General non-strict eval can change name resolution after native compilation.
- **Options considered:** Remove the guard, compile eval globally, or add dynamic binding support across both paths.
- **Decision:** Add the necessary representation and lookup semantics before admitting general sloppy eval.
- **Rationale:** The first two alternatives can produce plausible but incorrect results.
- **Consequences:** Strict-source admission can land independently; general sloppy eval remains open until its tests pass.
- **Status:** Accepted engineering constraint.

## 10. Interpreter and caller-context integration

`Interpreter::caseDirectEval` in `Interpreter-slowpaths.cpp` reconstructs the active environment from retained bytecode debug/scoping metadata, then calls `evalInEnvironment`. Native eval-created closures can execute this bytecode path during nested evaluation. Therefore a native-only fix is insufficient when a dynamic function contains another eval call.

The current interpreter also rejects non-strict callers and requires retained lexical metadata. Some ordinary interpreter fixtures lack that metadata. Removing the metadata check would replace a precise rejection with incorrect global behavior. For the incremental strict-source work, test both a native caller and a dynamic Function body, and identify whether the bytecode path has the required scope information.

Derived constructors, enclosing private names, and `super` need more than a declaration table. Derived construction carries an initialization state for `this`. Private names have identities independent of their spelling. Super operations depend on a home object and receiver. These contexts need explicit metadata and lifetime rules before their current rejections can be removed. Keep independent tests for direct calls and captured arrows, because an arrow inherits context rather than introducing its own.

## 11. Implementation sequence and review boundaries

1. **Publish the guide and establish tasks.** Preserve the original evidence and record the starting revision. Upload this guide before changing the implementation, as requested.
2. **Scale measurement.** Add deterministic scheduling and checkpoint controls, adversarial tests, output protection, and report metadata. Commit this infrastructure separately from runtime semantics.
3. **Capture pre-change eval results.** Run the eval families and store their terminal results under the immutable build fingerprint. Use these records to select concrete regressions.
4. **Admit strictly evaluated source from sloppy callers.** Detect the directive with the parser, retain current shared-slot mapping, cover nested dynamic calls, and preserve the general sloppy boundary. Commit the validated semantic slice.
5. **Execute the broad profile.** Partition the entire pinned suite, aggregate only matching runs, and publish a failure inventory. A full profile may require substantial time and disk; record incomplete partitions explicitly.
6. **Implement general dynamic bindings.** First review environment ownership and lookup lowering. Then add declaration, closure, GC, conflict, and deletion tests before removing the admission boundary.
7. **Extend caller contexts.** Address private/super/derived-constructor contexts with separate design and regression milestones.

Each commit should state its validated scope. The detailed diary owns experiments and failures; the tasks own completion state; the result artifacts own measured totals. Avoid maintaining three inconsistent copies of the same current-state table.

## 12. Commands and development workflow

Run commands from the repository root. The existing build directory is `hermes/build-llvm`, and the local LLVM tools are under `/usr/lib/llvm-18/bin`. These locations are machine-specific, so pass them explicitly rather than embedding them in library code.

```bash
cmake --build hermes/build-llvm \
  --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4

python3 hermes/utils/test_shllvm_test262.py \
  --suite /tmp/llvm-test262 --build-dir hermes/build-llvm \
  --llvm-bin /usr/lib/llvm-18/bin --output /tmp/eval-baseline.json \
  test/built-ins/eval

python3 hermes/utils/test_shllvm_test262_runner.py

python3 hermes/utils/test_shllvm_extensions.py \
  --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin \
  --jobs 3 --output /tmp/extensions.json
```

The second command describes the existing runner interface; new scheduling options become valid only after their implementation. Use tmux for long-running runs, capture output to a file, and record the process exit separately from the JSON completion flag. Do not rebuild or edit measured inputs during a final baseline. A fingerprint mismatch invalidates its claim to describe one immutable build.

## 13. Validation contracts

Runner tests must demonstrate disjoint partitions, complete union, deterministic assignment across input ordering, serial/parallel result equivalence, timeout classification, missing harness behavior, and protection of input files. Include empty partitions in the contract. A shard with no tests can complete successfully without claiming that any language behavior passed.

Dynamic-eval tests should cover the following independent behaviors:

- A genuine strict directive in a sloppy caller can read and mutate an existing local cell.
- A strict evaluated `var` does not leak into the caller.
- Comments before a directive are accepted, while escaped and parenthesized strings do not become directives.
- `this`, `arguments`, and constructor `new.target` retain the correct caller meaning.
- An escaped dynamic closure remains valid after collection, and nested eval sees shared mutations.
- Non-string eval still returns the same value, including object identity.
- Unsupported genuinely sloppy declaration injection remains a documented boundary until implemented.
- Const and TDZ failures occur at the correct phase and remain catchable where required.

For runtime changes, compare the independent Node oracle where applicable, run all four native optimization combinations, and execute real lli. The C backend shares substantial frontend/runtime code and has different lexical-eval support, so its mismatch must be classified rather than treated as independent proof against LLVM. The standard remains the normative reference.

## 14. Source and API reading map

Paths below are repository-relative and refer to the starting revision unless a later diary entry names a change. Search the listed symbols rather than depending on line numbers after edits.

| File | Symbols or role | Reading question |
|---|---|---|
| `hermes/utils/test_shllvm_test262.py` | `main`, `execute_variant`, `classify` | Where does each phase become a result? |
| `hermes/utils/test_shllvm_test262_runner.py` | classifier/preparation tests | Which false passes are explicitly prevented? |
| `hermes/utils/test_shllvm_test262_native.py` | real host probes | Does the actual native exception protocol match its unit tests? |
| `hermes/test/LLVMTest262/suite-lock.json` | revision and artifact identity | Which suite and interpretation rules are being executed? |
| `hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | `FunctionEmitter::emitEval` | How are visible declarations mapped to physical scopes? |
| `hermes/lib/BCGen/SH/LLVMNative/eval_extensions.h` | `SHLLVMEvalBinding`, `SHLLVMEvalScope` | Which metadata crosses the native ABI? |
| `hermes/lib/BCGen/SH/LLVMNative/eval_extensions.cpp` | `evaluate`, `compileInNativeEnvironment` | Which roots and owners survive compilation and escape? |
| `hermes/lib/BCGen/HBC/HBC.cpp` | `compileEvalModule` and its worker | How is eval resolved within a retained parent? |
| `hermes/lib/VM/Interpreter-slowpaths.cpp` | `Interpreter::caseDirectEval` | How is the environment recovered in bytecode? |
| `hermes/lib/VM/JSLib/JSLibInternal.cpp` | `createDynamicFunction` | Where is Function source assembled and compiled? |
| `hermes/lib/IRGen/ESTreeIRGen-expr.cpp` | direct-eval generation | Which source contexts become IR operands? |
| `hermes/lib/Sema/SemanticResolver.cpp` | declaration and assignment resolution | Which names are resolved before native execution? |
| `hermes/include/hermes/VM/Environment.h` | environment storage | What must change to trace dynamic binding storage? |
| `hermes/test/LLVMNativeExtensions/eval_*.js` | lexical, GC, and rejection contracts | Which boundaries already have executable evidence? |

## 15. Exercises and completion criteria

Trace the representative counter example through `emitEval`, its descriptors, and `compileInNativeEnvironment`. Explain why the slot index must describe the actual native environment rather than the synthetic parent function's original layout. Then write a test that mutates the same cell in both directions, requests collection, and repeats the observations.

Construct three strings containing the words `use strict`: a real directive, a comment, and a directive-like string after a non-directive statement. Explain which stage determines strictness and why a regular-expression scan would be unreliable. Extend the exercise to a strict string using `new.target` inside a constructor.

Finally, inspect one parse-negative and one runtime-negative Test262 source. Identify their expected phases and show how a compiler crash would be classified. Explain why a baseline with thousands of explicit unsupported variants can still be a completed measurement while the implementation remains nonconforming.

This ticket's baseline is complete only when every variant in its declared profile has a terminal record, the input identity checks pass, partitions reconcile, and failure attribution is published. Dynamic evaluation is complete only for the explicitly tested semantic scope. General sloppy eval, private/super context, and derived constructors must remain open until their implementation and qualification are actually finished.

## References

- [ECMAScript 2026 specification](https://tc39.es/ecma262/2026/multipage/), with the artifact digest in the suite lock.
- [PerformEval and declaration instantiation](https://tc39.es/ecma262/2026/multipage/global-object.html#sec-performeval), normative evaluation algorithms.
- [Pinned Test262 interpretation rules](https://github.com/tc39/test262/blob/0b4e0812022b18236b5276d2804948fdd9f71603/INTERPRETING.md), also available in the local pinned checkout.
- LLVM-ECMA-001's intern guide and implementation evidence, linked from this ticket index, for the wider native runtime and earlier results.
