# Direct LLVM language extension tests

Run the complete targeted gate after building the compiler and both runtime
bridge targets:

```sh
ASAN_OPTIONS=detect_leaks=0 python3 utils/test_shllvm_extensions.py \
  --build-dir build-llvm --llvm-bin /path/to/llvm/bin
```

The harness deliberately does not rebuild those targets. A single gate must
use one stable compiler/runtime build. Its evidence includes SHA-256 hashes of
the compiler, runtime libraries, fixtures, frontend, emitter, runtime sources,
and relevant CMake files. It fails the gate if these inputs change while the
tests run.

For each positive fixture, the harness runs Node as a script, compiles and runs
the inherited C backend at frontend O0 and O, then compiles and runs direct
LLVM at each frontend setting with LLVM O0 and O2. It also executes every
positive fixture with the real `lli` JIT at frontend O / LLVM O2. Native and
JIT execution must match the complete Node stdout and successful exit status.
Required C oracles must also match Node. Runtime-error fixtures require an
uncaught error of the declared class and exit status 1 from native/JIT code.

Node uses `vm.runInThisContext`, avoiding the CommonJS wrapper introduced by
`require`. This matters for global variables and dynamic evaluation. Node
also receives `--expose-gc`; native Hermes has its own `gc()` console binding.
Asynchronous fixtures include a completion line so an unexecuted Promise job
or silently dropped rejection cannot accidentally pass with empty output.

Compiler-error fixtures test both frontend optimization levels. They require
a diagnostic, no partial stdout module, preservation of an existing raw LLVM
file, and preservation of existing executable/LLVM/bitcode outputs through the
Python driver. No expected failure is counted as successful program execution.

## Fixture metadata

Place an optional JSON object in the first six lines:

```js
// SHLLVM_TEST: {"family":"async-generators","completion":"done: example","hermes_flags":["-Xasync-generators"]}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `kind` | `positive` | `positive`, `runtime-error`, `runtime-rejection`, or `compile-error`. File prefixes `error_`, `reject_`, and `unsupported_` also select negative contracts. |
| `family` | First filename component | A descriptive grouping retained in evidence. |
| `completion` | None | A complete line that must appear in successful output; use for every asynchronous fixture. |
| `expected_stdout` | Node output | Optional additional explicit expected output, including newlines. Node itself must satisfy it. |
| `expected_error` | `TypeError` | Error class required for a runtime-error fixture. |
| `expected_diagnostic` | Any diagnostic | Optional regular expression for raw compiler rejection. |
| `hermes_flags` | `[]` | Additional frontend `-X` options. The driver rejects output/backend selection through this field. |
| `runtime_flags` | `[]` | Arguments passed to native Hermes and `lli`, after compilation. |
| `c_oracle` | `required` | `required`, `record-only`, or `skip`; see below. |
| `c_oracle_reason` | None | Mandatory explanation when C is not a required oracle. |
| `rejection_reason` | None | Mandatory explanation for the separate `runtime-rejection` boundary contract. |

A `runtime-rejection` fixture describes valid JavaScript that the current
native implementation explicitly rejects. Node must execute it successfully;
native LLVM and `lli` must fail with the declared error class and optional
diagnostic. These fixtures count as documented boundary checks, never as
LLVM-versus-Node semantic matches. They require a nonempty `rejection_reason`.
Use `runtime-error` when Node and the native runtime should both throw.

### C oracle limitations

A direct LLVM extension can support a source program that the inherited C
backend cannot compile. This is relevant to newly introduced lexical eval IR.
Use `record-only` to attempt C and record its actual compile/run outcome, or
`skip` when that attempt has a documented incompatibility. Every such fixture
must explain the reason. The evidence reports these limitations separately;
a failed C compilation or mismatched C execution is never reported as a
matched oracle. Direct LLVM must still satisfy the Node contract.

Keep `required` for shared-runtime features. For example, a Promise scheduling
or typed-array discrepancy in both backends is a real failing test, not a
reason to waive the C oracle.

## Focused work and evidence

`--case` accepts a filename substring and may be repeated. `--quick` omits
native LLVM O0, `--skip-jit` omits JIT runs, and `--oracle-only` runs Node/C
inspection without claiming LLVM validation. These modes are marked as partial
gates. For example:

```sh
ASAN_OPTIONS=detect_leaks=0 python3 utils/test_shllvm_extensions.py \
  --llvm-bin /path/to/llvm/bin \
  --case async_ --case promise_ --case error_promise \
  --output docs/llvm/feature-work/async-promise-validation.json
```

The default evidence file is
`docs/llvm/feature-work/extension-validation.json`. It contains every command,
exit status, stdout/stderr, elapsed time, build manifest path, comparison,
oracle limitation, and input fingerprint. Completed fixture records are saved
incrementally and marked incomplete until the gate finishes. Counts distinguish
source fixtures, native executions, JIT executions, and expected-error cases.

This suite covers selected language and runtime contracts. It does not replace
Test262, device execution, or a proof of complete ECMAScript conformance.
