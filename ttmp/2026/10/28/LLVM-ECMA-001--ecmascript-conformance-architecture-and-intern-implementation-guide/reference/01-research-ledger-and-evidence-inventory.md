---
Title: Research ledger and evidence inventory
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
LastUpdated: 2026-10-28T18:29:06.937225894-04:00
WhatFor: "Understand the existing backend and plan measurable conformance work."
WhenToUse: "Onboarding, architecture review, and implementation planning."
---

# Research ledger and evidence inventory

## Scope and method

Research date: 2026-10-28. Source baseline: `3c3d5d6c803ae3711ec5d2d128237acf5dc38997`. This investigation combines source inspection with primary specification and Test262 documentation. It does not claim a new full conformance run. The guide distinguishes existing implementation, recorded earlier validation, inherited policy, and proposed work.

## Primary external references

- [ECMAScript 2026 edition-specific snapshot](https://tc39.es/ecma262/2026/multipage/): edition baseline proposed for the project. The page identifies its snapshot as a March 31, 2026 draft; an implementation baseline should retain an immutable artifact and digest.
- [Conformance](https://tc39.es/ecma262/2026/multipage/conformance.html): governs language completeness, optional clauses, extensions, and internationalization obligations.
- [Host layering points](https://tc39.es/ecma262/2026/multipage/host-layering-points.html): identifies the interfaces where an embedding must supply behavior.
- [Scripts and modules](https://tc39.es/ecma262/2026/multipage/ecmascript-language-scripts-and-modules.html): reference for module records, loading, linking, and evaluation.
- [PerformEval](https://tc39.es/ecma262/2026/multipage/global-object.html#sec-performeval): reference for contextual dynamic evaluation.
- [Execution contexts](https://tc39.es/ecma262/2026/multipage/executable-code-and-execution-contexts.html): foundation for environments, realms, and job execution.
- [Memory model](https://tc39.es/ecma262/2026/multipage/memory-model.html): reference for shared-memory semantics and agent interactions.
- [Test262 repository](https://github.com/tc39/test262): official suite and its stated coverage limitations.
- [Test262 interpretation contract](https://raw.githubusercontent.com/tc39/test262/main/INTERPRETING.md): authoritative runner contract. The consulted branch is mutable; no suite commit was selected or executed in this ticket.
- [TC39 test262-harness](https://github.com/tc39/test262-harness): an existing runner to evaluate against a direct LLVM integration. Its existence does not imply that it already supports this backend.

The research uses primary sources. Proposed module registries, result schemas, phase sequencing, and host interfaces are engineering recommendations derived from the source architecture and requirements; they are not copied implementation APIs or claims of completed work.

## Findings tied to source

### Module tests are skipped before feature filtering

`hermes/utils/testsuite/test_run_defs.py`, around line 170, returns `TEST_SKIPPED` when metadata includes `module`. The feature skip-list logic follows that return. Thus `--test-skiplist` is not enough to admit module tests. This observation concerns the runner; it does not independently prove the state of every parser or runtime module facility.

### Inherited unsupported-feature policy is broader than the release fixtures

`hermes/utils/testsuite/skiplist.json` contains unsupported and permanent-unsupported feature arrays. Selected species behavior now passes targeted release cases even though `Symbol.species` remains excluded by inherited policy. Re-audit these lists under a pinned suite; do not equate an exclusion with a current reproduced failure.

### The ABI has explicit lifetime and size constraints

`runtime.h` specifies rooted eight-byte value slots. `LLVMBackend.cpp` checks a 1,024 combined root/argument-slot limit before emitting a function. `eval_extensions.h` documents descriptor order, slot mapping, flags, and runtime bytecode compilation. These constraints are current code contracts, not future design options.

### Async success requires evidence of completion

`hermes/utils/testsuite/hermes.py` checks the Test262 asynchronous completion/failure markers independently of process exit status. A new LLVM execution mode must preserve the distinction between process completion and test completion.

## Existing validation records

The source import and previous fresh local validation are described by `EXTENSIONS-IMPORT.md`. The local records are under `ttmp/2026-10-28/extensions-validation/`: core 22/22, extension 53/53, driver 6/6, and defaults 5/5. Expected language errors and implementation-boundary rejections remain separate from positive cases. These results were already obtained before this ticket; this research did not rerun them.

The archived validation used a different build context from the fresh local build. Preserve their distinct fingerprints and sanitizer qualifications. No full Test262 percentage, physical PicoCalc execution result, or completion estimate for the proposed roadmap is asserted.

## Open research work retained for implementation

1. Select and lock the actual Test262 commit and specification artifact digest.
2. Enumerate required, optional, proposal, and host-dependent tests for the chosen profile.
3. Produce real failures through the LLVM path, including cases currently skipped by runner logic.
4. Audit ESM and realm facilities below the runner before deciding whether to extend or introduce runtime records.
5. Measure resource-limit failures and establish the shared-memory ownership model.
6. Review edition-specific builtin additions and Unicode data against the pinned frontend/runtime.
7. Establish a separate ECMA-402 and device-deployment qualification plan.

The guide's implementation phases deliberately keep these questions visible. They must be answered with reproducible evidence rather than converted into assumed support.
