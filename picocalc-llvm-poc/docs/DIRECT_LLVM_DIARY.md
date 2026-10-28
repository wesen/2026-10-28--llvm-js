# Direct LLVM backend engineering diary

## 2026-10-28 13:23 UTC — Recover and inspect the existing prototype

Recovered the original `picocalc-llvm-poc-complete.zip` into a separate working
directory. Read the original README, JS-to-C emitter, compiler wrapper, ABI
header, and all integration tests. The existing device lane is explicitly a
bounded integer JavaScript subset, with a 16-byte state structure, two fixed
RV32IM code slots, capability `ecall`s, and an instruction interpreter that
commits state and effects only after a successful turn. Keep this contract.

The direct LLVM lane will replace only per-module C generation/parsing. The
existing C emitter remains an explicit differential oracle. The independent
Static Hermes work provides the dynamic objects/closures lane; this device
prototype must not silently claim those broader semantics.

Installed toolchain is the shared private LLVM 18.1.3 toolchain. Inspected a C
ABI fixture lowered by Clang: RV32 uses opaque pointers, data layout
`e-m:e-p:32:32-i64:64-n32-S128`, and fixed-register inline-assembly constraints
for `a0` (`x10`) and capability selector `a7` (`x17`). The direct emitter will
state this ABI explicitly. Arithmetic will omit `nsw`/`nuw`, matching the
existing `-fwrapv` contract, and comparisons will preserve the existing C
frontend's unsigned `event`, `version`, and `state.schema` types.

Implementation plan: TypeScript AST to typed i32 expression values; mutable
locals use entry-block allocas; branches and loops use basic blocks;
short-circuit operators use branches and phi nodes; state accesses use GEP;
capability calls emit inline LLVM assembly. Generated `.ll` is fed directly
to the LLVM input path. Keep generated IR beside each ELF for review.

## 2026-10-28 13:27 UTC — Implement and test the complete original device lane

Added `compiler/js2llvm.js`, a direct LLVM emitter for the complete existing
integer world grammar. Changed `compile.py` to select it by default for JS and
retain `--backend c` for the previous path. The daemon accepts the same backend
option. Output metadata now identifies the backend, source/generated-content
hashes, optimization level, and measured frontend/LLVM/link durations. C source
input remains supported through its original route.

Pinned TypeScript 5.8.3 with a generated lockfile. The initial sandboxed npm
attempt failed before dependency retrieval; the reviewed network retry
succeeded. Initial direct LLVM verification and native RV32 interpretation
succeeded, including nested short-circuit phi nodes, source side effects,
unsigned promotion, wrapping overflow, and local-variable loops at O0/O2/Oz.

Added eight test methods, including 200 seeded C-versus-LLVM event comparisons,
LLVM assembler/verifier checks, bounded arithmetic edge cases, compile-failure
preservation of the previous ELF, and negative language-boundary checks.
The first full run passed 23 of 24 tests; the sole failure was the existing
Unix socket service test because sandbox policy prevented daemon binding.
Requested the permitted local-socket execution environment for that gate.
This failure is environmental and is retained in `logs/direct-llvm-tests.txt`;
it is not silently reported as a compiler regression or omitted.

## 2026-10-28 13:30 UTC — Final validation and native artifacts

The first permitted-socket execution returned a tool status of zero, but its file ended mid-suite. That incomplete file was not accepted as a successful gate. A repeated run captured the entire subprocess output and verified the unittest summary: **24 tests passed, zero failed, zero skipped**, in 17.132 seconds. The complete record is `logs/direct-llvm-tests-with-sockets-final.txt`; `logs/direct-llvm-validation.json` records the log and final source hashes. The final direct-frontend-only run also passed all eight test methods after tightening optional-chain rejection.

The artifact collector assembled and verified six direct LLVM modules, linked them as freestanding RV32 ELF images, and executed the hot-reload scenario. Version 1 increments score to 3; version 2 retains state and changes score to 43; a bad migration aborts without replacing the active generation; the surviving version then triples score to 129. Final epoch remains 2. No generated C participates in this path. Logs include actual RV32 disassembly, ELF metadata, the eleven-record scenario trace, tool versions, phase timings, and source/artifact hashes.
