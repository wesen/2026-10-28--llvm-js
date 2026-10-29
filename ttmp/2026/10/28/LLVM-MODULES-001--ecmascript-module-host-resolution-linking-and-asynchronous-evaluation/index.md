---
Title: ECMAScript module host resolution linking and asynchronous evaluation
Ticket: LLVM-MODULES-001
Status: complete
Topics:
    - llvm
    - javascript
DocType: index
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/lib/IRGen/ESTreeIRGen-stmt.cpp
      Note: Existing CommonJS lowering and its live-binding limitation
    - Path: repo://hermes/utils/shllvm.py
      Note: Driver integration point
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T22:53:01.229504205-04:00
WhatFor: ""
WhenToUse: ""
---

# ECMAScript module host resolution linking and asynchronous evaluation

## Overview

Implemented a closed filesystem module host compiled through Hermes and LLVM: lexical live bindings, export resolution, cyclic linking/evaluation, namespaces, dynamic imports, and top-level await. See the [implementation guide](design-doc/01-module-host-architecture-and-implementation-guide.md), [diary](reference/01-implementation-diary.md), and [operational contract](../../../../../hermes/docs/llvm/MODULES.md). Explicit unsupported contracts and qualification counts are recorded with retained evidence.

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
