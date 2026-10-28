# 3. Validation, findings, and boundaries

## 3.1 What each validation layer establishes

LLVM assembly and verification check the representation: types, instructions, blocks, and control flow must form a valid module. They cannot determine whether a getter ran in the right order or two closures share the right binding. The native differential suite therefore compares the program's actual output with both Node and the unchanged Static Hermes C backend. Node provides an independent language implementation; the C backend holds the Hermes frontend and runtime largely constant while changing the code generator.

The comparison controls matter. Both Hermes paths use ES6 block scoping and temporal-dead-zone checks. Without matching configuration, a difference may be a frontend-mode difference rather than a backend error. Tests use deterministic output; collection is explicitly requested where it is part of the test. A timeout limits the external test process, and does not claim that native guest execution has instruction fuel.

<!-- VALIDATION_TABLE -->

The main suite counts source cases separately from executions. Sixteen positive sources, two Hermes optimization settings, and two LLVM optimization settings produce 64 native comparisons. Three additional source cases exercise runtime errors at both Hermes settings, producing six executions. Three source cases are expected compile rejections. The three `lli` comparisons are another execution path for selected positive programs, not three more source cases.

The counter example is a separate successful native/JIT demonstration. It is not silently added to the suite's 64-comparison or three-JIT counts. The driver and lexical-default suites also have their own denominators.

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

The native frame limit bounds only its explicit tagged payload to approximately 8 KiB. Native headers, jump buffers, compiler spills, recursion and runtime frames add further use. Both the native stack checks and the admission limit are useful safeguards; neither is a complete resource budget.

## 3.5 Sanitizer and platform qualifications

The compiler, Hermes runtime and bridge were built with AddressSanitizer. Generated LLVM function bodies are not explicitly ASan-instrumented, so the result must not be described as full generated-code sanitizer coverage. The execution environment blocked LeakSanitizer's process inspection; the recorded commands set `ASAN_OPTIONS=detect_leaks=0`. Address checking remained active. This setting is an environment qualification, not a recommended default for every user.

The validated dynamic backend is Linux x86-64 with LLVM/Clang 18.1.3 and a 64-bit Hermes runtime. The bridge asserts eight-byte pointers and values. A separate Clang ABI probe confirmed that the native callback returning `SHLegacyValue` uses the `i64 (ptr)` LLVM signature on this host. That experiment does not establish an ABI for RV32 or another operating system.

## 3.6 What this release does not establish

The supported ordinary function, object, closure and class cases are substantial, but the emitter does not cover every Hermes instruction or every ECMAScript construct. Generators and direct eval are explicit negative fixtures; regular-expression literal creation is also rejected by the driver tests. BigInt literal lowering, specialized typed objects/fast arrays and private-field operations remain outside the implemented set. No Test262 pass, full upstream suite pass, or exhaustive class-feature coverage is claimed.

The host JIT path uses an external `lli` process. It is a real LLVM JIT execution path, but it is not a new embedded ORC API, a native-code sandbox, or a hot-reload manager. Compilation units, code and constant storage must remain alive for the runtime's lifetime. The host backend has no automatic rollback of arbitrary heap mutation and no world capability boundary. Those concerns are addressed as integration work in Chapter 4.

The PicoCalc lane's final 24-test run establishes the inherited bounded integer-world behavior in the simulator. It includes 200 seeded C-versus-LLVM event comparisons and the original 160 Node oracle comparisons. Six modules were independently assembled and verified, linked to RV32IM ELF images, and executed in the instruction runner. These counts are not host JavaScript conformance tests and do not establish physical-device execution.

## 3.7 Reading the evidence

The final host results are `docs/llvm/evidence/validation.json` and `validation.log`. The command-publication and lexical-default records are `driver-validation.json` and `lexical-defaults-validation.json`. `validated-files.json` connects the execution evidence to hashes of the actual inputs and binaries. Selected emitted IR, disassembly and build metadata are in `evidence/samples/`. Toolchain package provenance and the native callback ABI probe are in `evidence/toolchain/`.

The device results are `picocalc/logs/direct-llvm-validation.json` and `direct-llvm-tests-with-sockets-final.txt`, together with the replay trace and ELF audit. Earlier failures and incomplete attempts are explicitly named and retained for the diary; they are not the final gate. The release manifest hashes the packaged files, and the patch verification records an application to the exact upstream base with an identical resulting source tree.
