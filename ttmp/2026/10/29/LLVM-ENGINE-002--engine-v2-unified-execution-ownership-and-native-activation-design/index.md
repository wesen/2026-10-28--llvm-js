---
Title: Engine v2 unified execution ownership and native activation design
Ticket: LLVM-ENGINE-002
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
LastUpdated: 2026-10-29T12:12:00.436167987-04:00
WhatFor: ""
WhenToUse: ""
---

# Engine v2 unified execution ownership and native activation design

## Overview

Design a parallel engine-v2 integration with shared Hermes language/runtime semantics, engine-owned activation storage, local code identity, one module registry, and explicit job pumping. The detailed design is delivered; implementation remains open.

Read [the intern implementation guide](design-doc/01-engine-v2-architecture-and-intern-implementation-guide.md) and [the investigation diary](reference/01-design-investigation-diary.md). The current engine remains runnable as a reference; no directory has been moved or archived.

## Key Links

- **Related Files**: See frontmatter RelatedFiles field
- **External Sources**: See frontmatter ExternalSources field

## Status

Current status: **active**

## Topics

- llvm
- javascript

## Tasks

See [tasks.md](./tasks.md) for the current task list.

## Changelog

See [changelog.md](./changelog.md) for recent changes and decisions.

## Structure

- design/ - Architecture and design documents
- reference/ - Prompt packs, API contracts, context summaries
- playbooks/ - Command sequences and test procedures
- scripts/ - Temporary code and tooling
- various/ - Working notes and research
- archive/ - Deprecated or reference-only artifacts
