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
