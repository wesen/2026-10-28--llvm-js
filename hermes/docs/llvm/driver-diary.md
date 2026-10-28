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
