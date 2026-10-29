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

# Enable the frontend's async-generator syntax and lowering.
python3 utils/shllvm.py run --hermes-arg=-Xasync-generators \
  test/LLVMNativeExtensions/async_generators.js
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
python3 utils/test_shllvm_extensions.py --jobs 2
```

Node must be on PATH. The runners execute Node with `--expose-gc`, define
`print` as `console.log`, and compare successful programs with the existing
C-emission backend and the direct LLVM backend. Both Hermes optimization levels
(`O0`, `O`) and both LLVM levels (`0`, `2`) are exercised. The core suite executes
three programs through `lli`, verifies runtime error classes, and checks that
rejected constructs preserve an existing output file.

The extension harness uses script semantics through Node's `vm.runInThisContext`
so global and eval tests do not accidentally acquire a CommonJS module scope.
Every positive extension fixture also runs through real `lli`; async fixtures
must print a completion marker. C-oracle limitations for lexical direct eval
are explicit fixture metadata. Deliberate unsupported-language rejections are
separate contracts and are not counted as matching Node semantics.

The current host release gates are `feature-work/core-final-validation.json`
and `feature-work/extension-final-validation.json`, with companion logs and
`feature-work/final-validated-files.json`. The extension runner records the
sources, compiler and runtime hashes and checks for changes during a gate.
The historical first-release results remain in `evidence/final-validation.json`:
22 cases, 64 native comparisons, three JIT comparisons and six runtime-error
executions. Current counts come from the new gate files and the report's
validation table. The original 50,000-allocation closure test still calls `gc`
unconditionally; new fixtures collect suspended generators and async/eval
closures too. These are integration tests, not full ECMAScript conformance.

`evidence/post-review-verifier.json` records the focused verifier-flag and LLVM
output checks. `evidence/post-review-driver.json` records a missing-static-archive
first-run check and native/JIT executions with automatic builds enabled.
`evidence/samples/` contains emitted LLVM, selected application disassembly, and
build metadata for representative programs. The diary records failures found
and corrected during implementation.

## Explicit boundaries

Generators, RegExp/BigInt literals and private-field operations now have direct
LLVM emission. Typed-array objects use the existing runtime through generic
calls and property operations, with the included indexed-property corrections.
Direct string eval in a strict caller, or with a genuine strict directive in
the evaluated source, uses actual native environment cells. Dynamically
supplied eval and Function strings compile to Hermes bytecode. General
non-strict direct string eval and evaluated super/private-name context retain
explicit limits. Derived constructors and their captured arrows reject string
eval at runtime; non-string arguments pass through unchanged, including before
`super()`. Runtime source strings preserve UTF-16 code units, including lone
surrogates; ordinary source files retain UTF-8 scalar-value validation.

The ordinary LLVM frontend now preserves runtime error timing for const
assignment and TDZ operations, including catchable exceptions. Dynamic strict
evaluation also uses runtime const checks. Specialized internal typed-object/fast-array IR remains distinct from
ordinary JavaScript typed arrays. This is an experimental backend over a
pinned language/runtime pipeline, with targeted evidence for its features.

The current bridge uses the existing Static Hermes unit lifecycle: a unit and
its code/string storage must remain alive until its runtime is destroyed.
Unloading an old code generation while closures still refer to it is not
supported. Device integration, an RV32 runtime ABI, capability confinement,
transactional OS state updates and generation-based hot reload need their own
implementation and validation.
