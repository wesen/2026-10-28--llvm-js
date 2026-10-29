---
Title: Broad baseline results and failure attribution
Ticket: LLVM-ECMA-002
Status: active
Topics:
    - llvm
    - javascript
DocType: analysis
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/utils/summarize_shllvm_test262.py
      Note: Validates inventory and derives failure groups
    - Path: repo://ttmp/2026/10/28/LLVM-ECMA-002--test262-conformance-baseline-and-dynamic-evaluation/reference/evidence/full-baseline-summary.json
      Note: Completed baseline receipt and feature provenance
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T20:46:20.855990503-04:00
WhatFor: ""
WhenToUse: ""
---

# Broad baseline results and failure attribution

## Measurement status

The full experiment completed with all 102,992 planned variants recorded. The selection contains 53,615 executable source files and 294 fixture files. All 53,968 recorded input fingerprints remained unchanged and the pinned Test262 checkout remained clean. The runner returned exit status 1 because non-passing tests exist; the report's `complete: true` establishes completion of the experiment, not conformance.

| Final classification | Variants |
|---|---:|
| Pass | 76,801 |
| Semantic failure | 19,598 |
| Unsupported | 6,584 |
| Timeout | 9 |
| Total | 102,992 |

No crash or infrastructure-error classification appears in this run. That observation is limited to this runner's classification and captured execution profile. The authoritative receipt and feature ledger are in `reference/evidence/full-baseline-summary.json`; every variant is retained in `full-baseline-results.jsonl`. The raw report SHA-256 is `ecdc48aa52b238b27d9976ef8e36114e966d50a6c0bf40fe57e6b21596f780e9`.

The nine runtime timeouts are preserved in this baseline. A separate single-worker experiment with a 120-second runtime budget rechecked their nine source files, producing 18 strict/sloppy variants: three passed and 15 reported semantic failures, with no timeouts. Among the nine originally timed-out strict variants, three passed and six reported semantic failures. The three passes are the two BMP comment loops and staging/sm/regress/regress-610026.js. Inputs remained unchanged. These results, retained in `reference/evidence/timeouts-before.json`, do not replace the original profile totals.

## What this experiment measures

The selection is the entire `test` directory in Test262 revision `0b4e0812022b18236b5276d2804948fdd9f71603`. It includes base-language tests, Annex B, internationalization tests, and features that may not belong to the pinned ECMAScript artifact. The result is an exploratory pinned-suite baseline. It is not an edition-qualified conformance percentage.

Each source is expanded into its required strictness or module variant. Fixture files are inventoried but not executed independently. Expected runtime and parse errors remain ordinary test contracts: a passing negative test must satisfy the expected error phase and type. Source-contract counts from the project's native regression suites use different units and are reported separately.

The host profile is Linux native execution, frontend O0 and LLVM O0. Compilation has a per-stage timeout of 60 seconds and execution has a timeout of 10 seconds. Sixteen independent workers run on the local host. The experiment does not establish isolated performance measurements, physical PicoCalc execution, or behavior at all optimization settings.

The recorded build disables Intl (`HERMES_ENABLE_INTL=OFF`), the Hermes VM JIT, and address/undefined-behavior/thread sanitizers. It enables Unicode RegExp property escapes and uses Hades GC with 64-bit heap values. Clang is Ubuntu 18.1.3; the independent Node oracle is 24.18.0. The compiler/runtime implementation is built in Release with `-O1 -DNDEBUG`; this is distinct from the tested program's frontend O0 / LLVM O0 profile. Locale/timezone and selected environment settings are recorded in `reference/evidence/host-profile.json`.

Consequently, failures caused by absent Intl in this experiment describe a disabled build capability, not proof that Hermes has no Intl implementation. Enabling that option would require a separately built and qualified profile. Historical sanitizer results from the imported release do not apply automatically to this local baseline.

## Result categories and their limits

A pass records agreement with the test's observable contract. It does not prove complete support for the feature named by the test. For example, an implementation can produce the expected error on one invalid declaration while still failing valid declaration cases. The result must be interpreted across the family rather than as a feature-level Boolean.

A semantic failure records a mismatch observed by the runner. It can reflect engine semantics, missing builtins, unavailable host services referenced by the test, or a harness completion problem. The raw commands and source references are needed to distinguish these causes. The existing runner's compile-stage unsupported category is conservative and also contains compiler diagnostics requiring review; it is not a list of specification-sanctioned exclusions.

Timeouts and crashes are distinct from language errors. A timeout under a contended host does not prove an infinite loop. Rechecking a timeout with a larger execution budget produces a separate experiment and must not silently rewrite the original profile's result. The initial partial run identified strict variants of the Annex B leading/trailing BMP RegExp escape cases as candidates for this review.

Explicit host boundaries include modules, cross-realm facilities, and agent/shared-memory requirements recognized by metadata. The initial host does not provide the complete $262 API. The summarizer lists textual helper references in failing source and harness files as investigation candidates; a reference in a comment or unused branch is not proof that the helper was invoked.

## Failure attribution from the completed inventory

The following grouping is mechanical triage. It assigns an observed stage and diagnostic category; it does not independently prove the root cause of every failure.

| Observed category | Variants |
|---|---:|
| semantic_failure / runtime: runtime failure requires inspection of retained command evidence | 19,454 |
| unsupported / compile: compiler diagnostic requires review | 2,126 |
| unsupported / compile: function exceeds 1024 combined root/argument-slot admission limit | 1,699 |
| unsupported / host/preparation: module loading/linking/evaluation is not implemented by this runner | 843 |
| unsupported / host/preparation: host capability unavailable: Atomics, SharedArrayBuffer | 486 |
| unsupported / host/preparation: host capability unavailable: SharedArrayBuffer | 436 |
| unsupported / host/preparation: host capability unavailable: cross-realm | 390 |
| unsupported / host/preparation: host capability unavailable: Atomics | 286 |
| unsupported / compile: unsupported instruction | 218 |
| semantic_failure / parse: stage failure requires inspection of retained command evidence | 144 |
| unsupported / host/preparation: host capability unavailable: IsHTMLDDA | 84 |
| timeout / runtime: runtime failure requires inspection of retained command evidence | 9 |
| unsupported / compile: direct eval in a derived constructor is not supported | 8 |
| unsupported / host/preparation: host capability unavailable: SharedArrayBuffer, cross-realm | 8 |

The 1,699 root-slot rejections are especially significant for baseline planning. The backend's 1,024 combined root/argument-slot bound can reject a large generated harness or fixture before the target operation executes. These records cannot establish whether the underlying builtin would otherwise pass. Raising the bound without reviewing native stack use would change a resource contract; an independent O-optimized profile or lifetime-based slot reuse is a more informative next experiment.

The 843 module-host rejections are explicit host boundaries. Two passing records under language/module-code do not establish module execution: source families also contain syntax contracts that can be satisfied without linking a module graph. Module resolution, linking, namespace objects, live bindings, cyclic execution, dynamic import, and top-level await still require implementation.

The largest non-passing families are listed below. Family paths are an organizational aid rather than an exact feature dependency graph.

| Family | Pass | Semantic failure | Unsupported | Timeout |
|---|---:|---:|---:|---:|
| `test/built-ins/Temporal` | 0 | 9,154 | 56 | 0 |
| `test/intl402/Temporal` | 0 | 3,130 | 928 | 0 |
| `test/language/expressions` | 19,469 | 350 | 1,467 | 0 |
| `test/built-ins/Atomics` | 0 | 10 | 768 | 0 |
| `test/language/statements` | 17,249 | 330 | 436 | 0 |
| `test/staging/sm` | 1,898 | 483 | 249 | 1 |
| `test/built-ins/TypedArray` | 2,208 | 660 | 22 | 0 |
| `test/language/module-code` | 2 | 0 | 600 | 0 |
| `test/built-ins/Array` | 5,545 | 530 | 44 | 0 |
| `test/built-ins/RegExp` | 3,254 | 100 | 402 | 0 |
| `test/intl402/NumberFormat` | 0 | 398 | 104 | 0 |
| `test/intl402/DateTimeFormat` | 0 | 442 | 48 | 0 |

Temporal and Intl-related records dominate this list. This build disables Intl, and catalog categories are not a substitute for edition review. The published feature ledger deliberately retains `edition_membership: unreviewed` alongside the exact pinned catalog category. A standards-qualified subset requires mapping each included feature to the captured specification and reviewing tests without feature metadata; this edition audit remains open.

## Runtime changes qualified before broad execution

The runtime build includes the strict-source admission change in `20fd0f6`. A sloppy caller can now directly evaluate source whose actual directive prologue requests strict mode. Parser-produced directive nodes determine admission, and the semantic resolver propagates the resulting strictness into nested functions. General non-strict direct evaluation still has an explicit rejection contract.

The targeted regression gates pass 22/22 core source contracts and 63/63 extension source contracts. The extension gate includes all four native optimization combinations and real lli for applicable cases. It separately checks directive lookalikes, closure lifetime, caller values, const/TDZ errors, and nested bytecode evaluation.

The exact same 474-variant eval selection improved from 381 passing variants to 390. There were nine failure-to-pass transitions and no pass-to-nonpass transitions. Seventy-six semantic failures and eight unsupported variants remain. These totals are owned by `reference/evidence/eval-comparison.json`, with full before/final evidence alongside it.

## Measured remaining eval problems

The direct-eval guard explains many non-strict cases, but it does not explain every remaining failure. Source inspection and the independent diagnostic probe establish separate work for global environment behavior. New globals introduced by indirect eval are non-configurable in this runtime, global lexical bindings created by native code are not visible to indirect eval, and strict indirect-eval var declarations remain visible globally. The probe records the exact outputs under Node and native execution.

`Interpreter::declareGlobalVarImpl` unconditionally clears the configurable flag. A correction must represent script declaration and eval declaration policy separately. Global lexical visibility requires shared runtime storage and ownership across compilation units, rather than ordinary-property fallback. Strict indirect evaluation needs its own declaration environment. None of these repairs follows from simply admitting more direct-eval strings.

General sloppy local evaluation also needs extensible binding storage and eval-sensitive identifier lookup. The existing Environment has fixed trailing slots and an ABI mirror used by native code. The proposed design in `design-doc/02-general-sloppy-eval-storage-and-compiler-integration.md` identifies allocation, tracing, semantic scope metadata, and compiler lowering requirements. It remains a design until those operations and tests are implemented.

## Evidence publication

The publication script rejects an incomplete report or inconsistent partition inventory. Git receives every variant's identity and status, the complete input fingerprint set, fixture inventory, summary counts, and representative failure commands. The complete raw JSON report is additionally retained as a compressed local build artifact with a digest in the receipt.

Representative failure samples are bounded by family, status, and observed phase. They are an entry point into the evidence, not a replacement for the complete result inventory. Feature provenance uses the pinned Test262 catalog while edition membership remains separately marked unreviewed. This prevents a current catalog label from being treated as proof about the captured specification artifact.

## Priorities after the baseline

The first priority is to review the largest failure groups and distinguish missing host services from engine defects. The second is to implement the measured eval environment changes under focused regression tests. General sloppy declaration injection requires a coordinated compiler/runtime change and should not be enabled before its binding and lifetime contracts are satisfied.

Modules, realms, and shared-memory agents need explicit host designs. Their current unsupported records provide a measured starting point but do not constitute implementation. The separate requested module follow-up should use this baseline's scope distinctions rather than interpreting every unsupported module test as a parser defect.
