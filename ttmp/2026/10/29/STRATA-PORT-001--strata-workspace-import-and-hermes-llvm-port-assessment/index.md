---
Title: Strata workspace import and Hermes LLVM port assessment
Ticket: STRATA-PORT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: index
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: "Complete Strata workspace import and assessment of its Hermes/LLVM porting guides."
LastUpdated: 2026-10-29T20:26:38.976987118-04:00
WhatFor: ""
WhenToUse: ""
---

# Strata workspace import and Hermes LLVM port assessment

## Import and findings

The [assessment](analysis/01-workspace-inventory-and-hermes-llvm-port-findings.md) identifies the porting documents, implementation status, conflicting migration directions, and concrete corrections.

Read the [imported intern guide](reference/02-imported-strata-hermes-llvm-intern-guide.md). The full ZIP is preserved under `archive/strata-workspace-full.zip`; the extracted tree is `source/`. Recreate it with `python3 scripts/01-import-workspace.py` from this ticket directory. Hashes are in `reference/import-manifest.json`; the [diary](reference/01-import-and-investigation-diary.md) records the investigation.

## Overview

Import and inspection are complete. The native port remains proposed. The archive contains both an older Hermes-emitter improvement plan and a later Strata-first plan; the assessment distinguishes them and identifies integration corrections before any implementation.

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
