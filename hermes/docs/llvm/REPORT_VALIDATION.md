# 3. Validation, findings, and boundaries

## 3.1 What each validation layer establishes

LLVM assembly and verification check the representation: types, instructions, blocks and control flow must form a valid module. They cannot determine whether a getter ran in the right order or two closures share the right binding. The differential suites therefore compare actual output with Node and the existing Static Hermes C backend where that backend has the required semantics. Node is an independent language implementation. The C backend compares code generators while using the same patched frontend and runtime. Its inherited direct-eval helper lacks lexical environment support and is explicitly excluded as an oracle for those cases.

The comparison controls matter. Both Hermes paths use ES6 block scoping and temporal-dead-zone checks. Without matching configuration, a difference may be a frontend-mode difference rather than a backend error. Tests use deterministic output; collection is explicitly requested where it is part of the test. A timeout limits the external test process, and does not claim that native guest execution has instruction fuel.

<!-- VALIDATION_TABLE -->

The suites count source cases separately from executions. Each positive extension source is run at two Hermes optimization settings and two LLVM optimization settings, producing four native comparisons, plus an `lli` execution. Expected runtime errors use error-class contracts. Explicit unsupported-language boundaries use a separate rejection contract: a Node-valid program rejected by this backend is not counted as a successful language-semantic comparison. Compile rejections also check preservation of previously published output.

The historical 22-case baseline and its 64 native comparisons remain in `evidence/final-validation.json`. The extension release reruns the updated core suite and the new extension suite against the current build. The counter demonstration, driver checks, lexical-default checks and directed specification probes retain separate denominators.

## 3.2 Functions, shared capture, and collection

The function suite exercises recursive factorial, mutual recursion, higher-order calls and an escaping returned closure. Its recorded output is:

```text
40320 true true 42 42
```

The closure suite checks shared mutable state, separate factory invocations, nested captures and recursion through a captured binding:

```text
41 42 41 41 101 41
42 43
210
```

The allocation fixture creates 50,000 temporary object/array structures, retains independently created closures, confirms the `gc` hook is a function, calls it unconditionally, and reads retained state afterward:

```text
gc-hook function
2 alive after collection 0,5000,10000,15000,20000,25000,30000,35000,40000,45000
```

This is materially stronger than merely allocating a few objects and hoping collection occurred. In the pinned runtime the hook calls `runtime.collect("forced")`. Nevertheless, this experiment does not exercise every collector schedule, every allocation-failure path, or every possible object graph. Its specific result is that the tested live closure graph survives the explicit collection request and remains callable.

## 3.3 Errors, language defaults, and publication

The runtime-error fixtures check that constructing an arrow and calling a nonfunction raise TypeError, and reading a missing global raises ReferenceError. The exception fixture also checks nested handlers and finally paths, including values retained through throwing and catching. The raw CLI checks establish default `let` loop captures of `0 1 2`; explicitly disabling block scoping produces the inherited legacy behavior `3 3 3`.

A closure-mediated read of an uninitialized lexical binding raises a catchable ReferenceError with default direct-emission flags. Explicitly disabling the TDZ option instead yields undefined. An obvious same-function TDZ violation is rejected statically by the upstream frontend. Likewise, the pinned frontend rejects assignment to a `const` binding during compilation, even when it appears inside `try`. Standard JavaScript can make such assignment a catchable runtime TypeError. These retained frontend boundaries are documented rather than presented as language conformance.

Failure publication was checked by leaving a known old output file in place and compiling invalid or unsupported input. The driver reports failure, retains that file, and emits no partial stdout module. Emission with a deliberately nonexistent `CC` still succeeds, establishing that the direct compiler's output stage does not invoke a C compiler for the guest program.

## 3.4 Integration bugs found during the work

The diary retains failed attempts because they explain why the final design contains its less obvious safeguards.

| Finding | Correction | Why it matters |
|---|---|---|
| Loop callbacks observed one final value | Enabled ES6 block scoping and TDZ by default in direct mode; matched flags in the C reference | Language configuration changes closure semantics before code generation |
| Error construction crashed in stack-trace recording | Set `SHLocals.src_location_idx` to the runtime's zero invalid-location sentinel | Native metadata is part of correctness, even when normal arithmetic works |
| Shared bridge symbols were hidden | Exported bridge entry points in the CMake object target | Native linkage and JIT lookup need visible ABI symbols |
| Uninit was treated like Empty | Matched upstream's undefined encoding and preserved TDZ masks | Ordinary undefined must not be confused with an uninitialized lexical binding |
| Explicit object prototypes lacked runtime cache state | Added a registered weak empty-shape cache to the unit | Class and inherited-object allocation must use the actual runtime contract |
| Root admission was too permissive | Limited combined root/argument slots to 1,024 | A source function must not request an enormous explicit native frame |
| Specialized object instructions could change semantics | Rejected unsupported typed forms before ordinary-object lowering | A valid-looking substitute can silently change property attributes |
| Promise.all collapsed a reaction job | Always invoked each input's then method | Microtask order and observable then access are language behavior |
| Promise species and subclass paths diverged | Added species selection and direct capability settlement | Constructor choice and reaction-job count are observable |
| Thenables ran synchronously; public primitive Promises were cached | Queued resolution jobs and returned fresh public wrappers | Callback order and object identity must match the language |
| Async-generator return interrupted an awaited finally | Resumed internal awaits with next | Cleanup and the original pending completion survive suspension |
| Negative typed-array keys became ordinary properties | Classified canonical numeric indexes before property fallback | Typed arrays have different indexed-property rules from ordinary objects |
| Static direct eval had no caller environment | Added scope descriptors, retained compiler metadata and shared environment execution | Native and evaluated closures must share live cells |
| Nested eval lost its scope or arguments alias | Restored lexical scope and captured argument metadata during runtime compilation | Dynamic closures must retain their caller bindings after return and collection |
| Optimized eval-visible bindings lost TDZ checks | Widened ordinary values while retaining internal Empty/Uninit states | An unknown value is not an initialized binding |
| Artificial eval parents admitted global new.target | Marked synthetic script parents as program scopes | Implementation scaffolding must not change source syntax context |
| Unused results exhausted the root-slot limit | Shared one rooted discard slot while retaining separate slots for used values | Larger unoptimized async functions fit without relaxing the frame bound |

The native frame limit bounds only its explicit tagged payload to approximately 8 KiB. Native headers, jump buffers, compiler spills, recursion and runtime frames add further use. Both the native stack checks and the admission limit are useful safeguards; neither is a complete resource budget.

## 3.5 Sanitizer and platform qualifications

The compiler, Hermes runtime and bridge were built with AddressSanitizer. Generated LLVM function bodies are not explicitly ASan-instrumented, so the result must not be described as full generated-code sanitizer coverage. The execution environment blocked LeakSanitizer's process inspection; the recorded commands set `ASAN_OPTIONS=detect_leaks=0`. Address checking remained active. This setting is an environment qualification, not a recommended default for every user.

The validated dynamic backend is Linux x86-64 with LLVM/Clang 18.1.3 and a 64-bit Hermes runtime. The bridge asserts eight-byte pointers and values. A separate Clang ABI probe confirmed that the native callback returning `SHLegacyValue` uses the `i64 (ptr)` LLVM signature on this host. That experiment does not establish an ABI for RV32 or another operating system.

## 3.6 What this release does not establish

The emitter now supports the requested generator and value operations and exercises async execution in the extension suite. Remaining limits include specialized internal typed-object/fast-array instructions and the explicit direct-eval boundaries explained in Chapter 7. General sloppy direct string eval would need dynamic caller binding injection. Evaluated class-private names and super references require additional class context. Dynamic source compiles to Hermes bytecode, not runtime LLVM. No Test262 pass, full upstream suite pass, exhaustive class-feature coverage, or performance improvement is claimed.

The host JIT path uses an external `lli` process. It is a real LLVM JIT execution path, but it is not a new embedded ORC API, a native-code sandbox, or a hot-reload manager. Compilation units, code and constant storage must remain alive for the runtime's lifetime. The host backend has no automatic rollback of arbitrary heap mutation and no world capability boundary. Those concerns are addressed as integration work in Chapter 4.

The PicoCalc lane's final 24-test run establishes the inherited bounded integer-world behavior in the simulator. It includes 200 seeded C-versus-LLVM event comparisons and the original 160 Node oracle comparisons. Six modules were independently assembled and verified, linked to RV32IM ELF images, and executed in the instruction runner. These counts are not host JavaScript conformance tests and do not establish physical-device execution.

## 3.7 Reading the evidence

The extension release gates are `docs/llvm/feature-work/core-final-validation.json` and `extension-final-validation.json`, with companion logs. Command-publication and lexical-default records are `driver-final-validation.json` and `lexical-defaults-final-validation.json` in the same directory. `final-validated-files.json` connects those records to the actual compiler, VM, bridge, driver and implementation sources. The extension harness also records input hashes before and after execution. Earlier baseline and first-pass records remain intact. Selected emitted IR, disassembly and build metadata are in `evidence/samples/`; toolchain provenance and the callback ABI probe are in `evidence/toolchain/`.

The device results are `picocalc/logs/direct-llvm-validation.json` and `direct-llvm-tests-with-sockets-final.txt`, together with the replay trace and ELF audit. Earlier failures and incomplete attempts are explicitly named and retained for the diary; they are not the final gate. The release manifest hashes the packaged files, and the patch verification records an application to the exact upstream base with an identical resulting source tree.
