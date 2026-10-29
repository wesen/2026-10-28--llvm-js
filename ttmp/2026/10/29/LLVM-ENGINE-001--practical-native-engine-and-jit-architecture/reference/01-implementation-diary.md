---
Title: Implementation diary
Ticket: LLVM-ENGINE-001
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
LastUpdated: 2026-10-29T09:32:28.842857718-04:00
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
SHUnit explicitly persists until runtime destruction. Retaining all registered code for that lifetime avoids introducing unsafe individual-code unloading. The emitter already supports creator-only units, so a separate calling convention is unnecessary.

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
