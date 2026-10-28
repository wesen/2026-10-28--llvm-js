# Running the direct LLVM backend

The driver in `utils/shllvm.py` accepts JavaScript, invokes Static Hermes' new
`-emit-llvm` mode, assembles and verifies the resulting LLVM IR, and uses LLVM to
produce an executable or run the module through `lli`. The shared/static bridge
is built once through CMake dependency tracking. Individual JavaScript programs
do not produce C source and do not invoke a C frontend.

## Build prerequisites

Use a native Linux x86-64 host, a C++ build toolchain, CMake, Ninja, Python 3, and
LLVM 18 tools (`clang`, `llvm-as`, `opt`, `lli`). The recorded toolchain was LLVM
18.1.3. The runtime bridge currently checks for eight-byte host pointers; the
presence of other targets in LLVM does not establish a working device runtime.

A representative configuration is:

```sh
cmake -S . -B build-llvm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DHERMES_ENABLE_ADDRESS_SANITIZER=ON
cmake --build build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 3
```

The recorded build used `-O1 -DNDEBUG` for its C++ release flags to reduce build
cost; this is distinct from the frontend and LLVM optimization choices for each
JavaScript program. Set `LLVM_BIN` if the LLVM executables are not on PATH, and
`HERMES_BUILD_DIR` for a different configured build directory. Both also have
corresponding command-line options.

## Commands

```sh
# Keep human-readable LLVM IR and optimized bitcode.
python3 utils/shllvm.py emit test/LLVMNative/closures.js -o out/closures.ll

# Produce a native executable, along with .ll, .bc and .build.json artifacts.
python3 utils/shllvm.py build test/LLVMNative/closures.js -o out/closures
./out/closures

# Compile and execute with a subprocess timeout.
python3 utils/shllvm.py run test/LLVMNative/classes.js

# Real LLVM JIT execution in the lli host process.
python3 utils/shllvm.py jit test/LLVMNative/gc_closures.js

# Select frontend and LLVM optimization independently.
python3 utils/shllvm.py run --hermes-opt O0 --llvm-opt 0 \
  test/LLVMNative/exceptions.js
```

The driver enables ES6 block scoping and temporal-dead-zone checks explicitly.
These options matter for a closure created inside a `let` loop and for a closure
that reads a lexical binding before its declaration executes. The original C
backend requires the same options when used as a semantic comparison.

Arguments after `--` are forwarded to the generated program/`lli` program.
Static Hermes itself uses `--` to distinguish runtime flags from script
arguments, so an invocation that needs script arguments can contain a second
separator. `--no-runtime-build` uses an already-built matching bridge and is
intended for validation batches. Normal invocations ask CMake to ensure the
bridge and dependent libraries are current.

A failed frontend emission or LLVM verification leaves an existing LLVM output
untouched. Executable publication also uses a temporary file followed by a
rename. Build metadata contains source, IR, compiler, runtime and executable
hashes and the commands that were run.

## Native execution and JIT are separate paths

`build` and `run` link compiled LLVM code with a once-built static bridge and the
Hermes runtime/console shared libraries. `jit` asks LLVM's `lli` executable to
JIT the bitcode and load the shared bridge. The latter is real native execution
through LLVM, but it is not an in-process embedding API or a hot-reload manager.
Every invocation currently creates its own process/runtime lifetime.

For an AddressSanitizer runtime build, the driver preloads the matching Clang
ASan shared library into `lli`. The runtime and bridge are instrumented. The
emitted LLVM bodies do not carry ASan instrumentation attributes, so this must
not be described as complete instrumentation of all generated code.

In the execution sandbox used for this report, LeakSanitizer could not inspect
`/proc`. Validation therefore set `ASAN_OPTIONS=detect_leaks=0`; address checks
remained enabled. Ordinary users should only apply that setting if their
environment has the same restriction. The driver does not disable leak
checking automatically.

## Differential validation

```sh
python3 utils/test_shllvm.py --jobs 2
```

Node must be on PATH. The runner executes Node with `--expose-gc`, defines
`print` as `console.log`, and compares each successful program with the original
C-emission backend and the direct LLVM backend. Both Hermes optimization levels
(`O0`, `O`) and both LLVM levels (`0`, `2`) are exercised. The suite also executes
three programs through `lli`, verifies runtime error classes, and checks that
rejected constructs preserve an existing output file.

The final release run passed **22 source cases**: **16 positive programs**, **3 runtime
error programs**, and **3 explicit compile rejections**. There were **64 native
LLVM comparisons** with Node and the C backend, **3 successful `lli` JIT
comparisons**, and **6 checked runtime-error executions**. The allocation test
creates 50,000 temporary object/array structures, retains closures, confirms
that `gc` exists, invokes it unconditionally, and reads the captured state
successfully afterward. These are integration tests, not a full ECMAScript
conformance certificate.

Final release results are in `evidence/final-validation.json` and
`evidence/final-validation.log`; `evidence/final-validated-files.json` identifies
the exact tested implementation, compiler, runtime and bridge. The complete
suite was rerun after the final verifier guard, automatic static/shared bridge
build correction and dependent VM rebuild. The original run remains unchanged
in `evidence/validation.json`, `evidence/validation.log` and
`evidence/validated-files.json`.

`evidence/post-review-verifier.json` records the focused verifier-flag and LLVM
output checks. `evidence/post-review-driver.json` records a missing-static-archive
first-run check and native/JIT executions with automatic builds enabled.
`evidence/samples/` contains emitted LLVM, selected application disassembly, and
build metadata for representative programs. The diary records failures found
and corrected during implementation.

## Explicit boundaries

Generators and dynamic `eval` are rejected by this backend. The pinned upstream
frontend also rejects an assignment to a `const` binding during compilation,
even inside a `try` block; standard JavaScript can instead raise a catchable
runtime TypeError. That limitation is retained and tested as an explicit
compile rejection. The implementation is an experimental backend over the
pinned Static Hermes language/runtime pipeline, not a claim that every
ECMAScript program is accepted.

The current bridge uses the existing Static Hermes unit lifecycle: a unit and
its code/string storage must remain alive until its runtime is destroyed.
Unloading an old code generation while closures still refer to it is not
supported. Device integration, an RV32 runtime ABI, capability confinement,
transactional OS state updates and generation-based hot reload need their own
implementation and validation.
