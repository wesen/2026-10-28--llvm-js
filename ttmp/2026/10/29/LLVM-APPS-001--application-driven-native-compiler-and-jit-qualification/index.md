---
Title: Application driven native compiler and JIT qualification
Ticket: LLVM-APPS-001
Status: complete
Topics:
    - llvm
    - javascript
    - application-qualification
DocType: index
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T11:33:00.904555912-04:00
WhatFor: ""
WhenToUse: ""
---

# Application driven native compiler and JIT qualification

## Overview

Implemented four application workloads: data processing, an asynchronous queue, a persistent C++ embedding host, and pinned fflate compression. Final qualification: **96 successful executions, nine known unoptimized library admission boundaries, zero unexpected failures**. Input/build fingerprints stayed unchanged. The root-slot boundary remains assigned to LLVM-MODULES-002 M08.

Read [the results](analysis/01-application-qualification-results-and-remaining-boundaries.md), [the design](design-doc/01-four-application-workloads-and-results-driven-qualification.md), and [the detailed diary](reference/01-implementation-diary.md). Run the command documented in `hermes/examples/llvm-apps/README.md` to reproduce the campaign.

## Key Links

- **Related Files**: See frontmatter RelatedFiles field
- **External Sources**: See frontmatter ExternalSources field

## Status

Current status: **complete** (bounded application campaign; M08 remains open in LLVM-MODULES-002).

## Topics

- llvm
- javascript
- application-qualification

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
