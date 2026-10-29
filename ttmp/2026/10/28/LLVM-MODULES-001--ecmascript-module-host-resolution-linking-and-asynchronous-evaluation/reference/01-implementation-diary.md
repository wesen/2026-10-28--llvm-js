---
Title: Implementation diary
Ticket: LLVM-MODULES-001
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
LastUpdated: 2026-10-28T21:47:56.366696322-04:00
WhatFor: ""
WhenToUse: ""
---

# Implementation diary

## Step 1: Publish the prior milestone report and design the module lifecycle

Published a new 3,355-word textbook-style project report in the go-go-parc vault and pushed commit 4ec9372. Created LLVM-MODULES-001 and designed a separate source-text module path after confirming that inherited Hermes CommonJS lowering copies import values and cannot implement live bindings.

### Prompt Context
**User prompt (verbatim):**
> write a detailed project report for the obsidian vault as a deep dive technical analysis blog post using a textbook writing style (no analogies, see skill).
> Commit and push the bsidian vault when done (go-go-parc vault).
>
> Then, creat a new docmgr ticket and create a design doc for:
>
> ---
>
> |  |  |
> |---|---|
> | Modules | Implement and test the module host: resolution, linking, live bindings, cycles, dynamic import, and top-level await. |
>
> Then, implement and commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)

**Assistant interpretation:** Complete the report publication first, then design and implement a module host with measured semantics and explicit host policies.

### What I did
Read the vault-writing, textbook, docmgr, diary and commit skills. Reviewed current driver, eval source, conformance runner, and CommonJS import/export lowering. Consulted the pinned ECMAScript module algorithms and Babel parser documentation. Created the design with lexical generator factories, binding-aware imports, explicit graph linking, namespace behavior, and DFS asynchronous evaluation.

### Why
Modules need persistent lexical bindings and distinct linking/evaluation phases. Reusing the current require/exports lowering would preserve neither live imports nor cyclic initialization semantics. The proposed host compiles its own JavaScript and module bodies to LLVM without executing user modules in Node.

### What worked
Vault push succeeded: 544da12..4ec9372 main -> main. Only the new report was staged; unrelated dropcut-studio changes remain untouched. Existing generators and Promise runtime provide the required suspension and job mechanisms.

### What didn't work
No implementation tests have run yet. Babel packages are not installed in this repo, so the new build-time compiler needs explicit pinned dependencies. Existing CommonJS lowering is not a conforming ESM implementation.

### What I learned
An instantiation suspension can preserve var/function initialization and lexical TDZ using existing generator environments. Async cycles require cycle-root and pending-dependency state; a recursive Promise.all loader is insufficient.

### What was tricky to build
The design must keep deferred dynamic modules from executing or failing unrelated entries during build-time graph discovery. Binding rewriting must distinguish shadowed locals and preserve undefined call receivers.

### What warrants a second pair of eyes
Review source transformation boundaries, direct eval restrictions, namespace Proxy invariants, and the asynchronous cycle algorithm against the specification.

### What should be done in the future
Implement the compiler and host, then validate independent graph fixtures and integrate the explicit driver mode. Track any admission boundaries as tests rather than silently changing module semantics.

### Code review instructions
Read the design before code. Compare genImportDeclaration in ESTreeIRGen-stmt.cpp with the proposed cell-based imports. Review the source record and lifecycle state definitions first when implementation lands.

### Technical details
Vault note: Projects/2026/10/28/PROJ - Direct LLVM JavaScript - Conformance Baseline and Dynamic Evaluation.md. Prior runtime commit fb560e2; repository checkpoint 04777c3. The new module host uses a closed filesystem graph with explicit inclusion for computed dynamic imports.

## Step 2: Implement graph compilation, lexical linking, and evaluation

Implemented a pinned Babel-based build compiler and a JavaScript host that itself compiles through LLVM. The first ten graph contracts pass under Node ESM, optimized native execution, and real lli. Added explicit driver mode, graph hashes, and input overwrite protection. This is an initial integration checkpoint; the full optimization matrix and expanded cases follow.

### Prompt Context
See Step 1. The module areas requested by the user determine the implementation and test scope.

### What I did
Added module-host/compiler.cjs and runtime.js, pinned Babel 7.28.5 dependencies and lock, and --module/--module-root/--module-include driver flags. Implemented lexical generator instantiation, export resolution and star ambiguity, live namespace accessors, runtime import assignment errors, DFS cycle roots, async dependency scheduling, dynamic imports and import.meta. Added ten multi-file oracle fixtures and test_shllvm_modules.py.

### Why
The module's generator frame supplies actual lexical storage across instantiation and evaluation. The host tracks lifecycle state separately from source execution. Binding-aware transformations preserve shadowing and imported call receivers; copying values would not.

### What worked
The first live-binding program printed live-ok in generated Node execution and native LLVM at both O and O0. The ten-graph quick gate passes all cases under Node ESM, native O/O2, and lli O/O2, with unchanged fingerprints. Cases cover cycles, async diamonds/cycles, dynamic identity, cached failures, namespaces, reexports, default names, import assignment, and meta/context.

### What didn't work
The first gate was 7/8. Its error fixture incorrectly required repeated parse errors to be the same object. Node failed with `Error: cached error: ./syntax.mjs`; linking and evaluation errors did preserve identity. Corrected only the parse-error expectation. Source review also found that marking every partially linked dependency failed would poison valid modules, so linking rollback now resets unfinished dependency environments and caches the importing root's failure. Added a valid-dependency-after-failure assertion.

### What I learned
Imported binding assignment is a runtime TypeError, not an early syntax rejection. The initial design stated otherwise and has been corrected. A generated accessor reference preserves RHS effects and read-before-write behavior for compound/update operations. Anonymous default function/class/arrow exports also need the externally observable default name preserved.

### What was tricky to build
Import assignment targets include destructuring and loop targets, while referenced identifiers include normal calls. They require distinct lowering. Namespace descriptor values change while their non-configurable keys remain stable; the Proxy target uses writable data descriptors so live values satisfy invariants.

### What warrants a second pair of eyes
Review DFS async parent bookkeeping, link rollback, default function initialization, and the generated wrapper's top-level this/arguments handling. Review filesystem identity and artifact protection before expanding loader policies.

### What should be done in the future
Implement top-level for-await cleanup, expand scheduling/error/order tests, test computed-only inclusion and resolver aliases, add build-tool safety tests, and run the complete optimization matrix and unchanged script gates. Integrate a selected Test262 module experiment without rewriting historical results.

### Code review instructions
Start at compileGraph, then runtime link/exportCell/inner/fulfilled. Follow generated factory code for the live and import-writes fixtures. The initial gate receipt is reference/evidence/initial-ten-graphs.json.

### Technical details
Build-only dependencies are installed with pnpm --dir hermes/utils/module-host install --ignore-scripts. node_modules is ignored. Runtime modules do not execute in Node; the generated host and factories pass through the existing shermes/LLVM pipeline. Direct eval, import attributes/options, and top-level for-await currently have explicit host boundaries.

## Step 3: Expand to for-await and measure the pinned module-code selection

The eleven-graph matrix passed at all four native optimization combinations and real lli. The first full module-code selection completed with 564 passes, 24 semantic failures, and 14 unsupported records across 602 variants, with unchanged inputs. Its failure evidence exposed both host corrections and shared-runtime defects; repairs are now being built and are not yet qualified.

### Prompt Context
See Step 1. The implementation continues across all requested module lifecycle areas rather than stopping at the first passing graph.

### What I did
Implemented top-level for-await lowering with async-from-sync iteration, iterator closing, exception precedence, labels and per-iteration bindings. Added explicit --modules mode to the pinned Test262 runner, including module completion markers and separate parser/link validation attribution. Preserved initial Test262 and matrix reports. Added compiler tests for deterministic graphs, deferred errors, identity, boundaries and hardlink output protection.

### Why
A module implementation must preserve control transfers through suspended loops and distinguish completed evaluation from a process that exits while a Promise remains pending. Syntax and linking expectations also need correct phase attribution for imported source failures.

### What worked
The split for-await graph passes Node, native and lli. Eight build-tool tests pass. The initial full graph matrix passes 11/11 with 44 native and 11 lli executions. The pinned module-code experiment records 564/602 passes; its source phase, runtime phase and host boundary categories remain separate.

### What didn't work
The first for-await probe retained stale AST nodes and failed compilation with `error: '(' expected after 'for'`. Moving declarations into their final AST before binding traversal fixed it. The combined six-loop probe then exceeded the existing 1024 combined root/argument-slot limit even at O. Preserved that source as scripts/01-oversized-for-await-probe.mjs and split independent contracts into distinct module frames. The root-slot limit is unchanged.

The pinned suite found three namespace-alias failures, two default class-name failures, dependency parse phase mismatches, a Proxy freeze defect, and runtime error classification gaps. Object.freeze incorrectly changed the Proxy object's HiddenClass without invoking its target/traps. The pending repair invokes actual internal methods for seal/freeze and integrity queries. Async errors also lacked the guarded exception marker; the event loop now has an explicit Test262 reporting flag, with all C/LLVM callers updated.

The first build of an internal module Promise reaction builtin failed with `no member named 'moduleThen' in namespace 'hermes::vm::Predefined'`. Added the matching predefined string and restarted the build. This was an incomplete registration, not a runtime success.

### What I learned
Namespace reexports must share one cell per target namespace, or equal exports appear spuriously ambiguous. Default class naming must respect an existing static name property. Errors parsing dependencies are externally resolution failures, while an entry parse error remains a parse failure. Module jobs need internal Promise reactions rather than public then/species behavior.

### What was tricky to build
For-await closure and cleanup rules require precise placement of the close-needed flag: a failing next operation must not close, while a body abrupt completion must. A thrown body completion takes precedence over a closing error. Module completion signaling must not turn an unresolved TLA into a false pass.

### What warrants a second pair of eyes
Review the new Promise builtin registration, shared Proxy integrity algorithms, event-loop thrown-value inspection, namespace cell identity, and leaf-to-root async rejection order. Review retained failures before accepting the subsequent counts.

### What should be done in the future
Finish the rebuilt-runtime checks, rerun the affected module selection and full matrix, qualify hostile exception probes and the full core/extension gates, then document remaining admission boundaries and publish the final ticket state.

### Code review instructions
Read the initial receipt and failed variant list, then review compiler.cjs transformations and runtime.js scheduling. Inspect JSObject::seal/freeze, objectIsSealed/objectIsFrozen, ConsoleBindings.cpp, Builtins.def, and the Promise moduleThen implementation.

### Technical details
Initial implementation commit: 8b88615. The selected Test262 profile is frontend O / LLVM O2 with eight workers. Early parse checks use Babel; link-only validation uses the same host in Node without executing source bodies; executable contracts run through LLVM. This distinction is included in each module result.

### Step 3 follow-up: builtin lowering and independent oracle limits
The rebuilt compiler rejected `$SHBuiltin.moduleThen` with `unknown SH builtin call`; registering the runtime builtin does not automatically add source-level IR generation. Added explicit three-argument lowering to GetBuiltinClosure plus ordinary call, with spread rejection. The next focused gate passed default names, intrinsic jobs, namespace identity, live bindings, and reexports.

Two expanded oracle assumptions needed qualification. Node 24.18.0 treats duplicate routes to the same namespace as ambiguous, unlike the pinned specification's namespace-binding rule; this now has a separate specification-directed fixture with the Node result retained. Mutating public Promise.then during Node dynamic import also failed inside Node's loader. The intrinsic-jobs fixture now checks mutation during await, restores then, and separately checks dynamic import; no Node failure is counted as a matching result.

The special-names fixture exposed `ownKeys target key is non-configurable but not present in trap result`. Hermes stores ordinary indexed keys numerically internally but compared them directly with the Proxy trap's string keys. Normalizing target snapshot keys before invariant comparison fixes the representation mismatch; a standalone Proxy regression accompanies the module numeric-export case. The patch is being rebuilt before qualification.

## Step 4: Qualify the complete module host and shared runtime corrections

The final graph matrix passes 14/14 contracts across 56 native executions and 14 real lli executions. The pinned module-code selection improves from 564 passes, 24 semantic failures, and 14 unsupported variants to 585 passes and 17 unsupported variants, with no semantic failures or timeouts. The same variant identities and source hashes were compared; no previously passing variant regressed.

### Prompt Context
See Step 1 for the original request. This checkpoint completes the requested module-host implementation, evidence, and documentation within the explicitly documented filesystem host policy.

### What I did
Completed intrinsic Promise reaction lowering, namespace identity and default-name corrections, Proxy integrity operations, numeric ownKeys invariant normalization, and actual-thrown-value reporting for asynchronous Test262 exceptions. Ran the selected module suite, the full graph matrix, core and extension gates, exception probes, and compiler tests. Added the operational MODULES.md guide and retained compressed full Test262 receipts with uncompressed SHA-256 hashes.

### Why
The initial suite showed that source transformation alone was insufficient: namespace operations depend on correct underlying Proxy internal methods, and async evaluation depends on intrinsic reaction scheduling. Negative tests also require reliable phase/type attribution rather than matching user-controlled diagnostic text.

### What worked
The final Test262 receipt contains 396 runtime passes, 166 parse passes, and 23 resolution passes. All 602 planned variants were classified. The graph and Test262 receipts report no changed inputs; the extension receipt also confirms unchanged inputs. Core passes 22/22 and extensions 66/66. Nineteen hostile/ordinary exception probes have their expected outcomes, and eight compiler tests pass. The selected Test262 result retains 17 unsupported records, so its aggregate command exits nonzero intentionally; that exit is not hidden or relabeled as a complete-conformance success.

### What didn't work
After the numeric-key runtime fix, the special-names fixture disagreed with Node 24.18.0: Node enumerated numeric export names as 2,10, while the pinned ModuleNamespaceCreate algorithm requires lexicographic order 10,2. All five LLVM executions already matched that specification expectation. Preserved numeric-key-oracle-mismatch.json, added an explicit oracle.json qualification, and reran the complete graph matrix. Together with duplicate namespace reexport identity, there are two specification-directed cases and twelve Node-matched cases. Neither mismatch counts as independent Node agreement.

### What I learned
A host may complete its task queue while an entry evaluation remains pending on an unresolved Promise. The inherited console loop does not implement Node's exit-code-13 convention. Documented this lifecycle policy and retained explicit completion assertions in conformance tests. ECMAScript module evaluation state and operating-system process success are distinct observations.

### What was tricky to build
Shared-runtime repairs affect ordinary scripts as well as module wrappers. Their separate Proxy regression and complete extension gate were needed to check that internal-method dispatch changes did not break the existing execution path. Metadata keys such as __proto__ and numeric export names also require preserving ordinary string identity at every stage, from JSON emission to Proxy invariant checks.

### What warrants a second pair of eyes
Review the shared Proxy GC handles and trap order, moduleThen's private input contract, async dependency fulfillment/rejection ordering, and compiler scope rebuilding before imported-binding rewriting. Read both Node qualifications against the pinned specification before treating the matrix as cross-engine agreement.

### What should be done in the future
Expand to import attributes/source phases, module lexical eval, script-mode dynamic imports, and larger root frames as separate work. Define an embedding-specific pending-entry shutdown policy if deployment requires a nonzero process exit for unresolved TLA. The historical 102,992-variant broad baseline was not rerun; this checkpoint qualifies the selected module profile and existing gates only.

### Code review instructions
Start with MODULES.md and the design guide's implemented checkpoint. Compare initial-to-final.json, then inspect the full compressed receipts as needed. Read compiler.test.cjs and the fourteen graph directories, especially the two oracle.json files. Review JSObject.cpp, JSLib/Object.cpp, JSProxy.cpp, ConsoleBindings.cpp, and the private builtin registration together with the host changes.

### Technical details
Build command: `cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4`. Compiler checks: `pnpm --dir hermes/utils/module-host test`. Module matrix: `python3 hermes/utils/test_shllvm_modules.py --output /tmp/llvm-module-matrix-qualified.json`. Test262 command and exact profile are in MODULES.md; suite revision is 0b4e0812022b18236b5276d2804948fdd9f71603. Large evidence JSON is losslessly gzip-compressed with deterministic timestamp zero; receipt-hashes.json records uncompressed identity. Parsing uses Babel and link-only validation uses the host in Node; executable module bodies run as LLVM native code. Prior implementation checkpoint is 8b88615; the final code commit is recorded in the next milestone.

## Step 5: Commit the qualified checkpoint

Committed the final implementation, tests, operational guide, and retained evidence as **185923d** (`Qualify module semantics and fix shared Promise and Proxy behavior`). Earlier checkpoints are **98aac5f** (design) and **8b88615** (initial host implementation). All four ticket tasks are complete; docmgr doctor reports all checks passed.

The requested textbook project report was published before module implementation in go-go-parc as **4ec9372** (`Document LLVM conformance baseline and dynamic eval implementation`). Local main and origin/main report zero commits of divergence. The note is `Projects/2026/10/28/PROJ - Direct LLVM JavaScript - Conformance Baseline and Dynamic Evaluation.md`. Unrelated vault edits were not included.

Validation is the unchanged-code evidence recorded in Step 4; no additional broad run was needed for this bookkeeping entry. Review remaining host boundaries in MODULES.md before using the selected suite totals as a broader conformance claim.
