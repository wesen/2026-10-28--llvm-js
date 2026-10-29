---
Title: Implementation diary
Ticket: LLVM-ECMA-002
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
LastUpdated: 2026-10-28T19:53:27.698270549-04:00
WhatFor: ""
WhenToUse: ""
---

# Implementation diary

## Step 1: Establish the follow-up ticket and intern guide

Created LLVM-ECMA-002 at implementation revision `9985945`, separating the next conformance measurement and evaluation work from the earlier release analysis. The guide explains current code, proposed changes, and acceptance criteria without treating the full-suite inventory as an execution result.

### Prompt Context
**User prompt (verbatim):** "Ok, create a new docmgr ticket to do the next conformance baseline and dynamic evaluation"

**Follow-up (verbatim):** "Create  a detailed analysis / design / implementation guide that is for a new intern, explaining all the parts of the system needed to understand what it is, with prose paragraphs and bullet point sand pseudocode and diagrams and api references and file references. It should be very clear and technical. Store in the ticket and the nupload to remarkable.


TGhen implement, commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"

**Assistant interpretation:** Publish the technical guide, then implement the scoped program in validated increments with a detailed diary.

### What I did
Created the ticket and two documents using docmgr. Read the runner, native eval descriptors, native bridge, runtime bytecode compilation, and interpreter direct-eval path. Consulted the specification and Test262 interpretation documentation. Authored the guide with dependency-ordered concepts, examples, diagrams, API contracts, and implementation phases.

### Why
Broad measurement requires scalable execution and truthful coverage accounting. Dynamic evaluation requires shared binding identity and retained context, so removing admission guards alone would be incorrect.

### What worked
The existing sources identify a narrow first semantic increment: strict evaluated strings from sloppy callers. General sloppy declarations remain a separate environment and lookup problem. Ticket creation and source inspection succeeded.

### What didn't work
An initial source search used two nonexistent public ABI paths; the actual eval ABI is local to `lib/BCGen/SH/LLVMNative/eval_extensions.h`. No runtime implementation or new baseline is claimed at this documentation checkpoint.

### What I learned
Both the native bridge and bytecode interpreter reject sloppy callers before inspecting string strictness. Nested eval requires considering both paths. The runner currently writes a complete growing report after each sequential execution.

### What was tricky to build
The scope contains distinct outcomes: a completed measurement, a qualified semantic increment, and eventual general dynamic binding support. The guide gives each its own acceptance criteria.

### What warrants a second pair of eyes
Review the proposed dynamic binding lookup ordering and the use of parser-derived strictness without losing caller syntax context.

### What should be done in the future
Upload the guide, implement scalable measurement, capture eval failures, and land validated evaluation improvements. Keep general sloppy binding storage and enclosing-context work open.

### Code review instructions
Start with the guide's architecture and source map, then compare its current-state descriptions with the existing runner and eval bridge. Use docmgr doctor for ticket hygiene.

### Technical details
Starting revision: `9985945`. Pinned Test262 revision: `0b4e0812022b18236b5276d2804948fdd9f71603`. Current suite profile remains exploratory because edition/proposal partitioning is incomplete.

### Step 1 delivery receipt

`docmgr doctor --ticket LLVM-ECMA-002 --stale-after 30` passed. `remarquee upload bundle` returned `OK: uploaded LLVM-ECMA-002-Intern-Guide.pdf -> /ai/2026/10/28/LLVM-ECMA-002`. This confirms cloud delivery, not physical device synchronization. The guide contains prose, three text diagrams, pseudocode, an API/source reading map, implementation phases, and validation contracts.

## Step 2: Scale execution and capture the eval baseline

The guide was committed as `466c481`. Implemented bounded worker scheduling, stable source partitioning, configurable report checkpoints, compact passing records, and protection against replacing experiment inputs. Captured the unchanged-runtime eval baseline before any semantic edit.

### Prompt Context
See Step 1. The user subsequently asked to finish this work before starting the vault report and module follow-up.

### What I did
Added runner options for jobs, shard count/index, checkpoint interval, and compact output. Added tests for disjoint complete partitions, ordering independence, worker bounds, exception propagation, and output aliases. Ran the existing native eval builtins with one and four workers and compared test/variant/status identities. Executed `test/language/eval-code test/built-ins/eval` with eight workers.

### Why
Sequential execution and complete JSON rewrites after every result would make larger profiles unnecessarily expensive. Each worker still owns an independent directory and executable; only the coordinator writes the report.

### What worked
All 16 runner unit tests passed. Both serial and parallel builtin runs completed with 20/20 passing variants and identical identities/statuses. The pre-change eval run completed with stable inputs: 474 variants, 381 pass, 85 semantic failure, 8 unsupported. Its nonzero exit is expected because failures remain, while its report completion flag is true.

### What didn't work
The eval baseline exposes language failures; no skip list was added. There were no scheduling test failures. General full-suite aggregation and edition membership remain separate work.

### What I learned
The dedicated eval-code family has 474 variants together with eval builtins; other eval-dependent tests exist elsewhere and must be included in the broad profile. Completing this family does not mean all eval semantics are covered.

### What was tricky to build
Physical output aliases, including hardlinks and the temporary JSON publication path, can otherwise overwrite an input despite different path strings. Protection tests preserve original input bytes. Stable partitioning uses the suite-relative path rather than Python's randomized hash.

### What warrants a second pair of eyes
Review report completion on worker exceptions and aggregate validation before combining partitions. The fingerprint set covers the full selected file set, not only one partition.

### What should be done in the future
Implement and test strict-source admission, then run the broad baseline on the resulting immutable build. Add a checked report aggregator before publishing partition totals.

### Code review instructions
Read `bounded_results`, `shard_paths`, and `protect_output`, followed by SchedulingTests. Reproduce the eval baseline with explicit suite/build/tool paths and `--jobs 8 --compact`.

### Technical details
Pre-change results are in `reference/evidence/eval-before.json`. The exact command selected `test/language/eval-code test/built-ins/eval` at frontend O0 / LLVM O0. `/tmp/llvm-002-serial.json` and `/tmp/llvm-002-parallel.json` are local integration receipts; their status equivalence was checked in Python.
