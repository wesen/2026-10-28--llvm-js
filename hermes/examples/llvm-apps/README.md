# Application qualification

Four runnable applications exercise the direct LLVM compiler and persistent JIT:

| Application | Work performed | Independent checks |
|---|---|---|
| data-pipeline | Parse/validate JSON, normalize customers, aggregate orders | Python fixture expectations and Node |
| async-queue | Four workers, timers, retries, failures, cooperative cancellation | Python terminal outcomes, attempt and cleanup counts |
| persistent-host | Compile rule plugins into one Engine; recover from errors; collect before callbacks | Node corpus replay, Python ledger expectations, native unit/error counts |
| archive-library | Unmodified fflate 0.8.2 gzip/ZIP and streaming compression | Node output plus Python ZIP/gzip decoding of actual bytes |

## Build and run

From the repository root, using the configured LLVM 18 build:

```sh
pnpm --dir hermes/examples/llvm-apps install --frozen-lockfile --ignore-scripts
pnpm --dir hermes/utils/module-host install --frozen-lockfile --ignore-scripts
cmake -S hermes -B hermes/build-llvm -DHERMES_BUILD_LLVM_JIT=ON
cmake --build hermes/build-llvm \
  --target shllvm-jit shllvm-app-host shermes shllvm_runtime --parallel 4
python3 hermes/utils/qualify_shllvm_apps.py --output /tmp/application-results.json
```

The runner requires Node, Python 3, `/usr/bin/time`, the configured compiler and
runtime, and LLVM tools under `/usr/lib/llvm-18/bin` by default. Override
`--build-dir` and `--llvm-bin` for another installation. No environment overrides
are needed. Use `--sizes small --repeat 1` for the first complete smoke run, or
`--apps persistent-host --sizes large` to focus on retained native state.

By default all three sizes and two repetitions run. Module applications execute
under Node, JIT at Hermes O0/O, and AOT at Hermes O0/O with LLVM O2. The persistent
application executes under Node and the native embedding at Hermes O0/O; a fresh
AOT process does not implement the persistent compilation contract.

The JSON receipt retains commands, stdout/stderr, elapsed wall time, process peak
RSS, source/build fingerprints, fixture identities, and structured outcomes.
Generated source, manifests, and AOT executables remain in a sibling
`<receipt-stem>-artifacts` directory. Use a fresh output path when comparing runs.
JIT stderr contains compile/materialization and execution timings; AOT build and
execution are separate commands. These are workload observations, not controlled
comparative benchmarks. Script input preparation and module bundling are distinct
from application execution.

## Contracts and known boundary

A result is successful only when its application output matches its oracle and
its completion contract. Node/AOT modules require a completion marker; the JIT
uses the existing trusted host completion protocol. Subprocess timeouts kill the
whole process group. Persistent expected failures must occur at their designated
phase, after which later valid plugins and delayed callbacks must still work.

The unoptimized fflate bundle currently exceeds the backend's 1,024 combined
root/argument-slot limit. The receipt calls this `known-admission-boundary`, never
`pass`. The campaign exits zero when all cases are either successful executions
or this specifically recognized boundary; consumers must inspect `summary` to
report execution coverage. Unexpected errors, mismatches, timeouts, changed
fingerprints, and missing completion cause a nonzero exit. The library is neither
trimmed nor patched to bypass the limit.

The persistent host is a concrete example of the private Engine API, not a
concurrent server or untrusted-code sandbox. It retains native code until close.
Cancellation in the queue is cooperative application state, not native execution
interruption. fflate's Worker APIs are outside the tested synchronous profile.

Design, diaries, receipts, and dispositions are in LLVM-APPS-001 under `ttmp`.
