# Imported release and local validation

Imported on 2026-10-28 from `/home/manuel/Downloads/direct-llvm-release`.
All 13,052 SHA-256 manifest entries verified before copying. The complete
release is retained, including licenses, upstream test fixtures, the patch,
provenance, and curated historical evidence (including sample RV32 ELF files).
New builds, caches, dependencies, and generated artifacts are ignored.

## Version distinction

The supplied directory and `~/Downloads/picocalc-llvm-poc-complete.zip` contain
the 40-file direct-LLVM patch against Hermes
`f837b9dd8396ebf5c4e8115412417d273565f0fe`. They do not contain the later
124-file patch described in the colleague's handoff. In particular,
`hermes/test/LLVMNativeExtensions`, `utils/test_shllvm_extensions.py`, and
`docs/llvm/feature-work` are absent. Generators and direct eval remain rejected
in this release. Do not apply the newer handoff's 53/53 extension result to
this checkout.

## Local build

The installed Clang 18 initially selected an incomplete GCC installation.
Selecting the complete GCC 13 installation fixed C++ configuration:

```sh
cmake -S hermes -B hermes/build-llvm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/bin/clang-18 \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++-18 \
  -DCMAKE_CXX_FLAGS=--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13 \
  -DCMAKE_C_FLAGS_RELEASE='-O1 -DNDEBUG' \
  -DCMAKE_CXX_FLAGS_RELEASE='-O1 -DNDEBUG'
cmake --build hermes/build-llvm \
  --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4
```

This local build does not enable AddressSanitizer. The supplied historical
sanitizer evidence remains separate from fresh local validation.

For the RV32 suite, TypeScript 5.8.3 was installed with
`pnpm --dir picocalc-llvm-poc install --ignore-scripts --lockfile=false`.
The machine lacked LLD; the Ubuntu LLVM 18.1.3 linker package was downloaded
and extracted under `/tmp/llvm-import-tools`, without system installation.

```sh
LD_LLD=/tmp/llvm-import-tools/extracted/usr/lib/llvm-18/bin/ld.lld \
  make -C picocalc-llvm-poc test
```

The complete RV32 suite passed **24/24 tests**, including the local Unix socket
compiler service. The initial missing-linker failure and the successful run
are retained under `ttmp/2026-10-28/import-validation/`.

Original release instructions and evidence remain unmodified. Fresh local
validation and the technical report draft are in that same dated directory.

## Fresh host results

The 456-step compiler/runtime build succeeded. The complete host matrix passed
22/22 source contracts, 64 positive native comparisons, three actual lli runs,
and six expected runtime-error executions. Publication checks passed 6/6;
lexical-default checks passed 5/5. No quick mode, case filter, or JIT skip was
used. All local suite exit statuses were zero. JSON and logs are preserved
in the dated validation directory. Staged Git blobs also matched all 13,052
release manifest hashes after disabling line-ending conversion.
