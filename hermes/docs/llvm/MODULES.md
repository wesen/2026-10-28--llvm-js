# Source-text modules on the direct LLVM host

The explicit `--module` path compiles a closed source-text module graph. Module
bodies and the module host become Hermes IR, LLVM IR, and native code. Node and
pinned Babel packages parse and transform source at build time; they do not
execute application module bodies in the deployed program.

## Install and run

```sh
pnpm --dir hermes/utils/module-host install --frozen-lockfile --ignore-scripts
cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared --parallel 4
python3 hermes/utils/shllvm.py run --module \
  --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin \
  hermes/test/LLVMModules/await-diamond/main.mjs
```

`emit`, `build`, and `jit` accept the same module options. The compiler and runtime
must come from the same build: module jobs use the private `moduleThen` builtin.
The ordinary script path remains available without `--module`.

`--module-root DIRECTORY` sets the graph root; its default is the entry file's
directory. `--module-include FILE` adds another discovery root and is repeatable.
Use it for a target reachable only through a computed dynamic import:

```sh
python3 hermes/utils/shllvm.py run --module \
  --module-include /project/modules/selected.mjs \
  /project/modules/main.mjs
```

## Resolution policy

Requests must be exact `./` or `../` filesystem paths inside the graph root.
There is no extension search, package lookup, CommonJS fallback, network access,
or runtime source-file loading. Query/fragment suffixes, backslashes, NUL, and
bare specifiers are rejected. Existing files are identified by canonical paths;
symlink aliases discovered at build time share that identity.

Static dependencies are discovered recursively. Literal dynamic imports add
records without linking or executing their bodies. Explicitly included roots
supply additional records for computed imports. A request outside that manifest
rejects its import Promise. A malformed dynamic-only source is also deferred;
an error in the entry's static dependency graph fails build-time validation.

The build manifest records every read source hash, graph identity, compiler and
runtime-host hashes, dependency lock, loaded build dependency hashes, and Node
version/executable identity. All published artifact paths are checked against
source paths, including hardlinks. Generated artifacts belong in the configured
build directory or the explicitly requested output location.

## Linking and live bindings

Each module becomes a strict generator factory. Its first execution registers
getter closures and suspends before source statements. The generator frame
holds the module's actual bindings: functions are hoisted, vars contain undefined,
and lexical declarations retain TDZ until evaluation initializes them.

Imports are rewritten by lexical binding identity, preserving shadowing. Reads
resolve to the exporting cell; assignments use an internal accessor reference
that throws TypeError while preserving operand effects. Imported calls keep an
undefined receiver. Reexports and export-star resolution follow cell identities,
terminate cycles, omit default from stars, and distinguish genuinely ambiguous
exports from two routes to the same binding.

A namespace has null prototype, sorted export keys, stable identity, live data
descriptors, Symbol.toStringTag `Module`, and non-extensible shape. Writes fail.
Seal/freeze behavior and numeric-key Proxy invariants require the accompanying
shared-runtime fixes. Names such as `__proto__` are stored as ordinary metadata
keys rather than interpreted as object-literal prototype setters.

## Evaluation and asynchronous work

A DFS stack records ancestor indices and cycle roots. Evaluation of synchronous
cycles does not wait recursively on a back edge. Async records track pending
dependencies, parents, and execution order; completion releases ready ancestors
in that order. Errors propagate to dependent records and are retained for later
imports. A failed link rolls back unfinished dependency environments so a bad
importer does not poison an otherwise valid dependency.

Top-level await becomes generator suspension. The host resumes fulfillment with
`next` and rejection with `throw`, preserving source try/catch/finally. Top-level
for-await lowers async iteration and cleanup explicitly, including async-from-sync
value awaiting and abrupt-completion precedence. Large transformed functions can
still exceed the unchanged 1,024 combined root/argument-slot limit.

Dynamic import returns a fresh Promise for each call, sharing graph evaluation
and namespace state. Import options may be absent or contain an empty `with`
object; non-empty attributes are unsupported. Invalid option types and getter
errors reject normally. `import.meta` has stable per-module identity and a file
URL. Module jobs use an intrinsic Promise reaction builtin rather than public
`then` or species construction.

## Boundaries

This is a filesystem host with targeted conformance evidence. It does not claim
complete ESM or ECMAScript conformance. Direct eval in transformed modules is
explicitly rejected because rewritten imported bindings cannot yet be supplied
to eval's lexical compiler context. Non-empty static/dynamic import attributes,
source-phase imports, and deferred import phases are explicit boundaries.
Arbitrary mutation of all host-used intrinsics is not a qualified contract.
Generated source positions are not original-module source maps.

Dynamic import in ordinary script mode has not been added by this path. Use a
module entry for the module host. Existing language/runtime and root-slot
admission limitations can still reject a module's body. A graph waiting on an
unresolved Promise can remain incomplete; process exit alone is not evidence
that its evaluation completed.

## Validation

```sh
pnpm --dir hermes/utils/module-host test
python3 hermes/utils/test_shllvm_modules.py --output /tmp/module-graphs.json
python3 hermes/utils/test_shllvm_test262.py \
  --suite /tmp/llvm-test262 --build-dir hermes/build-llvm \
  --llvm-bin /usr/lib/llvm-18/bin --modules --hermes-opt O --llvm-opt 2 \
  --jobs 8 --compact --output /tmp/module-test262.json test/language/module-code
```

The graph gate compares Node ESM with four native optimization combinations and
real lli. Specification-directed cases retain the Node mismatch and its stated
qualification instead of counting it as a Node match. In particular, the pinned
namespace-binding identity rule differs from Node 24.18.0's treatment of duplicate
namespace re-export routes. Numeric export keys are a second recorded difference:
the pinned namespace algorithm sorts them lexicographically, while the tested
Node version enumerates them numerically.

The Test262 module path uses Babel for entry parsing and the shared host's
link-only mode in Node for resolution checks; source bodies never execute during
that validation. Native bodies run through LLVM. Each module record identifies
that validation engine. Imported-source syntax failures are attributed to
resolution, and explicit host boundaries cannot satisfy a syntax-negative test.
A completion marker is required for positive module contracts, including tests
without an async flag, so unresolved evaluation cannot silently pass.

The updated native event loop reports actual thrown exception type through the
Test262 protocol for timer/microtask errors. It never infers a type by parsing a
user-controlled stack string. Historical baseline records remain unchanged.

Detailed design, diary, initial failures and final qualification are maintained
under `ttmp/2026/10/28/LLVM-MODULES-001--ecmascript-module-host-resolution-linking-and-asynchronous-evaluation`.

### Qualified checkpoint (2026-10-28)

- Fourteen graph contracts: 56 native executions and 14 real lli executions.
  Twelve graphs match Node; two use documented specification expectations.
- Test262 `0b4e0812022b18236b5276d2804948fdd9f71603`, module-code selection,
  frontend O / LLVM O2: 585 passes and 17 unsupported variants out of 602.
  Passes comprise 396 runtime, 166 parsing, and 23 resolution contracts.
- Unsupported: eight attribute cases, three source-phase module cases, four
  ordinary-script variants outside the module path, and two root-slot rejections.
- Existing gates: core 22/22; extensions 66/66. Structured exception probes 19/19;
  build compiler tests 8/8.

The graph, Test262, and extension receipts report unchanged inputs. The broad
102,992-variant historical baseline was not rerun. These results qualify the
selected host profile; they do not establish complete language conformance.
