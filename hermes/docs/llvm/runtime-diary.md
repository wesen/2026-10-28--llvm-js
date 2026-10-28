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
