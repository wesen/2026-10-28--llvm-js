---
Title: Import and investigation diary
Ticket: STRATA-PORT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T20:26:47.626728688-04:00
WhatFor: ""
WhenToUse: ""
---

# Import and investigation diary

## Step 1: Import the returned Strata workspace and locate the porting plan

Imported the complete archive into STRATA-PORT-001 and inspected the primary guide, supporting porting chapters, session records, workbench source, and representative bridge definitions in our existing fork. The archive contains a substantial workbench, while real Hermes/LLVM execution remains proposed.

### Prompt Context
**User prompt (verbatim):** "ok, now look at ~/Downloads/strata-workspace-full.zip, and import it into a new docmgr ticket, and check if you find the documents on how to port strata against hermes and llvm. Then report back to me abut wha tyou found"

### What I did
Created the ticket, preserved the ZIP, extracted all 1,083 regular files, recorded hashes, imported the main guide as a searchable docmgr reference, and wrote the findings analysis. Inspected helper signatures, source paths, link flags, content counts, and proposed-file presence without executing imported code.

### Why
The user needs to know whether the returned work contains an actionable porting plan and what is implemented versus prospective. A byte-preserving import keeps the supplied material distinct from local assessments.

### What worked
Found the exported intern guide and two relevant textbook chapters plus supporting backend documentation. Confirmed the later Strata-first direction through the reconstructed session summary, and found the older incremental-Hermes plan in Chapter 21. Verified representative ABI mismatch directly against runtime.h. ZIP CRC and per-file hash checks preserve import identity.

### What didn't work
The first broad archive listing exceeded the output limit; subsequent inspection used focused paths and bounded reads. An attempted read of `hermes/tools/shllvm-jit/CMakeLists.txt` failed because that file does not exist; the executable targets are defined in `hermes/tools/shermes/CMakeLists.txt`. No imported harness was run, so its historical totals are not local verification results.

### What I learned
The guide acknowledges illustrative helper bindings and describes the missing native files explicitly. It is a concrete implementation proposal, not an already working native compiler. Its simple link command omits build-dependent sanitizer flags that our driver supplies.

### What was tricky to build
Imported Markdown includes heterogeneous metadata and generated assets. Preserved raw bytes under archive/, excluded that subtree from docmgr scanning, and registered a separate frontmatter-bearing copy of the primary guide. Git retains the original archive and extraction script rather than duplicating generated site assets.

### What warrants a second pair of eyes
Review native root/argument lifetime, exceptional restoration, contract narrowing, and the guide's excessively strong checker-versus-runtime equivalence requirement. Reconcile the two migration strategies before planning implementation.

### What should be done in the future
Select the desired porting direction, audit ABI contracts against current source, and define a bounded first execution milestone. This turn does not authorize or perform the port.

### Code review instructions
Read the analysis first, then the imported guide sections 9–14 and Chapter 21 section 21.5. Inspect the import manifest and rerun scripts/01-import-workspace.py to reconstruct and verify the raw tree. Compare the illustrative constant declaration with runtime.h and the link command with utils/shllvm.py.

### Technical details
The receipt records ZIP and per-file SHA-256 identities. All archive paths were checked for absolute/traversal entries and symlinks before extraction. Native code, dependencies, browser services, and imported helper scripts were not executed. External research was unnecessary for locating and comparing these local artifacts.

## Step 2: Validate the import and ticket

The extraction script verified the original ZIP SHA-256, CRCs, file inventory, and all 1,083 extracted file hashes. `docmgr doctor --ticket STRATA-PORT-001 --stale-after 30` passed. No imported checks were executed. The full archive, registered guide, findings, manifest, and restoration script are the deliverables.
