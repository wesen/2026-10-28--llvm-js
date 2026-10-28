# Direct LLVM implementation: language extensions

This release extends the actual Static Hermes compiler with a direct LLVM IR
backend. It includes functions, dynamic objects, escaping lambdas, shared
mutable captures, constructors, classes and exceptions, plus the generator,
async, rich-value and dynamic-source work described below. The host target is
Linux x86-64 with the real Hermes managed runtime. The existing PicoCalc RV32
integer-world lane is included with its earlier validated evidence.

## Start here

Read `picocalc-llvm-poc-report.pdf` for the undergraduate textbook report.
Read `Direct-LLVM-Engineering-Diary.md` for the detailed implementation record.
Editable chapters and the PDF renderer are in `hermes/docs/llvm/`.

| Path | Contents |
|---|---|
| `hermes/` | Complete pinned source, direct emitter, runtime bridges, driver, tests and evidence |
| `picocalc-llvm-poc/` | Direct LLVM integer-world compiler, RV32 simulator and transaction/reload tests |
| `Static-Hermes-direct-LLVM.patch` | Compiler, runtime, test and design-document changes against the exact base |
| `PROVENANCE.json` | Base identity, tool versions, hashes, exact patch verification and validation qualifications |
| `SHA256SUMS.txt` | SHA-256 of every other packaged regular file |

The upstream base is `facebook/hermes`, branch `static_h`, commit
`f837b9dd8396ebf5c4e8115412417d273565f0fe`. The archive already contains the modifications; do not apply
the patch again inside it. Licences and third-party notices are retained.
Build directories, downloaded toolchains, Git history and node_modules are
omitted.

## Implemented extensions

| Family | Implementation and exercised behavior |
|---|---|
| Generators | Direct native generator callbacks, sent values, next/throw/return, yield-star delegation, iterator cleanup, suspended finally and collection |
| Async and Promises | Await/rejection, thenables, jobs, combinators, species, subclass reaction timing, async-generator request queues and return cleanup |
| RegExp and BigInt | Fresh literal RegExp objects; exact serialized BigInt bytes; dynamic operations and conversion errors |
| Private fields | Private-name creation, add/load/store, private-in, methods/accessors, brands and failed receivers |
| Typed arrays | Ordinary constructors/calls plus corrected canonical numeric-index and receiver property semantics |
| Dynamic source | Indirect/global eval, Function construction, strict lexical direct eval, shared native/bytecode cells and nested eval |

Static source follows `JavaScript -> Hermes SSA -> LLVM IR -> LLVM`.
Individual guest programs do not generate C. Fixed C/C++ runtime support is
compiled once. Dynamically supplied eval/Function strings use the Hermes
bytecode compiler and interpreter; they are not compiled to LLVM at runtime.

## Build and run

Use Linux x86-64, LLVM/Clang 18, CMake, Ninja and Python 3. Node is needed for
the differential tests. The recorded LLVM version is 18.1.3.

```sh
cd hermes
cmake -S . -B build-llvm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DHERMES_ENABLE_ADDRESS_SANITIZER=ON
cmake --build build-llvm \
  --target shermes shllvm_runtime shllvm_runtime_shared --parallel 3

python3 utils/shllvm.py run examples/llvm/counter.js
python3 utils/shllvm.py jit test/LLVMNativeExtensions/generator_protocol.js
python3 utils/shllvm.py run --hermes-arg=-Xasync-generators \
  test/LLVMNativeExtensions/async_generators.js
python3 utils/shllvm.py run test/LLVMNativeExtensions/eval_lexical_bindings.js
python3 utils/shllvm.py emit test/LLVMNativeExtensions/features_bigint.js \
  -o out/bigint.ll
```

Set `LLVM_BIN` when LLVM tools are not on PATH; set `HERMES_BUILD_DIR` for a
different build directory. The driver normally ensures its runtime libraries
are current. `--no-runtime-build` is for validation batches using a matching
completed build. The repeatable `--hermes-arg=-X...` option forwards frontend
features without changing backend/output selection.

The recorded C/C++ Release build used `-O1 -DNDEBUG` and AddressSanitizer.
Its restricted environment required `ASAN_OPTIONS=detect_leaks=0` for both
the generated build tools and execution. Address checks remained active in
the runtime/bridge; generated LLVM bodies were not explicitly instrumented.
Apply that leak-check workaround elsewhere only if the environment requires it.

## Final evidence

The core gate passed **22/22 source
contracts**, including **68 native
Node/C comparisons** and **3 real lli checks**.

The complete extension gate passed **53/53
source contracts**: 44 successful programs,
3 language-error cases,
3 explicit runtime-boundary cases and
3 compile-error cases. It recorded
**176 successful-output native comparisons**,
**188 native Node-contract matches**
(including checked language errors), and
**12 expected native rejections**.
The lli results are **47 Node-contract matches**
and **3 explicit boundary rejections**.
No filter, quick mode, JIT skip or oracle-only option was used.

Driver publication checks passed **6/6**;
raw lexical-default checks passed **5/5**.
The final inputs were unchanged during the gate. The authoritative records
are `hermes/docs/llvm/feature-work/core-final-validation.json`,
`extension-final-validation.json`, their logs and
`final-validated-files.json`. The extension runner records all input hashes.

C and LLVM share the patched frontend/runtime. For lexical eval the inherited
C helper lacks caller-environment semantics, so its limitation is explicit
fixture metadata rather than a passing comparison. A separate typed-array
receiver probe records an observed Node-version difference against the
specification-derived expectation. Successful language behavior and deliberate
unsupported-context rejection remain separate counts.

The unchanged RV32 lane retains its previous **24/24 tests**, 200 C/LLVM event
comparisons, 160 Node events, six verified ELF modules and 11 replay records.
Earlier host evidence remains in `hermes/docs/llvm/evidence/`. Failed builds
and exploratory runs are preserved as engineering history, clearly separated
from current final gates.

```sh
python3 utils/test_shllvm.py --jobs 2
python3 utils/test_shllvm_extensions.py --jobs 2
python3 utils/test_shllvm_driver.py
python3 utils/test_shllvm_defaults.py
```

## Explicit boundaries

Native direct string eval currently requires a strict caller. Sloppy caller
variable injection and lookup are not implemented. Evaluated super references
and class-private names need additional class context; direct eval in derived
constructors and their captured arrow contexts is rejected. The fixtures test
these diagnostics separately from JavaScript semantic success.

Specialized internal typed-object and fast-array IR forms remain outside the
admitted subset. Ordinary static const reassignment and some obvious TDZ
violations retain upstream frontend diagnostics. The emitter enforces its
documented native root/argument admission limit. No complete ECMAScript or
Test262 result, broad upstream-suite result, or performance speedup is claimed.

The dynamic Hermes runtime is validated on the host. The RV32 lane retains its
i32 world ABI, 8 KiB guest stack and fixed state structure. Physical
PicoCalc/ESP32-P4 execution and a dynamic-object device runtime are not claimed.
Compilation-unit metadata, code and pools must remain alive for the associated
runtime lifetime.

## Apply the compact patch

In a clean checkout at the exact upstream base:

```sh
git apply --check /path/to/Static-Hermes-direct-LLVM.patch
git apply /path/to/Static-Hermes-direct-LLVM.patch
```

The patch was checked and applied to an independent private Git index; its
resulting tree matched the proposed implementation tree. The working
repository index was unchanged. The full ZIP was also checked member by
member for CRC and SHA-256 integrity. Historical absolute paths in logs
describe the recording environment; select local paths with driver options.
