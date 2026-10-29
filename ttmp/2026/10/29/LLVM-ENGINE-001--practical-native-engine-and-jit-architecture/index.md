---
Title: Practical native engine and JIT architecture
Ticket: LLVM-ENGINE-001
Status: complete
Topics:
    - llvm
    - javascript
DocType: index
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T10:02:50.368917451-04:00
WhatFor: ""
WhenToUse: ""
---

# LLVM-ENGINE-001

Define a practical AOT and baseline JIT engine: one runtime, one owner thread, runtime-lifetime native code, and explicit supported-language boundaries. Architecture design is written; runtime linkage and frontend extraction still need implementation probes.

## Documents

- [Design](design-doc/01-engine-architecture-scope-ownership-and-execution-contracts.md)
- [Diary](reference/01-implementation-diary.md)
- [Tasks](tasks.md)

## Dependencies and scope

- LLVM-JIT-001 implements this contract.
- LLVM-MODULES-002 records optional module follow-ups; most are not prerequisites.
- LLVM-ECMA-002 remains the owner of deeper dynamic-evaluation work.

## Current state

Planning artifacts are complete. Execution tasks remain open; no engine or follow-up feature is claimed implemented by this documentation change.

## Related tickets

- [LLVM-MODULES-002](../LLVM-MODULES-002--module-host-follow-up-backlog-and-bounded-improvements/index.md)
- [LLVM-JIT-001](../LLVM-JIT-001--minimal-in-process-llvm-jit/index.md)
