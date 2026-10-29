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
RelatedFiles:
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/eval_extensions.cpp
      Note: Eval source admission and derived non-string passthrough
    - Path: repo://hermes/lib/Support/UTF8.cpp
      Note: Runtime source encoding preserves surrogate code units
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

## Step 7: Reproduce the remaining global-eval distinctions

The final eval comparison was committed as `fd03426`. While the broad run continued, inspected remaining indirect-eval cases and wrote a diagnostic probe that distinguishes global property attributes, global lexical visibility, and strict eval-local declarations.

### Prompt Context
See Step 1. This investigation supports dynamic-evaluation failure attribution without changing the measured build.

### What I did
Ran scripts/03-eval-global-environment-probe.js through Node's script context and the ordinary LLVM driver with the existing build. Read the corresponding Test262 sources and Interpreter::declareGlobalVarImpl. Added the observations and implementation constraints to the general-eval design.

### Why
The remaining failures are not all explained by the sloppy direct-eval guard. Generalizing that guard would not repair global lexical visibility or eval declaration attributes.

### What worked
The probe completed on both engines and produced three concrete differences: configurable true versus false; lexical value outside versus ReferenceError; and strict eval var visibility undefined versus number. The runtime declaration helper explicitly sets configurable to zero, providing a source connection for the first result.

### What didn't work
All three observed behaviors remain incorrect in this build. No fix or conformance pass is claimed. The probe is intentionally excluded from Test262 totals.

### What I learned
Script and eval declaration policies must be represented separately. Flipping the existing global property flag unconditionally would fix one eval case while breaking ordinary script declaration semantics. Global lexical bindings also need shared runtime ownership across compilation units.

### What was tricky to build
The probe must run as a script rather than Node's CommonJS wrapper; otherwise its top-level lexical environment would not match the intended experiment. The recorded source uses independent names for each observation.

### What warrants a second pair of eyes
Review global lexical environment lifetime and the distinction between strict evaluated var storage and script-global property declaration. These are prerequisites for reliable cross-unit evaluation.

### What should be done in the future
Use the measured distinctions to implement separate declaration policies and shared global lexical storage, retaining the ordinary script contracts.

### Code review instructions
Read the probe and its JSON receipt, then the Observed indirect-eval defects section of the general-eval design and declareGlobalVarImpl.

### Technical details
The native command uses --no-runtime-build, preserving the immutable build used by the broad run. Its outputs and the source digest are recorded in reference/evidence/global-eval-probe.json.

## Step 8: Prepare non-string eval support in derived constructor contexts

The LLVM emitter currently rejects derived-constructor DirectEval instructions before the runtime can apply non-string passthrough. Prepared a narrow change that carries the context as a caller flag and rejects strings only after the runtime has returned non-string inputs. The broad baseline still runs the unchanged 20fd0f6 binaries; this source patch is deliberately not built until that experiment finishes.

### Prompt Context
See Step 1. This is another bounded dynamic-evaluation increment, not general derived-constructor string support.

### What I did
Added named caller flags, moved the derived-context guard from LLVM emission to runtime string admission, and added a positive fixture for missing arguments, primitives, object identity, captured arrows, collection, and argument exceptions before super. Migrated the two existing string boundary fixtures from compile-error contracts to runtime-rejection contracts.

### Why
Non-string eval arguments do not require source compilation or constructor syntax context. Rejecting the whole instruction prevents valid passthrough behavior and can also reject code whose unsupported string path never executes.

### What worked
The independent Node oracle prints derived-eval-non-string-ok. Source review confirms the IR generator already loads the captured this cell without a TDZ read check in derived contexts. Native validation is pending the completed baseline.

### What didn't work
No native success is claimed yet. String evaluation in derived constructors remains unsupported and retains an explicit runtime diagnostic.

### What I learned
The admission point matters: source-context restrictions can be applied after the language's non-string return rule. The ABI already carries caller flags, so the context does not need a second value or a new environment layout.

### What was tricky to build
A pre-super eval call must not accidentally read this. The existing captured-cell load is retained; the runtime returns non-string inputs before inspecting or compiling caller source context. Escaped arrows must preserve the same behavior after the constructor returns.

### What warrants a second pair of eyes
Review the migration of two rejection contracts and the order of the runtime guard. Ensure no source conversion or this-read is introduced before non-string passthrough.

### What should be done in the future
After broad execution and fingerprint verification, rebuild and run the focused constructor contracts plus the affected regression gate. Record results before committing the semantic change.

### Code review instructions
Read emitEval, SHLLVMEvalCallerFlags, and evaluate together with eval_derived_non_string.js and both migrated boundary fixtures.

### Technical details
The measured broad-build source commit remains 20fd0f6. Only source/test files have changed at this checkpoint; compiler/runtime artifacts used by the baseline have not been rebuilt.

## Step 9: Preserve UTF-16 code units in runtime source strings

A source probe found that runtime string compilation replaces lone surrogate code units with U+FFFD. Prepared a dedicated source conversion and parser mode that preserves those units while combining valid surrogate pairs for Unicode identifier classification. The broad experiment still uses its original binaries; native validation follows its completion.

### Prompt Context
See Step 1. The user subsequently wrote, "finish first, sorry", deferring the separate report/module follow-up until this work is finished.

### What I did
Added scripts/04-eval-utf16-probe.js and eval_utf16_source.js. Introduced convertUTF16ToUTF8PreservingSurrogates and an explicit allowSurrogatesInSource parser/compilation flag. Enabled the flag only for runtime source compilation and updated native direct eval, VM direct eval, and ordinary runtime eval conversion paths.

### Why
ECMAScript strings contain UTF-16 code units. Converting an unpaired surrogate to a replacement character changes the evaluated source and resulting literal value. Ordinary source-file decoding should continue to reject invalid UTF-8 scalar values.

### What worked
Node executes the new fixture and prints eval-utf16-source-ok. The fixture covers direct/indirect eval, Function, templates, raw templates, RegExp, an astral identifier, bytecode callers, and a nested escaping eval closure after GC.

### What didn't work
Running scripts/04-eval-utf16-probe.js through the frozen native driver produced `55296 65533` and `56320 65533`, where the Node script oracle produced `55296 55296` and `56320 56320`. ASCII 65 remained 65 in both. Native validation of the repair is pending; these observations establish the defect rather than proving the patch.

### What I learned
The existing single-surrogate encoder is also unsuitable: it encodes a valid pair as two separate source characters. An astral identifier must be reconstructed as one Unicode code point during lexing, while lone surrogates remain individual code units inside strings and other permitted lexical contexts.

### What was tricky to build
The lexer has consuming and peeking decoder paths. All must use the same mode. Runtime compilation disables lazy parsing for this encoding mode so a later parser cannot accidentally lose the setting. The mode is installed before the first token is read.

### What warrants a second pair of eyes
Review decoder error handling, surrogate pair advancement, and propagation through both native-context compileEvalModule and ordinary BCProviderFromSrc creation. Check that static source retains its original UTF-8 rejection behavior.

### What should be done in the future
After the baseline, run the native fixture at all optimization combinations, a malformed-static-source rejection probe, and the full regression gates. Recheck baseline timeouts on the original build before changing binaries so timing and semantic differences remain distinguishable.

### Code review instructions
Start with UTF8.cpp, JSLexer.h and CompileFlags. Follow the runtime conversion callers and parser creation sites. Read eval_utf16_source.js for the observable contract and the source probe for the original mismatch.

### Technical details
The source encoding uses four-byte UTF-8 for a valid surrogate pair and three-byte extended UTF-8 for an individual surrogate. Lexer decoding admits the latter only with allowSurrogatesInSource. This does not change JavaScript string storage, the LLVM value ABI, or the source-file default.

## Step 10: Complete and publish the full pinned-suite baseline

The full selection completed: 76,801 passes, 19,598 semantic failures, 6,584 unsupported variants, and nine timeouts, totaling 102,992 variants. All 53,968 fingerprints stayed unchanged and the Test262 checkout stayed clean. Published the complete compact inventory, fingerprints, fixture list, failure samples, and summary; retained the full raw report as a digested compressed local build artifact.

### Prompt Context
See Step 1 and the user's finish-first instruction recorded in Step 9.

### What I did
Executed scripts/02-publish-baseline-evidence.py against /tmp/llvm-002-full.json. Reconciled 53,909 selected files as 53,615 source files plus 294 fixtures. Filled the analysis document with final counts, stage-based failure attribution, largest families, and limitations. Started scripts/05-recheck-baseline-timeouts.py against the same frozen build with one worker and a 120-second runtime limit.

### Why
A completed inventory is necessary for future regressions and prioritization. Broad-suite counts must be reproducible and distinguish host admission, engine behavior, harness limits, and edition provenance.

### What worked
The publisher accepted the report after completeness, partition coverage, source hash, and clean checkout validation. The raw report SHA-256 is ecdc48aa52b238b27d9976ef8e36114e966d50a6c0bf40fe57e6b21596f780e9. No crash or infrastructure-error category was recorded.

### What didn't work
19,598 semantic mismatches, 6,584 unsupported records, and nine timeouts remain. The process exit status is 1 as expected for a completed run with failures. A diagnostic script initially assumed a partial checkpoint had a final counts field and raised KeyError: counts; the partial schema intentionally omits that final summary, so the diagnostic was changed to count its available records. No baseline data was changed.

### What I learned
The largest groups include missing Temporal/Intl capabilities, module-host admission, and 1,699 root-slot limit rejections. A root-slot rejection does not test the eventual target operation. Pinned catalog labels cannot establish edition membership, so the ledger explicitly leaves that audit open.

### What was tricky to build
The baseline had to retain its original compiler/runtime identity while later source fixes were prepared. The receipt records runtime source 20fd0f6 and runner source fd08c16 independently of the publication commit. The aborted earlier partial run was not merged into this experiment.

### What warrants a second pair of eyes
Review the distinction between complete execution and conformance, and the unsupported category's mixed host/compiler causes. Review summary-to-inventory consistency before citing counts externally.

### What should be done in the future
Complete the original-build timeout recheck, then rebuild and validate the pending eval changes. Edition qualification, general sloppy binding storage, global lexical integration, and richer source contexts remain open.

### Code review instructions
Read the analysis first, then full-baseline-summary.json and representative samples. Use scripts/02-publish-baseline-evidence.py to regenerate publication from the retained raw report, preserving its original artifact identity.

### Technical details
The broad profile is frontend O0 / LLVM O0, 16 workers, 60-second compilation and 10-second runtime stage limits. The local full raw archive is hermes/build-llvm/conformance/llvm-ecma-002-full.json.gz. Compact per-variant evidence is tracked; build artifacts are not staged.

### Step 10 validation follow-up
The original-build timeout recheck completed with unchanged inputs: 18 variants, three passes and 15 semantic failures, no timeouts. The runner expands each selected source into both strict/sloppy variants; among the nine originally timed-out strict variants, three pass and six fail semantically. Preserved the complete rerun in reference/evidence/timeouts-before.json. Only after this finished was the pending source rebuilt.

## Step 11: Qualify eval passthrough and runtime source encoding

Built the prepared changes after the complete baseline and original-build timeout recheck. Both repairs pass their focused tests and the complete native regression gates. The selected eval family has no status regressions, and six previously failing strict RegExp variants now pass when rechecked with the same larger time budget.

### Prompt Context
See Step 1 and Step 9. This checkpoint completes the measured baseline and bounded input-semantics increment; it does not close the ticket's larger declaration-storage and source-context work.

### What I did
Ran `cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4`, then the four-case eval-derived/UTF16 selection, the full core and extension gates, the 474-variant eval selection, and scripts/05-recheck-baseline-timeouts.py on the repaired build. Added scripts/06-check-static-utf8-rejection.py. Updated the driver boundaries and analysis with actual behavior and separate follow-up evidence.

### Why
The parser mode affects multiple runtime compilation paths. Qualification must cover both semantic preservation inside strings and unchanged ordinary file admission. The derived-constructor change also moves a rejection from compile time to runtime, so both old boundary fixtures and valid passthrough need independent checks.

### What worked
Build exit 0. Focused gate 4/4, with 16 native and four real lli executions. Full core 22/22; full extension 65/65, 256 native and 64 lli executions, unchanged input fingerprints. Static high/low surrogate source probes both reject with exit 1 and Invalid UTF-8 diagnostics. The 474 eval statuses exactly match the prior 390-pass/76-semantic-failure/eight-unsupported result. At a 120-second runtime limit, the timeout-source selection improves from 3/18 to 9/18 passes with six strict RegExp failure-to-pass transitions and no pass regressions.

### What didn't work
Nine sloppy variants in the timeout-source selection remain semantic failures because general non-strict direct eval is still rejected. General/global declaration semantics and private/super/derived string contexts remain unfinished. No full-suite run on the newer binaries is claimed.

### What I learned
The Unicode mismatch was independently observable and also explained six failures in the longer-budget RegExp experiment. The original ten-second timeouts hid those semantic differences; preserving both budgets and both builds makes the attribution reviewable.

### What was tricky to build
All lexer decoder entry points must agree about surrogate admission. The ordinary source parser must remain strict about UTF-8 while runtime-supplied strings preserve their existing code units. For derived constructors, passthrough must happen before source-context rejection and before any receiver-sensitive operation.

### What warrants a second pair of eyes
Review the new parser flag's eager-parse policy, the runtime conversion callers, and the caller flag ABI. Review that the two migrated derived string fixtures now expect runtime rejection rather than compilation failure. The broader fixed-slot environment representation is unchanged.

### What should be done in the future
Implement extensible sloppy-eval declaration storage and native/bytecode identifier resolution, correct global lexical and eval declaration policies, and extend private/super/derived string contexts. Complete the edition-membership audit before claiming an edition-qualified conformance score. The deferred module work remains separate.

### Code review instructions
Start with the analysis's Subsequent eval input corrections section. Follow convertUTF16ToUTF8PreservingSurrogates through runtime eval and parser flags. Read eval_derived_non_string.js, eval_utf16_source.js, and both boundary metadata changes. Compare evidence/eval-input-comparison.json with the preserved before/after receipts.

### Technical details
Native optimization coverage remains frontend O0/O by LLVM O0/O2, with real lli at frontend O / LLVM O2. The source-file rejection receipt identifies the rebuilt compiler by SHA-256. The historical full baseline remains tied to 20fd0f6. Evidence and documentation publication commit: b21f8b5.

## Step 12: Commit the qualified changes and deliver the updated guide

Implementation and evidence are committed as `fb560e2` (Preserve runtime eval UTF-16 source and derived non-string passthrough); the complete broad baseline is committed as `b21f8b5`. Uploaded the intern guide plus completed analysis with a new document name, preserving earlier documents and annotations.

- Command: `remarquee upload bundle` with design-doc/01 and analysis/01, name LLVM-ECMA-002-Intern-Guide-and-Baseline-Revision-3, destination /ai/2026/10/28/LLVM-ECMA-002, toc-depth 2, non-interactive.
- Result: `OK: uploaded LLVM-ECMA-002-Intern-Guide-and-Baseline-Revision-3.pdf -> /ai/2026/10/28/LLVM-ECMA-002`.
- Evidence: reference/evidence/guide-revision-3-upload.json records uploaded input hashes and the delivery output. This proves cloud delivery; device synchronization was not independently checked.
- Remaining work: the ticket stays active for general sloppy declaration storage, global environment semantics, private/super/derived string contexts, and edition qualification. The separate vault report and module-host request remain deferred under the user's finish-first instruction.
