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

Validated the practical native-engine architecture: one runtime, one owner thread, runtime-lifetime code, request-scoped frontend compilation, and explicit supported-language boundaries. Decisions and probe evidence are complete.

## Documents

- [Design](design-doc/01-engine-architecture-scope-ownership-and-execution-contracts.md)
- [Diary](reference/01-implementation-diary.md)
- [Tasks](tasks.md)

## Dependencies and scope

- LLVM-JIT-001 implements this contract.
- LLVM-MODULES-002 records optional module follow-ups; most are not prerequisites.
- LLVM-ECMA-002 remains the owner of deeper dynamic-evaluation work.

## Current state

Architecture decisions validated by a two-unit LLJIT probe and committed as 5932980. Shared runtime linkage, lifetime ordering, frontend boundary, and completion contracts are recorded; implementation is delivered by LLVM-JIT-001.

## Related tickets

- [LLVM-MODULES-002](../LLVM-MODULES-002--module-host-follow-up-backlog-and-bounded-improvements/index.md)
- [LLVM-JIT-001](../LLVM-JIT-001--minimal-in-process-llvm-jit/index.md)
