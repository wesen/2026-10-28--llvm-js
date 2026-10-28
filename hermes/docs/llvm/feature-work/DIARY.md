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
