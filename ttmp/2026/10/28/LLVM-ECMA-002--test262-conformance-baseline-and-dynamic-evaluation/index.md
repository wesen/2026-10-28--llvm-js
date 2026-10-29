---
Title: Test262 conformance baseline and dynamic evaluation
Ticket: LLVM-ECMA-002
Status: active
Topics:
    - llvm
    - javascript
DocType: index
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T19:53:27.553137174-04:00
WhatFor: ""
WhenToUse: ""
---

# Test262 conformance baseline and dynamic evaluation

This ticket continues LLVM-ECMA-001 at source commit `9985945`. It owns the next reproducible Test262 baseline, failure attribution, and incremental expansion of direct lexical evaluation. Full ECMAScript compatibility remains the larger program; this ticket must preserve unsupported cases in its results.

## Deliverables

- [Intern analysis, design, and implementation guide](design-doc/01-baseline-execution-and-dynamic-evaluation-implementation-plan.md).
- [Detailed implementation diary](reference/01-implementation-diary.md).
- [Tasks and acceptance work](tasks.md).
- Reproducible baseline results with explicit selection, build fingerprints, and failure categories.
- Validated dynamic-evaluation improvements, committed at coherent milestones.

## Starting evidence

The preceding ticket contains the [system guide](../LLVM-ECMA-001--ecmascript-conformance-architecture-and-intern-implementation-guide/design-doc/01-intern-guide-to-the-direct-llvm-runtime-and-ecmascript-conformance.md) and [implementation evidence](../LLVM-ECMA-001--ecmascript-conformance-architecture-and-intern-implementation-guide/reference/implementation-evidence/). Its final regression gates passed 22 core and 56 extension source contracts. These are targeted regressions, not full-suite conformance totals.

## Scope boundary

Inventory modules, realms, shared-memory capabilities, and other missing features, but implement this ticket's runtime changes around evaluation. Module loaders and agent execution require separate architectural work. Baseline completion and language-feature completion are separate acceptance decisions.
