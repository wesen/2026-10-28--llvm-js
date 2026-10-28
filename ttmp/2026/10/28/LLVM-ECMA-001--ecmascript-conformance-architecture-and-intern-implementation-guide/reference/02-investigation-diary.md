---
Title: Investigation diary
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
LastUpdated: 2026-10-28T18:29:07.070544628-04:00
WhatFor: "Understand the existing backend and plan measurable conformance work."
WhenToUse: "Onboarding, architecture review, and implementation planning."
---

# Investigation diary

## 2026-10-28 — Request and scope

The user requested a new docmgr ticket and a detailed intern-oriented analysis, design, and implementation guide, followed by reMarkable upload. The user also stated: “We want to make this setup fully ecmascript compatible, so do your diligent research as well.” The deliverable is a researched implementation plan; this ticket does not change runtime semantics.

I used the docmgr, ticket-research-docmgr-remarkable, textbook-authoring, remarkable-upload, and git-commit-instructions skills. The repository already had `.ttmp.yaml` and vocabulary configuration, with zero tickets, so initialization was unnecessary. Created `LLVM-ECMA-001` and three documents with `docmgr ticket create-ticket` and `docmgr doc add`.

## Access failure and recovery

Initial shell commands produced no output and eventually reported a bubblewrap bind-mount failure for `/newroot/mnt/pico`: “No such device.” A minimal escalated `/bin/pwd` succeeded. Subsequent authorized local documentation operations used escalated execution to bypass the broken sandbox mount. This was an environment failure, not a repository failure or an approval rejection.

An initial source search used `hermes/lib/BCGen/LLVMNative/LLVMBackend.cpp`, which does not exist. `rg --files` located the actual path under `hermes/lib/BCGen/SH/LLVMNative/`. The guide and its reference table use the corrected paths.

## Source inspection and research

Read the compiler bridge headers, emitter admission check, eval descriptors, generator/async source anchors, inherited Test262 preprocessing, runner execution, and skip policy. The key new finding was the unconditional module skip before feature filtering in `test_run_defs.py`. The inherited permanent exclusions and stale-looking species exclusion also require explicit re-evaluation.

Consulted the edition-specific ECMA-262 pages and official Test262 interpretation and runner documentation. Chose a proposed ECMAScript 2026 host64 baseline while explicitly retaining the snapshot's draft identity and the need to lock a Test262 revision. No entire external suite was downloaded or run; no new conformance percentage was inferred.

## Authoring and review

Wrote a 21-chapter guide with foundational prose, a worked closure example, three Mermaid diagrams, existing ABI declarations, proposed API and runner pseudocode, gap analysis, four decision records, seven implementation phases, source references, and exercises. The research ledger separates direct observations from proposals and outstanding measurements. Proposed behavior is not represented as implemented code.

Validation and upload results are recorded below after finalization.

## Documentation validation

The first reference-audit run used an incorrect fixed parent depth and therefore reported every path missing. Changed it to locate the ancestor containing `.ttmp.yaml`; the rerun checked 24 source/document paths with no missing entries and confirmed balanced fences and three Mermaid diagrams. This was a validation-script path error, not missing source. `docmgr doctor --ticket LLVM-ECMA-001 --stale-after 30` passed all checks. `git diff --check` also passed.

Started the requested bundle upload in the `llvm-ecma-upload` tmux session using `remarquee upload bundle`, guide first and research ledger second, with a depth-two table of contents. The destination is `/ai/2026/10/28/LLVM-ECMA-001`, document name `LLVM-ECMA-001-Intern-Guide`. No overwrite flag was used.

## Delivery

The uploader exited 0 and returned: `OK: uploaded LLVM-ECMA-001-Intern-Guide.pdf -> /ai/2026/10/28/LLVM-ECMA-001`. The receipt records hashes of both uploaded Markdown inputs. This proves successful cloud delivery, not physical device synchronization. The tmux session had exited when subsequently queried, consistent with command completion. No extra cloud listing or overwrite was needed.

All requested documentation tasks are complete. The proposed conformance implementation backlog remains unchecked. No compiler/runtime source was changed during this ticket.

## Step 1: Start the LLVM conformance runner and trustworthy exception reporting

The implementation begins with the first milestone in the guide: a pinned Test262 runner that keeps unsupported behavior and infrastructure failures visible. Reading the native exception printer exposed a false-pass risk: a thrown string or a modified stack could resemble a TypeError diagnostic. I therefore added an opt-in native host path that inspects the actual thrown object's constructor name.

### Prompt Context
**User prompt (verbatim):** "Then once done, implement and commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"
**Assistant interpretation:** Begin the implementation roadmap, validate meaningful milestones, and commit with detailed ongoing evidence.
**Inferred user intent:** Make measurable progress toward full ECMAScript compatibility without losing implementation history.

### What I did
- Fetched official Test262 into `/tmp/llvm-test262`; pinned `0b4e0812022b18236b5276d2804948fdd9f71603` and the interpretation document hash.
- Added `test_shllvm_test262.py`, an explicit LLVM script runner with per-stage commands/results and no inherited skip list.
- Added an opt-in `--shllvm-test262` native host switch and `test262_extensions.cpp` to inspect thrown constructor names.
- Added adversarial runner tests; `python3 hermes/utils/test_shllvm_test262_runner.py` passed 11 tests.

### Why
Expected-error tests must not pass because LLVM compilation crashed or because an arbitrary string resembled an exception. A dedicated reporter avoids wrapping test source in a function, which would alter global and lexical semantics.

### What worked
The suite clone completed successfully. The Python tests cover wrong error type/phase, signals, sanitizers, missing executables, timeouts, missing/duplicate async completion, raw source preservation, include containment, and explicit host boundaries.

### What didn't work
`cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4` failed compiling the new helper: `test262_extensions.cpp:26:48: error: indirection requires pointer operand ('PseudoHandle<>' invalid)`. The property-read API returns a CallResult containing PseudoHandle; double dereference is invalid. Corrected handle creation to use `getHermesValue()` and restarted the narrow build.

### What I learned
The current native host already supplies global/evalScript/detachment hooks but does not provide the entire Test262 host. Parser-only negatives also cannot yet establish all semantic early-error behavior. Those limitations belong in the report.

### What was tricky to build
The exception value returned by guarded initialization must become a rooted handle before property access can allocate. Constructor/name getters can themselves throw; such results must be invalid diagnostics rather than a substitute expected exception. The opt-in switch is removed before runtime option parsing and is not consumed after the script-argument separator.

### What warrants a second pair of eyes
Review rooted-handle lifetime and the exception reporter's interaction with user-defined constructor/name getters. Review strictness variant preparation and whether negative-phase classification can produce false positives.

### What should be done in the future
Run real pinned Test262 cases, add native reporter regression probes, and measure larger family failures. Modules, agents, realms, semantic early errors, and structured asynchronous exceptions remain separate work.

### Code review instructions
Start with `utils/test_shllvm_test262.py`, then `LLVMNative/test262_extensions.cpp` and `runtime.c`. Run the Python test module before native integration checks.

### Technical details
The runner invokes parser, LLVM emission, assembly, verification/optimization, linking, and native execution separately. Reports preserve commands, stdout/stderr, durations, input/artifact hashes, selected suite revision, and explicit unsupported reasons. No source is silently executed through a bytecode fallback.

## Step 2: Validate and commit the first runnable conformance milestone

The corrected native helper built successfully. Fourteen native adversarial probes matched their expected classifications, and the unchanged default execution path passed the full core and extension gates. A first real upstream selection produced a complete, fingerprint-stable baseline: 348 passing variants, four semantic failures, and one explicit unsupported compilation among 353 variants from 200 source files.

### Prompt Context
See Step 1 for the verbatim implementation request. This checkpoint completes the initial runnable runner and measures the next source-level work; it does not complete the whole conformance roadmap.

### What I did
- Ran `python3 hermes/utils/test_shllvm_test262_runner.py`: 11 tests passed.
- Ran `test_shllvm_test262_native.py` with the pinned suite and explicit build/tool paths: all 14 synthetic probes matched.
- Ran `test_shllvm.py` and `test_shllvm_extensions.py` with `--jobs 3`, without quick mode, case filters, or JIT skipping: 22/22 and 53/53 source contracts passed.
- Ran the new Test262 runner over `test/language/statements/variable` and `test/language/expressions/await` at frontend O0 / LLVM O0.
- Added `hermes/docs/llvm/TEST262.md` and persisted baseline/probe evidence in `reference/implementation-evidence/`.

### Why
The native host change needed both adversarial opt-in coverage and the established default-host regression gates. A broad family selection provides better next-step evidence than isolated handpicked successes.

### What worked
The full extension gate completed with 200 native and 50 real lli executions, unchanged fingerprints, and no failed cases. The new baseline completed with no changed inputs and a clean pinned suite.

### What didn't work
The first smoke run used `-dump-ast` for a strict `arguments` binding early error and incorrectly observed no parser rejection. Changed the command to `-dump-transformed-ast`, which includes semantic validation; that upstream case then passed. A separate HTML-comment probe failed native compilation with `error: invalid expression (possible JSX: pass -parse-jsx to parse)`; it remained unsupported rather than being counted as an expected runtime error.

The complete variable/await baseline failed `12.2.1-11.js`, `12.2.1-17-s.js`, `S12.2_A5.js`, and sloppy `cptn-value.js`, each with `SHLLVM_TEST262_EXCEPTION:SyntaxError`. `binding-resolution.js` was unsupported with `error: with statement is not supported`. Source inspection identified the Function-body case as the explicit sloppy arguments-assignment prohibition; the other failures involve currently restricted sloppy eval.

### What I learned
The baseline can separate delivered async behavior from remaining dynamic-scope behavior. Its 348 passes are selected variant results, not an ECMAScript-wide percentage. The native reporter protects negative cases against string/stack spoofing, while asynchronous uncaught-error identity remains an explicit limitation.

### What was tricky to build
Timeout handling now kills complete process groups; captured output uses temporary files and a one-MiB per-stream reporting limit. Input fingerprinting includes the driver, metadata parser, compiler/runtime binaries, build configuration, tool binaries, selected sources, and harness files.

### What warrants a second pair of eyes
Review the frontend-only early-error boundary, host capability exclusions, and separation of real suite results from synthetic runner probes.

### What should be done in the future
Fix mutable sloppy arguments bindings first, then expand the measured baseline and prioritize dynamic environments. Specification artifact digest pinning and edition/proposal partitioning remain open.

### Code review instructions
Read `docs/llvm/TEST262.md`, the Python runner/classifier, and the opt-in runtime path. Reproduce the two selected directories with the command in that document. Evidence retains every baseline variant and full failure commands; successful stdout/stderr is omitted from the compact committed baseline.

### Technical details
Pinned suite: `0b4e0812022b18236b5276d2804948fdd9f71603`. Baseline: 353 variants, 348 pass, 4 semantic_failure, 1 unsupported. The native probe evidence has a separate schema and does not inflate these totals.
