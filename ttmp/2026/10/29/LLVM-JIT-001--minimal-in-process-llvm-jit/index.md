---
Title: Minimal in-process LLVM JIT
Ticket: LLVM-JIT-001
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
LastUpdated: 2026-10-29T09:32:28.913562973-04:00
WhatFor: ""
WhenToUse: ""
---

# LLVM-JIT-001

Implement a persistent in-process baseline LLVM JIT in two checkpoints: emitted-IR execution, then reusable source compilation. The design exists; neither checkpoint has been implemented by this ticket.

## Documents

- [Design](design-doc/01-baseline-in-process-jit-implementation-and-qualification.md)
- [Diary](reference/01-implementation-diary.md)
- [Tasks](tasks.md)

## Dependencies and scope

- LLVM-ENGINE-001 owns the architecture and lifetime contract.
- Coordinate pending async completion with M01 in LLVM-MODULES-002.
- Existing LLVM-MODULES-001 graphs provide bundled-module regression fixtures.

## Current state

Planning artifacts are complete. Execution tasks remain open; no engine or follow-up feature is claimed implemented by this documentation change.

## Related tickets

- [LLVM-MODULES-002](../LLVM-MODULES-002--module-host-follow-up-backlog-and-bounded-improvements/index.md)
- [LLVM-ENGINE-001](../LLVM-ENGINE-001--practical-native-engine-and-jit-architecture/index.md)
