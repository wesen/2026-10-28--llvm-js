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
