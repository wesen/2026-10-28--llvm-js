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

## Step 5: Reframe the architecture as a graduate design research assignment

Prepared a research-informed critique and a self-contained handoff containing the pinned implementation, the two prior proposals, a new seminar brief, and review templates. The assignment explicitly permits substantial redesign and postpones implementation decisions. It also asks the researcher to derive the foundations, describe a path to a custom system, and design reusable components with concrete independent consumers.

### Prompt Context
**User prompt (verbatim):** "so now that you are looking at these, and maybe read them, what would you potentially address / improve in our design? Can you maybe make a little package for an intern with our new design doc, our current code, and a detailed document on what to research and study, to hand it off to get like, a grad seminar work / project back?"

**User clarification (verbatim):** "(not implementing, but refining or updating or really recreating our design / parts of our design)"

**User addition (verbatim):** "also ask them to study and expose the fundamental underpinnings in case we want to not only build with what we have but potentially work our way up to a full custom system, and also idedntify more self contained subsystems that can be reused across different projects, for certain passes and other things"

**Assistant interpretation:** Produce a critical design-research assignment and source package. Do not implement the proposed compiler or require the intern to implement it.

### What I did
Wrote design document 03, approximately 5,200 words, with a semantic contract, transformation-permission distinctions, infrastructure comparison, root-policy comparison, worked throwing-getter example, foundational study sequence, dependency replacement stages, reusable subsystem catalog, source-reading map, annotated reading ledger, and eight-week return plan. Added templates for decisions, subsystem contracts, claims/evidence, and the final paper. Added a package builder and standalone verifier. Updated the ticket overview and marked earlier implementation tasks deferred pending the research gate.

### Why
The earlier designs selected substantial infrastructure before sufficiently comparing alternatives. The current root-slot failure supports investigating root allocation, but does not prove an arena is the right choice. A compositional builder does not by itself establish semantic preservation or type safety. The revised assignment gives the researcher permission and criteria to remove or replace proposed abstractions.

### What worked
Source inspection connects the questions to actual emitter admission, engine ownership, runtime exception restoration, module preparation, and application evidence. Selected primary documentation clarifies structural conversion legality, speculation versus memory effects, and the limits of framework-provided non-local control modeling. The first package verification covered 13,494 tracked source files, ZIP CRC checks, all payload hashes, and source archive paths. A final rebuild follows metadata corrections; its authoritative digest is in deliverables/package-receipt.json.

### What didn't work
The Appel author PDF endpoint returned HTTP 403 during research. The brief identifies that access limit and assigns full reading through the publication record rather than claiming to have studied the paper. The initial package was built before final frontmatter and entry-point corrections; it was regenerated. The first `docmgr doctor --ticket LLVM-ENGINE-002 --stale-after 30` reported four `invalid_frontmatter` errors: `frontmatter delimiters '---' not found` in START-HERE and the three Markdown templates. Added ticket reference frontmatter to each. The next check reported four missing numeric-prefix warnings; numbered the local Markdown files and preserved conventional packet names in the builder. Reran the check before final packaging. No engine tests were run because the compiler and runtime were not changed.

### What I learned
MLIR's current effects rationale explicitly leaves a gap for full non-local control-flow modeling. Adopting MLIR would not eliminate our exception/GC obligations. Reuse also needs a boundary between generic algorithms and language policy: SCC decomposition can be shared, whereas live bindings and asynchronous module evaluation require additional semantics.

### What was tricky to build
The assignment must allow a custom system without turning an eight-week seminar into a full JavaScript runtime implementation. The brief separates a small formal core, production integration requirements, and staged future replacement. It asks for design pseudocode and derivations, with execution results labeled separately. Packaging uses a pinned git archive for all tracked source and separately versioned current documents, avoiding a circular archive of itself or accidental inclusion of local build products.

### What warrants a second pair of eyes
Review observation equivalence, exceptional post-effect state, edge-specific liveness, collector relocation assumptions, and whether the proposed reusable subsystem interfaces are sufficiently independent. Check that the reading coverage ledger does not imply papers were read in full. Evaluate the realism of two candidate subsystem designs and their proposed consumers.

### What should be done in the future
The researcher should return the revised design, six decision records, two reusable subsystem API designs, semantic examples and counterexamples, foundational exposition, and a custom-system roadmap. Implementation requires a later decision; the earlier phase list is not the current assignment.

### Code review instructions
Start with design document 03 and handoff/01-START-HERE.md. Review scripts/01-build-seminar-package.py and handoff/VERIFY.py for source completeness and verification behavior. Run the builder from the repository root and docmgr doctor for LLVM-ENGINE-002. Compare the source inventory to the pinned baseline, not to a later handoff-only commit.

### Technical details
Source baseline: 87d4658c4ed27aee42ddf4e023f9e9666ef3a2a1. Git archive preserves tracked source and licenses without the git database or untracked products. The outer ZIP has fixed timestamps; the inner gzip uses mtime zero. The manifest hashes every payload except itself; an adjacent SHA-256 covers the complete archive. Generated ZIPs are ignored, while the builder, documents, templates, and bounded receipt are tracked. No reMarkable upload or external message was requested for this handoff.

## Step 6: Validate and deliver the research package

Final package validation passed: 13,494 tracked source files, ZIP CRC, payload SHA-256 verification, source path checks, and byte-for-byte matching of the final guides/templates with the archive. Docmgr doctor passes after the metadata corrections described in Step 5.

- **Prompt context:** Step 5.
- **Artifact:** `deliverables/LLVM-ENGINE-002-design-seminar-handoff.zip` (47,198,798 bytes).
- **SHA-256:** `6f8328df3817d5c4b91345fb5291474ff2f8a33e1fb254f0a25b0aca6c07c6d6`.
- **Source revision:** `87d4658c4ed27aee42ddf4e023f9e9666ef3a2a1`.
- **Validation limits:** Archive/document validation only; no new compiler execution claims or full-paper review claims.
- **Next:** External design research; earlier engine implementation proposals remain deferred.
