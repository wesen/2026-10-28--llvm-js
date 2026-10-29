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

## Step 3: Admit strict evaluated strings from sloppy callers

Runner infrastructure and the pre-change baseline were committed as `fd08c16`. Added a shared parser-based strictness check and used it in both native direct eval and the bytecode interpreter. This is an admission change for strictly evaluated source, not general sloppy declaration injection.

### Prompt Context
See Step 1 and the user's instruction to finish this work first.

### What I did
Added `evalSourceIsStrict` to the runtime eval implementation. It parses on the compiler stack executor and inspects parser-produced directive nodes without global semantic resolution. Native and interpreter callers retain non-string passthrough and require either a strict caller or a genuine strict directive. Added a fixture for native and dynamic callers, shared mutations, GC, this, arguments, new.target, nested eval, no var leakage, const errors, and TDZ.

### Why
Strict evaluation does not introduce caller variable bindings, so it can use the existing shared-slot mechanism. Parser metadata distinguishes actual directives from comments, escapes, and parenthesized strings. Global semantic resolution during detection would reject valid constructor new.target.

### What worked
The independent Node oracle prints `strict-source-eval-ok`. The runtime build is in progress; native success is not yet asserted.

### What didn't work
No native validation result is available at this checkpoint. General non-strict source remains explicitly rejected.

### What I learned
JSParser restores parser state when leaving parseProgram, so its post-parse mode is not the appropriate strictness oracle. The AST's directive nodes provide the same spelling-sensitive basis used by semantic directive scanning.

### What was tricky to build
Nested evaluation executes bytecode, even when its original caller was native. Both entry paths need the same admission rule, while final compilation must still apply the caller's lexical and syntactic context.

### What warrants a second pair of eyes
Review raw directive spelling, compiler-stack execution, and exception propagation. Verify escaped strings are not accidentally admitted, and ensure genuinely strict source does not leak declarations.

### What should be done in the future
Run focused native/lli tests, adversarial directive probes, the same pinned eval selection, and the full regression gate. Preserve any failures before correcting them.

### Code review instructions
Start with evalSourceIsStrict in VM/JSLib/eval.cpp, then its two callers and the new extension fixture.

### Technical details
The helper returns CallResult<bool>; parser failure becomes a runtime SyntaxError. Accepted source still compiles through the existing strict eval path, preserving existing const/TDZ and environment ownership behavior.

### Step 3 focused failure and correction

The first focused extension run failed in all four native combinations and lli with `Uncaught SyntaxError: sloppy direct string eval is unsupported; use strict evaluated source, a strict caller, or indirect global eval` at `anonymous (eval:1:25)`. Temporary print markers localized the failure to invocation of the nested arrow, after both native strict-source evaluation and the first dynamic Function evaluation had succeeded. Source inspection showed `SemanticResolver::runInScope` used only `semInfo->strict`, ignoring the evaluated program's directive prologue. Updated it to combine caller strictness with `scanDirectives(rootNode->_body).useStrictNode`, before declaration processing and nested-function resolution. The fixture remains unchanged. This repairs semantic strictness inheritance rather than forcing individual nested calls to supply a directive.

### Step 3 rejection-fixture correction

The full extension gate initially passed 57/58. Its sole failure was the new aggregate directive-boundary fixture's Node oracle: `Error: directive lookalike was admitted`. The harness correctly requires unsupported-context sources to be valid successful JavaScript under Node. The fixture had incorrectly asserted the implementation's rejection inside the source itself. Replaced it with six independent valid JavaScript sources, each relying on the harness to check the native rejection and Node success. The runtime implementation did not change. The core gate passed 22/22 and the strict-source positive fixture passed all native/lli combinations, including the previously failing nested arrow.

### Broad-run scheduling adjustment

The initial full selection used six workers and processed roughly 2,800 variants in three minutes. Stopped that run deliberately with Ctrl-C to increase concurrency to sixteen workers on this eight-CPU, 64-GB host; compiler/linker subprocess waits leave opportunities for overlap. The interrupted report remains `complete: false` and is preserved locally as `/tmp/llvm-002-full-interrupted.json`. Restarted from the beginning with the same immutable build and `--jobs 16 --compact --checkpoint-every 2000 test`. No results from the interrupted run will be added to the final totals.

### Step 3 final regression qualification

The corrected complete extension gate passes 63/63 source contracts with unchanged inputs; the core gate passes 22/22. This includes the strict-source positive fixture at all four native optimization combinations and real lli, and all six directive-lookalike rejection contracts. Receipts are `reference/evidence/strict-eval-extensions.json` and `strict-eval-core.json`. General non-strict eval remains unsupported. The first post-change eval-family run (before the nested strictness resolver correction) improved from 381 to 390 passes without a previously passing variant regressing; final full-profile evidence will supersede that intermediate measurement.

A source-path audit corrected the guide's Environment declaration reference from a nonexistent standalone header to `hermes/include/hermes/VM/Callable.h`. All literal repository file references then resolved. Uploaded the corrected guide under a new name, preserving any annotations on the first upload: `OK: uploaded LLVM-ECMA-002-Intern-Guide-Revision-2.pdf -> /ai/2026/10/28/LLVM-ECMA-002`. This is cloud-delivery evidence.

## Step 4: Validate report aggregation and document the remaining storage change

The strict-source runtime milestone was committed as `20fd0f6`. Added a checked report summarizer while the full pinned-suite run executes against that unchanged build. Inspected the actual Environment allocation, tracing, native mirror, and disabled semantic unresolver hook to make the remaining general-eval design concrete.

### Prompt Context
See Step 1. The later vault/module request remains deferred until this work reaches its requested checkpoint.

### What I did
Implemented report identity, partition, count, variant, fixture, and source-inventory checks. Added failure triage and an explicitly unreviewed edition-feature ledger. Ran adversarial aggregator tests and a real two-shard eval-builtin experiment. Added a detailed proposed storage/compiler integration design with source references and a reproducible broad-baseline script.

### Why
A sum of unrelated successful reports is not a baseline. Missing partitions or mixed builds must be rejected. General sloppy eval also needs semantic scope information beyond the current nearest-visible physical-slot descriptors.

### What worked
All three aggregator tests passed, including multiple invalid-report subcases. The two real partitions reconcile to 20 passing eval-builtin variants. All 16 runner tests still pass. The new design identifies Environment tracing and native layout assertions that any storage implementation must update together.

### What didn't work
The broad run is not yet complete and cannot be summarized as a final result. Early results include semantic failures and timeouts; these remain part of the experiment. Edition membership is unreviewed rather than inferred from feature tags.

### What I learned
Environment has fixed trailing storage and an explicit C layout mirror. The existing eval descriptor chain is physical and filters shadowed declarations; general declaration-conflict checking needs additional semantic scope metadata. The disabled unresolver hook alone cannot implement dynamic binding lookup.

### What was tricky to build
Aggregation must treat empty partitions, fixtures, and metadata failures consistently while rejecting duplicate variant identities. Failure categories remain triage hints; compiler diagnostics are not automatically sanctioned unsupported language contexts.

### What warrants a second pair of eyes
Review aggregate coverage checks and the proposed static-slot versus dynamic-cell binding representation. Do not mistake the additional design document for an implemented environment ABI change.

### What should be done in the future
Finish the broad run, preserve its report identity and ranked failures, and then use those findings to prioritize general eval storage and caller-context work.

### Code review instructions
Start with summarize_shllvm_test262.aggregate and its tests. Read the new general-eval design against Callable.h, sh_mirror.h, Callable.cpp, and genCallEvalExpr.

### Technical details
The broad run selects all of `test`, uses sixteen workers, frontend O0 / LLVM O0, compact passing records, and a checkpoint every 2,000 variants. Its raw report is `/tmp/llvm-002-full.json`; only a final `complete: true` with unchanged inputs can qualify it. The reusable invocation is in `scripts/01-run-broad-baseline.sh`.

## Step 5: Separate host requirements and feature provenance from conformance results

Report aggregation was committed as `b1e0bae`. Extended the summarizer to annotate the pinned feature catalog and identify textual host-helper references in failing source and harness files. These annotations preserve original execution classifications and expose uncertainty rather than manufacturing a cleaner conformance score.

### Prompt Context
See Step 1. This is failure-attribution work while the broad immutable-build experiment runs.

### What I did
Added optional `--suite` annotation with clean-checkout/revision checks and per-file source/harness hash verification. Recorded proposed/standard/test-harness catalog categories separately from unreviewed edition membership. Added source-reference candidates for $262 helpers. Added tests for source changes, dirty catalogs, category separation, and unchanged status counts.

### Why
The initial host does not implement the full $262 API. Some runtime failures can therefore involve missing test-host services rather than the language operation under investigation. Textual references are useful triage evidence but cannot prove invocation, so they do not replace the actual result. A catalog label also cannot establish membership in the pinned edition artifact.

### What worked
All four aggregator tests pass, including hash and cleanliness rejection cases. Annotated the completed pre-change eval report successfully without changing its totals. Inspected the pinned catalog's three sections and the specification artifact's algorithm anchors.

### What didn't work
No new test failure occurred. Edition membership remains unreviewed; the current annotations are not an edition-qualified pass rate. The full run is still incomplete.

### What I learned
The catalog contains features whose status must be checked against the particular artifact, rather than against a current proposal status. A scan of runtime-negative test sources found no direct $262 reference in that small set, but this is not a general proof of host completeness.

### What was tricky to build
Source annotations must refer to the actual executed bytes. Reading a newer checkout would give persuasive but unrelated diagnostics. The summarizer therefore validates both revision and examined file identities and records its own source digest.

### What warrants a second pair of eyes
Review the distinction between a textual helper reference and an executed missing-host operation. Do not reclassify all matching tests as unsupported automatically.

### What should be done in the future
Use the final broad results to review large failure groups and record concrete edition membership decisions with normative references.

### Code review instructions
Read annotate_suite and its adversarial test. Verify that counts remain those of the original reports and that annotations cannot silently accept changed source or harness bytes.

### Technical details
`pinned_catalog_category` is independent of `edition_membership`. The summary records feature-catalog and summarizer SHA-256 digests. The full run had processed more than 16,000 variants at this checkpoint and was still incomplete.

## Step 6: Compare the final eval build against the original selection

The final eval-family run completed against the same immutable runtime build used by the broad experiment. It improves nine previously failing variants without regressing any previously passing variant. The nested-arrow regression is covered separately by the complete extension suite.

### Prompt Context
See Step 1. This checkpoint records a semantic result while the broad profile continues.

### What I did
Re-ran `test/language/eval-code test/built-ins/eval` at frontend O0 / LLVM O0 with two workers and compact passing records. Compared exact test/variant key sets and statuses against the pre-change report, asserting identical coverage and no pass-to-nonpass transitions.

### Why
The earlier post-change measurement preceded the semantic strictness fix. A final same-selection comparison is needed to characterize the delivered build rather than combining intermediate results.

### What worked
The run completed with unchanged inputs and a clean suite: 390 pass, 76 semantic failure, 8 unsupported, totaling 474 variants. Before the change there were 381 pass, 85 semantic failure, and 8 unsupported. Nine failures became passes and no previously passing variant regressed.

### What didn't work
Seventy-six semantic failures and eight unsupported cases remain in this family. This is a qualified strict-source increment, not completion of general dynamic evaluation.

### What I learned
The measured improvements include strict-source declaration environments, lexical contexts, strictness override, and receiver behavior. General non-strict declaration injection requires the separate storage/compiler design already recorded in the ticket.

### What was tricky to build
Comparison must use exact test/variant identities. Equal totals alone could hide changed selection or an improvement offset by a regression.

### What warrants a second pair of eyes
Review the nine changed identities in eval-comparison.json and the retained failure commands in eval-final.json. The Node and optimization-matrix regression evidence remains separate from this pinned O0 profile.

### What should be done in the future
Finish and attribute the full pinned-suite result. Continue general dynamic binding and caller-context implementation under separate validated increments.

### Code review instructions
Open reference/evidence/eval-comparison.json first, then eval-final.json. The implementing source commit is 20fd0f6; report/triage changes are in subsequent commits.

### Technical details
Exact coverage: 474 variants. The final command used `--jobs 2 --compact`; worker count changes scheduling but not variant identity. Both reports preserve their build/input fingerprints.
