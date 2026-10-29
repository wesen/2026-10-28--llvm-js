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

## Step 3: Implement all four runnable applications and the first comparison matrix

Implemented the application runner and persistent native host, then ran the complete small-input matrix. Sixteen executions passed; two unoptimized fflate compilation attempts hit the already documented admission boundary. These two cases are explicitly classified as boundaries and are not included in the passing count.

### Prompt Context
**User prompt (verbatim):** "Implement, commit at appropriate intervals and keep a detailed diary as you work (using the diary format from the skill)"
**Assistant interpretation:** Implement LLVM-APPS-001 with all four workloads and retain meaningful evidence and intermediate commits.

### What I did
Added `hermes/utils/qualify_shllvm_apps.py`, a C++ persistent manifest host, its CMake target, and independent Node corpus replay. The data and queue fixtures have Python-computed expectations. Archive output includes actual ZIP/gzip bytes, decoded independently using Python standard-library readers. Added timeout process-group cleanup and source/binary/fixture fingerprints to the runner after the initial run.

### Why
The application algorithms must execute in JavaScript while result comparison remains independent. A persistent host must reuse one engine and recover after errors, so repeatedly invoking the CLI is insufficient. Independent binary decoding strengthens same-library round-trip checks.

### What worked
`python3 hermes/utils/qualify_shllvm_apps.py --sizes small --repeat 1 --output /tmp/llvm-app-small.json` completed with 16 passes and 2 known admission boundaries. Data and queue ran under Node and both frontend profiles in JIT and AOT modes. The persistent corpus ran in Node and both native profiles, publishing closures, forcing GC after each admitted submission, recovering from parse/initializer errors, and draining delayed callbacks. Optimized archive execution matched Node and passed independent Python ZIP/gzip decoding.

### What didn't work
The initial sandboxed tmux command returned `error connecting to /tmp/tmux-1000/default (Operation not permitted)`; the authorized escalated command built successfully. Both unoptimized archive modes reported `function exceeds 1024 combined root/argument-slot admission limit`. Added root/argument counts to the compiler diagnostic; rebuilding those targets is the next checkpoint. No cap change or library trimming was introduced.

### What I learned
The existing engine supports a useful persistent plugin application without a new host value API. The small matrix found no new semantic mismatch. Archive compilation pressure remains a profile-specific admission limit, while optimized output is usable.

### What was tricky to build
Asynchronous module completion must be checked separately from an exit status. Node/AOT require the explicit marker; JIT uses host completion tokens. The persistent final report runs in a delayed callback after previously registered timers. Native GC occurs before callbacks run, exercising captured state retention.

### What warrants a second pair of eyes
Review independent fixture expectations, the distinction between intentional failures and arbitrary failures, timeout cleanup of child processes, and whether binary-format oracle comparisons inspect actual bytes. The persistent corpus must retain pre-throw side effects rather than assuming transactional initialization.

### What should be done in the future
Finish diagnostic rebuild, run larger and repeated inputs, strengthen harness failure checks where needed, and publish exact results and limitations.

### Code review instructions
Start at qualify_shllvm_apps.py and persistent-host/main.cpp. Replay the small command above; run shllvm-jit-test after the compiler diagnostic rebuild. Initial receipts are archived as small-initial.json.gz.

### Technical details
The initial campaign ran against the pre-diagnostic binaries. The runner was subsequently improved, so its archived fingerprint identifies that earlier revision. AOT uses LLVM O2 and both Hermes O0/O profiles; JIT uses LLJIT defaults and both Hermes profiles. fflate remains unmodified and pinned to 0.8.2.

## Step 4: Diagnose scaled admission failures and correct fixture loading

The first repeated three-size campaign produced 92 successful executions, nine known fflate admission boundaries, and three unexpected large-queue failures. The queue failure occurred in generated input setup, not queue logic. Changed fixture setup to parse JSON data instead of compiling large JavaScript object literals. A complete corrected campaign is running.

### Prompt Context
See Step 3 for the implementation request. Code checkpoint **dc4ca9d** implements all four applications and the first matrix.

### What I did
Added root and argument counts to the admission diagnostic without changing the limit. Ran the existing native lifecycle suite and driver publication checks. Added six harness rejection checks for wrong results, missing completion, duplicate output, process failure, and timeouts. Archived the initial scaled receipt and regression output. Replaced generated `APP_INPUT` object literals with `JSON.parse` of a serialized input string.

### Why
A large fixture should exercise runtime application allocation rather than consume thousands of compiler root slots solely to construct input data. The JSON loader is the same for Node, AOT, and JIT; it does not rewrite the application or third-party library. More precise diagnostics separate this harness issue from the genuine unoptimized module-factory limit.

### What worked
All data sizes and both queue sizes below the largest passed. All persistent sizes passed, including 240 plugins with expected parse/initializer failures, forced collections, and later callback execution. Optimized fflate passed all sizes in Node/AOT/JIT, including independent binary decoding. Fingerprinted inputs remained unchanged in the scaled receipt. `shllvm-jit-test` reports engine-lifecycle-ok; driver publication checks pass 6/6; harness rejection checks pass 6/6.

### What didn't work
`shllvm-jit /tmp/llvm-app-full-artifacts/async-queue-large/input.js` rejected at `1:1` with `function exceeds 1024 combined root/argument-slot admission limit (roots=2329, arguments=1)`. The library bundle separately rejects at `428:2482` with `(roots=1084, arguments=3)`, the generated module factory source location. The latter remains a documented admitted-profile boundary; optimized library execution works. No broad conformance or unoptimized library success is claimed.

### What I learned
The queue application itself was not the cause of its initial large-input rejection. Data transport can accidentally become a compiler stress test if JSON objects are emitted as source expressions. Exact input loading must therefore be included in qualification evidence.

### What was tricky to build
AOT compilation is once per scenario/profile and execution repeats; JIT recompiles each fresh process. Consequently a failed AOT compilation creates one boundary record while two JIT attempts create two. Reports must distinguish execution counts from source contracts. A zero campaign exit means no unexpected outcomes, not that known-boundary cases executed successfully.

### What warrants a second pair of eyes
Review that the JSON fixture loader preserves identical input values and that the known-boundary classifier matches only the documented fflate O0 admission diagnostic. Review the unchanged 1,024-slot policy separately from the application results; increasing it requires stack/root lifetime reasoning.

### What should be done in the future
Finish the corrected campaign and publish the results table, commands, limitations, and root-slot follow-up disposition. Do not add speculative allocator or stack changes solely to erase a recorded boundary.

### Code review instructions
Compare first-scaled-campaign.json.gz with the final receipt once available. Start at the setup writer in qualify_shllvm_apps.py, then LLVMBackend.cpp's admission diagnostic. Run `python3 hermes/utils/test_shllvm_apps.py` and the documented qualification command.

### Technical details
Three sizes: 32/2048/16384 order rows, 12/96/256 jobs, and 12/80/240 plugins. Two repetitions. The fflate dataset scale is 10/400/4000, including empty, Unicode, JSON, and patterned-text documents. No runtime semantic implementation changed in this step.
