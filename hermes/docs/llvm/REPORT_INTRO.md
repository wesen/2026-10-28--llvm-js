# 1. What was implemented

## 1.1 The result

This release adds a working direct LLVM backend to Static Hermes and updates the earlier PicoCalc integer-world compiler to emit LLVM IR directly. The host backend includes functions, objects, escaping lambdas, mutable captures, constructors, classes and exceptions. This extension adds generators, async/await, Promise validation and runtime corrections, RegExp literals, BigInt, private fields, typed arrays, and lexical evaluation support. It runs against the actual Hermes runtime on Linux x86-64, including LLVM's `lli` JIT. The smaller PicoCalc backend generates RV32IM code and preserves the existing simulated world's transaction and generation protocol.

The distinction between these two targets is essential. The host backend supplies the dynamic language mechanisms requested in this update. The device-oriented prototype supplies a bounded integer ABI and an RV32 execution environment. They are both implemented, but the host's managed JavaScript heap has not been ported into the device world. No physical PicoCalc or ESP32-P4 execution is claimed.

The source baseline is Facebook's Static Hermes branch at commit `f837b9dd8396ebf5c4e8115412417d273565f0fe`. The accompanying patch adds the direct emitter and its integration; the pinned upstream commit alone does not contain these changes. The release includes a complete source snapshot, a patch that applies to that exact base, test fixtures, raw validation records, this report's Markdown source, and a detailed engineering diary.

## 1.2 What "direct to LLVM" means

The previous Static Hermes path translated Hermes IR into C, then relied on a C compiler to translate that program into LLVM IR and machine code. The new path translates Hermes IR into LLVM IR itself. The JavaScript frontend, semantic analysis, and useful module lowering remain; the program-specific C representation and C parser stage are removed.

A fixed C bridge remains as part of the runtime implementation. It is compiled once for a particular runtime configuration. This bridge implements stable entry points for tagged values, root frames, environments, object operations, calls and compilation units. A C++ lexical-eval helper is built into the full Hermes VM. Calling this prebuilt runtime from generated LLVM does not regenerate a C translation of each guest program. Dynamically supplied eval/Function strings use Hermes's bytecode compiler; runtime LLVM compilation of those strings is not claimed.

The first implementation emits textual `.ll` files. LLVM still parses those files, verifies their structure, optimizes them, and emits native code. This choice makes the translation inspectable in a teaching laboratory and avoids linking the compiler frontend to LLVM's C++ libraries. An in-memory LLVM API or bitcode writer could remove the textual IR parsing step later, after the runtime contracts are stable. The current implementation makes no measured compilation-speed or execution-speed claim.

## 1.3 Feature map

The table names mechanisms exercised by the delivered tests. It is a feature inventory for this release, not a full ECMAScript conformance statement. Chapter 3 explains exactly how the evidence was collected.

| Area | Implemented and exercised examples | Source to inspect |
|---|---|---|
| Functions | Named functions, recursive factorial, mutual recursion, higher-order and indirect calls | `functions.js`; `emitCall`; `shllvm_call` |
| Lambdas and closures | Arrows and function expressions; escaping, nested, recursive and shared mutable captures | `closures.js`; environment helpers |
| Lexical bindings | Per-iteration loop capture; closure-mediated temporal dead zones | `lexical_tdz.js`; compiler-default checks |
| Objects | Literals, computed keys, own-property definition, identity, cycles, getters and setters | `objects.js`; `accessors.js` |
| Arrays | Literal holes, indexed mutation, and callbacks into generated functions | `arrays_callbacks.js` |
| Invocation rules | `this`, lexical arrow receiver, arguments, constructors, `new.target` and rejected arrow construction | `arrows_this.js`; `arguments.js`; `constructors.js` |
| Classes | Ordinary inheritance, `super`, getters, captured receiver, `instanceof` and static inheritance | `classes.js` |
| Control and exceptions | Branches, loops, phi transfers, nested catch/finally, return and loop control through finally | `control_phi.js`; `exceptions.js` |
| Dynamic values | Strings, UTF-16 data, coercion, arithmetic and runtime error classes | `strings.js`; `coercion.js`; error fixtures |
| Collection | Escaping closures retain live state after allocation churn and explicit collection | `gc_closures.js` |
| Generators | Next/throw/return, yield-star delegation, suspended finally clauses, iterator cleanup and collection | `generator_*.js`; `shllvm_generator` |
| Async and Promises | Await, thenables, jobs, rejection, combinators, species, async-generator queues and cleanup | `async_*.js`; `promise_*.js` |
| Rich values | Exact BigInt literals, RegExp literals, private names/fields/methods, buffers and typed arrays | `features_*.js`; `value_extensions.c` |
| Dynamic source | Global eval, Function and direct eval from strict callers sharing native environment cells | `eval_*.js`; `function_*.js`; `eval_extensions.cpp` |
| Device world | Direct LLVM integer code, capability ecalls, bounded RV32 execution, transactional reload | PicoCalc compiler and supervisor tests |

Original host fixtures are in `hermes/test/LLVMNative/`. Extension fixtures are in `hermes/test/LLVMNativeExtensions/`. The direct-eval boundaries and precise test contracts are described in Chapters 3 and 7.

## 1.4 A complete worked program

The runnable example `hermes/examples/llvm/counter.js` combines the requested features. A counter object contains three lambdas. The lambdas share a mutable binding; a second counter receives a different binding. A higher-order function produces an array callback. A class returns an arrow that keeps its receiver, and an exception object carries another retained function.

<!-- COUNTER_SOURCE -->

The native executable and the `lli` JIT produced the same output:

<!-- COUNTER_OUTPUT -->

The first line is a compact closure test. Both updates and the read through `first` reach the same environment, giving 41, 42, and 42. The other counter's update produces 105 independently. The snapshot creates a new ordinary object containing the current value. The array result demonstrates a returned function used as a callback. The value 50 confirms that the method's returned arrow can still find the counter after the method returns. Finally, the caught object retains a read closure and observes the later value 52.

The output is recorded evidence, not merely an expected result inferred from the example. Its native and JIT logs are `docs/llvm/evidence/counter-native.txt` and `counter-jit.txt`. The corresponding generated modules and build manifests can be reproduced with the driver in Chapter 5.

## 1.5 How to use this report

An undergraduate reader should be comfortable with functions, pointers, basic data structures, and the idea of a compiler. Chapter 2 introduces the remaining concepts as needed: intermediate representations, basic blocks, phi values, tagged values, roots, closure environments, and ABI contracts. It follows the implementation from frontend lowering through execution.

Chapter 3 separates structural verification, differential execution, error testing, and collector stress. Chapter 4 connects the host backend to the inherited PicoCalc design and identifies the remaining device work. Chapter 5 gives build and execution commands. Chapter 6 is a source-reading guide with primary references. Five exercises at the end of Chapter 2 turn the implementation into a laboratory.

The diary records decisions, observable experiments, failures and fixes. It does not replace the final evidence: an early failed run remains useful history, while only the explicitly identified final runs support the release counts. This distinction is part of sound compiler engineering.
