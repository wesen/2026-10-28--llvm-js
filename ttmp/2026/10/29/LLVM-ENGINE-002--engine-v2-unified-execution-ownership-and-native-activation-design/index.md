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

The earlier proposals design a parallel engine-v2 integration with shared Hermes language/runtime semantics, engine-owned activation storage, local code identity, one module registry, and explicit job pumping. The detailed design is delivered; implementation remains open.

Read [the intern implementation guide](design-doc/01-engine-v2-architecture-and-intern-implementation-guide.md) and [the investigation diary](reference/01-design-investigation-diary.md). The current engine remains runnable as a reference; no directory has been moved or archived.

The second design, [Composable compiler language](design-doc/02-composable-compiler-language-grammar-effects-ownership-and-hermes-llvm-integration.md), defines the grammar, effect and ownership contracts, IR levels, provider composition, and concrete integration. Its original proposed implementation order was: establish the small core grammar before the activation/emitter vertical slice.

## Current research assignment

The [research-informed redesign and seminar handoff](design-doc/03-research-informed-redesign-and-graduate-seminar-handoff.md) is the current assignment. Study and revise or replace the design before implementing it. Earlier implementation phases remain historical proposals pending this design review. The brief adds fundamental underpinnings, a staged path toward a custom system, and independently reusable subsystem contracts.

The [package entry point](handoff/01-START-HERE.md) describes the handoff. Build the ZIP with `python3 ttmp/2026/10/29/LLVM-ENGINE-002--engine-v2-unified-execution-ownership-and-native-activation-design/scripts/01-build-seminar-package.py` from the repository root. The generated package contains the full tracked source at the pinned baseline, all three guides, templates, and verification metadata. Generated archives are intentionally not committed.

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
