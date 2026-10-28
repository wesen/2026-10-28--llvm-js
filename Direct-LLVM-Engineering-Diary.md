# Direct LLVM engineering diary


28 October 2026. Consolidated from contemporaneous component records. This is a record of implementation decisions, observable actions, experiments, failures and fixes. Component chronology and original timestamps are retained; later final results supersede preliminary attempts without deleting them.


The host dynamic-JavaScript backend and the scalar RV32 PicoCalc lane have separate validation claims.


## Contents


1. Language extension integration diary

2. Async and Promise validation diary

3. Dynamic evaluation implementation diary

4. Rich values and typed-array diary

5. Project diary

6. Compiler integration and validation diary

7. Runtime bridge and test diary

8. PicoCalc direct LLVM diary

9. PicoCalc review diary

10. LLVM toolchain preparation


# Component record 1: Language extension integration diary


# Language-extension engineering diary

Date: 28 October 2026. This continues the direct LLVM implementation release.
It records decisions, observable changes, commands, failures and results.

## 1. Scope and source checkpoint

The requested extension covers generator functions and yield, async/await and
Promises, RegExp literals, BigInt, private fields, typed arrays, dynamic eval
and Function. The previous release's sources and final validation identities
were captured before editing. Earlier evidence remains historical and intact.

The existing compiler is the pinned Static Hermes source plus the direct LLVM
backend; the baseline includes 22 passing source cases and the separate
PicoCalc integer-world implementation. This phase extends the host dynamic
backend. It does not imply a new physical-device runtime port.

## 2. Reuse existing language machinery

Source inspection found that shared SH lowering already calls
LowerGeneratorFunction, which translates suspension and resumption to a heap
environment/state machine. CreateGeneratorInst remains for runtime object
creation. Async lowering drives these generators through the existing Promise
and console job queue. The first implementation step is to preserve that
lowering and emit the missing creation operation, then exercise next, throw,
return, delegation, finally and collector lifetime.

RegExp, BigInt and private fields have existing SH runtime helpers. The new
bridge must pass rooted operands and avoid guessing heap layouts. The
repository's gc-safe-coding guidance was read before runtime work.

Dynamic eval needs separate investigation: upstream DirectEvalInst has source
and strictness operands, and the Static Hermes runtime path does not currently
carry a caller lexical environment. Wiring this path as-is would not establish
correct local lexical evaluation. Global/indirect eval and Function can use the
existing dynamic compiler, while lexical integration must preserve binding
identity, mutation, strictness and lifetime.

## 3. First executable generator and value integration

The first generator protocol program compiled to LLVM IR, passed LLVM
verification in the driver, linked and ran successfully. Its output includes
sent values, caught throws, early returns, finally cleanup, completed-generator
behavior and a TypeError for a reentrant next call. The actual output and
compiler stderr are retained as generator-protocol-native.txt and its stderr
companion. The build log is generator-build.log.

Added iterator begin/next/close bridges, plus property-name enumeration bridges.
The for-in operations write caller-owned root slots and return a boolean used
by the LLVM terminator. Their successor branches still use the emitter's phi
edge-copy mechanism. This matters when loops and generator state machines
share mutable state. Additional fixtures cover yield-star delegation, iterator
closing on abrupt exits, suspended finally clauses, enumeration and collection
while generator/closure environments remain live.

Integrated exact ParsedBigInt byte constants and RegExp/private-name operations
using the existing runtime helpers. BigInt bytes have a separate immutable
module pool; no conversion through Number is involved. Private operations use
the runtime's supported uncached path and preserve brands rather than string
properties. CMake includes value_extensions.c in both bridge libraries.

Independent oracle probes exposed two shared-runtime issues worth investigating:
Promise.all settled already-fulfilled inputs too early relative to another
queued reaction, and typed-array negative-index assignment diverged from Node.
The Promise implementation has been corrected to schedule each then reaction;
the new runtime build and regression fixtures will validate the change.

## 4. Preserve failed experiments and distinguish shared-runtime defects

The first integrated extension matrix tested 24 source fixtures. Twenty
passed and four failed. The failures were async-generator cleanup after
return, async-generator completion state, typed-array negative-index
assignment, and Promise subclass species behavior. The same discrepancies
appeared through the C backend, establishing that they were shared-runtime
semantics rather than LLVM-only instruction selection errors. The records
remain in extension-first-pass.json and its log.

That early run also detected a changed fixture fingerprint: the generator
GC test was strengthened from an optional collection call to an unconditional
one while the run was active. It is diagnostic evidence, not a frozen release
gate. Final validation must start only after all source and fixture edits
are complete.

The first compiler build exposed an instruction representation mistake:
BinaryPrivateInInst is a tagged BinaryOperatorInst case, not a separate C++
instruction class. Handling its ValueKind in the binary emitter fixed the
compile error. The build failure and subsequent successful build are retained
as extensions-build-1.log and extensions-build-2.log.

## 5. Native lexical evaluation and runtime ownership

The direct-eval implementation now carries the exact visible declarations,
physical scope chain, receiver, new target and arguments alias through IR.
The runtime reconstructs a non-executed compiler scope scaffold, maps its
variables to the existing environment slots, and compiles the eval source
to Hermes bytecode. Native and evaluated closures share cells; no snapshot
or copy-back protocol is involved.

The helper uses VM/compiler implementation APIs and therefore belongs in
the full VM archive. The first full link failed because that archive's new
directly compiled source was not position-independent. Setting the archive's
POSITION_INDEPENDENT_CODE property corrected the shared-library link.
extensions-build-3.log preserves the failure, and extensions-build-4.log
records the successful correction.

Actual O0-frontend / LLVM-O2 native probes passed lexical reads and writes,
shadowing, inaccessible out-of-scope declarations, replacement of eval,
non-string eval arguments, TDZ, const mutation errors, exceptions, receiver
and arguments capture, constructor new.target, and escaping closures across
explicit collection. eval-initial-native-probes.json records these executions.
It also preserves the then-unfixed nested-eval failure and raw boundary
probe outcomes; the generic probe did not yet classify every deliberate
boundary using the final fixture metadata.

Optimized emission then exposed a scope-hoisting dependency omitted from
the initial implementation. The optimizer had moved an eval-visible binding
outside the retained environment chain. ScopeHoisting now follows the
captured Variable parents and arguments parent as dependencies. Source-site
global/derived-constructor context is retained explicitly so inlining cannot
silently change new.target legality or the derived-constructor boundary.

A lifetime review found that retaining the synthetic parent's shared Module
alone did not preserve its FunctionIR: BytecodeFunction destruction deletes
the associated function. The bridge now transfers that ownership to the
module before destroying the temporary provider. Nested interpreted eval
uses retained scope/debug metadata to find the actual current environment.
These follow-up changes require the next consolidated build and matrix.

## 6. Async, Promise and typed-array corrections

Focused validation after build 4 passed all 17 selected async/Promise cases:
68 native contracts and 17 real lli executions, with C checks at both frontend
optimization levels. The source and binary fingerprints were unchanged
during that focused gate. Its filename is async-promise-fixed-pass.json;
selection makes it a partial gate, not the final complete extension result.

The fixes address demonstrated Promise.all scheduling, species construction,
thenable invocation timing, subclass reaction timing, Promise.resolve object
identity, and continuation of an internal await reached during generator
return/finally. A further external-return rejection probe showed that the
return argument must be awaited before injecting the completion into a
suspended async generator. Source return expressions must likewise await
inside their original try/catch/finally context. The frontend and driver
follow-up is included in the next build, with new regression fixtures.

Typed-array canonical numeric-index handling now prevents negative,
fractional, NaN and infinite numeric keys from becoming ordinary properties.
Build-4 probes passed across C, native LLVM and lli. A specification-directed
distinct-receiver probe records a Node-version difference honestly rather
than silently changing the expected output. Another probe found that an
ordinary target with a typed-array receiver bypassed exotic definition.
The additional receiver guard and regression are queued for the next build.

## 7. Consolidated build and final-gate preparation

After the three implementation streams reached source freeze, the root
started extensions-build-5.log with CMake targets shermes, shllvm_runtime and
shllvm_runtime_shared, using six parallel build jobs. This rebuild includes
all IR metadata, optimizer, runtime, typed-array and async frontend changes.
Agents do not run competing CMake builds against the shared directory.

The report now has a textbook chapter explaining the new mechanisms, source
reading pointers, explicit remaining eval contexts and laboratory exercises.
The PDF assembler reads named final evidence files and refuses failed,
partial or changed-input extension gates. Counts will be inserted from actual
completed records. The final run and artifact checks will be appended below.

Build 5 stopped because the warning wrapper type is CLFlag, not llvh::cl::opt;
it lacked getNumOccurrences. Added CLFlag::isSpecified, which checks both the
positive and negative spellings, and retained explicit warning overrides.
Independent review also caught an arrow visitor that skipped default-parameter
expressions; it now visits all arrow children while isolating function context.

Build 6 compiled those changes, then its internal hermesc subprocess hit the
known LeakSanitizer sandbox restriction because the build command omitted the
environment workaround. Build 7 uses ASAN_OPTIONS=detect_leaks=0 for the build
as well as execution. AddressSanitizer remains enabled; this is not a source
fix or a passing test result. All three build logs are retained.

## 8. Complete rebuild and focused post-build checks

Build 7 exposed two C++ type errors in the interpreter bridge: a typed
PinnedValue<Environment> cannot be assigned a generic pinned/GC HermesValue.
Both assignments now use the existing vmcast extraction, with no allocating
operation before assignment to the local root. This matches the established
debugger environment-extraction pattern.

Build 8 required resumed shell invocations. A session reported completion
while the log stopped before the final targets; a CMake/Ninja dry run still
listed outstanding work. The remaining work was resumed with four jobs. The
final resumed log ends with VM, console and shared-bridge links, and a fresh
dry run reported 'ninja: no work to do.' Only then were agents told to run
their native/JIT probes. The completion check avoids assuming that a shell
status alone establishes a fully refreshed runtime.

Four direct-eval warning-option checks passed: default suppression, explicit
enable, explicit disable and last-option precedence. Their evidence is
eval-warning-options.json. The first probe mistakenly used /dev/null as a
publication destination; atomic replacement correctly could not replace that
device. That failed invocation remains in eval-warning-options-initial.json.
The corrected probe uses stdout and checks that real LLVM definitions were
emitted along with the expected diagnostic behavior.

The value component's six focused C/native/lli executions passed after the
complete build. The new typed-array receiver guard rejects an invalid numeric
definition without coercing its value; a valid element write coerces once.
The specification-directed distinct-receiver probe also matches the intended
algorithm. values-final-probes.json records actual output and unchanged hashes
across these focused checks; its Node discrepancy remains explicit.

The async component reproduced a frontend traversal gap using three small
programs. Nested await was rejected as being outside an async function, and
async-generator expressions inside await/yield operands reached execution
without the required transformation. Both C and LLVM exposed the frontend
problem. traversal-probe-build8.json preserves those failures. The operand
visitors will be corrected after the current focused gate completes, and the
new regressions will join the final gate.

## 9. Final integration corrections before source freeze

Build 9 completed all requested links. A subsequent Ninja dry run reported
no remaining work. Its eval probes now pass nested lexical evaluation,
Function-local arguments, escaped arrow receiver/arguments after collection,
and optimized closure TDZ behavior. The fixes restore lexical context and
captured arguments during dynamic compilation, and preserve Empty/Uninit
alongside the ordinary Any type during conservative type inference.

One probe still exposed global context leaking through the non-executed eval
scaffold: eval of another eval of new.target was accepted at script level.
The final helper correction marks every synthetic script parent as a program
scope. A permanent fixture checks both rejection in global/arrow contexts
and valid native/dynamic constructor contexts. The Node oracle passes; the
rebuilt native matrix is the release gate for that correction.

Two larger async fixtures had exceeded the 1,024 combined root/argument-slot
limit only with the unoptimized frontend. The emitter previously allocated
a distinct root to every instruction, including side-effect-only operations
and values with no users. It now retains unique slots for used results and
constants, plus a separate rooted discard slot for unused results and a
scratch slot. No instruction is deleted and the admission limit is unchanged.
An independent review checked helper reentrancy, allocation sequences, phi
transfers and frame initialization. The formerly oversized modules now pass
LLVM assembly and verification with maximum combined counts of 642 and 826.

The next focused async run was interrupted before final completion. Its
incremental record contains 11 passing positive fixtures, 44 native runs,
11 lli runs and 22 matching C runs, including both formerly oversized cases.
It has complete:false and no final fingerprint check, so it is retained only
as partial evidence. The final complete gate will replace its validation role.

Read-only review then identified one remaining AST traversal gap: async
generators in default parameters of ordinary declarations, expressions,
async functions and async generators. A small probe confirmed that Node
returned valid Promise-based iterators while both frontend optimization
levels produced caught TypeErrors on the current build. Ordinary async
function defaults worked. The permanent correction visits parameter nodes
under their own function context before the body transformation. The failed
probe remains in async-parameter-traversal-build9.json.

The documentation review corrected stale private-field wording, clarified the
difference between JavaScript private fields and internal fixed-slot IR, and
reversed a diagram arrow to show bridge calls entering the managed runtime.
Source filenames were added to the new reference entries so the PDF retains
useful reading pointers even when a local Markdown link cannot be opened.

## 10. Completed frozen release gates

Build 10 completed all 16 steps, ending with the full VM, console and shared
bridge links. A fresh Ninja dry run reported no work. The final source freeze
then covered 679 implementation, configuration, fixture, harness and binary
identities. The complete gates ran against that single build, with no case
filter, quick mode, JIT skip or oracle-only mode. All 679 identities remained
unchanged through the run.

The core suite passed 22 of 22 source contracts: 17 positive programs, three
runtime-error contracts and two compile-rejection contracts. It recorded 68
positive native comparisons across the four frontend/LLVM combinations,
three real lli executions and six separate runtime-error executions.

The extension suite passed 53 of 53 source contracts: 44 positive programs,
three language-error cases, three explicit runtime-boundary cases and three
compile-error cases. Its 200 native executions comprise 176 successful-output
comparisons, 12 language-error checks and 12 expected unsupported-context
rejections. Its 50 lli executions comprise 44 successful programs, three
language-error checks and three boundary rejections. Every applicable LLVM
module went through the driver's assembly and verification pipeline.

Forty extension cases matched the required C oracle at both frontend levels.
Ten executable cases explicitly excluded the inherited C direct-eval helper;
their evidence explains why its missing native environment is not a semantic
oracle. The three compile-error cases use publication/diagnostic contracts.
The distinction matters: an unsupported-context rejection is not a successful
Node semantic comparison. The core and extension paths share the patched
frontend and runtime where C comparisons are required.

The command-publication suite passed six of six checks; the raw lexical-default
suite passed five of five. The authoritative records are core-final-validation,
extension-final-validation, driver-final-validation and
lexical-defaults-final-validation JSON files and logs. final-validated-files.json
records successful commands, unchanged hashes and the full 679-file identity
map. These are the release results; interrupted or selected earlier probes
remain historical evidence. No Test262 suite, physical device execution or
performance benchmark was run in this phase.

## 11. Report and release review

The regenerated report contains 35 pages, approximately 15,124 words and two
vector architecture figures. Every page was rendered to PNG. The integration
owner reviewed pages 1-18 through contact sheets and inspected the feature
map, architecture figure and validation tables at full-page resolution. An
independent reviewer inspected pages 19-35, including the new language chapter
and source-reading guide. A text/bounds check found no empty text layers,
replacement glyphs, placeholders or text outside page boundaries.

The first rendered review caught another stale host-feature paragraph in the
PicoCalc integration chapter. It was updated to the current implementation
and final evidence filenames. The small generator-state table was kept on
one page. All pages were re-rendered and the changed layouts reviewed again.
The final PDF is 221,967 bytes with SHA-256
4d4a02e3d60defbf44dfaf968983685db1f676807c487fda4c22194dbca99c68.
PDF_REVIEW.md and pdf-text-check.json retain the review scope and results.

The release builder uses a private Git index and private object directory to
construct the patch against the pinned upstream base. It checks application
to a second independent index and requires an identical resulting tree,
without staging the working repository. The source archive includes the
complete compiler/runtime sources, both test suites, raw evidence, the report
and this consolidated diary. Its verification reads every ZIP member and
compares both CRC and SHA-256. Final packaging results follow this entry.

The patch verification completed successfully for 124 paths and a 421,828-byte
patch. Applying it to the independent base index produced tree
01e2d894b12153ddd4dd0a5e04ed06d5c70d987a, exactly matching the proposed changes.
The repository index was unchanged, and every one of the 679 tested inputs
still matched. The first assembled archive passed CRC and SHA-256 readback
for all 13,192 members. It contained 13,090 Hermes source/documentation/evidence
files and 95 PicoCalc files, plus the top-level release artifacts.

After appending these observed results, the metadata and archive builders are
run once more to incorporate this diary entry and refresh its hashes. The
same patch, tested-input and per-member checks are required before the four
updated deliverables are saved. RELEASE_VALIDATION.json beside the archive
records its final byte count and hash without introducing a self-hash cycle
inside the ZIP.



# Component record 2: Async and Promise validation diary


# Async, Promise, and extension validation diary

Date: 28 October 2026. This log records observable engineering work and
decisions; it does not contain a private reasoning transcript.

## Baseline inspection

The existing direct backend calls the real Static Hermes runtime and its
console event loop. `StaticHInit.cpp` enables the native microtask queue for
CLI execution. `ConsoleBindings.cpp::run_event_loop` drains microtasks before
processing timers and after each timer task. Therefore ordinary Promise jobs
already have an execution mechanism.

The frontend lowers async functions to a generator closure passed to the
`HermesBuiltin_spawnAsync` builtin. `lib/InternalJavaScript/02-AsyncFn.js`
drives that generator with `next` and `throw`, resolves the async return value,
and rejects uncaught exceptions. The missing native generator emission is
therefore the central backend dependency for async/await.

## Reproduced inherited Promise.all ordering defect

The existing Promise implementation deliberately optimized an already-fulfilled
input in `Promise.all` by invoking the element resolver synchronously unless
the runtime enabled test262 mode. The source comment itself acknowledged that
this collapses an observable microtask step.

The two-line probe in `promise-all-order-probe.js` schedules a resolved
`Promise.all` callback and a separate resolved-Promise callback. Actual output
before the change:

- Node: `tick`, then `all`.
- Unmodified C-emission path with the original Hermes runtime: `all`, then `tick`.

Both processes exited successfully, so an exit-code-only test would miss this
semantic difference. The new Promise fixture preserves this ordering check.

The fix always invokes `nextPromise.then(resolveElement, capReject)`, matching
the required PromiseReactionJob ordering and observable `then` access. It
removes the test262-only correctness gate; it does not add a new scheduling
system or change the LLVM bridge.

Reference: ECMAScript `PerformPromiseAll` in
https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-performpromiseall.
The runtime rebuild and post-change execution are performed by the parent
build owner; this entry records the reproduced failure and source correction,
not an unperformed success claim.

## Test harness and first integration pass

Added ten initial asynchronous/Promise fixtures with explicit completion
markers. Node executed all ten successfully. Coverage includes primitive and
thenable awaits, closures, lexical `this` and `arguments`, try/catch/finally,
retention across `gc()`, async iteration, queued generator requests, Promise
combinators, resolution/rejection, and subclasses. Separate fixtures exercise
uncaught errors and invalid syntax.

Implemented `utils/test_shllvm_extensions.py`. The default gate uses two
frontend optimization settings, two LLVM optimization settings, and the real
`lli` JIT for every executable fixture. Node runs each source as a script via
`vm.runInThisContext`; this avoids accidentally testing CommonJS lexical scope
when validating dynamic eval. The inherited C backend is required by default.
Explicit C-oracle limitations are recorded separately with a reason and actual
outcome; they never become successful C comparisons.

Added repeatable frontend `--hermes-arg=-X...` options to the Python driver for
async-generator fixtures. Validation rejects output/backend switches in this
option, and build manifests retain the arguments. The rejection of
`--hermes-arg=-emit-c` was checked before runtime tests.

The build owner ran the first integration matrix: 20 of 24 selected source
cases passed. All generator and initial value features except the known typed
array indexing case passed. The shared runtime produced three asynchronous
failures: async-generator finalization in two fixtures and Promise subclass
species selection. Both C and direct LLVM reproduced them. The first pass is
diagnostic evidence, not the release gate: the input fingerprint also detected
the generator GC fixture being strengthened during that run.

Evidence: `extension-first-pass.json`, `extension-first-pass.log`,
`initial-native-probes.json`, and `async-generator-close-c-probe.json` in this
directory. The corrected `Promise.all` order was already successful in the
first direct LLVM probes and matrix.

## Async-generator return and finally correction

`04-AsyncIterator.js` drives the transformed synchronous generator with a
Promise request queue. A yield tagged as kind 0 represents an internal await.
The old code reused a pending `return` request when that await completed. If
`return("closed")` entered a `finally` block containing `await 0`, it resumed
with `return(0)`. This skipped the remainder of cleanup and replaced the
original return value.

Changed kind-0 fulfillment to resume with `next(resolvedValue)`. The underlying
generator retains its pending completion while the finally body executes.
Rejection still resumes with `throw(error)`, which can replace that completion.
No IRGen or event-loop change was needed.

Added `async_generator_finally.js` to check normal cleanup, a finally return
overriding the original return, a finally throw, yielding during cleanup,
rejection during cleanup, injected throw after an await, and original loop-body
exception precedence during async iterator close. Node's complete expected
outputs are saved in `async-promise-node-oracles.json`.

## Promise species and reaction scheduling

The previous `then` and `finally` implementation explicitly ignored
`Symbol.species`. Added the default static species getter and shared
SpeciesConstructor selection with null/undefined fallback, observable lookup
ordering, and invalid-constructor rejection. `finally` now uses the abstract
PromiseResolve operation instead of reading a user-overridable `C.resolve`.

The existing subclass path also routed results through an intermediate core
Promise. This introduced a second reaction job. The corrected handler settles
the selected constructor's capability in the original reaction job. Added
`promise_species.js` and `promise_subclass_order.js` to cover selection,
single-read getters, invalid species, generic finally validation without a
premature `then` read, proxy constructor inspection, and relative microtask
ordering between core and subclass Promises.

The JavaScript builtin requires a side-effect-free constructor predicate. Added
`HermesInternal.isConstructor` using the existing VM operation and predefined
symbol. The new native wrapper performs no allocation and reads an argument
already rooted in the native call frame. Before editing VM code, read the
repository's `gc-safe-coding` skill and complete `doc/GCSafeCoding.md`; no new
legacy GCScope or unrooted value was introduced.

## Thenable jobs and public Promise identity

A focused probe found two additional shared-runtime defects. For a thenable,
Node printed `sync|then|tick|resolved:4`; the C runtime printed
`then|sync|resolved:4|tick`. The runtime invoked the thenable synchronously.
The same probe found `Promise.resolve(0) === Promise.resolve(0)` true in Hermes
and false in Node because public resolve returned a cached Promise.

Changed resolution to read `then` synchronously but invoke it in a queued
NewPromiseResolveThenableJob, including adoption of another core Promise.
Captured intrinsic `Reflect.apply` avoids observing a then function's user
`call` or `bind` properties. Public `Promise.resolve` now allocates a fresh
wrapper for non-Promise values; private await caches remain inaccessible.
Added `promise_thenable_jobs.js` to check thenable lookup/invocation order,
adoption order, fresh primitive wrappers, exact-Promise identity, and negative
zero preservation.

The pre-change commands and actual output are preserved in
`promise-thenable-order-probe.json`; the source probe is kept alongside it.
After adding these regressions, all 14 positive async/Promise fixtures pass
Node. Rebuilt C/native LLVM/JIT validation is pending the coordinated runtime
rebuild at this diary entry.

## Reference material checked

The implementation decisions were checked against the following primary
ECMAScript algorithms, accessed 28 October 2026. Stable section anchors are
used because section numbers change between specification editions.

- [SpeciesConstructor](https://tc39.es/ecma262/multipage/abstract-operations.html#sec-speciesconstructor): constructor and species lookup, default selection, and constructibility validation.
- [NewPromiseReactionJob](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-newpromisereactionjob): settling a reaction's capability within the same job.
- [NewPromiseResolveThenableJob](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-newpromiseresolvethenablejob): deferring invocation of a thenable until surrounding execution completes.
- [PromiseResolve](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise-resolve): exact-Promise identity and fresh capabilities for other resolutions.
- [Promise.prototype.finally](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise.prototype.finally): species selection and abstract PromiseResolve, without consulting a public resolve override.
- [AsyncGeneratorYield](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-asyncgeneratoryield): queued resumptions and normal/abrupt completion handling.

These algorithms support the targeted contract choices; the regression suite
does not assert complete Promise branding, cross-realm behavior, or full
ECMAScript conformance.

## Rebuilt focused gate: all initial corrections pass

After the coordinated fourth build, ran the async/Promise selection with both
frontend settings, both native LLVM settings, and real `lli`. The process
exited 0: **17/17 source contracts, 68/68 native contracts, and 17/17 JIT
contracts passed**. This comprises 14 positive programs and three expected
uncaught errors. Every C oracle matched Node at both frontend levels. Input
fingerprints were unchanged throughout this focused run.

Evidence: `async-promise-fixed-pass.json` and
`async-promise-fixed-pass.log`. These are preserved as historical validation of
that build, not overwritten by the subsequent return-protocol work.

## Return values, source cleanup, and async request completion

A further focused helper probe found a distinct case: passing a rejected
Promise to `asyncGenerator.return()` must deliver its rejection at the suspended
yield, where an enclosing catch may recover. The old helper called the
underlying synchronous generator's return immediately, skipped that catch, and
only observed the rejection after the generator had closed. The native Node
generator recovered and yielded a value; the helper rejected instead.

Fixing only request entry would still add an extra microtask when the driver
awaited the final iterator value. The correction therefore makes the two
required await points explicit:

1. The AST transformation rewrites a source `return expression` to await the
   expression within the source generator's try/catch/finally context.
2. The runtime awaits an external `return(value)` argument before injecting
   its return or throw completion into the suspended generator.

Once the underlying generator reports completion, the driver can complete the
request directly. It does not add an extra await or unwrap a Promise that an
async delegate legitimately returns as the final result's value. Completed
next/throw requests are drained iteratively, preventing a long queued tail
from consuming recursive native stack frames. Return requests in that tail
still await their arguments.

The AST visitor treats nested arrows as separate function contexts. It also
wraps empty async generators, whose iterator methods still must return
Promises and expose `Symbol.asyncIterator`.

Added `async_generator_return_values.js`, `async_generator_return_order.js`,
`async_generator_queue_completion.js`, and `async_timers.js`. The last case
checks cancellation, microtasks between timer callbacks, and awaiting a timer
resolution. The queue case creates 2,052 requests and runs `gc()` before
settlement. All four new sources pass Node; their outputs are retained in
`async-return-node-oracles.json`.

The helper-only before/after evidence is
`async-return-rejection-helper-probe.json` and
`async-return-fixed-helper-probe.json`. The corrected helper matches native
Node for return-argument rejection, return-expression rejection, and relative
return/tick ordering. This isolates the JavaScript driver behavior; rebuilt
AST-to-C and AST-to-LLVM validation remains the next gate.

Reference:
[AsyncGeneratorUnwrapYieldResumption](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-asyncgeneratorunwrapyieldresumption).

## Final review: interrupted gate and parameter-expression traversal

The build-9 focused gate was interrupted after eleven positive cases had
completed. Its retained JSON explicitly says `complete: false`: the eleven
cases passed all 44 native executions, eleven real `lli` executions, and 22 C
oracle executions. Both previously oversized unoptimized programs,
`async_generator_finally.js` and `async_generator_return_values.js`, are among
these completed cases. No failure is recorded, but this partial run does not
provide a completed input-identity check or a release result. The final full
gate must establish those independently. The partial evidence remains in
`async-promise-final-pass.json` and its log.

A source review then found that function declarations and function expressions
visited only their bodies. Arrow functions already visited their parameters,
but a nested async generator in another function's default parameter could
remain untransformed. A concrete build-9 probe covered defaults in ordinary
declarations, ordinary function expressions, async functions, and async
generators. Node returned Promise-valued iterator results yielding 1, 2, 3,
and 4. Both Hermes frontend O0 and O with LLVM O2 produced caught TypeErrors
for all four cases. An ordinary async-function default remained correct.
The source and outputs are preserved in
`traversal-probes/generator_in_parameters.js` and
`async-parameter-traversal-build9.json`.

The correction visits every parameter node before transforming or moving a
function's parameters. Parameter traversal uses a fresh non-async-generator
context, so an enclosing generator cannot rewrite another function's default
expressions as its own suspension points. Nested functions still establish
their own context, and the visitor restores the previous state before visiting
the body. The existing early return for lazy function bodies is preserved.
The permanent `async_parameter_expressions.js` fixture covers all four failed
forms and the working ordinary-async control. Runtime validation of the
correction awaits the coordinated final build; no passing result is inferred
from the source change itself.

## Final frozen validation: async and Promise contracts pass

The coordinated final build and complete extension matrix are now verified.
`extension-final-validation.json` records 53/53 source contracts passing,
`complete: true`, `partial_gate: false`, no skipped cases, and unchanged input
fingerprints. Filtering its actual records by the `async`, `async-generators`,
and `promises` families yields **24/24 contracts**: twenty positive programs,
three expected runtime errors, and one invalid-await compiler rejection.

The 23 executable async/Promise contracts passed all **92 native executions**
(frontend O0/O crossed with LLVM O0/O2), **23 real `lli` executions**, and
**46 C oracle executions**. These totals include the three expected-error
contracts; the positive-program totals are 80 native, twenty `lli`, and forty
C executions. Every executable contract matched Node's declared result.
The invalid-await fixture passed all six compiler/driver publication checks
across the two frontend settings.

Coverage includes await values and exceptions, captures and GC, timer/job
ordering, async-generator queues and delegation, return/finally behavior,
completed requests, Promise combinators and resolution, species and subclass
ordering, thenable jobs, and expected Promise errors. Both
`async_nested_expressions.js` and `async_parameter_expressions.js` matched Node
through all four native combinations, real `lli`, and both C configurations.
This closes the pending validation for operand and parameter traversal. The
earlier interrupted focused evidence remains unchanged. These are targeted
host contracts, not a full ECMAScript conformance result.



# Component record 3: Dynamic evaluation implementation diary


# Dynamic evaluation implementation diary

## 2026-10-28 — Baseline investigation

The direct LLVM backend initially rejected `DirectEvalInst`. Indirect eval and
the `Function` constructor already have VM builtins, so their missing work is
end-to-end validation and keeping the runtime compiler enabled. The upstream C
backend's `_sh_ljs_direct_eval` calls `vm::directEval` with a null environment.
Consequently its results are not a valid oracle for lexical direct eval.

Read the IR builder, semantic resolver, SH instruction selector, native VM
environment helpers, `evalInEnvironment`, `compileEvalModule`, and the GC-safe
coding skill before selecting the implementation. Native SH environments are
real Hermes `Environment` objects, which can be captured by bytecode closures.
This is the key interoperability point.

## Design decision — strict lexical eval uses the existing runtime compiler

The runtime compiler's local-eval entry point requires retained IR and semantic
scope data. A generated LLVM unit has no bytecode parent to supply that data.
The extension therefore reconstructs a small **non-executed scope parent** from
native binding descriptors. The descriptors record identifier names, lexical
rules, environment order, and actual native slot indexes. The scope parent is
compiled with metadata retained; its variables are then mapped to the native
slot indexes. `compileEvalModule` resolves the requested string in these scopes.
`Runtime::runBytecode` receives the actual native environment and the caller's
`this` and `new.target` values. Evaluated closures therefore share the original
bindings instead of capturing a copied snapshot.

Dynamic strings compile to Hermes bytecode and execute in the existing VM. The
surrounding statically known program still compiles directly to LLVM IR. This
distinction must be explicit in the architecture report.

Sloppy direct string eval can introduce new `var` bindings into its caller.
The upstream native frontend has no dynamic lookup machinery for this operation.
The bridge will reject that case with a `SyntaxError` until that machinery exists.
Non-string eval arguments still return unchanged, as JavaScript requires.

## Optimization and GC constraints

Direct eval must retain visible variables even when no static expression reads
them. It may also assign a different value or type to a local variable. Explicit
IR operands and conservative optimizer handling keep these variables in shared
environments and invalidate cached frame values across calls. Environment and
argument operands are rooted by the generated LLVM frame. The runtime extension
must finish C++ RAII cleanup before invoking SH's non-local exception transfer.

## Validation record

Implementation and differential validation are in progress. This section will
be updated with commands, observed failures, corrections, and final results;
no unrun test is claimed as passing.

## 2026-10-28 — First implementation completed

Added `eval_extensions.h/.cpp`. The bridge is compiled inside the full VM, where
the intentionally hidden compiler and VM symbols can be called. Only its C
entry point is exported to generated LLVM modules. The compiler scaffold uses
one anonymous function per physical environment, including environments with
zero visible bindings. It never invents a JavaScript-visible marker variable.

An important correction came from reading IRGen: ordinary source blocks can
share one `VariableScope`. Listing all variables in that scope would expose
names outside their lexical block and select the wrong shadowed declaration.
The new `DirectEvalInst` records the nearest semantic declaration for each
visible name at the original source location. Descriptor generation groups
those selected bindings by their actual physical environment. Implicit
`arguments` is eagerly captured when eval is present, and its hidden native
slot is given the one intentional source-level alias `arguments`.

Added conservative handling in store-once analysis, stack promotion, frame
load/store optimization, and function analysis. An eval-visible binding cannot
be treated as a constant or cached forever in a native stack slot. Existing
memory type inference already treats an unknown user as an arbitrary value,
so it did not need a new special case.

Two semantic traps were addressed before the first native build. First, using
`const` declarations in the scaffold would make the existing semantic checker
reject writes during compilation; JavaScript instead requires a catchable
runtime `TypeError`. The scaffold now uses `let` and restores the native
Variable's constness before eval compilation. Eval compilation also enables
the existing deferred-check mode for constants declared inside the evaluated
source. Second, a function scaffold could accidentally make `new.target` legal
in global eval. Global eval text receives a separate non-executed global-syntax
validation before the lexical compile.

Added six positive differential fixtures and one explicit feature-boundary
fixture. All seven scripts ran successfully in Node with `--expose-gc`. The
positive expectations include shared writes in both directions, changes of
value type, block shadowing, out-of-scope names, const errors, TDZ errors,
ordinary/arrow `this` and `arguments`, constructor `new.target`, thrown values,
and escaped dynamic closures after garbage collection. The sloppy-boundary
script is valid JavaScript in Node and is deliberately labeled as a native
feature restriction, not a language-conformance error.

Remaining explicit boundaries under review: constructor eval before `super`,
class home-object/private-name metadata, and direct eval invoked from dynamic
bytecode (whose inherited opcode still lacks lexical integration). They must
receive diagnostics or a real metadata path before support is claimed.

## 2026-10-28 — Emission probes and ownership review

Ran every eval fixture through the newly built compiler at frontend `-O0` and
`-O`, followed by LLVM 18 `llvm-as` for successful modules. The unoptimized
positive fixtures assembled. The intended derived-constructor diagnostic
appeared at both optimization settings. Several optimized fixtures correctly
failed the emitter's environment-chain check; this exposed an additional
optimizer assumption in `ScopeHoisting`. That pass knew about explicit
`ResolveScopeInst` uses but not about environments reached by an evaluated
string. An optimized closure could therefore lose its lexical parent's
environment even while `DirectEvalInst` still retained its variables. The
queued fix adds captured-binding parent scopes to the existing dependency
analysis, preserving optimization for unrelated scopes.

A lifetime review found another subtlety beyond ordinary shared ownership:
`BytecodeFunction::~BytecodeFunction` destroys its associated IR Function.
Destroying the non-executed synthetic provider would therefore destroy the
Module's remembered top-level Function while the eval provider still shared
the Module. The planned ownership transfer clears the synthetic bytecode
functions' `functionIR` pointers only after successful eval compilation.
The shared Module's owning compiled-functions list then releases those
metadata-only functions at Module destruction. The error path keeps its
ordinary cleanup. A second reviewer independently checked that ownership
relationship in the source.

Prepared separate nested-eval tests, including a returned bytecode closure that
performs another eval after the original native caller has returned and after
GC, and a strict `Function`-created function whose eval captures locals. Both
fixtures match their expected output in Node. They are awaiting the interpreter
metadata integration and native validation.

## 2026-10-28 — First native results and nested-eval integration

The coordinated build compiled the new IR, bridge, and emitter successfully.
Its shared-library link first exposed a CMake integration issue: the new source
was added directly to the full VM static archive without PIC. The build owner
enabled PIC on that target and relinked successfully. This was a build-system
problem, not a language semantic failure.

The first unoptimized native probes match Node for
`eval_closure_gc.js`, `eval_global.js`, `eval_lexical_bindings.js`,
`eval_lexical_errors.js`, `eval_this_arguments.js`, and
`function_constructor.js`. Evidence is recorded in
`eval-initial-native-probes.json`. In particular, the const/TDZ error classes,
mutation in both directions, arguments captured through an arrow, constructor
`new.target`, and closure survival after GC all match. The initial nested-eval
probe produced the predicted missing-global `ReferenceError`, confirming that
the inherited interpreter opcode also needed lexical integration. Boundary
fixtures rejected as designed; the initial simple probe script labeled them
as failures because it had no boundary-metadata logic. Those records remain
unaltered and must not be cited as positive semantic passes.

Implemented the additional scope-hoisting dependency and ownership transfer
described above. Native descriptor sizes and member offsets now have compile
time assertions matching the LLVM host64 ABI. Global/derived-constructor
context is stored at the original eval site and copied during IR cloning,
rather than inferred from the function that happens to own the instruction
after optimization. This preserves top-level-arrow rules and remains correct
if a function is inlined. Scaffolding declarations now use `var`; actual TDZ and
const rules still come from the original Variable metadata. This also allows
an inherited non-strict identifier such as `let` to be represented without
introducing a synthetic-source syntax error.

The interpreter's direct-eval slow path now reads `DebugScopingInfo` at the
current bytecode instruction, obtains its environment from the recorded frame
register or spilled environment slot, roots it with `Locals`/`PinnedValue`, and
calls `evalInEnvironment` with the caller's `this` and `new.target`. Missing
metadata receives an explicit error; it never silently substitutes the global
environment. Runtime source compilation now retains scope metadata even in a
build with `HERMES_ENABLE_DEBUGGER=OFF`, and enables TDZ/deferred const checks.
Lazy compilation and the full runtime optimization pipeline are disabled on
this path until they have an equivalent metadata-preservation contract. This
is a deliberate memory/compilation-speed tradeoff for correct local eval.

The new build and the full optimized/native/JIT differential gate remain
pending at this entry.

## 2026-10-28 — Complete focused matrix, first iteration

The interpreter change initially failed to compile because
`PinnedValue<Environment>` requires a typed object value, not assignment of a
generic `PinnedHermesValue`/`GCHermesValue`. Corrected both extractions with
`vmcast<Environment>` followed immediately by assignment to the existing local
root, matching the debugger's established representation. There is no
allocating call between extracting the raw pointer and rooting it.

Ran the complete focused eval/Function matrix against build 8: both Hermes
frontend levels, both LLVM levels, all native executions, and real `lli`, with
Node and required C oracles. Input fingerprints remained unchanged. The result
was **12 of 14 case contracts passed**, including all five explicit boundaries.
The failed evidence is retained in `eval-build8-validation.json`, not overwritten
with a success summary.

Two failures were informative. First, nested eval immediately inside an
eval-program body reported missing scope metadata. Comparing `doItInScope` with
ordinary program/function generation revealed that it did not establish the
current lexical scope. Its bytecode locations therefore had no usable scope
index. Second, a `Function`-created function's direct eval shared ordinary
locals correctly, but its caller-arguments expression produced `NaN`. The
saved `EvalCompilationData` deliberately contained a null arguments operand,
and eval IRGen never restored a caller arguments capture. Both paths now retain
and restore that metadata. Eval through an arrow also preserves its inherited
capture state instead of constructing a new ES5 argument/this context.

Three additional focused probes are recorded in
`eval-build8-extra-probes.json`. A transient `Function` parent whose returned
eval closure performs another eval after GC passed at both frontend settings;
no speculative generic-provider ownership change was made. Nested global
context testing was blocked by the missing lexical-scope metadata and will be
repeated after that correction. The third probe demonstrated a real optimizer
bug: a closure reading a never-initialized `let` threw `ReferenceError` at O0,
but returned an invalid value printed as `NaN` at O. Type inference's early
`Any` return for an eval user discarded the `Empty` possibility from the
binding's initialization stores. The correction unions arbitrary JavaScript
values while continuing to scan those stores. Synthetic variable types now
also include `Empty` whenever the original binding obeys TDZ.

Added permanent regressions for the TDZ optimization failure, the passing
transient-parent lifetime case, and an escaped arrow from a `Function` body
performing nested eval of its inherited `this` and `arguments` after GC.
These corrections await the next coordinated build.

## 2026-10-28 — Nested global context retained through eval

Build 9's concrete native probes now match Node at both frontend optimization
levels for nested lexical eval, `Function` caller arguments and escaped arrows,
and the never-initialized captured `let` regression. The evidence is preserved
in `eval-build9-concrete-probes.json`. One remaining probe exposed a distinct
semantic-context bug: `eval("eval('new.target')")` in a strict script was
incorrectly accepted, even though the first-level global syntax check correctly
rejected a direct `new.target` expression. Nested global `arguments` remained
undefined, and the real constructor control already passed.

The scaffold's anonymous functions are only metadata containers; none runs.
Their retained `FunctionInfo` records nevertheless looked like real function
contexts to `SemContext::nearestNonArrow` during a second eval compilation.
The bridge now marks every synthetic parent as a program node when the original
caller has global context. The existing semantic walk then skips those levels
and reaches the actual global function. Ordinary and constructor callers keep
their function context. Functions introduced inside the evaluated string also
keep their own normal metadata.

Added `eval_nested_global.js` with direct and arrow-origin nested global
rejections, a nested global-arguments check, and both native and dynamically
created constructor controls. This change is confined to compile-time metadata;
it introduces no new GC roots, allocations, or runtime ownership changes. The
fixture's Node oracle passed, printing both expected `SyntaxError` results,
undefined global `arguments`, and true for both constructor controls. Native
validation is pending the next coordinated build at this entry.

## 2026-10-28 — Final frozen validation

The completed `extension-final-validation.json` records **53 of 53 extension
contracts passed**, with no skipped cases, no partial selection, and unchanged
source/binary fingerprints. The eval/Function portion contains **12 positive
programs, three runtime boundary rejections, and two compiler boundary
rejections**. Each positive program matched Node under all four native
combinations of Hermes O0/O and LLVM O0/O2, and under the real `lli` JIT at
Hermes O / LLVM O2: **48 native comparisons and 12 JIT comparisons**. This
includes nested global `new.target` rejection and both real-constructor
controls, shared lexical mutation, captured TDZ errors, and escaped eval
closures after GC.

The three runtime boundaries (sloppy caller, enclosing class private names,
and method `super`) produced the declared rejection in **12 native runs and
three JIT runs**. Direct eval in derived constructors and their arrow contexts
passed the separate compiler-rejection and output-publication contracts at
both frontend optimization levels. These are explicit support boundaries,
not successful comparisons with Node's behavior for those valid programs.

Five positive programs also matched the existing C backend at both frontend
levels. Seven positive lexical/context fixtures and the three runtime
boundary fixtures exclude that C oracle for documented reasons: its native
direct-eval entry does not supply the required caller environment or context.
Those exclusions do not skip LLVM execution or the applicable Node oracle.
The C and LLVM paths share the patched runtime and frontend, so their
agreement is a useful second code-generation check, not an independent
language implementation. This targeted host matrix does not establish full
ECMAScript conformance or a device execution result.



# Component record 4: Rich values and typed-array diary


# Value features engineering diary

Date: 28 October 2026. Observable actions, design decisions and results are
recorded here; this is not a private reasoning transcript.

## Runtime contracts inspected

Read the repository's GitHub development guidance and GC-safe coding skill.
Inspected the original C emitter's BigInt serialization, RegExp creation,
private-name creation and private-field operations. Inspected the actual
StaticH runtime implementations to establish null-cache behavior and root
requirements.

The existing root-slot ABI can expose all of these operations without creating
a second value representation. Added `value_extensions.c` and
`value_extensions.h`; the wrappers accept caller-owned rooted values and write
the result directly back to a rooted slot. RegExp pattern/flag symbols remain
rooted by the registered compilation unit. BigInt literal bytes have native
unit lifetime and do not contain heap pointers.

## BigInt representation

The implementation plan uses the same ParsedBigInt byte representation as the
upstream C emitter. The LLVM emitter must intern these exact bytes separately
from strings, add LiteralBigInt to the rooted-constant set, and call the bridge
to create the managed BigInt. Converting a literal through double would lose
precision. Calling the global BigInt constructor would introduce observable
dependence on a user-replaced global.

Existing runtime arithmetic helpers cover BigInt arithmetic and errors;
exponentiation is already lowered through a builtin by the shared pipeline.
Tests include values larger than 64 bits, alternate radices, signed
division/remainder, shifts, exponentiation and mixed-type errors.

## Private access and caches

The SH private-field helper APIs explicitly permit a null inline cache. The
first lowering therefore uses that correct path and requires no new unit
cache allocation or weak-cache rooting. This also avoids an important trap:
private-membership caches store a boolean in their slot field, while field
access caches store an actual field offset. Those two operation kinds must
never share one cache entry.

Private names are preserved as the runtime's private-name values, not public
strings. Shared lowering already expands PrivateBrandCheckInst. Fixtures
exercise private fields, methods, accessors, static storage, inherited access,
independent same-spelling brands, failed receiver checks, duplicate stamping
and non-extensible object stamping.

## Typed arrays and RegExp

Ordinary typed-array construction and methods already use the existing generic
constructor/property/call path. New fixtures exercise real buffer and view
semantics, overlapping set, clamping, numeric conversion and bounds. BigInt
typed arrays depend on the newly added BigInt literal path.

RegExp tests check literal identity, captures, lastIndex, sticky/global flags,
Unicode code points, dotAll/multiline behavior, replacement callbacks, named
captures, and invalid runtime RegExp construction. A replaced global RegExp
constructor must not intercept literal creation.

## Validation in progress

Created six source fixtures and began independent Node and unchanged C-backend
probes at Hermes O0/O. Results are retained in values-initial-oracles.json,
including failures and differences if present. Direct LLVM validation follows
emitter integration and rebuild by the parent task.

## Initial oracle results and corrective work

The six initial programs compiled successfully through the original C backend
at Hermes O0 and O. Five matched Node exactly: RegExp, BigInt, private fields,
BigInt typed arrays, and the combined GC stress program. The ordinary typed
array program disagreed on one observable value: after `a[-1] = 8`, Hermes
returned `8` and Node returned `undefined`. All other output in that program
matched. The complete initial JSON is retained without overwriting it.

Source inspection traced the discrepancy to the ordinary property fallback in
`JSObject::putComputedWithReceiver_RJS` and an existing typed-array TODO in
`defineOwnComputedPrimitive`. After coordinating file ownership, added a
focused fix in `lib/VM/JSObject.cpp`. A fixed stack buffer and Hermes's existing
number parser/formatter implement the canonical numeric string roundtrip;
ordinary names such as `"01"` and `"1.0"` remain ordinary properties. No object
layout or GC metadata changed. New string roots use Locals and PinnedValue.

The property operations now preserve the distinction between numeric `-0`
(property `"0"`) and string `"-0"` (invalid typed-array index). Invalid writes
still call the existing typed-array setter so ToNumber/ToBigInt conversion,
observable valueOf calls, exceptions, and detached-buffer checks remain in
the runtime's established implementation. Definitions validate the index and
attributes before attempting value conversion.

Added `features_typed_array_indices.js` for invalid numeric keys, canonical
versus noncanonical spellings, own descriptors, nonextensible arrays, same-
receiver conversion failures, GC during key/value conversion, distinct
Reflect.set receivers, and shadowed numeric prototype entries. Node completes
this differential fixture successfully. A syntax-only C++ compile using the
actual build compilation flags passes.

## Independent-reference limitation

A focused test uncovered a separate Node v24.22.1 discrepancy with the current
ECMA-262 TypedArray [[Set]] algorithm. For an invalid canonical numeric index
and a distinct Receiver, the specified operation succeeds without converting
the value. This Node build instead invokes valueOf, and throws for Symbol or
Number-to-BigInt values in that case. The VM fix follows the specification.
This difference is preserved in `typed-array-receiver-spec-probe.js` and
`typed-array-receiver-spec-probe.md`, separate from the ordinary differential
matrix. The matrix still exercises a distinct receiver using a primitive
numeric value on which both implementations agree.

The initial emitter integration note mistakenly treated BinaryPrivateInInst
as a C++ class. The integrated build identified it as an instruction tag;
the correct dispatch is a ValueKind case within BinaryOperatorInst. The
integration note has been corrected and the runtime bridge contract did not
change.

## Cross-component review

Reviewed the integrated generator, iterator, for-in, BigInt and private-field
LLVM emission against the original C emitter and the actual StaticH helper
signatures. Confirmed operand order, mutable iterator slots, branch polarity,
registered root-slot storage, native function metadata lifetime, and BigInt
pool ownership. No concrete ABI or GC blocker was found in these new paths.

Reviewed the dynamic-evaluation bridge without editing its owner's files.
Confirmed that the child bytecode provider shares the compiler Module and
retains the parent semantic context. Caller values are borrowed from existing
LLVM root slots, and C++ owners are destroyed before the SH exception longjmp.

Reported two concrete concerns to the evaluation owner and parent task: the
ordinary-function metadata scaffold does not supply class home-object or
private-name lexical context for valid method eval expressions, and the
documented EvalError for unsupported sloppy string eval initially differed
from the implementation's SyntaxError. Their final handling belongs to the
evaluation component's report and tests.

The evaluation owner then identified an ownership detail missed by the first
review: BytecodeFunction's destructor explicitly deletes its FunctionIR, even
when the containing Module is shared. Rechecked the full destruction path.
deleteBodyExceptEvalData moves retained synthetic functions, including the
global function, into Module's owning compiledFunctions list. Nulling only
the synthetic parent's BytecodeFunction FunctionIR links after successful
eval compilation transfers cleanup to that Module list and preserves the
top-level metadata pointer needed by nested eval. The evaluated provider
continues to own its own FunctionIR normally, and unsuccessful compilation
keeps the original cleanup path. This corrected review was sent to the
evaluation owner and parent task before the final build.

## 2026-10-28 — Focused execution and final receiver correction

After coordinated build 4, the original typed-array program, canonical-index
boundary program, and specification-directed receiver probe all passed
through C at Hermes O, native LLVM at Hermes O / LLVM O2, and lli at the same
settings. The two normal fixtures matched Node; the receiver probe matched
all four specification-derived lines. Complete commands, output and artifact
hashes are retained in `values-build4-probes.json`.

Read-only inspection also identified the reverse receiver case:
`Reflect.set({}, "-1", value, typedArrayReceiver)`. The target is ordinary, so
the early typed-array target check cannot enforce the receiver's exotic
definition rules. Prepared a focused patch while the shared build ran, then
applied it after completion and the checks above. It delegates canonical keys
on typed receivers to `defineOwnComputedPrimitive` before ordinary property
addition. The fixture now checks invalid and valid reverse-receiver writes
and their conversion counts.

Using the expanded fixture with the still-unmodified build 4 binary preserved
the concrete remaining failure: invalid assignment returned true instead of
false. Neither implementation converted the value, and valid-index writes
matched. The actual before-guard results are in
`typed-array-receiver-before-guard.json`. Source is now stable for the next
coordinated rebuild and final matrix. No result from the pending guard build
is claimed here.

## 2026-10-28 — Async transformation review

During the consolidated build, independently reviewed the new async-generator
return transformation and request driver without editing their owner's
files. Found that the new arrow-function visitor isolated its body correctly
but skipped default parameter expressions, unlike the prior generic visitor.
A nested async generator in an arrow default would therefore escape this
transformation. Reported the narrow correction—traverse the arrow's children
while the enclosing-generator flag is false—to the async owner and parent.
The owner confirmed the issue and will add the corresponding regression at
the next coordinated source-edit checkpoint.

## 2026-10-28 — Final value-component verification and freeze

After coordinated build 8 completed and the parent verified that Ninja had
no remaining work, reran the expanded canonical-index/receiver fixture and
the normative distinct-receiver probe through all three routes: the C
emitter with the shared updated runtime, direct native LLVM, and lli.
All six Hermes executions exited successfully and matched their expected
output. The reverse receiver regression now returns false without conversion
for the invalid key and converts once for the valid element.

The normal fixture matches Node v24.22.1. The normative probe continues to
match the specification's four lines on all three Hermes routes while
preserving the known Node difference as an explicit nonmatching reference
record. This is an oracle limitation, not a suppressed assertion.

`values-final-probes.json` records commands, full outputs, exit statuses,
timings and SHA-256 hashes of the checked source files, compiler and bridge/
VM binaries before and after execution. The hashes were unchanged throughout
the run. Source and regression fixtures for this component are now frozen;
the parent task owns the full combined optimization matrix and release
packaging.

## Final frozen extension gate

The complete extension-final-validation.json records 7 of 7 passing
rich-value fixtures, with 28 native LLVM output comparisons, 7 real lli
comparisons and 14 matching C executions. All are positive language cases.
The complete 53-case gate used unchanged source and binary inputs and no
selection, quick mode or JIT skip. The separate typed-array distinct-receiver
specification probe and its recorded Node-version discrepancy remain separate
from these differential fixture results. Earlier failures are retained.



# Component record 5: Project diary


# Direct LLVM backend engineering diary

Date: 28 October 2026 (America/New_York).

This records observable decisions, changes, commands, and results. It is an
engineering diary, not a verbatim reasoning transcript.

## 1. Recovering the actual integration target

The request follows the PicoCalc native-world prototype and the proposal to
replace Static Hermes's C emitter with a direct LLVM emitter. The recovered
PicoCalc archive contains the TypeScript AST-to-C compiler, fixed world ABI,
RV32IM emulator, compilation service, and transactional generation replacement.
It is being upgraded in parallel so existing worlds retain an executable
regression target. GoJSLab and the Wazevo F0–F7 work are earlier projects and
remain separate.

The Static Hermes source is pinned at
f837b9dd8396ebf5c4e8115412417d273565f0fe on the static_h branch. The new emitter
branches after module-level lowering and before C-specific register allocation
and call lowering. LLVM tools version 18.1.3 were installed privately and
validated for native execution and RV32 object emission.

## 2. ABI and garbage collection design

Generated JavaScript bodies go directly from Hermes IR to textual .ll. A fixed
C bridge is compiled once against the pinned runtime headers. It exposes
primitive integer/pointer ABI entry points; it is not generated per program.
The bridge owns knowledge of SHRuntime, SHUnit, stack-frame layouts, and inline
runtime helpers. Generated functions retain Hermes's native callback convention.

Every Hermes IR result and mutable stack slot gets a position in a caller-owned
SHLocals root frame. Values are reloaded from those locations after potentially
allocating calls. Phi nodes become simultaneous copies on CFG edges. This
prioritizes auditable moving-GC correctness before register/liveness tuning.

Metadata uses fixed-width function descriptors translated into the runtime's
native bitfields by the bridge. No generated LLVM struct guesses at SHUnit's
layout. Units and their code must survive until the associated runtime is
destroyed; hot reload therefore replaces complete runtime generations.

## 3. Validation plan

Build with AddressSanitizer as requested by the upstream development guide.
Run llvm-as and the LLVM verifier on generated modules. Compare actual native
execution with the existing C emitter and Node for deterministic JS programs:
named/recursive/higher-order functions, escaping mutable closures, independent
captures, methods/lexical this, arrays, property access, and collection stress.
Run the recovered PicoCalc world's original transactional tests through direct
LLVM and C paths. Treat RV32 object generation separately from device execution.

Further entries are appended as implementation and validation complete.

## 4. Direct IR implementation checkpoint — 2026-10-28T09:39:37-04:00

The new C++ emitter now produces complete textual LLVM modules with function
metadata, constant pools, function bodies, unit creation, and an optional main.
The existing C emitter is kept as a semantic reference. Its module-level lowering
is shared; C register allocation and call rewriting are bypassed.

Rooted slots implement mutable locations. Phi edges first load every incoming
value, then store every destination. This avoids corrupting cyclic loop-carried
assignments. Literal objects are expanded through ordinary Hermes property
helpers; optimized PrLoad/PrStore operations use their preserved property names,
so they do not assume a different object allocation layout. Arrays preserve
length and holes. Dynamic arithmetic uses the existing runtime coercion helpers;
explicit floating IR operations emit LLVM floating instructions without
fast-math flags.

The compiler integration preserves existing output files when source validation
or unsupported lowering fails. Six driver acceptance checks passed, including
emission with CC pointing to a nonexistent executable. The first broad module
assembled with llvm-as and executed natively at LLVM O2, printing
45 720 11 12 12 for a loop sum, recursion, and shared mutable closures.

## 5. Additional language and ABI work

Added ordinary constructors, classes, receivers, arguments access, and
try/catch/finally. A caller-owned jump buffer is linked by a C helper, but
_setjmp is called directly inside the generated LLVM function with
returns_twice. A volatile try-state dispatch selects the active catch region;
root reads/writes are volatile in functions that have exception regions.
Callbacks never jump into a C helper that has already returned.

Three independent review findings were resolved: typed object subclasses are
explicitly rejected instead of accidentally changing property enumerability;
the explicit root-plus-argv admission limit was reduced from 65,536 roots to
1,024 combined slots; and TDZ checks preserve the invalid-type mask, including
the distinction between Empty and Uninit. Upstream encodes Uninit as undefined,
which the bridge now matches. The stack admission does not claim to bound all
LLVM spills, recursive frames, or runtime allocation.

## 6. Native testing found real integration bugs

The first native matrix found that upstream ES6 block-scoping is opt-in. Without
that option, callbacks from a let loop observe the final loop variable. The
new driver and C reference invocations are being configured consistently, with
separate tests for per-iteration captures and temporal dead zones.

AddressSanitizer also found an error-stack-trace crash: the bridge initialized
src_location_idx to UINT32_MAX, whereas this pinned runtime uses zero for an
invalid location. The value is now zero. This was a bridge bug, not a change to
JavaScript's exception behavior. The compiler and runtime retain AddressSanitizer;
LeakSanitizer was disabled in these sandbox runs after its process-inspection
operation failed. Later validation records retain that qualification.

## 7. PicoCalc compatibility lane

The recovered TypeScript frontend now emits LLVM directly for the inherited
integer world language. The original C route remains selectable as an oracle.
The complete gate captured 24 tests passing, with no failures or skips, including
200 C/LLVM event comparisons and the original 160 Node event comparisons.
Six direct LLVM modules were independently assembled and verified, linked as
RV32IM ELF files, and executed by the original instruction runner.

The recorded replacement trace retains state, changes generation, rejects an
old-generation queued event, rolls back a failed migration, and continues the
surviving generation to score 129. A denied sandbox Unix-socket test and an
incomplete first permitted retry are both preserved in the device diary; only
the subsequent complete test log counts as the 24-test gate.

## 8. Final host matrix and raw defaults

The final full matrix passed all 22 source cases: 16 positive programs, three
runtime-error fixtures, and three compile rejections. The positive sources ran
at Hermes O0/O and LLVM O0/O2, producing 64 native comparisons with matching
Node and unchanged C-backend output. Three selected programs also passed actual
lli JIT execution, including the closure and forced-collection fixtures. The
three error sources produced six checked error executions.

The collection fixture allocates 50,000 temporary structures, prints the actual
gc hook type, explicitly requests collection, and then reads retained captured
values. This establishes the recorded survivor graph; it does not establish all
collector schedules or a freestanding device runtime.

Six compiler-driver checks passed. Five additional raw CLI checks established
modern lexical defaults, respected explicit disable overrides, and recorded the
upstream static-TDZ diagnostic. The supplied const reassignment likewise remains
a compile-time rejection. These are visible language boundaries, not suppressed
test failures.

## 9. Worked example and independent review

Added examples/llvm/counter.js, combining independent counter environments,
three sibling lambdas, object snapshots, an array callback, a class method
returning a lexical-this arrow, and an exception retaining a read closure.
Native compilation and lli execution both produced:

```text
41 42 42 105
{"value":42,"description":"captured state"}
7,14,21
50
example 52
```

A read-only review followed the argument buffer through its nonallocating copy
into the Hermes register stack, checked root restoration after longjmp, checked
all-loads-before-any-stores phi transfers, and checked unit/code lifetime. No
new blocker was found in those paths. It identified a diagnostic parity gap:
the direct emitter did not consult the lowered-Hermes-IR verification option.

## 10. Final verifier guard and evidence chain

Added the same conditional IR_LOWERED verification sequence used by the C
backend. Only LLVMBackend.cpp and the rebuilt compiler changed relative to the
historical 34-entry validation manifest; the other 32 entries retained their
hashes. The original complete-matrix JSON and manifest were preserved.

Focused validation compiled all 16 positive sources at both Hermes levels with
verify-ir explicitly off and on: 32 pairs had byte-identical emitted IR, and
all 64 modules passed llvm-as and the LLVM verifier. The updated compiler also
passed the counter native and lli runs. The full native matrix was not rerun.

Upstream's full Hermes IR verifier is enabled by HERMES_SLOW_DEBUG in a Debug
build. Our Release build uses its no-op implementation. The focused evidence
therefore proves option plumbing, unchanged emission and actual LLVM
verification; it does not claim a malformed-Hermes-IR rejection experiment.
The two verifier layers are documented separately.

## 11. Reproducible release and report

The final compact patch was built using an isolated temporary Git index and
applied to a second index initialized at the pinned upstream base. The resulting
trees were identical. The main working-tree index was unchanged. The patch
contains 40 selected source, fixture and guide files; the full release also
contains the upstream source tree, both projects' evidence and diaries, and the
new textbook report.

The report is assembled from the reviewed architecture, integration, driver,
introduction and validation chapters. It includes exact vector diagrams,
the executed counter example, evidence tables, primary references and five
laboratory exercises. PDF layout was checked by rendering every page and
checking extracted text bounds; final packaging also checks archive CRCs and
member hashes. Detailed component records follow in the consolidated diary.

## 12. First-run dependency correction

The last reproduction review found that the wrapper refreshed only the shared
bridge target, although native linking consumes the static archive. The initial
test matrix had already-built libraries, so it did not exercise a missing
archive on first use. The automatic build now requests both static and shared
bridge targets; the initial documented build command does likewise.

Focused validation temporarily moved the static archive aside, invoked the
ordinary native run without the no-runtime-build shortcut, and observed CMake
recreate an identical archive. The counter output matched. The ordinary lli
path also passed with both targets requested. This evidence is separate from
the previous full matrix and verifier-option checks. No instruction translation
changed in this correction.

The test instructions now distinguish the main runner's environment variables
from the raw driver's compiler option and the lexical check's build-dir/clang
options. The PDF was regenerated after these final reproduction corrections.

## 13. Final gate on the exact release binaries

The automatic dependency build refreshed libhermesvm.so as well as rebuilding
the missing static archive. That changed runtime binary was a concrete reason
to repeat the complete host matrix. The rerun used the final compiler, driver,
VM and both bridges, without quick mode or a JIT skip.

All 22 source cases passed: 64 native comparisons with Node and the C backend,
three lli comparisons, six expected runtime-error executions, and three
compile-rejection preservation cases. The 42 recorded implementation, fixture,
tool and binary hashes were identical before and after the final gate.
Original full-matrix and focused-review JSON files remained byte-identical.

The final release evidence is final-validation.json, final-validation.log and
final-validated-files.json. The report, source release and provenance identify
that gate separately from the earlier successful matrix and intermediate
diagnostic/dependency checks. No further implementation changes followed it.



# Component record 6: Compiler integration and validation diary


# Compiler driver and build diary

Date: 28 October 2026. This records actions and observed outcomes, not hidden reasoning.

## Source baseline

Retrieved the official Static Hermes `static_h` repository and pinned commit `f837b9dd8396ebf5c4e8115412417d273565f0fe`. Inspected the native compiler driver, pre-allocation lowering, register allocation, runtime frame and root conventions, closure helpers, object operations, exception handling, and module lifetime contract. Initial source inspection notes are in the separate research handoff.

## Build configuration

The repository asks for AddressSanitizer during development. Configured `build-llvm` with Clang 18, CMake 4.4.4, Ninja 1.13.2, `CMAKE_BUILD_TYPE=Release`, `-O1 -DNDEBUG`, and `HERMES_ENABLE_ADDRESS_SANITIZER=ON`. This keeps sanitizer checking while limiting compilation cost. Parallelism is three compiler processes. The built-in test suite is disabled for this build; focused new-backend tests will run separately. Boost context is disabled. Default Unicode support remains enabled.

Command:

```sh
cmake -S . -B build-llvm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/tmp/llvm-direct-toolchain/bin/clang \
  -DCMAKE_CXX_COMPILER=/tmp/llvm-direct-toolchain/bin/clang++ \
  -DCMAKE_MAKE_PROGRAM=/tmp/llvm-direct-toolchain/bin/ninja \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DHERMES_ENABLE_TEST_SUITE=OFF \
  -DHERMES_ENABLE_ADDRESS_SANITIZER=ON \
  -DCMAKE_CXX_FLAGS_RELEASE='-O1 -DNDEBUG' \
  -DCMAKE_C_FLAGS_RELEASE='-O1 -DNDEBUG' \
  -DHERMES_ALLOW_BOOST_CONTEXT=0
cmake --build build-llvm --target shermes -j3
```

Configuration succeeded. Initial compiler build contains 252 scheduled steps. The first run began before driver edits but may compile edited translation units before finishing; it is not evidence of an untouched baseline binary.

## Direct LLVM command integration

Added `OutputLevelKind::LLVM` and the `--emit-llvm` command-line choice. The compiler keeps the ordinary frontend/semantic-analysis/optimization pipeline, then calls `sh::generateLLVM` instead of generating C. The output defaults to a `.ll` file derived from the final input basename. `-o -` writes the completed module to standard output.

Emission is buffered until backend success so failed opcode validation cannot expose a partially emitted stdout module. Named output uses the existing temporary-file-and-rename `OutputStream`, preserving an existing file when compilation fails. The new mode does not invoke a C compiler.

Added a public `sh::lowerForLLVM` wrapper around the existing module lowering, preserving SSA before SH register allocation. The LLVM backend must not run the register-allocation-dependent second lowering stage. The SH backend CMake target now includes `LLVMNative/LLVMBackend.cpp`.

Checkpoint UTC: 2026-10-28T13:25:54.580037+00:00

## First build and integration corrections

The first Ninja invocation began from the original generated build graph. It completed the compiler objects but could not link the new driver because the new LLVM emitter source was not present in that graph yet. Reconfiguration correctly added the source. The first emitter compilation then reported four mismatched instruction getter names. The emitter owner corrected these against the pinned `SH.cpp` implementation; no changes to existing Hermes instruction APIs were needed.

The next build successfully linked `shermes` and `hermesc`. During runtime dependency generation, LeakSanitizer failed because this sandbox prevents reading another process's `/proc/.../task` directory. The error explicitly identified LeakSanitizer's process-inspection restriction. Reran with `ASAN_OPTIONS=detect_leaks=0`, leaving AddressSanitizer address instrumentation enabled. Therefore the validation is not leak-sanitizer evidence.

## Once-built bridge targets

Added a PIC object target for `LLVMNative/runtime.c`. Both `shllvm_runtime` (static archive) and `shllvm_runtime_shared` reuse that single object. The resulting libraries are `build-llvm/lib/libshllvm_runtime.a` and `.so`. The shared library links the existing Hermes runtime and console bindings. Generated programs can reuse this runtime instead of recompiling C per source module.

## Actual emission and publication checks

Compiled a real JavaScript probe containing a for loop, recursive factorial, an object, an arrow function, a function expression, and two closures sharing a mutable captured variable. `shermes -O0 --emit-llvm` emitted a 30,892-byte module with eight LLVM function definitions. `llvm-as` 18 accepted it. Expected runtime output is `45 720 11 12 12`; execution is still pending the VM dependency build at this checkpoint.

Ran `utils/test_shllvm_driver.py`: all six cases passed. The checks cover default `.ll` creation with an invalid `CC`, no generated C, stdout main, exported-unit main suppression, syntax failure preserving an existing output, and unsupported backend instruction failure preserving both existing output and empty stdout. Evidence is stored in `docs/llvm/evidence/driver-validation.json`.

Checkpoint UTC: 2026-10-28T13:31:53.425529+00:00

### Bridge symbol visibility

Inspected the generated compile command and found that upstream globally sets `-fvisibility=hidden`. Added a bridge-specific default-visibility override because independently compiled LLVM modules and `lli` must resolve the public `shllvm_*` ABI. The standalone static and shared runtime bridge targets remain separate from the compiler backend target.

## First native execution

Linked the probe's LLVM IR directly against the newly built static bridge archive, existing shared Hermes runtime, and console bindings. Clang `-O2 -fsanitize=address` produced an executable, which printed exactly `45 720 11 12 12` and exited successfully under `ASAN_OPTIONS=detect_leaks=0`. This executes the loop, recursive calls, returned object, arrow closure, function expression, and shared mutable environment; the result is not an interpreter-only reference output. The compiler also produced an x86-64 ELF object with a `.text` section of 0x168c bytes before final linking.

The shared bridge rebuild is still completing dependency updates. Its object and static archive already carry the explicit symbol visibility and latest runtime helpers. Native probe execution did not rely on the still-stale shared bridge.

Checkpoint UTC: 2026-10-28T13:37:23.142435+00:00

## Lexical-scoping defaults

Differential execution identified that upstream Static Hermes leaves ES6 block scoping and temporal-dead-zone checking disabled by default. That legacy configuration gives loop closures shared bindings rather than the usual per-iteration `let` bindings. Updated only direct LLVM mode to enable both options before parsing/semantic analysis. Explicit `-Xes6-block-scoping=false` or `-Xenable-tdz=false` remains respected. Existing C backend defaults remain unchanged, so differential C reference commands pass both flags explicitly.

This change selects existing Hermes frontend behavior; it is not a claim of full ECMAScript conformance. The implementation will be checked with actual per-iteration closure and uninitialized-binding programs.

## Runtime safety finding

The runtime validation agent found a native error-stack-trace crash caused by an incorrect source-location invalid sentinel in the new bridge. The pinned Hermes source uses zero, not `UINT32_MAX`. That agent corrected `runtime.c`; the final bridge rebuild must include the correction. This is an example of why code generation must preserve runtime metadata conventions even when LLVM accepts the IR.

## Final compiler and bridge build

The compiler, static bridge, and shared bridge all built successfully. The final incremental invocation completed 17 steps. `llvm-nm -D` verified that the shared library exports the public `shllvm_*` ABI, including call, run, frame sizing, try setup, and object-parent helpers. The shared library contains the corrected source-location sentinel and current class/exception helpers. No build processes remained at handoff.

The original C backend also ran the first probe and printed the same `45 720 11 12 12`, confirming that the new command-line output level did not disrupt that path.

## Raw command-line lexical behavior

Added and ran `utils/test_shllvm_defaults.py`, which invokes `shermes --emit-llvm` directly rather than relying on a wrapper that might supply flags. All five final checks passed:

| Check | Observed result |
| --- | --- |
| Default loop capture | `0 1 2` from three per-iteration closures |
| Explicit block-scoping false | `3 3 3`, preserving the requested legacy option |
| Default cross-function TDZ read | A caught `ReferenceError`, then initialized value `7` |
| Explicit TDZ false | `undefined`, then initialized value `7` |
| Obvious same-function TDZ violation | Compile-time diagnostic; no partial stdout module |

The final test deliberately retains the pinned frontend's static-diagnostic boundary rather than claiming that every early lexical read becomes a catchable runtime exception. The closure-mediated case proves the emitted dynamic check executes correctly.

Two test-harness issues were resolved before the final result: the first manual dynamic-link command omitted the explicitly referenced Hermes runtime library, and the initial TDZ-disabled expectation assumed an ignored function result would be printed. The corrected linker includes `-lhermesvm`; the test now explicitly prints the inner result. No compiler semantic change was made to satisfy that mistaken expectation. Initial command failure evidence is retained in `lexical-defaults-initial-failure.json`.

Reran the six driver publication/output tests against the rebuilt compiler: 6/6 passed. The raw lexical suite is 5/5; these are separate from the larger runtime agent's differential matrix.

Reproduction:

```sh
ASAN_OPTIONS=detect_leaks=0 python3 utils/test_shllvm_driver.py \
  --evidence docs/llvm/evidence/driver-validation.json
ASAN_OPTIONS=detect_leaks=0 python3 utils/test_shllvm_defaults.py \
  --clang /tmp/llvm-direct-toolchain/bin/clang \
  --evidence docs/llvm/evidence/lexical-defaults-validation.json
```

Use a normal installed Clang path outside this workspace; the absolute toolchain path above records the validation environment. Leak detection is disabled only to accommodate the observed sandbox process-inspection restriction. Address checking remains enabled in the built runtime and bridge.

Completed checkpoint UTC: 2026-10-28T13:42:40.866405+00:00


## Post-review lowered-IR verifier parity

Checkpoint UTC: 2026-10-28T13:51:07.449957+00:00

The final source review identified one concrete diagnostic parity omission: the new `generateLLVM()` entry point did not honor `BytecodeGenerationOptions::verifyIR` after Static Hermes lowering. The existing C backend performs `verifyModule(..., VerificationMode::IR_LOWERED)` at that point. Added the `IRVerifier.h` include and the same conditional check before `assignIndexToVariables()`. Failure reports `Lowered IR verification failed` and returns false, preserving the driver's buffered publication behavior. No other implementation source was changed for this correction.

Before editing, captured the current compiler, implementation, runtime, and fixture hashes in `docs/llvm/evidence/post-review-before.json`. Every file matched the existing `validated-files.json` from the complete differential matrix. Both that historical manifest and `validation.json` remain unchanged; the earlier 64 native comparisons continue to describe their original compiler identity.

Rebuilt only the `shermes` target with the existing ASan Release configuration. The incremental build compiled the emitter, rebuilt the compiler archive, and linked `shermes` in three successful steps. Build command and complete output are in `post-review-build.log` and the new evidence JSON.

| File | Previously validated SHA-256 | Post-review SHA-256 |
| --- | --- | --- |
| `lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | `0209190e48cadde302d3237615f6972e5a3c65a3c1d86a7f454cd5b49d816c15` | `04569fe6e459ef02a43eddf0e4883748151581955857d9143e03c5ea405b8126` |
| `build-llvm/bin/shermes` | `0c0541c75d1d9826df860e7277577b8ec01838ebafd1dde5763605d30cbed347` | `29c967d6ec9212051d0e38d5d952d8e10e7175d2d2977a42a250a6dbfdcfb7f8` |

The focused verification explicitly used `-verify-ir=false` and `-verify-ir=true` for all 16 positive fixture sources, once at Hermes `-O0` and once at Hermes `-O`. All 32 enabled/disabled pairs were byte-for-byte identical. All 64 emitted modules assembled with LLVM 18 `llvm-as` and passed `opt -passes=verify -disable-output`. Each command, result, source hash, and LLVM output hash is recorded in `docs/llvm/evidence/post-review-verifier.json`. Removing exactly the new include and conditional guard reproduces the previous emitter hash; no other source differences are hidden in this update.

Ran `examples/llvm/counter.js` through the updated compiler once as a native executable and once through `lli`, with Hermes `-O` and LLVM `-O2`. Both executions exited zero and matched the prior five-line counter output, including the captured object snapshot, array callback, class method, and caught exception. New stdout/stderr captures have the `post-review-counter-` prefix so the prior execution captures remain intact. The full native differential matrix was not rerun.

Verification scope matters here: upstream `verifyModule()` performs full Hermes checks only when `HERMES_SLOW_DEBUG` is defined. CMake enables that definition in Debug configuration; this existing Release compiler uses the upstream no-op implementation. These checks therefore establish flag plumbing and output invariance, plus real LLVM assembler/verifier acceptance. They do not demonstrate malformed-Hermes-IR rejection in a Debug build. The new guard follows the same configuration-dependent behavior as the C backend.

AddressSanitizer remained configured for the compiler/runtime/bridge. `ASAN_OPTIONS=detect_leaks=0` remains necessary for the previously recorded sandbox restriction; no leak-sanitizer claim is made. The runtime libraries, bridge sources, driver sources, and test fixtures retain their historical validated hashes. The post-review evidence reports all checks passed and exactly the two expected changed files.



# Component record 7: Runtime bridge and test diary


# Direct LLVM runtime bridge diary

## 2026-10-28 — toolchain and contract

Located no LLVM compiler in the active environment. Downloaded official Ubuntu Noble LLVM/Clang packages, version 18.1.3-1ubuntu1, into a private `/tmp/llvm-direct-toolchain` directory and extracted them without system package installation. Installed CMake 4.4.4 and Ninja 1.13.2 in the same private directory. Verified LLVM assembly, optimization, `lli` execution, native linking/execution, C runtime compilation, and RV32IM relocatable object generation. The RISC-V check demonstrates code generation only, not target execution. Package hashes, URLs, commands and outputs are retained with the toolchain evidence.

## ABI inspection

Inspected upstream `static_h.h`, `sh_legacy_value.h`, `sh_runtime.h`, `sh_stack_frame.h`, `StaticH.cpp`, `StaticHUnit.cpp`, and `SH.cpp`. The existing runtime supplies value semantics, object access, allocation, environments, closures, calls and console bindings. A direct IR backend can retain these runtime contracts while replacing per-program C emission.

`SHLegacyValue` is an eight-byte struct containing a union of `uint64_t` and `double`. A Clang 18 host ABI probe confirmed both a return of this type and an indirect callback call lower as `i64 (ptr)` on this x86-64 Linux build. The bridge statically requires eight-byte values and eight-byte pointers. This evidence does not establish an executable RV32 runtime ABI.

Rather than reproducing C bitfield layout for `SHNativeFuncInfo` in LLVM, selected a public metadata descriptor with four 32-bit integers: name index, argument count, function kind, and invocation prohibition. The once-built C bridge copies these descriptors into actual native runtime structures. The compilation unit, symbol table, read/write property caches and function metadata share one allocation, released by the existing Hermes runtime lifecycle.

## Rooting and stack ownership

Every LLVM value slot is in caller-owned `SHLocals` storage. `shllvm_frame_size` supplies its size, `shllvm_enter` initializes all roots to undefined, links the root list and reserves outgoing argument registers, and `shllvm_leave` restores the runtime stack. No root record is allocated in a bridge helper's temporary stack frame, and no heap-allocated frame requires cleanup when Hermes uses longjmp for an exception.

Native closures capture the existing Hermes heap environment. The absence of an environment is represented by undefined in root slots, converting to a null parent pointer only at the runtime API boundary. An object-tagged null pointer is explicitly avoided because it is not a valid GC root.

Call lowering copies already-evaluated arguments into the outgoing register frame without allocating, then enters `_sh_ljs_call`. The compiler must reserve its maximum explicit argument count and retain all operands in rooted storage until the copy. Results are written through explicit output pointers. Runtime helper calls receive pointers to rooted values, avoiding aggregate ABI assumptions and permitting moving-GC updates.

## Implemented operation families

The bridge covers constants, NaN-canonicalized numbers, booleans, truthiness, parameters, global values/bindings, string symbols, closure creation, environment creation/load/store/traversal, dynamic and builtin calls, numeric/coercing binary and unary operations, objects, arrays, property lookup/write/definition/deletion, receiver-sensitive property operations, accessors, constructor setup/result selection, `this`, `new.target`, invocation restrictions, lazy arguments, and runtime throw/type checks.

Global `try-get` and `try-put` operations retain upstream missing-binding behavior. By-id property operations use per-string caches registered in `SHUnit`, keeping cache pointers visible to the collector. Arbitrary property operations use existing dynamic runtime helpers.

Corrected the proposed invocation enum interpretation after checking the actual upstream declaration: `Function::ProhibitInvoke` is 0=None, 1=Construct, 2=Call. The runtime bridge matches these values.

## Initial compile validation

`runtime.c` compiles using Clang 18 with `-std=gnu11 -DNDEBUG -Wall -Wextra -Werror -Wno-unused-parameter` and the generated runtime configuration header. It also compiles with AddressSanitizer enabled, matching the current Hermes build. End-to-end execution and GC behavior require the complete compiler/runtime build and subsequent integration tests; successful object compilation alone is not a semantic validation claim.

## Exceptions and class completion

Added the existing Hermes class-creation operation, constructor invocation checks, receiver-sensitive accessors and superclass support through explicit value pointers. Function metadata uses the original prohibition enum (none/construct/call).

Implemented an opaque exception-record API. `shllvm_try_begin` links a caller-owned `SHJmpBuf` and returns its actual `jmp_buf` address; it intentionally does not call setjmp. The generated LLVM function must execute `_setjmp` itself, with LLVM's `returns_twice` attribute, while that activation remains alive. Catch preparation restores Hermes roots/current frame/register-stack state without removing the function's handler. Catch-value extraction and rethrow use the original runtime operations.

A source audit found that upstream `LiteralUninit` is represented as undefined, while `LiteralEmpty` uses the empty tag. Corrected the initial bridge mapping and added an explicit two-bit TDZ check mask rather than conflating the two values. This was found before integrated execution.

## Build/run tools and semantic fixtures

Added a standard-library-only Python driver for direct IR emission, LLVM assembly and verification, optimized bitcode, native linking, and `lli` JIT execution. The bridge is built through a shared CMake target once and thereafter reused through build-system dependency tracking. Metadata records source/IR/runtime/executable hashes and commands. Per-program C generation is absent from this pipeline; the unchanged C backend remains available only as a test comparator.

Added Node-backed fixtures covering recursion, mutual recursion, higher-order functions, mutable/sibling/multilevel closures, lexical arrow `this`, methods/accessors, ordinary and derived constructors, object identity/cycles/dynamic properties, Unicode property names, arrays and native callbacks, per-iteration closures, simultaneous phi updates, coercion order, missing arguments, lazy arguments, runtime errors, nested exceptions and finally control flow, and allocation pressure with retained closures. The initial fifteen positive source fixtures all ran successfully under Node. Final backend execution results are recorded separately.

The first native link attempt encountered hidden bridge symbols because the upstream project enables hidden visibility globally. The build owner corrected the bridge target to export its C ABI. This was a bridge packaging issue, not evidence of a successful native run.

The ASan build's LeakSanitizer cannot inspect `/proc` in the sandbox. Validation uses `ASAN_OPTIONS=detect_leaks=0` for this environment and records that setting. AddressSanitizer remains enabled. The driver itself does not silently change this setting for ordinary users.

## First differential execution: defects and corrections

The first direct LLVM native functions case returned the expected `40320 true true 42 42`. The initial wider matrix exposed two actionable problems. First, both the original C backend and the LLVM backend used legacy loop binding behavior by default. Enabling the existing `-Xes6-block-scoping` frontend option produced distinct per-iteration environments and matched Node. The driver and C comparison commands now explicitly use that option; fixtures retain their original closure semantics.

Second, constructing an Error crashed while recording its native stack trace. Symbolization located `JSError::recordStackTrace`, and source inspection showed the bridge had chosen the wrong invalid source-location sentinel. The actual `SHSrcLocationTable::kInvalidLocIdx` is zero, not UINT32_MAX. Corrected the bridge header initialization to zero. Error creation must be rerun after rebuilding the bridge; successful arithmetic/closure tests had not exercised this path.

A pending static archive rebuild also temporarily lacked the newly added explicit-prototype helper. Build/export mismatches are recorded as failed build stages, not semantic successes.

## Successful integrated validation

After rebuilding the bridge with the zero source-location sentinel and enabling the frontend's block-scoping/TDZ options, the complete recorded differential matrix passed. There were 22 source cases: 16 successful programs, three runtime-error programs and three explicit compile rejections. The successful programs produced 64 native LLVM outputs across the Cartesian product of Hermes O0/O and LLVM O0/O2, each matching both Node and the existing C backend. Three additional programs (functions, mutable closures and allocation/GC closures) ran through LLVM `lli` and matched Node. Six native error executions reported the expected TypeError/ReferenceError. All rejection tests left the sentinel output file unchanged.

The forced-GC fixture reported `gc-hook function` and executed `gc()` unconditionally after allocating 50,000 object/array structures with cycles and retaining ten escaping closures. Its output preserved the independent captures `0,5000,...,45000` and a mutable counter object after collection. The upstream implementation of `gc()` calls `runtime.collect("forced")`; this is stronger evidence than merely allocating garbage without demonstrating that collection occurred.

Class inheritance/super calls, lexical arrow `this`, getters/setters, nested try/catch/finally with thrown closure-bearing objects, finally overrides of returns, break/continue through finally, recursion, function identity, Unicode strings/property names, `arguments`, callbacks from array builtins, coercion order and TDZ errors all passed their differential checks.

Native execution links the shared Hermes VM and console libraries explicitly; the bridge is reused as a static archive. The JIT path loads the shared bridge into `lli`, preloading the matching ASan runtime when necessary. Runtime and bridge address checks are active; generated LLVM function bodies are not claimed to be fully ASan-instrumented.

`docs/llvm/evidence/validation.json` contains commands, exit statuses and output for the successful run; `validation.log` is its compact transcript. Earlier failed runs remain separate evidence. Representative emitted `.ll` files, build records and extracted application disassembly are in `evidence/samples/`; binary/source identities captured after validation are in `evidence/validated-files.json`.

## 2026-10-28T14:04:00+00:00 — final first-run driver correction and release gate

Documentation review found that ordinary build/run invocations requested only the shared bridge target, while native linking requires the static archive. Updated the automatic CMake invocation to request both `shllvm_runtime` and `shllvm_runtime_shared`, updated the missing-artifact diagnostic, and corrected the initial build command in `DRIVER.md`. The driver SHA256 changed from `ed3f17fd1ff5b8beb67857fb4c5514492e629e4ac896332fd9f5a88acae4a456` to `dc3e04a08fcfafadaf585884880b5a30bee39579520d5b57ffc0ebbf7614a291`.

The focused check temporarily moved the static archive to a private backup and ran the counter through the normal native driver path with automatic builds enabled. CMake recreated the archive byte-for-byte. Native and `lli` executions both requested the two targets and produced the expected five output lines. `post-review-driver.json` records the exact before/after file hashes, commands, output and missing-archive simulation. The first automatic build also completed 13 pending dependency steps following the compiler-only verifier review, regenerating internal bytecode and relinking the VM. Only `libhermesvm.so` changed identity among the previously captured binaries, to SHA256 `dac68c34fed2114807d88ab6ae34d556b49c695305391c55550a00b195f24b1e`. No binary-equivalence assumption was made for that relink.

The final complete matrix was therefore rerun with `utils/test_shllvm.py --jobs 2 --output docs/llvm/evidence/final-validation.json`, with no quick mode, case filtering or JIT skips. It passed all 22 source cases, 64 native LLVM comparisons with Node and the C backend, three `lli` cases, six checked runtime-error executions and three compile-rejection/output-preservation cases. All 42 implementation/tool/fixture/compiler/runtime/bridge identities were unchanged before and after the gate. `final-validation.log` and `final-validated-files.json` retain the transcript and exact tested identities. The original full-matrix records and both focused review JSON records remain byte-for-byte intact. `DRIVER.md` now distinguishes the original evidence from the final release gate.

## 2026-10-28T14:04:59+00:00 — final patch verification

Refreshed the 40-file compact patch against pinned upstream `f837b9dd8396ebf5c4e8115412417d273565f0fe`, excluding build artifacts, evidence, reports and diaries. Used one private temporary Git index to construct the patch and a second independent index to apply it to the exact base. `git apply --cached --check` succeeded, the applied tree matched the proposed tree `7a091c6a393ce8304ce071c0cc0ddcd48e8f584d`, and the main repository index remained unchanged. The final patch is 177507 bytes with SHA256 `96e60e6773a883c05708bee5e3636e8f72e0f15f0209521df7b38bd7cd98471f`. `PROVENANCE.json` retains the original and final full gates separately, the focused verifier/driver review records, all selected source hashes, and the final tested binary identities.



# Component record 8: PicoCalc direct LLVM diary


# Direct LLVM backend engineering diary

## 2026-10-28 13:23 UTC — Recover and inspect the existing prototype

Recovered the original `picocalc-llvm-poc-complete.zip` into a separate working
directory. Read the original README, JS-to-C emitter, compiler wrapper, ABI
header, and all integration tests. The existing device lane is explicitly a
bounded integer JavaScript subset, with a 16-byte state structure, two fixed
RV32IM code slots, capability `ecall`s, and an instruction interpreter that
commits state and effects only after a successful turn. Keep this contract.

The direct LLVM lane will replace only per-module C generation/parsing. The
existing C emitter remains an explicit differential oracle. The independent
Static Hermes work provides the dynamic objects/closures lane; this device
prototype must not silently claim those broader semantics.

Installed toolchain is the shared private LLVM 18.1.3 toolchain. Inspected a C
ABI fixture lowered by Clang: RV32 uses opaque pointers, data layout
`e-m:e-p:32:32-i64:64-n32-S128`, and fixed-register inline-assembly constraints
for `a0` (`x10`) and capability selector `a7` (`x17`). The direct emitter will
state this ABI explicitly. Arithmetic will omit `nsw`/`nuw`, matching the
existing `-fwrapv` contract, and comparisons will preserve the existing C
frontend's unsigned `event`, `version`, and `state.schema` types.

Implementation plan: TypeScript AST to typed i32 expression values; mutable
locals use entry-block allocas; branches and loops use basic blocks;
short-circuit operators use branches and phi nodes; state accesses use GEP;
capability calls emit inline LLVM assembly. Generated `.ll` is fed directly
to the LLVM input path. Keep generated IR beside each ELF for review.

## 2026-10-28 13:27 UTC — Implement and test the complete original device lane

Added `compiler/js2llvm.js`, a direct LLVM emitter for the complete existing
integer world grammar. Changed `compile.py` to select it by default for JS and
retain `--backend c` for the previous path. The daemon accepts the same backend
option. Output metadata now identifies the backend, source/generated-content
hashes, optimization level, and measured frontend/LLVM/link durations. C source
input remains supported through its original route.

Pinned TypeScript 5.8.3 with a generated lockfile. The initial sandboxed npm
attempt failed before dependency retrieval; the reviewed network retry
succeeded. Initial direct LLVM verification and native RV32 interpretation
succeeded, including nested short-circuit phi nodes, source side effects,
unsigned promotion, wrapping overflow, and local-variable loops at O0/O2/Oz.

Added eight test methods, including 200 seeded C-versus-LLVM event comparisons,
LLVM assembler/verifier checks, bounded arithmetic edge cases, compile-failure
preservation of the previous ELF, and negative language-boundary checks.
The first full run passed 23 of 24 tests; the sole failure was the existing
Unix socket service test because sandbox policy prevented daemon binding.
Requested the permitted local-socket execution environment for that gate.
This failure is environmental and is retained in `logs/direct-llvm-tests.txt`;
it is not silently reported as a compiler regression or omitted.

## 2026-10-28 13:30 UTC — Final validation and native artifacts

The first permitted-socket execution returned a tool status of zero, but its file ended mid-suite. That incomplete file was not accepted as a successful gate. A repeated run captured the entire subprocess output and verified the unittest summary: **24 tests passed, zero failed, zero skipped**, in 17.132 seconds. The complete record is `logs/direct-llvm-tests-with-sockets-final.txt`; `logs/direct-llvm-validation.json` records the log and final source hashes. The final direct-frontend-only run also passed all eight test methods after tightening optional-chain rejection.

The artifact collector assembled and verified six direct LLVM modules, linked them as freestanding RV32 ELF images, and executed the hot-reload scenario. Version 1 increments score to 3; version 2 retains state and changes score to 43; a bad migration aborts without replacing the active generation; the surviving version then triples score to 129. Final epoch remains 2. No generated C participates in this path. Logs include actual RV32 disassembly, ELF metadata, the eleven-record scenario trace, tool versions, phase timings, and source/artifact hashes.



# Component record 9: PicoCalc review diary


# PicoCalc integration and independent backend review

## 2026-10-28 13:35 UTC — Read-only source review

Read the in-progress direct LLVM emitter and C runtime bridge against the
upstream SH C emitter, lowering passes, IR instruction definitions, StaticH
runtime helpers, and native register-stack layout. This review did not modify
the emitter or bridge. Their authors were actively editing them, so each
finding refers to the code observed at review time rather than a frozen final
revision.

### Confirmed implementation relationships

- Phi-edge lowering loads every incoming value before any destination store;
  this implements simultaneous assignments for loop-carried swaps.
- Every runtime-value result and constants live in SHLocals root slots.
  The separate argv array is copied into the traced register stack before a
  runtime call; the copy loop itself allocates nothing.
- The array allocator creates both capacity and logical length. LiteralEmpty
  elements remain literal through the upstream LoadConstants pass, so skipping
  their definition preserves holes. Subsequent dynamic stores remain in IR
  order.
- Function-name indexes, expected argument counts excluding this, function
  kinds, and invocation prohibitions correspond to SH.cpp's metadata table.
- Returned tagged values are loaded before the nonallocating leave helper;
  this is safe only while that helper retains its no-allocation behavior.

### Findings sent to the implementer

1. BaseAllocObjectLiteralInst includes typed nonenumerable subclasses. Emitting
   every property enumerable=true for those subclasses is semantically wrong.
   Explicit rejection was observed being added during the review.
2. A 65,536-root admission permits more than 512 KiB in a native stack alloca,
   and argv could add more. Hermes's default/minimum native stack gap is 64 KiB.
   A before/after address check alone can jump across that gap. Suggested a
   conservative combined roots+argv admission or a size-aware stack check.
3. ThrowIfInst's bad-type mask may include Uninit. Upstream represents
   LiteralUninit as undefined and checks is_undefined for that arm; a helper
   checking only is_empty does not implement all masks. Suggested preserving
   the explicit mask or rejecting unimplemented checks.

The final validation owner must record fixes/tests for these issues; this
review log does not claim that review alone proved semantic equivalence.

### Integration document

Wrote PICOCALC_INTEGRATION.md explaining the executed scalar RV32 lane and the
separate dynamic native-host Hermes lane. It explicitly covers code/root/runtime
generation ownership, serialized state migration, the gap between canceled
external effects and heap rollback, native interruption, and the fact that
removing the bridge's host64 assertion is not an RV32 runtime port. No physical
ESP32-P4 execution or dynamic-heap device support is claimed.



# Component record 10: LLVM toolchain preparation


# LLVM toolchain investigation diary

2026-10-28 America/New_York. Task: locate or install host LLVM compiler tools for direct LLVM IR emission and native/RV32 compilation. Existing projects remain untouched.

## Discovery and installation

No clang, LLVM, Rust, or Go executables were present on PATH; no prior LLVM toolchain was available under /tmp, /opt, or the project workspace. Host is Linux x86-64 with GCC 13.3.0 and standard dynamic dependencies. Sandbox HTTP requests failed with Operation not permitted. Official Ubuntu metadata/package download actions received automatic approval. No user file was uploaded.

Installed Ubuntu Noble LLVM/Clang **18.1.3-1ubuntu1** by extracting ten official .deb packages beneath `/tmp/llvm-direct-toolchain/root`. No system installation or repository mutation occurred. Download checksums and source URLs are in `/tmp/llvm-direct-toolchain/manifest.json`.

Convenient executable directory: `/tmp/llvm-direct-toolchain/bin` (symlink to private LLVM bin). Executables find their shared LLVM libraries through existing relative RPATH; no LD_LIBRARY_PATH is required.

## Verification

Successfully assembled direct textual LLVM IR, verified and optimized it using `opt -passes=verify,default<O2>`, executed it through `lli` (exit value 42), compiled/linked and executed the same IR as a native executable (exit value 42), compiled/ran a C stdio program, and generated/disassembled a 32-bit RISC-V ELF object using `llc -mtriple=riscv32-unknown-elf -mattr=+m -filetype=obj`. These tests validate host execution and RV32 code generation; RV32 execution/device support are not demonstrated by this probe. Detailed commands, exit codes and output: `/tmp/llvm-direct-toolchain/validation.json`.

## Static Hermes build tooling

Installed PyPI binary distributions CMake 4.4.4 and Ninja 1.13.2 under `/tmp/llvm-direct-toolchain/python-tools`, with convenient symlinks in the same `/tmp/llvm-direct-toolchain/bin` directory. Checked version commands. Current Hermes source has a self-contained Linux Unicode backend and does not require missing ICU development headers for default configuration. No system installation.


