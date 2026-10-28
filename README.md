# Direct LLVM implementation release

This updates the PicoCalc prototype and adds a direct LLVM backend to the
actual Static Hermes compiler. It includes working functions, dynamic objects,
escaping lambdas, mutable captures, ordinary classes and exceptions on a
Linux x86-64 host, plus the updated RV32 integer-world prototype.

## Start here

Read `picocalc-llvm-poc-report.pdf` for the undergraduate textbook report.
Read `Direct-LLVM-Engineering-Diary.md` for the detailed engineering record.
The report's editable source and renderer are under `hermes/docs/llvm/`.

| Path | Contents |
|---|---|
| `hermes/` | Complete pinned Static Hermes source with the new backend, runtime bridge, driver and tests |
| `picocalc-llvm-poc/` | Updated direct LLVM integer-world compiler, RV32 simulator, transactional supervisor, tests and evidence |
| `Static-Hermes-direct-LLVM.patch` | Compact changes against the exact upstream base |
| `PROVENANCE.json` | Base identity, tool versions, selected hashes, patch-application verification and evidence qualifications |
| `SHA256SUMS.txt` | Hash of every other packaged regular file |

The host source baseline is `facebook/hermes`, branch `static_h`, commit
`f837b9dd8396ebf5c4e8115412417d273565f0fe`. The base alone does not contain the
new backend. Existing upstream licences and third-party notices are retained.
Git history, build directories, package caches and node_modules are omitted.

## Build and run the host backend

Use Linux x86-64, LLVM/Clang 18, CMake, Ninja, Python 3, and Node for the
differential tests. The recorded LLVM version is 18.1.3.

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
python3 utils/shllvm.py jit examples/llvm/counter.js
python3 utils/shllvm.py emit test/LLVMNative/closures.js -o out/closures.ll
```

Set `LLVM_BIN` to the LLVM bin directory when its tools are not on PATH.
Set `HERMES_BUILD_DIR` to use another build directory. Commands normally ensure
the runtime bridge is built. Individual guest programs emit LLVM directly;
they do not generate or parse C.

Native and JIT execution of the counter example both produced:

```text
41 42 42 105
{"value":42,"description":"captured state"}
7,14,21
50
example 52
```

The recorded environment used `-O1 -DNDEBUG` for the C/C++ Release build and
`ASAN_OPTIONS=detect_leaks=0` because LeakSanitizer could not inspect the sandbox.
AddressSanitizer remained active for the runtime and bridge; generated LLVM
bodies were not explicitly ASan-instrumented. Do not disable leak checking on
another machine unless its environment requires that workaround.

## Evidence

The final full host matrix passed **22/22 source cases**, including **64
native comparisons** with Node and the C backend, **3 lli JIT comparisons**,
**6 expected runtime-error executions**, and **3 compile rejections**. Compiler
publication checks passed **6/6**, and raw lexical-default checks passed **5/5**.
The separate RV32 suite passed **24/24 tests**, including the complete local
compiler-service test and simulator reload/migration regressions.

Final review added a conditional lowered-Hermes verifier call. The historical
full-matrix hashes remain intact. Focused checks of that final change produced
**32 byte-identical verify-option pairs**, **64 LLVM verifier passes**, and
successful native/JIT counter runs. Upstream's full internal Hermes verifier
is Debug-only; the recorded Release check demonstrates flag plumbing and output
invariance. It does not replace the real LLVM verifier checks.

The final wrapper also requests both bridge build targets automatically.
A focused first-run check removed the existing static archive, observed it
being rebuilt identically, and executed the counter successfully. The JIT path
passed with automatic building enabled as well. These two checks are recorded
separately; the original full-matrix counts are unchanged.

Because the first-run dependency build also refreshed the VM binary, the full
matrix was repeated against the final compiler, driver, VM and bridges. It
passed all 22 cases, 64 native comparisons, three JIT comparisons and six
checked errors without quick mode or skips. All 42 recorded implementation,
fixture, tool and binary hashes were unchanged across that final run.
The authoritative release records are `final-validation.json`,
`final-validation.log` and `final-validated-files.json`; earlier captures remain
available for the diary.

See `hermes/docs/llvm/evidence/` and `picocalc-llvm-poc/logs/`. Earlier failed
attempts are retained as history and clearly distinguished from final evidence.
Absolute paths inside historical logs describe the recording environment;
use the drivers' options to select paths on a new machine.

## Execution boundaries

The dynamic backend supports a tested instruction subset of Static Hermes.
Generators, direct eval, regex literals and several specialized typed/private
operations are not implemented. The upstream frontend rejects the supplied
const reassignment and some obvious TDZ violations at compile time. No complete
ECMAScript conformance or performance improvement is claimed.

The dynamic Hermes runtime is validated on the host. The RV32 lane retains the
restricted i32 world ABI, its actual 8 KiB guest stack and fixed state structure.
It does not run the host's objects and closures. Neither path has been tested on
physical PicoCalc/ESP32-P4 hardware. Dynamic-world migration, heap rollback,
capability bindings and safe code-generation lifetime remain integration work.

Host native code and lli run in a normal process; they are not an isolation
sandbox. SHUnit metadata, code and string pools must remain alive until their
associated runtime is destroyed.

## Apply the compact patch

In a clean checkout at the exact base above:

```sh
git apply --check /path/to/Static-Hermes-direct-LLVM.patch
git apply /path/to/Static-Hermes-direct-LLVM.patch
```

The full source archive is ready to build without applying the patch again.
The PicoCalc README documents its independent dependency installation,
toolchain settings, test runner and replay workflow.
