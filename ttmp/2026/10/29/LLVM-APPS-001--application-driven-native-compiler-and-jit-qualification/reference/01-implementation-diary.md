---
Title: Implementation diary
Ticket: LLVM-APPS-001
Status: active
Topics:
    - llvm
    - javascript
    - application-qualification
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T10:50:35.044027808-04:00
WhatFor: ""
WhenToUse: ""
---

# Implementation diary

## Step 1: Create application workloads and run the library early

Created LLVM-APPS-001 and the application-qualification topic. Implemented the first data, asynchronous queue, and archive application sources and began with the third-party library to expose substantial compiler issues early.

### Prompt Context
**User prompt (verbatim):** "Ok, create a new topic, and do all 4 apps (including the thirdparty library).

Stay focused on the results, no need to be supercautious at each step, there is nothing to lose moving boldly and thus uncover bigger issues.

commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"

**Clarification (verbatim):** "create a new ticket and design doc, is what i meant. Then  write a detailed project report for the obsidian vault as a deep dive technical analysis blog post using a textbook writing style (no analogies, see skill).
 Commit and push the bsidian vault when done (go-go-parc vault).    when done"

### What I did
Created the ticket/design, pinned fflate 0.8.2 with pnpm, and wrote the first three applications. The library uses its original ESM browser source, with synchronous APIs that do not require a browser Worker implementation.

### Why
Real compression and streaming code exercises larger control-flow graphs and typed arrays than the targeted feature fixtures. Data and queue applications cover ordinary business logic, errors, allocation, timers, and asynchronous cleanup.

### What worked
Dependency installation and Node import of the selected distribution are being checked; application execution results will be recorded at the next checkpoint.

### What didn't work
No execution result is claimed yet. Existing engine limits remain in force until an application demonstrates a reason to change them.

### What I learned
The existing module compiler can use an exact relative import of the pinned dependency; a general package resolver is not needed for this experiment.

### What was tricky to build
Comparison must separate deterministic application results from nondeterministic task order and filesystem host APIs. Inputs will be injected consistently, while algorithms and parsing remain inside each engine.

### What warrants a second pair of eyes
Review the independent expected-result calculations, library byte identity, and handling of failure outcomes so the suite does not count an early exit as successful execution.

### What should be done in the future
Finish the persistent embedding app, run all four workloads across input scales, fix observed blockers, then write the vault report from the actual evidence.

### Code review instructions
Start at examples/llvm-apps and the ticket design. Inspect the dependency lock and library manifest before interpreting archive results.

### Technical details
Prior engine checkpoint d0037da; LLVM 18.1.3. Third-party pin fflate 0.8.2 is an explicit reproducibility choice, not a claim that it is the newest release.

## Step 2: Bound the delivery to ticket/design and publish the engine report

The user's clarification is treated as a ticket/design and report delivery. The earlier interpretation in Step 1 expanded this into immediate completion of all four apps; that implementation campaign remains open instead. Preserve the exploratory sources and their results without claiming completed applications. The new report explains the finished engine/JIT milestone and the proposed qualification campaign separately.

### Prompt Context
See the verbatim clarification in Step 1. This checkpoint corrects the earlier scope interpretation rather than rewriting its historical record.

### What I did
Expanded the design with architecture, input/output contracts, failure categories, pseudocode, file/API references, workload details, and implementation milestones. Added tasks and related primary files through docmgr. Preserved the archive input, raw outputs, graph check, and selected SHA-256 fingerprints. Added a reproduction script. Wrote a roughly 4,100-word textbook-style vault report from the completed engine/JIT diaries, source, operational guide, and receipts.

### Why
The user requested a concrete design and detailed project report. Separating completed engine evidence, preliminary experiments, and future application acceptance criteria prevents a planning document from implying a completed qualification campaign.

### What worked
`shllvm-jit -O --stats /tmp/app-input.js /tmp/archive-app.js` completed the archive probe, reporting 1,430 input bytes, 269 ZIP bytes, checksum 3522948978, successful streaming restoration, and malformed ZIP rejection. Dependency installation and Node import of the pinned distribution succeeded. The optimized library unit reported compile_ms=3379.48 and execute_ms=31.388 in this single observation.

### What didn't work
`shllvm-jit --stats /tmp/app-input.js /tmp/archive-app.js` rejected the bundle with `424:2482:direct LLVM backend: function exceeds 1024 combined root/argument-slot admission limit`. No compiler/runtime change was made. Data and queue drafts have not received their designed execution matrix; the persistent application and shared runner do not exist yet. No full third-party-library comparison is claimed.

### What I learned
The optimized frontend can admit this library under the unchanged frame bound. The rejected profile identifies an actionable capacity issue, but attributing the reduction to a specific optimization requires further IR inspection. Root-slot capacity and the already-fixed native unit-table capacity are independent constraints.

### What was tricky to build
The report must explain persistent code ownership, GC roots, module completion, and profile-dependent admission without conflating them. Timing from this one archive probe is not a benchmark or a throughput comparison. The initial drafts are explicitly labeled exploratory in their README.

### What warrants a second pair of eyes
Check report claims against Engine.cpp, Frontend.cpp, JITHost.cpp, and the completed JIT receipts. Check that all application implementation tasks remain unchecked and that the admission failure is preserved alongside the successful optimized run.

### What should be done in the future
Execute the design's milestones, beginning with a deterministic data application and shared runner. Implement the persistent host, investigate unoptimized frame pressure, and qualify all four workloads before closing this ticket.

### Code review instructions
Read the design, tasks, and examples README first. Inspect the retained raw archive outputs and input. The replay script expects the existing build and records both exit statuses without treating a rejection as a passing application. Review the report as an explanation of completed engine work and future application work.

### Technical details
Engine source baseline d0037da. The library remains pinned to fflate 0.8.2. The report's completed 48/48 JIT, 22/22 core, and 66/66 extension figures are historical validated receipts, not new runs during this documentation checkpoint. Current changes do not modify compiler or runtime behavior.
