---
Title: Minimal in-process LLVM JIT
Ticket: LLVM-JIT-001
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
LastUpdated: 2026-10-29T10:27:50.293399773-04:00
WhatFor: ""
WhenToUse: ""
---

# LLVM-JIT-001

Implemented a persistent in-process baseline LLVM JIT with verified IR loading and reusable source compilation. Both checkpoints are qualified within the documented practical profile.

## Documents

- [Design](design-doc/01-baseline-in-process-jit-implementation-and-qualification.md)
- [Diary](reference/01-implementation-diary.md)
- [Tasks](tasks.md)

## Dependencies and scope

- LLVM-ENGINE-001 owns the architecture and lifetime contract.
- Coordinate pending async completion with M01 in LLVM-MODULES-002.
- Existing LLVM-MODULES-001 graphs provide bundled-module regression fixtures.

## Current state

Implemented the persistent source/IR JIT in 999c830. Focused qualification passes 48/48; existing core and extension gates pass 22/22 and 66/66. See hermes/docs/llvm/JIT.md for commands, API, and practical limits.

## Related tickets

- [LLVM-MODULES-002](../LLVM-MODULES-002--module-host-follow-up-backlog-and-bounded-improvements/index.md)
- [LLVM-ENGINE-001](../LLVM-ENGINE-001--practical-native-engine-and-jit-architecture/index.md)
