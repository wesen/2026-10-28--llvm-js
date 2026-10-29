---
Title: Implementation diary
Ticket: LLVM-JIT-001
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
LastUpdated: 2026-10-29T09:32:29.071150559-04:00
WhatFor: ""
WhenToUse: ""
---

# Implementation diary

## Step 1: Establish the bounded design and implementation backlog

Created this ticket and its design in response to the user's practical compiler/JIT direction. The result is a source-grounded plan with acceptance contracts and explicit deferrals, not a new implementation or conformance claim.

### Prompt Context
**User prompt (verbatim):** "we don't need full conformance, but as far as is reasonable to avoid overcomplexification. Now create the two tickets and design docs. Also make a ticket that contains all the module follow up work so that we don't forget / take notes on what is missing and why, with design doc."

**Assistant interpretation:** Create the two engine/JIT tickets discussed previously and one consolidated module follow-up ticket. Avoid making full conformance, speculative optimization, or generalized infrastructure prerequisites.

### What I did
Read the docmgr workflow, inspected current emitter/runtime/frontend entry points, reviewed the completed module design and evidence, and wrote the design and task inventory. Consulted the LLVM 18 ORC documentation and installed LLJIT headers for the proposed integration. Related the primary source files through docmgr.

### Why
The project needs a bounded route to an in-process native engine while retaining known module gaps for later decisions. Ownership and supported-profile choices must precede implementation so the first JIT does not acquire unnecessary unloading, tiering, or loader complexity.

### What worked
The current jit command invokes an external lli process. generateLLVM accepts Hermes IR rather than JavaScript source, so integrating LLJIT and extracting a source frontend are distinct deliverables. Installed LLVM 18 LLJIT headers confirm the intended addIRModule and lookup interfaces.

### What didn't work
Two initial source guesses were incorrect: `hermes/lib/BCGen/SH/LLVMNative/CMakeLists.txt` and `hermes/lib/BCGen/SH/LLVM.cpp` do not exist. Located the actual parent CMakeLists.txt and LLVMNative/LLVMBackend.cpp before grounding the design. No runtime implementation or new execution test was attempted in this documentation task.

### What I learned
Persistent execution requires a separation between unit initialization and runtime lifetime. Dynamic source compilation, ESM graph loading, and native code materialization are separate operations and should have separate acceptance claims.

### What was tricky to build
The design must preserve the existing runtime's persistent unit contract and distinguish currently available APIs from proposed ones. Proposed engine classes and methods are labeled explicitly. The module inventory records deferred decisions rather than silently expanding the release requirements.

### What warrants a second pair of eyes
Review runtime-before-code teardown, exception rooting, target/ABI validation, frontend process-global state, and the distinction between module entry completion and initializer completion. Validate exact LLVM API usage against installed headers at implementation time.

### What should be done in the future
Execute this ticket's open tasks in dependency order. Keep the first runtime single-thread-owned and retain code until engine destruction. Implement additional language behavior only when it fits the chosen practical profile or fixes admitted-program correctness.

### Code review instructions
Read the design's current-state section and proposed contracts, then the RelatedFiles. Check that tasks are still open and that the ticket does not claim its proposed interfaces already exist. Run docmgr doctor for this ticket after edits.

### Technical details
Source checkpoint: 8db50e0; module implementation: 185923d. Initial target: Linux x86-64 host64 with installed LLVM 18. References are local source plus https://releases.llvm.org/18.1.8/docs/ORCv2.html; the documentation version is not an assertion about the installed toolchain's patch version.

## Step 2: Implement the persistent engine and request-scoped frontend

Architecture checkpoint 5932980 established the shared-runtime linkage and teardown ordering. Implemented the first engine, frontend, runtime bridge, and lifecycle tests; the shared runtime is rebuilding and execution qualification has not yet run.

### Prompt Context
See LLVM-ENGINE-001 diary Step 2 for the verbatim implementation request. This continues the explicitly requested LLVM-JIT-001 work after architecture validation.

### What I did
Added Engine.h, Engine.cpp, Frontend.cpp, JITHost.cpp, a small shllvm-jit CLI, and lifecycle/module qualification harnesses. Replaced the eight-slot native unit table with growable storage and updated strong/weak root traversal, destruction, accounting, and bridge bounds checks. Added opt-in module bundle completion notifications without changing default module output.

### Why
A persistent JIT must execute multiple source submissions within one runtime, preserve escaped code through exceptions and GC, and distinguish pending module evaluation from completed unit initialization. Reusing the existing textual IR emitter and request-scoped compiler objects avoids mixing llvh and LLVM IR representations or resetting global command-line options.

### What worked
The earlier two-unit probe passed. The existing eight module-compiler unit tests still pass after adding opt-in host completion. Installed LLJIT APIs support context ownership, resource trackers, and symbol lookup as required.

### What didn't work
find_package(LLVM 18 REQUIRED CONFIG) rejected the installed 18.1.3 package under its version compatibility policy. Removing the version request then exposed target-name collisions: FileCheck, count, and not were already defined by bundled llvh. Replaced package target import with llvm-config-18 discovery of the installed headers and shared library, with an explicit major-version check. These are build integration corrections, not compatibility adapters.

### What I learned
The existing process-global unit identity counter and fixed eight-entry table make repeated engine sessions fail even if each session is small. Growing each runtime table preserves established identities and collector traversal; it also preserves a process-global high-water memory cost that must be documented and measured.

### What was tricky to build
Exceptions from initialized units cannot trigger code unloading because the initializer may have published a closure. Engine state marks execution attempted before invoking guarded initialization and retains all initialized code until runtime destruction. Module completion uses host callbacks and per-entry tokens, not stdout parsing.

### What warrants a second pair of eyes
Review dynamic unit-table root iteration, context lifetimes, linked runtime symbol resolution, and exception-root ownership. Host completion callbacks are a trusted internal protocol, not a security boundary against source tampering.

### What should be done in the future
Finish the build, run lifecycle and module gates, fix observed failures, then qualify ordinary AOT/native regressions and record measured compile latency and retained memory.

### Code review instructions
Start at Engine::create/loadIR/execute/close, then Frontend.cpp, JITHost.cpp, and StaticHUnit.cpp. Test code is in test/LLVMJIT/engine.cpp and utils/test_shllvm_jit.py.

### Technical details
Build: cmake -S hermes -B hermes/build-llvm -DHERMES_BUILD_LLVM_JIT=ON, then targets shllvm-jit and shllvm-jit-test. Runtime/console use one shared VM; compilation links hermescompiler and system LLVM 18.1.3. No LLVM JIT or frontend subprocess is used by the new source API.

## Step 3: Qualify persistent native source execution

Both JIT checkpoints now work: creator-only IR materializes inside the host, and source requests compile through fresh Hermes frontend contexts without shermes or lli subprocesses. The expanded gate passes 48/48 with unchanged fingerprinted inputs; existing core and extension gates pass 22/22 and 66/66.

### Prompt Context
See Step 2 and the LLVM-ENGINE-001 implementation request. The practical profile remains bounded and does not require full language conformance.

### What I did
Completed the build, ran lifecycle checks with more than eight units per engine, repeated/simultaneous engines, GC, throwing initializers, invalid IR/target/layout/creator, duplicate creators, missing symbols, and owner-thread enforcement. Executed fourteen module graphs and eight language-extension sources at both frontend optimization settings. Added pending/fulfilled/rejected entry checks and a bounded measurement/execve probe.

### Why
A working LLVM lookup is insufficient: native closures must survive return to the host, collection, and later compilation. Error recovery and retained code after a throwing initializer are central lifecycle requirements. The optional module callback protocol prevents unresolved top-level await from becoming a successful completion result.

### What worked
The 48-case JIT gate passes with unchanged inputs. The existing native core gate passes 22/22; extensions pass 66/66 with unchanged inputs. The source API executes bigint, private fields, RegExp, typed arrays, lexical eval, async functions, async generators, and generators through focused existing fixtures. Link inspection shows one libhermesvm shared library. The execve trace records only the host executable, with no compiler or lli child execution. A separate configuration succeeds with HERMES_BUILD_LLVM_JIT=OFF and an intentionally missing SHLLVM_CONFIG, confirming optional LLVM discovery.

### What didn't work
The runtime host initially used an ambiguous hermes namespace because facebook::hermes is also in scope; qualified ::hermes::vm. The frontend Context constructor requires moved code-generation settings; corrected the request-local call. Linking initially failed with undefined typeinfo for llvh::FoldingSetBase because the new target did not inherit Hermes's RTTI policy; applied hermes_update_cxx_flags. The first manual performance command repeated a fixture that intentionally asserts exactly one increment, and correctly threw on the second execution. Replaced it with a dedicated repeated-increment workload instead of weakening the assertion.

### What I learned
The baseline source compiler is fast enough to exercise repeated compilation in a small test process, but timing and RSS include compiler/runtime costs and do not establish a performance advantage. Fresh engine instances do not reset global native unit identities; table capacity still follows their high-water mark, which is explicitly retained as a practical limitation.

### What was tricky to build
The build had to preserve compiler no-RTTI settings while linking system LLVM and one shared runtime. Runtime-side exception reporting retains managed values within existing guarded/handle code. Initialized code is retained even when a source initializer throws after publishing a closure.

### What warrants a second pair of eyes
Review ownership and GC roots after growing the table; resource cleanup on materialization errors; helper lookup through the linked bridge dependency closure; and incomplete module status when console jobs are exhausted. The module callback names are a trusted protocol, not protected against arbitrary source tampering.

### What should be done in the future
Finish operational documentation and archive the receipts, then close the bounded implementation ticket. Defer index recycling, general module registry extension, arbitrary dynamic loading, native eval replacement, and speculative tiers unless a workload justifies them.

### Code review instructions
Run shllvm-jit-test and utils/test_shllvm_jit.py. Review the initial/final gate receipts, the measurement script, and the optional-off configuration receipt. All admitted module tests retain their prior two specification-directed Node qualifications.

### Technical details
Installed LLVM 18.1.3; Linux x86-64 host64. -O changes the Hermes frontend optimization profile; LLJIT uses its default native code-generation configuration. This build is not sanitizer-enabled. The optional-off check is a configuration check; the ordinary native gates run against the rebuilt enabled configuration.

## Step 4: Publish the operational contract and final qualification

Implementation checkpoint **999c830** is qualified. Added an explicit collection immediately after unit-table growth and reran the 48-contract gate: all pass with unchanged recorded inputs. Archived the final receipt, initial 32-contract checkpoint, existing core/extension receipts, optional-off configuration, illustrative measurements, and receipt hashes. Added `hermes/docs/llvm/JIT.md` and linked it from the existing driver/module guides.

### Prompt Context
See Step 2. This is the documentation and qualification completion of the requested bounded engine and JIT work.

### What I did
Documented build commands, the private source/IR API, source versus LLVM optimization settings, owner-thread use, exception reporting, growable root storage, code lifetime, trusted module notifications, and remaining limits. Verified the CLI creator-only IR mode and recorded the partial M01 module-backlog improvement without closing unrelated module work.

### Why
Users need a reproducible entry point and a precise distinction between the new source JIT and the existing external lli driver. Explicit limits prevent the completed milestone from being mistaken for full conformance, an incremental ESM loader, or an unbounded long-running compilation service.

### What worked
Final JIT qualification: 48/48. Core: 22/22. Extensions: 66/66. Module compiler unit tests: 8/8. The execution trace contains one execve for the host and no compiler/lli subprocess. Repeated-increment smoke runs report median compile/materialize times of about 4.23 ms (one increment), 2.69 ms (20), and 2.63 ms (100), with final process peak RSS of 66,772, 67,200, and 68,436 KiB respectively. These measurements include compiler/runtime state and are not a performance comparison or leak proof.

### What didn't work
No new failures occurred during final documentation qualification. Sanitizer instrumentation was not enabled, and optional-off verification was configuration-only; neither is represented as a completed runtime test. The historical broad Test262 inventory was not rerun.

### What I learned
Source compilation can remain a small request-scoped operation while the managed runtime and native code persist. The bounded design has useful explicit limits: compilation-unit globals communicate through the runtime, independently bundled module graphs do not merge, and code lives until engine destruction.

### What was tricky to build
The final evidence must distinguish entry completion from initializer completion and distinguish the native unit-count table from the unrelated 1,024 root/argument-slot admission limit. Documentation preserves both distinctions.

### What warrants a second pair of eyes
Review lifecycle invariants before embedding in a long-running service, especially global unit-index high-water storage, pending work at explicit close, and the private completion protocol's trusted-code assumption.

### What should be done in the future
Use the engine on a representative application before expanding its profile. Keep LLVM-MODULES-002 open for remaining module dispositions. Index recycling, richer host value handles, native dynamic eval, package loading, and speculative tiers are deferred.

### Code review instructions
Read JIT.md, the implementation commit, test/LLVMJIT/engine.cpp, and reference/evidence/final-48-contracts.json. Verify receipt-hashes.json against archived bytes. No generated binaries or node_modules are committed.

### Technical details
Engine architecture commit: 5932980. Implementation commit: 999c830. The final checkpoint adds documentation/evidence and the explicit post-growth GC assertion. Source compilation uses the existing Hermes backend and system LLVM 18.1.3 in one process; dynamic eval still uses the existing bytecode path.
