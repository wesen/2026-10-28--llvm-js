---
Title: Investigation diary
Ticket: LLVM-ECMA-001
Status: active
Topics:
    - llvm
    - javascript
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: "Evidence-backed onboarding and implementation planning for ECMAScript conformance."
LastUpdated: 2026-10-28T18:29:07.070544628-04:00
WhatFor: "Understand the existing backend and plan measurable conformance work."
WhenToUse: "Onboarding, architecture review, and implementation planning."
---

# Investigation diary

## 2026-10-28 — Request and scope

The user requested a new docmgr ticket and a detailed intern-oriented analysis, design, and implementation guide, followed by reMarkable upload. The user also stated: “We want to make this setup fully ecmascript compatible, so do your diligent research as well.” The deliverable is a researched implementation plan; this ticket does not change runtime semantics.

I used the docmgr, ticket-research-docmgr-remarkable, textbook-authoring, remarkable-upload, and git-commit-instructions skills. The repository already had `.ttmp.yaml` and vocabulary configuration, with zero tickets, so initialization was unnecessary. Created `LLVM-ECMA-001` and three documents with `docmgr ticket create-ticket` and `docmgr doc add`.

## Access failure and recovery

Initial shell commands produced no output and eventually reported a bubblewrap bind-mount failure for `/newroot/mnt/pico`: “No such device.” A minimal escalated `/bin/pwd` succeeded. Subsequent authorized local documentation operations used escalated execution to bypass the broken sandbox mount. This was an environment failure, not a repository failure or an approval rejection.

An initial source search used `hermes/lib/BCGen/LLVMNative/LLVMBackend.cpp`, which does not exist. `rg --files` located the actual path under `hermes/lib/BCGen/SH/LLVMNative/`. The guide and its reference table use the corrected paths.

## Source inspection and research

Read the compiler bridge headers, emitter admission check, eval descriptors, generator/async source anchors, inherited Test262 preprocessing, runner execution, and skip policy. The key new finding was the unconditional module skip before feature filtering in `test_run_defs.py`. The inherited permanent exclusions and stale-looking species exclusion also require explicit re-evaluation.

Consulted the edition-specific ECMA-262 pages and official Test262 interpretation and runner documentation. Chose a proposed ECMAScript 2026 host64 baseline while explicitly retaining the snapshot's draft identity and the need to lock a Test262 revision. No entire external suite was downloaded or run; no new conformance percentage was inferred.

## Authoring and review

Wrote a 21-chapter guide with foundational prose, a worked closure example, three Mermaid diagrams, existing ABI declarations, proposed API and runner pseudocode, gap analysis, four decision records, seven implementation phases, source references, and exercises. The research ledger separates direct observations from proposals and outstanding measurements. Proposed behavior is not represented as implemented code.

Validation and upload results are recorded below after finalization.

## Documentation validation

The first reference-audit run used an incorrect fixed parent depth and therefore reported every path missing. Changed it to locate the ancestor containing `.ttmp.yaml`; the rerun checked 24 source/document paths with no missing entries and confirmed balanced fences and three Mermaid diagrams. This was a validation-script path error, not missing source. `docmgr doctor --ticket LLVM-ECMA-001 --stale-after 30` passed all checks. `git diff --check` also passed.

Started the requested bundle upload in the `llvm-ecma-upload` tmux session using `remarquee upload bundle`, guide first and research ledger second, with a depth-two table of contents. The destination is `/ai/2026/10/28/LLVM-ECMA-001`, document name `LLVM-ECMA-001-Intern-Guide`. No overwrite flag was used.

## Delivery

The uploader exited 0 and returned: `OK: uploaded LLVM-ECMA-001-Intern-Guide.pdf -> /ai/2026/10/28/LLVM-ECMA-001`. The receipt records hashes of both uploaded Markdown inputs. This proves successful cloud delivery, not physical device synchronization. The tmux session had exited when subsequently queried, consistent with command completion. No extra cloud listing or overwrite was needed.

All requested documentation tasks are complete. The proposed conformance implementation backlog remains unchecked. No compiler/runtime source was changed during this ticket.

## Step 1: Start the LLVM conformance runner and trustworthy exception reporting

The implementation begins with the first milestone in the guide: a pinned Test262 runner that keeps unsupported behavior and infrastructure failures visible. Reading the native exception printer exposed a false-pass risk: a thrown string or a modified stack could resemble a TypeError diagnostic. I therefore added an opt-in native host path that inspects the actual thrown object's constructor name.

### Prompt Context
**User prompt (verbatim):** "Then once done, implement and commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"
**Assistant interpretation:** Begin the implementation roadmap, validate meaningful milestones, and commit with detailed ongoing evidence.
**Inferred user intent:** Make measurable progress toward full ECMAScript compatibility without losing implementation history.

### What I did
- Fetched official Test262 into `/tmp/llvm-test262`; pinned `0b4e0812022b18236b5276d2804948fdd9f71603` and the interpretation document hash.
- Added `test_shllvm_test262.py`, an explicit LLVM script runner with per-stage commands/results and no inherited skip list.
- Added an opt-in `--shllvm-test262` native host switch and `test262_extensions.cpp` to inspect thrown constructor names.
- Added adversarial runner tests; `python3 hermes/utils/test_shllvm_test262_runner.py` passed 11 tests.

### Why
Expected-error tests must not pass because LLVM compilation crashed or because an arbitrary string resembled an exception. A dedicated reporter avoids wrapping test source in a function, which would alter global and lexical semantics.

### What worked
The suite clone completed successfully. The Python tests cover wrong error type/phase, signals, sanitizers, missing executables, timeouts, missing/duplicate async completion, raw source preservation, include containment, and explicit host boundaries.

### What didn't work
`cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4` failed compiling the new helper: `test262_extensions.cpp:26:48: error: indirection requires pointer operand ('PseudoHandle<>' invalid)`. The property-read API returns a CallResult containing PseudoHandle; double dereference is invalid. Corrected handle creation to use `getHermesValue()` and restarted the narrow build.

### What I learned
The current native host already supplies global/evalScript/detachment hooks but does not provide the entire Test262 host. Parser-only negatives also cannot yet establish all semantic early-error behavior. Those limitations belong in the report.

### What was tricky to build
The exception value returned by guarded initialization must become a rooted handle before property access can allocate. Constructor/name getters can themselves throw; such results must be invalid diagnostics rather than a substitute expected exception. The opt-in switch is removed before runtime option parsing and is not consumed after the script-argument separator.

### What warrants a second pair of eyes
Review rooted-handle lifetime and the exception reporter's interaction with user-defined constructor/name getters. Review strictness variant preparation and whether negative-phase classification can produce false positives.

### What should be done in the future
Run real pinned Test262 cases, add native reporter regression probes, and measure larger family failures. Modules, agents, realms, semantic early errors, and structured asynchronous exceptions remain separate work.

### Code review instructions
Start with `utils/test_shllvm_test262.py`, then `LLVMNative/test262_extensions.cpp` and `runtime.c`. Run the Python test module before native integration checks.

### Technical details
The runner invokes parser, LLVM emission, assembly, verification/optimization, linking, and native execution separately. Reports preserve commands, stdout/stderr, durations, input/artifact hashes, selected suite revision, and explicit unsupported reasons. No source is silently executed through a bytecode fallback.

## Step 2: Validate and commit the first runnable conformance milestone

The corrected native helper built successfully. Fourteen native adversarial probes matched their expected classifications, and the unchanged default execution path passed the full core and extension gates. A first real upstream selection produced a complete, fingerprint-stable baseline: 348 passing variants, four semantic failures, and one explicit unsupported compilation among 353 variants from 200 source files.

### Prompt Context
See Step 1 for the verbatim implementation request. This checkpoint completes the initial runnable runner and measures the next source-level work; it does not complete the whole conformance roadmap.

### What I did
- Ran `python3 hermes/utils/test_shllvm_test262_runner.py`: 11 tests passed.
- Ran `test_shllvm_test262_native.py` with the pinned suite and explicit build/tool paths: all 14 synthetic probes matched.
- Ran `test_shllvm.py` and `test_shllvm_extensions.py` with `--jobs 3`, without quick mode, case filters, or JIT skipping: 22/22 and 53/53 source contracts passed.
- Ran the new Test262 runner over `test/language/statements/variable` and `test/language/expressions/await` at frontend O0 / LLVM O0.
- Added `hermes/docs/llvm/TEST262.md` and persisted baseline/probe evidence in `reference/implementation-evidence/`.

### Why
The native host change needed both adversarial opt-in coverage and the established default-host regression gates. A broad family selection provides better next-step evidence than isolated handpicked successes.

### What worked
The full extension gate completed with 200 native and 50 real lli executions, unchanged fingerprints, and no failed cases. The new baseline completed with no changed inputs and a clean pinned suite.

### What didn't work
The first smoke run used `-dump-ast` for a strict `arguments` binding early error and incorrectly observed no parser rejection. Changed the command to `-dump-transformed-ast`, which includes semantic validation; that upstream case then passed. A separate HTML-comment probe failed native compilation with `error: invalid expression (possible JSX: pass -parse-jsx to parse)`; it remained unsupported rather than being counted as an expected runtime error.

The complete variable/await baseline failed `12.2.1-11.js`, `12.2.1-17-s.js`, `S12.2_A5.js`, and sloppy `cptn-value.js`, each with `SHLLVM_TEST262_EXCEPTION:SyntaxError`. `binding-resolution.js` was unsupported with `error: with statement is not supported`. Source inspection identified the Function-body case as the explicit sloppy arguments-assignment prohibition; the other failures involve currently restricted sloppy eval.

### What I learned
The baseline can separate delivered async behavior from remaining dynamic-scope behavior. Its 348 passes are selected variant results, not an ECMAScript-wide percentage. The native reporter protects negative cases against string/stack spoofing, while asynchronous uncaught-error identity remains an explicit limitation.

### What was tricky to build
Timeout handling now kills complete process groups; captured output uses temporary files and a one-MiB per-stream reporting limit. Input fingerprinting includes the driver, metadata parser, compiler/runtime binaries, build configuration, tool binaries, selected sources, and harness files.

### What warrants a second pair of eyes
Review the frontend-only early-error boundary, host capability exclusions, and separation of real suite results from synthetic runner probes.

### What should be done in the future
Fix mutable sloppy arguments bindings first, then expand the measured baseline and prioritize dynamic environments. Specification artifact digest pinning and edition/proposal partitioning remain open.

### Code review instructions
Read `docs/llvm/TEST262.md`, the Python runner/classifier, and the opt-in runtime path. Reproduce the two selected directories with the command in that document. Evidence retains every baseline variant and full failure commands; successful stdout/stderr is omitted from the compact committed baseline.

### Technical details
Pinned suite: `0b4e0812022b18236b5276d2804948fdd9f71603`. Baseline: 353 variants, 348 pass, 4 semantic_failure, 1 unsupported. The native probe evidence has a separate schema and does not inflate these totals.

## Step 3: Represent sloppy arguments reassignment as a mutable environment binding

The runner milestone was committed as `82b943c` — “Add pinned direct LLVM Test262 runner and native error classification.” The first source correction targets the measured Function-constructor failure. The frontend explicitly prohibited assignment to the implicit arguments binding; simply removing that diagnostic would leave IRGen returning the original arguments object on subsequent reads.

### Prompt Context
See Step 1. This step implements a measured language gap and retains the strict-mode error contract.

### What I did
- Added `FunctionInfo::argumentsMayBeAssigned` and preserved it in semantic metadata cloning.
- Marked the owning function when a sloppy assignment targets its implicit arguments declaration, including nested arrow writes.
- Made capture-state initialization allocate mutable, Any-typed arguments storage for those functions and bind declaration data to it.
- Added `arguments_reassignment.js` covering assignment, compound/update/destructuring writes, arrows, escaping closures with GC, default parameters, generators, dynamic Function bodies, parameter shadowing, and strict rejection.
- Started the compiler/runtime rebuild before executing the new fixture.

### Why
The binding must be distinct from the arguments object. Reassigning it must preserve old references to the object while subsequent reads observe the replacement. A semantic assignment bit avoids forcing every ordinary arguments read into eagerly mutable storage.

### What worked
Source tracing identified the existing captured-arguments path as the correct shared-cell mechanism. Its declaration mapping already supports loads and stores, and cloning explicitly carries the new metadata. Validation results follow in the next checkpoint.

### What didn't work
No new execution result is claimed yet; the rebuild and regression runs are pending.

### What I learned
The previous captured-arguments slot had Object type. A mutable binding can hold numbers, strings, or any other value, so retaining that type would permit incorrect optimizer assumptions.

### What was tricky to build
An arrow's assignment must mark the declaration's owning function, not the arrow's own FunctionInfo. Semantic metadata also survives cloned ASTs used by other lowering paths. Default parameter evaluation must see initialized arguments storage before evaluating its expression.

### What warrants a second pair of eyes
Review ownership marking, metadata cloning, and generator/async prologue behavior. Broader var-arguments aliasing and mapped argument/parameter semantics remain distinct concerns.

### What should be done in the future
Run the new fixture through all frontend/LLVM combinations and real lli; rerun the pinned baseline and affected shared compiler regression gates.

### Code review instructions
Read the new FunctionInfo field, the sloppy branch of semantic assignment validation, and `initCaptureStateInES5FunctionHelper` together. Then read the new fixture before interpreting the test receipts.

### Technical details
The new field is set only for an implicit Arguments-special declaration and a non-strict assignment. Strict-mode eval/arguments assignments remain rejected before this branch. Existing ordinary shadowing declarations continue to use their own binding path.

## Step 4: Correct empty metadata lists and inventory the full pinned suite

While the shared semantic-header rebuild ran, I inventoried the entire pinned suite without executing it. The inventory exposed a concrete parser defect: `flags: []` became `['']`. The same inherited parser handles includes, so an empty include list could attempt to open the harness directory as a file. Correcting the parser itself avoids a runner-specific workaround.

### Prompt Context
See Step 1. This is a separately reviewable conformance-tooling checkpoint; the arguments implementation remains under validation.

### What I did
- Fixed `myFlowList` in `_monkeyYaml.py` to produce an empty list for empty or whitespace-only flow-list contents.
- Added an adversarial metadata regression; the Python runner checks now pass 12/12.
- Added ticket script `02-inventory-test262.py` and retained the resulting inventory summary.
- Downloaded the edition-specific single-page specification and recorded its digest in the suite lock: SHA-256 `0119d5a26afb504f4a7aba84d9d8288912044cc459c0552ea5f22f911cb87f40`, 7,530,216 bytes, retrieved 2026-10-28. The downloaded HTML is in `/tmp/llvm-ecma262-2026.html`; the durable lock records URL and digest, not a vendored copy.

### Why
Metadata defines the test contract. An empty list must not create an empty feature or a nonexistent include. Pinning the specification bytes also makes changes to the edition URL detectable.

### What worked
The corrected inventory has 53,615 test files, 102,992 variants, 294 fixture files, and no metadata errors. The previous 268 empty flag entries disappeared. The suite includes 843 module-tagged files and 5,624 async-tagged files; these are inventory counts, not executed passes.

### What didn't work
The original inventory silently included an empty-string flag 268 times. Source inspection traced this to splitting an empty string on commas. The regression now exercises flags, features, and includes together.

### What I learned
Reusing the upstream-derived parser does not eliminate the need to validate its edge cases against the pinned suite. The inventory supplies scope, not implementation status.

### What was tricky to build
The inventory must keep fixture files separate and distinguish source-file counts from expanded variants. Its output explicitly states inventory_only.

### What warrants a second pair of eyes
Review the spec snapshot's identity and the remaining need to partition proposals and edition-required tests. The URL plus digest is a pin; long-term offline retention remains an artifact-storage choice.

### What should be done in the future
Use the complete inventory to plan execution shards and classify host/profile exclusions without hiding required language gaps.

### Code review instructions
Run `python3 hermes/utils/test_shllvm_test262_runner.py` and the ticket inventory script with the pinned suite. The latter performs no program execution.

### Technical details
Inventory phases: 48,881 positive files, 4,660 parse-negative files, 40 runtime-negative files, and 34 resolution-negative files. Full inventory output remains `/tmp/llvm-test262-inventory.json`; the committed summary retains its hash and complete feature frequencies.

## Step 5: Qualify mutable arguments bindings and compare the same baseline

The arguments implementation passed its focused execution matrix and then the complete regression gates. The same 353 Test262 variants now contain 349 passes, three semantic failures, and one unsupported case. The previously failing strict-caller Function-constructor case now passes, with no previously passing variant lost.

### Prompt Context
See Step 1. The separate metadata/specification checkpoint is commit `219cdc5` — “Fix empty Test262 metadata lists and pin specification artifact.”

### What I did
- Ran the focused `arguments_reassignment` extension case through C, all four native frontend/LLVM combinations, and lli.
- Added asynchronous suspension/GC coverage to the fixture before the full gate.
- Updated the inherited `Sema/assign-arguments.js` test to accept sloppy assignment and explicitly retain a strict function rejection.
- Ran lit on `assign-arguments.js` and `invalid-args-eval.js`: 2/2 passed.
- Ran full core and extension gates: 22/22 and 54/54 source contracts passed, including the new fixture.
- Repeated the pinned variable/await baseline and retained the before/after evidence.

### Why
The change affects shared semantic analysis and IR generation, so LLVM-only output is insufficient. C comparison, optimized native execution, generator/async suspension, strict diagnostics, and broad regression checks exercise different consequences of the new binding representation.

### What worked
The focused test matched Node, C, native LLVM, and lli. The complete gate was fingerprint-stable. The original measured `12.2.1-17-s.js` failure is fixed.

### What didn't work
The remaining baseline failures still involve unsupported sloppy direct eval, and `with` remains unsupported. They are retained as failures; this patch does not reinterpret them as passes. No additional arguments regression failure occurred.

### What I learned
The existing captured-cell machinery correctly supports replacement values across default-parameter evaluation, escaping arrows, generator suspension, and async resumption once semantic ownership and the slot type are correct.

### What was tricky to build
A shared semantic-header change rebuilt 260 targets. Validation waited for the completed build before fingerprinting binaries. Generated lit scripts were removed individually after the successful run.

### What warrants a second pair of eyes
Review arguments aliasing and performance outside the tested replacement cases. `var arguments` aliasing and mapped parameters retain their existing separate semantics and are not claimed fixed here.

### What should be done in the future
Move LLVM's statically provable const/TDZ failures to the required runtime phase, and continue work on the remaining measured dynamic-scope gaps.

### Code review instructions
Compare the `baseline-milestone-1.json` and `baseline-arguments.json` variant outcomes, then inspect the focused fixture and the semantic/IRGen patch. The existing strict diagnostic test is an important guard against broadening invalid strict syntax.

### Technical details
All checks used the existing host64 configuration. The new extension total is 54 because one regression source was added; that total remains separate from 353 upstream Test262 variants and the synthetic runner probes.

## Step 6: Use ECMAScript runtime error timing in the ordinary LLVM workflow

The arguments milestone is committed as `f3b2fee`. The next correction removes a mismatch between the conformance runner and ordinary LLVM compilation: the runner explicitly enabled the existing compliance setting, but ordinary `shermes -emit-llvm` still rejected some catchable runtime errors during compilation. LLVM output now enables the same semantic setting by default.

### Prompt Context
See Step 1. This changes ordinary user-visible language behavior, not merely test configuration.

### What I did
- Enabled the shared compliance error-timing setting whenever the output target is LLVM.
- Replaced the default-check harness's historical static-TDZ rejection contract with runtime read/write checks, const reassignment, and an unexecuted invalid assignment.
- Added a regression covering const writes/updates, TDZ reads/writes, private getter/setter/method errors, and deletion of a super property.
- Updated the current architecture documentation while retaining historical imported evidence.
- Verified the new fixture's expected result with Node and started the rebuild and focused/default checks.

### Why
A valid program can catch these errors or never execute the offending operation. Rejecting the whole source changes observable semantics. The compiler already emits the necessary runtime checks under its compliance setting, so enabling that setting for LLVM avoids a second implementation of the same rules.

### What worked
The Node script oracle prints `language-error-timing-ok`. The source change is isolated to LLVM context configuration; validation of emitted behavior follows.

### What didn't work
No new failed validation is claimed at this stage. The earlier defaults harness intentionally expected the wrong conformance phase; its expectation is now replaced with executable runtime contracts.

### What I learned
The setting also controls premature diagnostics for private getter/setter/method operations and delete-super. Those paths need direct runtime coverage, not just a const-assignment example.

### What was tricky to build
The C frontend retains different default diagnostic policy. The new fixture records this oracle limitation explicitly and still compares native output with Node. Strict syntax rejection is not disabled by the compliance setting.

### What warrants a second pair of eyes
Review all uses of `CodeGenerationSettings::test262` and confirm the change does not turn actual grammar or strict-mode errors into accepted programs. Explicit TDZ/block-scoping overrides remain diagnostic nonconforming configurations.

### What should be done in the future
Qualify the full extension and publication gates after the focused cases, then continue closing dynamic-scope gaps measured by the pinned baseline.

### Code review instructions
Start with `createContext` in `tools/shermes/shermes.cpp`, then the eight raw-default cases and `language_error_timing.js`. Historical reports should remain historical rather than being rewritten to claim this behavior existed in the imported release.

### Technical details
The ordinary LLVM path now sets `codeGenOpts.test262` independently of the explicit `-test262` option. The existing bytecode/C frontend default policy is unchanged.

### Step 6 validation correction

The first full core run passed 21/22. Its sole failure was the historical `unsupported_const_assignment.js` contract: the compiler now returned exit 0 and replaced the sentinel output because this valid source correctly compiled. The recorded failure was `existing_output_preserved: false`, not a code-generation failure. Converted that fixture to `error_const_assignment.js` with an uncaught const assignment so the core suite now checks runtime TypeError; catchability is covered by the defaults and new extension fixture. Removed the obsolete const-rejection diagnostic branch from the core harness. The full extension gate already passed 55/55, defaults passed 8/8, and publication checks passed 6/6. Only the affected core gate needs a rerun.

## Step 7: Qualify default error timing and expand Function-family coverage

The corrected core contract now passes, completing this milestone's validation. Ordinary LLVM compilation preserves runtime error timing for the tested const, TDZ, private-access, and super-delete cases. A separately executed Function-family baseline supplies additional measured work rather than assuming all builtins are conforming.

### Prompt Context
See Step 1. This checkpoint closes the error-timing implementation step, not the overall ECMAScript program.

### What I did
- Re-ran the affected full core gate after migrating the const fixture: 22/22 passed.
- Retained the completed full extension gate: 55/55 passed, with stable fingerprints.
- Retained raw-default 8/8 and driver-publication 6/6 results.
- Completed `test/built-ins/Function` at frontend O0 / LLVM O0: 893 variants, 721 pass, 146 semantic failures, and 26 unsupported.
- Preserved compact per-variant Function results and full failure commands in the ticket evidence.

### Why
Runtime error timing needs validation in the ordinary driver, independently from the conformance runner's explicit flags. The Function family tests dynamic construction, calls, binding, source representation, and legacy properties, providing a useful next investigation set.

### What worked
All affected regression gates are green. The expanded Function run completed without changed inputs or a dirty pinned suite.

### What didn't work
The Function baseline retains substantial failures, including caller-property restrictions and function-source representations. Constructor tests with a trailing parameter line comment currently throw SyntaxError. No exclusions were added to hide these results.

### What I learned
The runtime constructs dynamic functions without a newline between parameter text and the closing parenthesis. A trailing line comment can therefore consume generated syntax. Separately, source-unavailable functions currently synthesize `[bytecode]` text rather than a standard NativeFunction representation. Those are separate changes with different compatibility and validation scope.

### What was tricky to build
Changing semantics requires migrating obsolete rejection tests without weakening their replacements. The core now requires an actual runtime TypeError, and separate positive cases require catchability and acceptance of unexecuted invalid operations.

### What warrants a second pair of eyes
Review the test migration and the C-oracle qualification. Full conformance remains unproven; the new baseline demonstrates outstanding work.

### What should be done in the future
Correct dynamic-function source boundaries, then address source representation and the broader runtime gaps under explicit tests.

### Code review instructions
Read the original core failure in Step 6, the replacement fixture, and the raw-default tests before reviewing the green receipts. Function-family failures are in `implementation-evidence/function-baseline.json`.

### Technical details
Current release regression totals are 22 core contracts and 55 extension contracts. Function baseline counts are variants and must not be added to the source-contract totals as if they used the same unit.

## Step 8: Correct dynamic function boundaries and source-unavailable representations

The default error-timing milestone was committed as `3912ed6`. The expanded Function baseline then identified a focused pair of defects: parameter line comments consumed generated delimiters, and source-unavailable callables returned nonstandard `[bytecode]` text while inspecting public properties. The patch adds source boundaries and uses NativeFunction syntax without invoking name/length getters for these callables.

### Prompt Context
See Step 1. This step follows the measured Function-family failures rather than expanding the skip list.

### What I did
- Inserted line breaks before the generated closing parameter delimiter and before body text in `createDynamicFunction`.
- Preserved explicitly retained source, but returned standard anonymous NativeFunction syntax for other non-builtin callables, including compiled JS, bound functions, and callable proxies.
- Removed synthesized parameter enumeration and public name/length reads from that fallback. Existing native-builtin name handling remains separate.
- Added `function_source_boundaries.js` covering ordinary/bound/proxy/revoked-proxy introspection and normal/generator/async dynamic constructors with line comments.
- Updated the affected function-constructor snapshots in native and interpreter test sources.
- Confirmed the new fixture's expected outcome with Node; started focused and upstream toString tests.

### Why
ECMAScript Function.prototype.toString requires either available source text or NativeFunction syntax for callable objects. A synthesized `[bytecode]` body does not satisfy that grammar. Reading a public name/length property can invoke getters or proxy traps that the operation should not invoke. Parameter comments also require delimiters on a fresh line.

### What worked
The independent script oracle prints `function-source-boundaries-ok`. Validation of the shared-runtime implementation follows in the next checkpoint.

### What didn't work
No new execution failure is asserted before the focused run. The baseline failure modes are preserved in the prior Function receipt.

### What I learned
The fallback must use ordinary NativeFunction grammar even for async/generator callables. Their source-unavailable representation cannot be synthesized with an async or generator prefix and a bytecode marker.

### What was tricky to build
A callable proxy must not be unwrapped or queried; revoked callable proxies still need a string representation. Dynamic constructors remain unnamed function expressions internally, avoiding introduction of an unintended lexical `anonymous` binding merely to format output.

### What warrants a second pair of eyes
Review the source-availability policy and retained-source branch. Native builtin initial-name preservation is still a separate concern; this patch does not claim to fix every builtin property mutation.

### What should be done in the future
Compare the exact toString subset against the prior baseline, then run full affected regression gates. Address remaining builtin/caller and dynamic-scope failures independently.

### Code review instructions
Read `JSLibInternal.cpp` source assembly and `Function.cpp` source fallback together with the new fixture. The existing native builtin path is intentionally visible for further review.

### Technical details
Primary algorithm reference: https://tc39.es/ecma262/2026/multipage/fundamental-objects.html#sec-function.prototype.tostring . Source availability determines whether retained text is returned; fallback is `function () { [native code] }`.

### Step 8 focused failure and correction

The first focused fixture failed in C, all native LLVM combinations, and lli with `Uncaught Error: proxy get` at `get`, `toString`, and `call`. Source inspection showed that `JSCallableProxy` inherits `NativeFunction`; a generic NativeFunction class check therefore incorrectly selected the builtin name-reading branch. Added the runtime's non-observable `isProxyObject` check to select the anonymous fallback for callable proxies, including revoked proxies. This is a runtime class-hierarchy correction, not a relaxed test expectation. The affected native function-constructor lit snapshot passed before this correction.

### Step 8 validation outcome and limits

After the proxy correction, the focused fixture passes its C comparison, all four native LLVM optimization combinations, and real lli. The complete core gate passes 22/22 and the extension gate passes 56/56, with unchanged inputs. The pinned Function.prototype.toString selection completes with 154/160 passing variants, compared with 44/160 in the prior Function baseline. The six remaining failures cover builtin native syntax, symbol-named builtins, and a computed method-name case that depends on retained source text. No failing variant was excluded.

A repository-wide search found additional `[bytecode]` expectations in interpreter, debugger, and REPL snapshots. Updated their expected representations and the source-visibility explanation. Built the interpreter and debugger executables to attempt those checks. Five of eleven selected snapshots passed, including retained/hidden source visibility in function-toString.js, both TDZ iteration cases, the REPL, and the native constructor fixture. Four debugger snapshots cannot execute with this build: `hdb compiled without Hermes debugger enabled.` The initial vars-async-arrow invocation also lacked the FileCheckOrRegen substitution (`FileCheck-18: Too many positional arguments specified!`). These debugger expectations remain execution-unverified. Source inspection confirms hdb renders values through Value.toString.

The two remaining interpreter fixtures stop at inherited direct-eval boundaries: function-constructor.js reports `direct eval requires retained lexical scope metadata` and source-visibility/with-eval.js reports `sloppy direct string eval is unsupported; use a strict caller or indirect global eval`. Their eval calls were preserved; converting them to indirect eval simply to obtain a green test would change their contracts. The passing native and conformance tests do not establish interpreter eval support.

Commands: `python3 hermes/utils/test_shllvm.py --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin --jobs 3 --output /tmp/llvm-source-core.json`; the same build/tool arguments to `test_shllvm_extensions.py` with output `/tmp/llvm-source-extensions.json`; and `hermes-lit -v` with explicit hermes, shermes, hdb, FileCheck paths on the eleven changed snapshots. The detailed result receipt is `implementation-evidence/function-source-milestone.json`. The snapshot log digest is recorded there. These results qualify the changed native behavior, not complete ECMAScript conformance.
