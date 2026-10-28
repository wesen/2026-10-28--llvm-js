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
