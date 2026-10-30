---
Title: Import and investigation diary
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
LastUpdated: 2026-10-29T20:26:47.626728688-04:00
WhatFor: ""
WhenToUse: ""
---

# Import and investigation diary

## Step 1: Import the returned Strata workspace and locate the porting plan

Imported the complete archive into STRATA-PORT-001 and inspected the primary guide, supporting porting chapters, session records, workbench source, and representative bridge definitions in our existing fork. The archive contains a substantial workbench, while real Hermes/LLVM execution remains proposed.

### Prompt Context
**User prompt (verbatim):** "ok, now look at ~/Downloads/strata-workspace-full.zip, and import it into a new docmgr ticket, and check if you find the documents on how to port strata against hermes and llvm. Then report back to me abut wha tyou found"

### What I did
Created the ticket, preserved the ZIP, extracted all 1,083 regular files, recorded hashes, imported the main guide as a searchable docmgr reference, and wrote the findings analysis. Inspected helper signatures, source paths, link flags, content counts, and proposed-file presence without executing imported code.

### Why
The user needs to know whether the returned work contains an actionable porting plan and what is implemented versus prospective. A byte-preserving import keeps the supplied material distinct from local assessments.

### What worked
Found the exported intern guide and two relevant textbook chapters plus supporting backend documentation. Confirmed the later Strata-first direction through the reconstructed session summary, and found the older incremental-Hermes plan in Chapter 21. Verified representative ABI mismatch directly against runtime.h. ZIP CRC and per-file hash checks preserve import identity.

### What didn't work
The first broad archive listing exceeded the output limit; subsequent inspection used focused paths and bounded reads. An attempted read of `hermes/tools/shllvm-jit/CMakeLists.txt` failed because that file does not exist; the executable targets are defined in `hermes/tools/shermes/CMakeLists.txt`. No imported harness was run, so its historical totals are not local verification results.

### What I learned
The guide acknowledges illustrative helper bindings and describes the missing native files explicitly. It is a concrete implementation proposal, not an already working native compiler. Its simple link command omits build-dependent sanitizer flags that our driver supplies.

### What was tricky to build
Imported Markdown includes heterogeneous metadata and generated assets. Preserved raw bytes under archive/, excluded that subtree from docmgr scanning, and registered a separate frontmatter-bearing copy of the primary guide. Git retains the original archive and extraction script rather than duplicating generated site assets.

### What warrants a second pair of eyes
Review native root/argument lifetime, exceptional restoration, contract narrowing, and the guide's excessively strong checker-versus-runtime equivalence requirement. Reconcile the two migration strategies before planning implementation.

### What should be done in the future
Select the desired porting direction, audit ABI contracts against current source, and define a bounded first execution milestone. This turn does not authorize or perform the port.

### Code review instructions
Read the analysis first, then the imported guide sections 9–14 and Chapter 21 section 21.5. Inspect the import manifest and rerun scripts/01-import-workspace.py to reconstruct and verify the raw tree. Compare the illustrative constant declaration with runtime.h and the link command with utils/shllvm.py.

### Technical details
The receipt records ZIP and per-file SHA-256 identities. All archive paths were checked for absolute/traversal entries and symlinks before extraction. Native code, dependencies, browser services, and imported helper scripts were not executed. External research was unnecessary for locating and comparing these local artifacts.

## Step 2: Validate the import and ticket

The extraction script verified the original ZIP SHA-256, CRCs, file inventory, and all 1,083 extracted file hashes. `docmgr doctor --ticket STRATA-PORT-001 --stale-after 30` passed. No imported checks were executed. The full archive, registered guide, findings, manifest, and restoration script are the deliverables.

## Step 3: Select Strata-first ownership and execute the first native program

Revised the working port guide, authored the intern design guide, and started an independent native compiler in strata/. The first program, `let x=1; print(x+2);`, now compiles through Strata, assembles with LLVM 18, links against the existing Hermes bridge, and prints `3`. The Hermes frontend was not invoked.

### Prompt Context
**User prompt (verbatim):** "Ok, update guide, and then tackle the strata-first direction. Create  a detailed analysis / design / implementation guide that is for a new intern, explaining all the parts of the system needed to understand what it is, with prose paragraphs and bullet point sand pseudocode and diagrams and api references and file references. It should be very clear and technical. Store in the ticket and the nupload to remarkable.\n\n\nThe analysis is detailed, but the implementation should be straightfoward, to the point, effective, forward-looking.\n\nThen implement, commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"

**User addition (verbatim):** "also, import the docs and strata source as source/ in the ticket as well, for reference"

### What I did
Moved the byte-preserved extracted reference tree to ticket/source and updated reconstruction paths. Copied core/frontend and licensed Acorn into a working strata/ tree. Added a deterministic engine assembler, a frontend entry point, a bridge-header signature reader, and a native LLVM emitter with real unit metadata. Corrected the registered guide's oracle, JIT, sanitizer, package-manager, stress-test and contract claims. Wrote the detailed native design and initiated its requested reMarkable upload.

### Why
The selected direction needs Strata to own translation. Calling the existing Hermes compiler would not exercise that architecture. Exact ABI declarations and registered homes give a small verifiable starting point. Completion records initially use managed environments rather than adding a graph-wide pair-rewriting pass before execution works.

### What worked
`llvm-as-18 /tmp/strata-first.ll -o /tmp/strata-first.bc` succeeded. Linking with clang-18 and the existing plain runtime build succeeded; `/tmp/strata-first` printed `3`. The frame used 11 registered homes and one outgoing argument slot. The ABI header SHA-256 is recorded by emission. Source reference material remains unchanged.

### What didn't work
No native failure occurred in this first scalar probe. Closures, exceptions, jobs and root reuse are not validated by this result. The existing build has AddressSanitizer and UndefinedBehaviorSanitizer disabled; this probe makes no sanitizer claim.

### What I learned
The imported IR is directly accessible after its frontend and cell-promotion pass, so native emission can bypass the illustrative LLVM printer without changing the educational pipeline. The live runtime accepts independently emitted unit data using the documented ASCII/UTF-16/hash layout.

### What was tricky to build
The native helper call builder validates argument count and derives LLVM types from actual prototypes. Function bodies are emitted before prologues so literal and temporary root counts are known. Captured parameters must be rooted before string materialization can collect. Handler state needs volatile storage and restored runtime frame state after longjmp.

### What warrants a second pair of eyes
Review signature extraction, unit string hashing, helper operand/output aliasing, closure environment mapping, longjmp state restoration, and full-lifetime interference before enabling root reuse.

### What should be done in the future
Build the CLI and differential corpus; validate the complete initial subset, then add checked root reuse and stress evidence. Future language expansion and speculative optimization remain outside the first native milestone.

### Code review instructions
Start with native/abi.js and native/emitter.js, compare runtime.h and ModuleEmitter in LLVMBackend.cpp, then inspect native/frontend.js. Reproduce the scalar probe through the forthcoming CLI.

### Technical details
No runtime bridge changes were needed. The baseline runtime is hermes/build-llvm on Linux x86-64; generated callbacks return tagged i64 and take the runtime pointer. Native homes include all SSA values and constants rather than relying on unproven type narrowing.

### Step 3 follow-up evidence
The CLI scalar fixture also passed at LLVM O2, printing `3`, `hello 世界`, and `NaN Infinity -Infinity`. Its initial sandboxed invocation failed with `spawnSync /usr/lib/llvm-18/bin/llvm-as EPERM`; the same driver succeeded with tool-execution escalation. This was an execution-permission failure, not malformed LLVM. The requested guide upload completed; see reference/03-native-guide-delivery.txt.

## Step 4: Validate the initial native subset

The first differential corpus passed 12/12 executions: six fixtures at LLVM O0 and O2. These cover arithmetic and UTF-16 strings, loops and merges, recursive and mutable closures, captured loop bindings, getters/setters and standard-library method calls, thrown object identity, nested handlers, finally return/throw behavior, promises, microtasks and timers.

### Prompt Context
See Step 3 for the authorized implementation request and source-reference addition.

### What I did
Added the native CLI with explicit build/tool options, LLVM assembly and verification, sanitizer-aware linking, temporary output publication and manifests. Added a Node differential runner and six semantic fixtures. Retained results in reference/evidence/first-native-subset.json.

### Why
Each fixture crosses a distinct native/runtime boundary. O2 checks are necessary because longjmp and volatile state can behave differently under optimization. CLI verification ensures actual LLVM tools accept the module, rather than relying on the workbench's textual checker.

### What worked
`node strata/test/native.test.js` reported 12/12 passing comparisons. No runtime changes were needed. All callbacks and functions came from Strata IR. No ASan instrumentation or aggressive moving-GC configuration is claimed by this run.

### What didn't work
The root policy is still distinct homes and is not yet sufficient for large functions. The original imported tool harness has not been rerun; this evidence covers the new native path.

### What I learned
Managed environments provide a direct initial implementation for cells, closure captures and internal completion records. The existing host loop executes queued Strata native callbacks without an extra scheduling layer.

### What was tricky to build
Call arguments are copied into the outgoing buffer immediately before the bridge copies them into managed stack slots. The catch path restores runtime frames before loading the thrown value. Simultaneous block transfers first read all sources and then write destinations.

### What warrants a second pair of eyes
Audit frontend subset semantics, uninitialized cells, nested finally behavior and escaped closure lifetimes beyond this small corpus. Root reuse must preserve noncollecting live ranges as well as safepoints.

### What should be done in the future
Add root reuse and larger imported fixtures, explicit collection tests, unsupported-source contracts, and a final profile audit.

### Code review instructions
Review strata/native, tools/strata-native.js and test/native.test.js. Run the differential runner; results and emitted modules are stored under /tmp/strata-native-tests by default.

### Technical details
Native compilation reads sanitizer configuration from the selected CMake cache. The current cache enables neither sanitizer. Every fixture compiles with the Strata frontend and cell promotion, with no speculative rewriting or type-based root omission.

## Step 5: Root reuse, imported applications and frontend corrections

Added full-lifetime root interference and a separate assignment checker. The expanded ledger/J corpus passed 68/68 checks with both distinct and reused storage at O0/O2, including expected-error J-07. A generated 1,200-value function was rejected with distinct storage but executed with 12 roots plus one argument slot under reuse, printing 1200. Subsequent receiver/profile review exposed a new strictness-metadata bug, recorded below and corrected before final validation.

### Prompt Context
See Step 3.

### What I did
Added native/roots.js, root-assignment negative checks, a wide-function probe, eight unchanged J fixtures and the ledger. Corrected method lookup to precede argument evaluation, separated EMPTY from legitimate undefined in TDZ storage, rejected unsupported async/generator declarations and direct eval, and added strict/sloppy receiver and global-typeof handling. Added explicit collection fixtures and configured a separate ASan plus handle-sanitizing runtime build.

### Why
Safepoint-only coloring cannot safely assign permanent homes: noncollecting lifetimes and helper output writes also conflict. The differential corpus needs to classify intentional errors separately. Frontend shortcuts become externally visible once the model runs against the real JavaScript runtime.

### What worked
The imported ledger and eight J programs passed the 68-case campaign, including the original uncaught error in J-07. The root checker rejects an intentionally colliding assignment. Wide execution prints 1200 with two SSA value slots and ten fixed/literal/global homes. The existing runtime bridge remained unchanged.

### What didn't work
The first imported runner aborted at J-07 with `AssertionError ... Error: missing field price` because it assumed every fixture exits successfully. Updated it to require the expected error message and failure exit while preserving preceding stdout. Source review found the initial TDZ mask would reject legitimate undefined; changed uninitialized cells to SHLLVM_EMPTY and check mask 1, with a regression.

After adding strict writes, the next campaign reported 36/72 passed and repeated `Cannot read properties of undefined (reading 'strict')`. Assignment targets are not all present in the frontend's scope map. Strictness is a function-level property here, so emission now reads `this.fn.meta.strict` rather than assuming every target has scope metadata. The failed receipt is retained. Final results must come from the corrected campaign, not this checkpoint.

The first stress build target built only the static bridge, not its managed-runtime dependencies. Started explicit hermesvm and shermes_console targets in tmux. No stress result is claimed until those libraries finish and programs execute.

### What I learned
The runtime's SHLLVM_UNINIT maps to undefined for particular inherited lowering conventions; Strata requires an unambiguous EMPTY sentinel for its cell model. Source metadata ownership is easier to maintain on the function than on every assignment AST node.

### What was tricky to build
The allocator handles parallel block transfers, function/block parameter writes, exceptional live values and result/operand conflicts. Constants and scratch homes remain separate. Handler liveness is conservatively included for every operation rather than relying on the imported effect annotations to exclude throws.

### What warrants a second pair of eyes
Review root interference around exceptional edges, source binding/receiver semantics, intentional library/subset boundaries, and whether stress negative controls actually force a relevant collection. The assignment checker checks allocation against recomputed requirements; it is not an independent proof that the liveness equations model every runtime obligation.

### What should be done in the future
Finish corrected native/stress validation, record configuration identities, complete CLI boundary and publication checks, and document the admitted profile precisely.

### Code review instructions
Inspect native/roots.js, frontend changes, and the new fixture sources. Run roots.test.js and boundaries.test.js, then native.test.js with the plain and stress runtime builds. Read the failed and successful receipts separately.

### Technical details
The stress build uses clang-18, Release O1 runtime compilation, HERMESVM_SANITIZE_HANDLES=ON and HERMES_ENABLE_ADDRESS_SANITIZER=ON. The normal build remains unchanged. The native test runner supports explicit build directories and a stress mode that passes -gc-sanitize-handles=1.

## Step 6: Complete native qualification and GC negative control

The final frozen compiler passed 76/76 checks on the normal runtime and 76/76 on a separately built ASan and handle-sanitizing runtime. Each matrix has 72 normal executions and four expected uncaught-error checks. All 152 build receipts have identical compiler-input fingerprints; delivered fixture hashes match their inputs. The first compiler milestone was committed as `62ee096`.

### Prompt Context
See Step 3 for the implementation and reference-source requests.

### What I did
Finished the supported-profile review, added receiver and explicit-collection cases, added rejection contracts for missing frontend behavior, and improved output publication/identity records. Made engine assembly publish via process-specific temporary files and rename so independent compiler processes cannot read partially generated modules. Ran the final plain and stress matrices in separate output directories. Recorded compressed receipts, a qualification summary, and the exact GC-negative diagnostic. Added run/build instructions and the implemented status to the guide.

### Why
A useful native compiler must demonstrate actual machine-code execution and collection safety for its admitted profile. Documentation must separate source limitations, expected language errors, and unsafe-root detection rather than combining them into a single success count. Fingerprints establish which code and runtime produced these results.

### What worked
- `node strata/test/native.test.js /tmp/strata-final-normal`: 76/76 passed.
- `node strata/test/native.test.js /tmp/strata-final-stress hermes/build-strata-gcstress stress`: 76/76 passed, passing `-gc-sanitize-handles=1` to every executable.
- `node strata/test/boundaries.test.js`: eight unsupported-context contracts and one parse-error contract passed.
- `node strata/test/roots.test.js`: corrupt allocation rejected, distinct wide-function admission rejected, reuse assigned two SSA homes and 12 total roots.
- `/tmp/strata-wide`: printed 1200 at LLVM O2.
- `node strata/test/driver.test.js`: failed compilation preserved five existing artifacts; source/output collision and invalid optimization were rejected; identity metadata was present.
- `node strata/test/gc-negative.test.js`: valid control printed 42; root-hidden mutation failed with an AddressSanitizer invalid read.
- Import verification still matched all 1,083 reference files.

### What didn't work
An early description called the GC-negative report a heap-use-after-free before inspecting its exact category. Corrected immediately: the actual report is `AddressSanitizer: SEGV on unknown address ...`, a read in `JSObject::defineOwnPropertyInternal`. The retained stderr is authoritative. The guide and final report use the actual category.

The first stress pass overlapped formatting of the CLI; no semantics changed, but those input identities were not treated as final. Repeated the qualification after source changes stopped, then verified fingerprint equality across both final matrices. No leak-check disabling was necessary in the successful stress run.

### What I learned
The existing bridge can execute independent Strata output under aggressive handle sanitization without changes to Hermes source. Root reuse substantially reduces a sequential program's frame, but constants and genuinely overlapping values remain bounded. Named function-expression self identity and implicit arguments need deliberate lowering, so the native profile rejects them rather than inheriting incorrect model behavior.

### What was tricky to build
The native compiler now separates frontend semantics, root allocation, ABI calls, and tool orchestration. This prevents the educational LLVM printer or unproven type facts from silently governing native memory safety. Manifests hash runtime shared libraries as well as the bridge, since hashing only the static bridge would miss a changed collector.

### What warrants a second pair of eyes
Review the remaining array-only iteration and fixed host-global assumptions before expanding the profile. Inspect root liveness equations and exceptional transfers independently of the passing corpus. The GC-negative mutation establishes detector activity for this concrete program, not universal detection completeness.

### What should be done in the future
Expand source constructs and iterator semantics based on real application failures, reduce constant-root pressure if measurements justify it, and decide whether to integrate Strata-generated units into the existing in-process JIT. ABI version negotiation, a replacement runtime/collector, and speculative tiers remain separate future work.

### Code review instructions
Read strata/README.md and guide section 13; inspect native/roots.js and emitter.js, then the frontend diffs. The final receipts are reference/evidence/final-native-normal.json.gz and final-native-stress.json.gz, summarized by native-qualification-summary.json. Run scripts/02-collect-native-evidence.py after reproducing the recorded output directories to verify identities.

### Technical details
Both root policies and LLVM O0/O2 are covered. The stress runtime uses HERMESVM_SANITIZE_HANDLES=ON, HERMES_ENABLE_ADDRESS_SANITIZER=ON, and runtime probability one. The runtime is ASan-instrumented; complete instrumentation of generated LLVM bodies is not asserted. Current root storage remains native-stack based under the 1,024 combined-slot bound. No runtime/frontend Hermes source changes were needed.

### Delivery and reference preservation
The validated guide uploaded successfully as `STRATA-PORT-001 Strata First Native Compiler Validated Guide.pdf` under `/ai/2026/10/29/STRATA-PORT-001`; the upload receipt is retained in reference/03-native-guide-delivery.txt. Imported implementation, authored documentation, source examples, and build tools are tracked verbatim under source/. Generated websites and remaining assets remain reconstructable from the preserved ZIP. This keeps the requested reference material directly readable in Git while retaining the complete original release.
