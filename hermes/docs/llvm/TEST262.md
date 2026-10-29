# Direct LLVM Test262 runner

`utils/test_shllvm_test262.py` executes an explicit selection from a pinned
Test262 checkout through the native LLVM path. It is a conformance-development
runner, not a claim of complete ECMAScript support. It never applies the
inherited Hermes skip list or silently falls back to bytecode for static source.

## Reproduction

The suite revision and interpretation-document digest are in
`test/LLVMTest262/suite-lock.json`. Fetch that exact revision into a separate
checkout. The runner rejects a mismatched or dirty checkout. Build the compiler
and both bridge targets before running; the runner does not rebuild during a
validation run.

From `hermes/`:

```bash
cmake --build build-llvm \
  --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4
python3 utils/test_shllvm_test262.py \
  --suite /path/to/test262 \
  --build-dir build-llvm --llvm-bin /usr/lib/llvm-18/bin \
  --output /tmp/test262-results.json \
  test/language/statements/variable test/language/expressions/await
```

Frontend O0 and LLVM O0 are the default baseline. Pass `--hermes-opt O` and
`--llvm-opt 2` for the optimized lane. Selection is mandatory, recorded in the
report, and never described as the full suite. The initial lock follows a
current Test262 revision containing proposals as well as standardized behavior;
an edition-specific feature partition remains unfinished.

## Execution and result contracts

Each test's metadata determines its strict/sloppy variants. Raw source retains
its bytes without harness injection. Other tests receive the prescribed harness
and includes, with strict directives before all other source. Source is never
wrapped in a function. Every executable variant gets a fresh process and work
directory. `_FIXTURE` files are inventoried but not run as independent tests.

Parse-negative tests run the frontend's `-dump-transformed-ast` mode, which
includes semantic validation without LLVM emission. Other cases pass through
LLVM emission, assembly, verification/optimization, linking, and execution as
separate recorded commands. A compiler or linker failure never satisfies an
expected runtime exception.

The opt-in native switch `--shllvm-test262` uses guarded unit initialization and
reports the actual thrown object's constructor name to stderr. It does not
infer error identity from a user-controlled message or stack. Non-object throws,
throwing constructor/name getters, and malformed names cannot match a negative
error expectation. Normal host execution retains its existing error display.
The switch is consumed only before `--`, preserving script arguments.

Asynchronous tests require exactly one success marker and no failure marker,
as well as successful process completion. Missing or duplicate completion is a
failure. Exceptions during event-loop draining currently retain the ordinary
host diagnostic; structured asynchronous negative-error reporting remains open.

Reports distinguish `pass`, `semantic_failure`, `unsupported`, `timeout`,
`crash`, `harness_error`, and `infrastructure_error`. Module and unavailable
agent/cross-realm capabilities have explicit unsupported reasons. A test using
another missing host facility can currently surface as a semantic failure;
feature tags alone are not a complete capability inventory.

Input and tool/runtime binary fingerprints are compared before and after the
run. A changed fingerprint or dirty suite makes the result incomplete. Partial
results are published atomically after each variant. An exit status of zero
requires a complete run with every selected executable variant passing.
Timeouts kill the process group, including compiler/linker children. Captured
output is stored in temporary files; report text is limited to one MiB per
stream, with overflow classified as infrastructure failure. This limits report
memory, not total temporary-disk consumption during an executing process.

## Runner validation

```bash
python3 utils/test_shllvm_test262_runner.py
python3 utils/test_shllvm_test262_native.py \
  --suite /path/to/test262 \
  --build-dir build-llvm --llvm-bin /usr/lib/llvm-18/bin \
  --output /tmp/native-classification-probes.json
```

The first command checks classification and preparation using adversarial
process outcomes. The second compiles and executes synthetic probes for real
exceptions, forged strings/stacks, throwing getters, runtime const errors,
missing/duplicate async completion, wrong error phase, and timeout handling.
Synthetic probes are recorded separately from upstream Test262 totals.

## Remaining conformance work

The runner does not implement module loading, concurrent agents, new realms,
or every current Test262 host hook. It does not establish proper semantics for
all accepted programs. Full specification artifact pinning, proposal/edition
partitioning, structured asynchronous exceptions, complete inventories, and
cross-configuration qualification remain tracked in ticket LLVM-ECMA-001.
The initial variable/await baseline is intended to identify the next source
changes rather than suppress failures with an inherited skip list.

## Bounded execution and partitions

Use `--jobs N` to run independent native processes concurrently. The coordinator
keeps at most N variants in flight and sorts final results by test and variant.
`--shard-count N --shard-index I` assigns source paths by SHA-256 modulo N;
all variants of one source stay together. Reports retain the full selection
fingerprints and record partition counts. Empty partitions are valid completed
measurements. Do not add overlapping or incompatible partitions together.

`--checkpoint-every N` publishes an atomic partial report after every N completed
variants (default 1000). An interrupted run remains incomplete; there is no
resume support yet. `--compact` omits command records only for passing variants,
retaining their source, harness and artifact identities. Failures keep commands.
Output and temporary publication paths cannot replace fingerprinted inputs.

Validate and summarize completed reports with:

```sh
python3 utils/summarize_shllvm_test262.py --output summary.json shard-*.json
```

The summarizer requires every partition, matching build and selection identities,
consistent result counts, unique test/variant records, and complete source/fixture
coverage. It rejects partial reports. Failure groups are triage categories rather
than normative judgments. The feature ledger marks edition membership unreviewed;
a feature tag alone does not establish membership in a particular edition.

Pass `--suite /path/to/pinned/test262` to the summarizer to annotate feature
labels using that checkout's `features.txt` and list textual `$262` helper
references in failing sources/harnesses. The checkout must be clean at the
reported revision, and examined source/harness bytes must match recorded hashes.
These references are candidates for investigation, including references in
comments or strings; they do not automatically reclassify a failure. The pinned
catalog's standard/proposed/harness categories are separate from reviewed
membership in a particular specification edition.
