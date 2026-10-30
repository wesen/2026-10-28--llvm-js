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
