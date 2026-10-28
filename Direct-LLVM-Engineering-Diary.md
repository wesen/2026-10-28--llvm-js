# Direct LLVM engineering diary


28 October 2026. Consolidated from contemporaneous component records. This is a record of implementation decisions, observable actions, experiments, failures and fixes. It is not a private reasoning transcript. Component chronology and original timestamps are retained; later final results supersede preliminary attempts without deleting them.


The host dynamic-JavaScript backend and the scalar RV32 PicoCalc lane have separate validation claims. Earlier GoJSLab/Wazevo work is not part of this implementation release.


## Contents


1. Project diary

2. Compiler integration and validation diary

3. Runtime bridge and test diary

4. PicoCalc direct LLVM diary

5. PicoCalc review diary

6. LLVM toolchain preparation


# Component record 1: Project diary


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



# Component record 2: Compiler integration and validation diary


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



# Component record 3: Runtime bridge and test diary


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



# Component record 4: PicoCalc direct LLVM diary


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



# Component record 5: PicoCalc review diary


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



# Component record 6: LLVM toolchain preparation


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


