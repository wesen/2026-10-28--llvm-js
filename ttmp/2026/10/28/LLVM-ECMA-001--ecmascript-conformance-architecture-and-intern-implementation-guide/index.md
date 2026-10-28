---
Title: ECMAScript conformance architecture and intern implementation guide
Ticket: LLVM-ECMA-001
Status: active
Topics:
    - llvm
    - javascript
DocType: index
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: "Evidence-backed onboarding and implementation planning for ECMAScript conformance."
LastUpdated: 2026-10-28T18:29:06.66270878-04:00
WhatFor: "Understand the existing backend and plan measurable conformance work."
WhenToUse: "Onboarding, architecture review, and implementation planning."
---

# ECMAScript conformance architecture and intern implementation guide

This ticket delivers an intern-oriented architecture and implementation plan for the verified direct LLVM JavaScript release. Documentation is complete and conformance implementation is active. The detailed diary records committed runner, metadata, arguments-binding, and runtime-error-timing milestones; the remaining roadmap stays open.

## Documents

- [Intern architecture and conformance guide](design-doc/01-intern-guide-to-the-direct-llvm-runtime-and-ecmascript-conformance.md)
- [Research ledger](reference/01-research-ledger-and-evidence-inventory.md)
- [Investigation diary](reference/02-investigation-diary.md)
- [Tasks](tasks.md)
- [Changelog](changelog.md)

## Scope

Explain the existing source and runtime, identify evidenced boundaries, define a measurable conformance program, and upload the guide plus research ledger as one reMarkable document. The user subsequently authorized implementation. Compiler/runtime work and its validation now continue in this ticket; full ECMAScript conformance and device deployment are not yet established. The remaining backlog is preserved in the guide and tasks.
