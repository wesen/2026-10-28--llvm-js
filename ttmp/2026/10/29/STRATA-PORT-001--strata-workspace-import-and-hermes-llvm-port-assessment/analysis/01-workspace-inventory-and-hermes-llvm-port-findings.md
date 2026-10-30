---
Title: Workspace inventory and Hermes LLVM port findings
Ticket: STRATA-PORT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: analysis
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/runtime.h
      Note: Actual helper ABI compared with the workbench
    - Path: repo://hermes/utils/shllvm.py
      Note: Build-dependent sanitizer link flags
    - Path: repo://ttmp/2026/10/29/STRATA-PORT-001--strata-workspace-import-and-hermes-llvm-port-assessment/archive/strata-workspace-full.zip
      Note: Original complete workspace import
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T20:26:47.535736858-04:00
WhatFor: ""
WhenToUse: ""
---

# Strata workspace import and Hermes/LLVM port findings

## Finding

The archive contains a detailed, explicit porting guide: **Strata on the real Hermes and LLVM: an intern's guide**, approximately 54 KB. Its intended architecture is Strata frontend → Strata core IR/analyses/root plans → real LLVM IR → LLVM native compilation → Hermes managed runtime through the existing `shllvm_*` bridge. The fork's compiler becomes a comparison baseline rather than the frontend of this new path.

This is a substantial implemented JavaScript workbench accompanied by a native-port proposal. It is not a completed Strata-to-Hermes native integration. The workbench's own documentation explicitly distinguishes LLVM-shaped text from executable LLVM output. Inspection confirms at least one ABI mismatch and the absence of the proposed native-port files.

The current import is read-only with respect to implementation: no dependency installation, archived tool execution, server, build, native port, or compiler/runtime edit was performed.

## Imported material and provenance

The original ZIP is preserved at `archive/strata-workspace-full.zip`; the extracted copy is at `source/`. The manifest at `reference/import-manifest.json` records the original ZIP SHA-256 and individual file sizes/hashes. The archive contains 1,307 entries, including directories, and 1,083 regular files totaling 25,527,745 uncompressed bytes. ZIP CRC validation passed and extracted bytes were checked against the manifest.

| Directory | Files | Contents |
|---|---:|---|
| `wb/` | 561 | Workbench engine, frontend, UI, generated site, textbook, presets, documentation, tools |
| `strata-api/` | 74 | Earlier examples-only API proposal and its site |
| `ds/` | 264 | Workbench/agent/stage design systems and assets |
| `exports/` | 2 | Porting guide Markdown and semantics architecture HTML |
| `session-records/` | 180 | Reconstructed session/subagent summaries, probe scripts and screenshots |
| `scripts/` | 2 | Supporting page/rendering scripts |

The content inventory independently confirms 90 preset metadata files, 24 textbook chapter entries, and 20 supporting documentation pages. These are content counts, not freshly executed test results.

The archive includes compiled/generated web assets, so version control retains the original ZIP as the authoritative full import instead of duplicating every generated file. `scripts/01-import-workspace.py` reconstructs the extracted tree and verifies every manifest hash. The primary intern guide is also imported as a normal docmgr reference document for discovery. Raw imported Markdown retains its original metadata and is excluded from docmgr validation through a ticket-specific ignore entry.

## Where to read

1. [Imported intern porting guide](../reference/02-imported-strata-hermes-llvm-intern-guide.md). The principal actionable plan; sections 9–14 contain the native emitter, ABI, GC-stress, language growth, measurement, and replacement work.
2. [Workbench Hermes/LLVM documentation](../source/wb/content-src/docs/16-hermes-llvm.md). The clearest inventory of what current LLVM text reproduces and omits.
3. [Textbook Chapter 16](../source/wb/content-src/book/16-llvm-ir-and-the-hermes-abi.md). Extended explanation of emitted LLVM shape and the Hermes ABI.
4. [Textbook Chapter 21](../source/wb/content-src/book/21-from-the-workbench-to-a-real-compiler.md). An earlier, materially different migration plan that initially improves the existing Hermes emitter.
5. [Semantics-first architecture export](<../source/exports/Semantics-first architecture for a composable JS compiler and JIT.html>). Foundational architecture document supplied as HTML; retained for subsequent design review, not exhaustively evaluated in this import.
6. [Session summary](../source/session-records/SESSION-SUMMARY.md). Explains that the intern guide became Strata-first after clarification, and lists reported checks and known gaps.

The exported guide contains embedded-content placeholders where diagrams appeared in the original document. Scratch screenshots are supplied, but I have not reconstructed or matched those placeholders to images. Workbench chapters include inline SVG diagrams. The session-records README explicitly says raw conversation/subagent transcripts were unavailable: the summaries are reconstructions, not verbatim transcripts.

## What exists in code

The implemented workbench lives in `wb/`, not in the earlier `strata-api/` proposal. The latter README explicitly labels its examples illustrative and unimplemented.

The workbench's `src/core` contains ten source parts:

- `00-prelude.js`: supporting definitions, units and type lattice.
- `10-effects.js` and `20-ops.js`: behavioral contracts, obligations, permissions, and operations.
- `30-ir.js`: graph construction, parsing/printing, verification, and dominance.
- `40-machine.js`: reference execution and modeled collection.
- `50-analysis.js`: dataflow machinery, liveness and type facts.
- `60-rewrite.js`: transformations including cell promotion.
- `70-lower.js`: runtime binding descriptions, root plans and LLVM text emission.
- `80-pipeline.js` and `90-engine.js`: pipeline and engine-facing orchestration.

There is also a JavaScript-subset frontend and generated browser/Node-loadable engine code. Documentation describes real Wasm execution for a restricted core and modeled execution for the reference/plan paths. The existence of those implementations was inspected; their operational correctness was not tested in this import.

The session summary reports harness 28/28, presets 90/90, book 24/24, docs 20/20, and a browser tour without page errors. These remain imported historical claims. `wb/package.json` has a placeholder failing `test` script, so `npm test` is not the validation entry point; the individual tools are the documented harnesses.

## What the native port guide proposes

| Stage | Proposed work | Main result |
|---|---|---|
| Baseline | Build our fork and reproduce its gates | Known local compiler/runtime baseline |
| Local workbench | Remove environment-specific dependency paths and run workbench checks | Node-accessible Strata implementation |
| Differential runner | Compare Node, Hermes bytecode/native/JIT, and Strata spec/plan | Shared observation and failure classification |
| Native emission | Replace illustrative helper bindings with the exact bridge ABI; emit module data | First Strata-compiled native executable |
| ABI contract | Versioned helper signatures, effects, collection/throw obligations and borrowing | Explicit runtime boundary |
| Root validation | Compare distinct/reused slots under real collection stress and negative controls | Evidence for root allocation and unwind correctness |
| Language growth | Grow the subset from application failures | Larger real applications, eventually fflate |
| Measurement | Compare correctness, frame size, runtime, code size and compile time | Evidence for subsequent replacements |
| Replacement | Custom runtime/collector, optional machine backend, more advanced JIT | Long-term independent system |

The first native milestones are `print(1 + 2)`, a numeric loop, objects and a throwing getter, shared captured variables, exception/finally paths, jobs/timers/promises, then the ledger and J-program corpus at LLVM O0/O2.

Three specific lowering decisions are called out: map captured cells to Hermes environments; lower completion records to kind/value pairs; and generate real string pools, function descriptors, unit construction, and entry-point registration. The ABI proposal adds helper metadata beyond C types: whether an operation can collect, throw nonlocally, execute user code, or read borrowed values after collection.

The files `wb/src/core/75-hermes-abi.js`, `wb/abi/strata-abi.json`, `wb/tools/strata-native.js`, and `wb/tools/import-plan.js` are proposed deliverables and are absent from this archive. Their absence agrees with the guide's description of work still to do.

## Cross-checks and qualifications

### 1. The LLVM ABI mismatch is concrete

In `wb/src/core/70-lower.js`, constant materialization declares and emits `shllvm_constant(ptr, ptr, i32)`. Our actual `hermes/lib/BCGen/SH/LLVMNative/runtime.h` declares `shllvm_constant(void *out, uint32_t kind, uint64_t bits)`. The workbench's binding cannot be linked and executed faithfully simply by adding the runtime library. Operator encodings, closure calling conventions, unit data, and exception cleanup also require deliberate translation.

The workbench docs explicitly disclose missing `shllvm_catch_prepare` and `shllvm_try_end` calls, simplified helper signatures, and an outgoing-argument rooting concern. These are required integration work, not documentation polish. A complete ABI audit remains outstanding; this import checked representative boundaries.

### 2. There are two competing migration plans

Chapter 21 starts with liveness and slot reuse inside the existing Hermes emitter, then helper contracts, and only adds a separate IR if evidence supports it. The exported guide instead starts with Strata owning the frontend and emission, using Hermes's compiler only as a baseline. The session summary identifies the latter as the later clarified direction. Preserve both as history, but select one explicitly before creating implementation tasks; they have different scopes and acceptance criteria.

### 3. The link recipe loses sanitizer flags

The exported native link command says it matches our driver, but omits sanitizer link flags. The current `hermes/utils/shllvm.py` derives `-fsanitize=address` and `-fsanitize=undefined` from build configuration before linking. Since the guide configures an ASan runtime, the new native driver should derive its link settings from actual build metadata or reproduce this logic. Copying the simplified command literally can fail to link the sanitizer runtime correctly.

### 4. Dependency setup needs local adaptation

The hard-coded `/opt/npm-tools/node_modules/` paths are present in `harness.js`, `check-common.js`, and `preset-check.js`, as the guide says. The guide suggests npm commands; this repository's instructions prefer pnpm. No installation or path edits were done here. The guide's release-era test totals and tool versions must also be distinguished from later local tickets and current gate definitions; fixed historic counts are not a universal success condition for an evolved tree.

### 5. Test agreement must not be described as proof

The guide asks every checker-rejected root plan to fail dynamically. That is too strong as a general acceptance rule: conservative rejection can be safe, and a concrete execution may not exercise the path requiring a missing root. Use deliberately chosen negative controls whose relevant paths and collections actually occur. Passing stress tests supports the tested cases; it does not prove all accepted plans correct.

Similarly, a test that observes no allocation cannot establish that a helper never collects, and checking allocations is not equivalent to checking collection. Narrowing effect/GC contracts requires source-level reasoning as well as tests. Treat Node as a differential reference, not the definition of ECMAScript correctness—the guide itself records a specification-directed disagreement with one Node version.

### 6. The JIT roadmap describes an optimizing tier

The guide's later profiling/guards/deoptimization work is a possible advanced JIT direction. Our existing eager ORC JIT already performs just-in-time compilation without speculation or deoptimization. Those additions should be scoped as a future optimization tier rather than prerequisites for calling a system a JIT.

### 7. Known workbench gaps are openly listed

The imported session summary lists missing operand-type verification, no narrowing for `!==`, a Promise adoption ordering discrepancy, missing NaN canonicalization and exception cleanup in LLVM text, a `statusReturn` choice that affects plans but not emitted text, widening behavior, and generator/shrinker limitations. These should be triaged before treating workbench checks as a correctness gate for native compilation. This inspection did not reproduce those bugs independently.

## Recommended next decision

The archive supplies the requested porting documents and enough concrete source to begin a bounded design review. The immediate useful step is to reconcile the two porting directions and audit the real ABI against Strata's operation/root model. For a Strata-first direction, the first execution milestone should be a minimal native program through the exact unit/frame/helper protocol. Do not combine that with a frontend expansion, new collector, or speculative JIT.

This ticket records the import and findings only. No proposed porting step has been implemented or marked validated by this inspection.
