---
Title: Design investigation diary
Ticket: LLVM-ENGINE-002
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
LastUpdated: 2026-10-29T12:12:00.60500545-04:00
WhatFor: ""
WhenToUse: ""
---

# Design investigation diary

## Step 1: Design a parallel engine integration with shared Hermes semantics

Created LLVM-ENGINE-002 and an intern-facing design guide for a deliberately incompatible engine integration. Recommended a new engine-v2 directory within the same repository while retaining the existing engine as a runnable reference. No engine implementation or source relocation was performed.

### Prompt Context
**User prompt (verbatim):** "Ok, let's create our own setup and geared towards simplicity, elegance, composability, effectiveness, clarity. Create a new docmgr tiket and Create  a detailed analysis / design / implementation guide that is for a new intern, explaining all the parts of the system needed to understand what it is, with prose paragraphs and bullet point sand pseudocode and diagrams and api references and file references. It should be very clear and technical. Store in the ticket and the nupload to remarkable.

 (the doc is detailed, the design is effective and elegant and simple and composable and opinionated first).

Before you start, would it make sense to start a new parallel implementation to void having to deal with the current setup (maybe in a different directory or by archiving the current one or so? Or is reuse fine and won't stand in the way?)"

### What I did
Read the ticket research, docmgr, diary and reMarkable upload skills. Inspected StaticHUnit.cpp registration, static_h.h frame operations, StaticH.cpp catch/throw restoration, Runtime.cpp root traversal anchors, the current Engine/Host API, and the existing application results. Wrote the architecture, ownership/API sketches, directory plan, runtime integration details, module state model, and phased acceptance gates.

### Why
A separate integration path permits changing native ABI, root ownership, and module identity together. Sharing Hermes avoids duplicating parser/runtime semantics and preserves the application suite as a useful comparison. Moving or archiving the current tree now would create path churn without proving the new design.

### What worked
The current source identifies narrow but essential integration points: _sh_enter/_sh_leave publish and restore local roots and managed frames; _sh_catch_no_pop restores runtime state on nonlocal exception transfer. StaticHUnit.cpp confirms process-global index assignment. These facts anchor the proposed arena checkpoints and engine-local registration.

### What didn't work
No implementation or runtime validation was attempted in this design task. Arena correctness, native callable dispatch, module-registry integration, and job-pump extraction remain unproven proposed work. Existing application success is not v2 qualification.

### What I learned
The major risk is not directory placement. New root storage must participate in every relevant exception restoration path, and the proposed native function signature needs an explicit managed-to-native callable path. Reuse is appropriate when its invariant is understood; it must not preserve old ABI constraints by accident.

### What was tricky to build
The guide separates active roots from suspended continuation state, code lifetime from activation lifetime, and module identity from native unit identity. Job budgets are explicitly checked between jobs, not advertised as preemption. AOT and JIT share descriptor/registration contracts without sharing process-local native pointers across processes.

### What warrants a second pair of eyes
Review the nonlocal-unwind design, return-value rooting, arena publication order, callable dispatch, and runtime-local AOT descriptor registration. Review the module linking/evaluation state split against existing cycle tests before implementation.

### What should be done in the future
Execute phase 0 and phase 1 before porting the emitter. Keep all implementation tasks open. Use unmodified unoptimized fflate as a frame-capacity acceptance case, then retain all four independent application contracts.

### Code review instructions
Read the guide introduction and example first, then Sections 7-11 for ABI, activations, unwinding, API, and module ownership. Inspect the related runtime source files. The text diagrams are intentionally renderer-independent for the reMarkable PDF.

### Technical details
Reference code checkpoint d715f43. Proposed target remains Linux x86-64 host64 with LLVM 18, one owner thread, retained code until close, and Hermes managed values. The proposed engine-v2 tree is not created in this task. No compatibility adapter or old-artifact loader is proposed.

## Step 2: Validate and deliver the guide

The 5,208-word substantive guide passed ticket hygiene, metadata/code-fence checks, and existing-file reference checks. Uploaded the guide through remarquee with a two-level table of contents to `/ai/2026/10/29/LLVM-ENGINE-002`.

- **Prompt context:** Step 1; this completes the requested design delivery.
- **Command/result:** `remarquee upload bundle ... --name "LLVM-ENGINE-002 Engine V2 Intern Design Guide" --remote-dir "/ai/2026/10/29/LLVM-ENGINE-002" --toc-depth 2 --non-interactive` returned `OK: uploaded LLVM-ENGINE-002 Engine V2 Intern Design Guide.pdf -> /ai/2026/10/29/LLVM-ENGINE-002`.
- **Validation:** docmgr doctor passed; all existing source paths in the reading table resolve. Proposed files and APIs are explicitly marked. Text diagrams require no Mermaid rendering dependency.
- **Limitations:** Cloud upload is confirmed; physical device sync was not checked. No runtime implementation or v2 correctness claim is made.
- **Next:** Implementation starts with isolation and the activation/GC/unwind prototype. Those tasks remain open.

## Step 3: Specify the composable compiler language

Added the second design document to the existing ticket. It defines a small typed CFG language and the contracts connecting semantic operations, runtime representations, root plans, and native artifacts. It is a design deliverable, not an implemented grammar or a new backend.

### Prompt Context
**User prompt (verbatim):** "Ok, write a second detailed design document that is entirely about this new approach, and tries to cover as much ground as possible based on what we built so far, and how it would concretely integrate into this framework, and how things can be expanded in the future. Create  a detailed analysis / design / implementation guide that is for a new intern, explaining all the parts of the system needed to understand what it is, with prose paragraphs and bullet point sand pseudocode and diagrams and api references and file references. It should be very clear and technical. Store in the ticket and the nupload to remarkable."

### What I did
Applied the grammar-builder, ticket-research, and reMarkable delivery guidance. Wrote the grammar table, effect model, block-parameter control flow, IR levels, pass/analysis contracts, liveness algorithm, root and ownership verification, provider composition, integration map, feature inventory, staging/cache policy, inspection API, defaults, experimentation model, 26 example subjects, implementation slices, and decision records.

### Why
The first guide establishes execution ownership; the new guide makes the compiler's meaning and decisions explicit. A canonical graph permits JS authoring and direct C++ frontend integration without embedding a second configuration process in every compile request. Effects and runtime obligations must be separate to preserve both JS semantics and GC safety.

### What worked
The design maps to existing source boundaries: request-scoped frontend, emitter root allocation and phi transfers, runtime helper calls, exception restoration, code registration, module evaluation, and independent application tests. The initial five examples exercise the small core before broader features are added.

### What didn't work
No implementation or dynamic validation occurred. Proposed effects, provider contracts, verifiers, and reference interpreter remain unimplemented. Property-test laws are not presented as universal correctness proofs. Current application passes remain historical v1 evidence.

### What I learned
A single generic backend interface would obscure complementary roles of Hermes and LLVM. A graph whose unknown calls appear pure would permit invalid rewrites; a graph whose runtime lowering introduces untracked safepoints would produce incorrect roots. Explicit phase contracts prevent both mistakes.

### What was tricky to build
The guide distinguishes effect-summary join laws from operation reordering, floating-point semantics from real-number algebra, exceptional post-effect state from rollback, and live runtime admission from serializable compiler IR. Loops use a finite-lattice fixed point rather than an arbitrary capped approximation.

### What warrants a second pair of eyes
Review edge-specific liveness with block parameters, normal/exception state-token use, runtime helper safepoint classification, alias-like storage, return rooting, and cache identity for customized passes. Review the selected Hermes import boundary before assuming all original semantic information survives lowering.

### What should be done in the future
Implement the canonical graph/verifier and the first five examples before porting the full emitter. Integrate the arena/exception experiment from the first guide next. Keep implementation tasks open and add providers only with concrete capability and correctness evidence.

### Code review instructions
Read the source-to-execution example, grammar table, effects, IR levels, and integration map first. Then review ownership/exception details and the phased plan. Existing source references are concrete; all future g APIs and examples are labeled proposed.

### Technical details
The document uses renderer-independent text diagrams for PDF delivery. It preserves current exact BigInt, UTF-16 dynamic source, promise ordering, private-field, typed-array, and lexical-eval requirements rather than replacing them with numeric toy semantics. No compatibility wrapper or runtime implementation was added.

## Step 4: Correct a reference and deliver the second guide

Delivered the roughly 7,400-word compiler-language guide with a two-level table of contents. The authoritative cloud copy is **LLVM-ENGINE-002 Composable Compiler Language Guide Revised.pdf** in `/ai/2026/10/29/LLVM-ENGINE-002`.

- **Prompt context:** Step 3.
- **Failure and correction:** The source-reference check raised `AssertionError: hermes/IR`; the concrete header directory is `hermes/include/hermes/IR`. The initial shell invocation continued to upload after the failed check. Corrected the path and reran validation in a separate successful command before uploading a new Revised copy. Did not overwrite either existing guide or remove annotations.
- **Validation:** docmgr doctor passed. Frontmatter, code fences, and all explicit existing Hermes path references passed checks after correction. Proposed APIs remain labeled and unimplemented.
- **Delivery result:** `OK: uploaded LLVM-ENGINE-002 Composable Compiler Language Guide Revised.pdf -> /ai/2026/10/29/LLVM-ENGINE-002`.
- **Evidence limit:** Successful cloud delivery; no physical device-sync claim. The old non-Revised copy remains, with the receipt identifying the corrected version.
- **Next:** Implement the canonical CFG, verifier, and five core examples before the runtime integration phase. No implementation task was marked complete by this document delivery.
