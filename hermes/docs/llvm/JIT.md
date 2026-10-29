# In-process baseline LLVM JIT

`shllvm-jit` compiles source through Hermes and executes LLVM-generated native
code in its own process. Multiple input files share one Hermes runtime. The
source frontend, LLVM IR parsing, native compilation, symbol resolution, and
execution are in-process; neither shermes nor lli is launched by this path.

This is the bounded engine implemented by LLVM-ENGINE-001 and LLVM-JIT-001.
It is an eager unit-level JIT, without speculative optimization, deoptimization,
tiering, or individual code unloading. It is qualified on Linux x86-64 host64
with LLVM 18.1.3. It does not claim full ECMAScript conformance or device support.

## Build

Start from the existing configured Hermes build described in DRIVER.md:

```sh
cmake -S hermes -B hermes/build-llvm \
  -DHERMES_BUILD_LLVM_JIT=ON \
  -DSHLLVM_CONFIG=/usr/lib/llvm-18/bin/llvm-config
cmake --build hermes/build-llvm \
  --target shllvm-jit shllvm-jit-test shermes shllvm_runtime --parallel 4
```

The optional target needs LLVM 18 development headers and its shared library.
The build uses llvm-config instead of importing LLVMConfig's tool targets,
which collide with bundled llvh target names. The existing configured Clang
build on this machine uses
`--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13` for its C++ library headers;
that is a machine-specific compiler setting, not a JavaScript option.

With `HERMES_BUILD_LLVM_JIT=OFF` (the default), the ordinary AOT compiler does
not discover or link system LLVM development libraries. Rebuild compiler/runtime
artifacts together after this change: the shared native unit table layout has
changed from a fixed array to growable storage.

## Run source in a shared runtime

```sh
hermes/build-llvm/bin/shllvm-jit first.js second.js
hermes/build-llvm/bin/shllvm-jit -O --gc-between --stats first.js second.js
```

Each file is a separate compilation unit, initialized once, in argument order.
Use `globalThis` or objects/functions reachable from it for explicit cross-unit
communication. This is not a claim of a REPL with persistent top-level lexical
bindings across separately compiled files. All units share the managed heap.

`-O` enables the existing Hermes optimized pipeline; without it the frontend
uses its no-optimization pipeline. LLJIT uses its default native code-generation
configuration. These flags do not implement a tiered optimizer or the driver's
independent LLVM O0/O2 optimization matrix. `--async-generators` enables that
frontend feature. `--gc-between` forces collection after each initialized unit.
`--stats` prints compilation/materialization time, execution time, retained unit
count, and process peak RSS in KiB to stderr.

A source/compile/runtime error exits 1. Incorrect CLI usage exits 2. An instrumented
module entry still pending after job draining also exits 2 with a `pending`
diagnostic. These two exit-2 situations are distinguished by their diagnostics.
The console job drain blocks for timers and registered task sources; it is not a
nonblocking poll or a general cancellation facility.

## Load existing LLVM output

For a backend-produced creator-only unit:

```sh
hermes/build-llvm/bin/shermes -emit-llvm -exported-unit=sample \
  sample.js -o /tmp/sample.ll
hermes/build-llvm/bin/shllvm-jit --ir sh_export_sample /tmp/sample.ll
```

The engine requires a defined exported C-calling-convention `ptr()` creator and
rejects a generated executable `main`. Explicit incompatible target triples and
data layouts are rejected. The loader verifies LLVM IR before materialization.
Inputs are trusted backend-produced native code; verification is not a sandbox.
The source API chooses unique engine-local creator names automatically.

## Modules

Use the existing build-time module compiler with the host completion option:

```sh
pnpm --dir hermes/utils/module-host install --frozen-lockfile --ignore-scripts
node hermes/utils/module-host/compiler.cjs \
  hermes/test/LLVMModules/await-diamond/main.mjs \
  --output /tmp/diamond.js --manifest /tmp/diamond.json --host-completion
hermes/build-llvm/bin/shllvm-jit /tmp/diamond.js
```

`--host-completion` generates calls to the engine's private entry notification
functions. Each graph entry gets a token and records pending, fulfilled, or
rejected state independently of unit initialization. After draining jobs, a
pending entry cannot be reported as completed. A forever-unresolved Promise
therefore produces an explicit pending result instead of an accidental pass.

This bookkeeping is a trusted internal protocol, not tamper-proof language
isolation. The native host installs the notification functions; an instrumented
bundle cannot run unchanged under a host that does not provide them. Default
compiler output is unchanged. A bundle generated without this option has only
ordinary script completion semantics in the engine: do not infer module-entry
completion from its unit initializer.

Babel remains build-time tooling. Computed imports still require explicit graph
inclusion, and separate bundles have separate module registries. No runtime
module source loading, package resolver, or native module eval was added here.
The original `shllvm.py jit` command still provides the separate lli execution
path; `shllvm-jit` is the new persistent engine executable.

## Private C++ API and ownership

`hermes/include/hermes/LLVMJIT/Engine.h` declares the private API:

- `Engine::create(error)` constructs one runtime and one LLJIT instance.
- `compile(source, filename, options)` compiles and materializes a unit.
- `loadIR(ir, creator)` admits backend-produced IR without executing it.
- `execute(unit)` initializes a unit at most once.
- `drain()` blocks through configured jobs and returns completed/error/pending.
- `collect()` forces runtime garbage collection.
- `close()` destroys the runtime before releasing its native code; it is idempotent.

Results contain a success flag, phase, diagnostic message, and engine-local unit
index. No unrooted tagged JavaScript value is exposed. Runtime exceptions are
printed through the existing runtime handle-based reporting path; the API result
reports the phase and a summary. Source diagnostics retain the submitted filename.

All engine operations and destruction belong to the creating thread. Methods
with Result return a state error on a wrong-thread call. Destruction of a live
engine from a different thread aborts as a programming error. The metadata
getter `unitCount()` also requires owner-thread use. There is no concurrent
execution or API reentrancy contract.

A source initializer can publish closures before throwing. Its code remains
retained after that exception, and later valid units can still execute. Parse,
verification, and materialization errors do not call an invalid creator. Native
out-of-memory conditions retain the underlying runtime's fatal policy.

Registered units cannot be unloaded individually. Shutdown releases console
bindings, destroys Hermes while code remains mapped, frees the host context, and
then destroys LLVM code/resources. Pending work is abandoned on explicit close;
close is not an implicit job-drain request. Drain before close when completion
is required.

The SHUnit root table now grows beyond the previous eight-entry bound. Strong
roots, weak roots, destruction, lookup checks, and memory accounting use the new
capacity. Globally unique unit indices retain their existing process lifetime,
so a newly created runtime's table can reflect a prior process-wide index
high-water mark. Code memory grows with units retained by an engine. Neither
unbounded compilation nor long-lived-server memory stability is claimed.

## Validation and measurements

```sh
hermes/build-llvm/bin/shllvm-jit-test
python3 hermes/utils/test_shllvm_jit.py --output /tmp/jit-qualification.json
```

The final focused gate passes 48/48 with unchanged recorded inputs:

- One lifecycle suite exercises repeated/simultaneous engines, more than eight
  units, shared state, escaped closures, forced GC, exceptions, invalid inputs,
  duplicate creators, missing symbols, thread checks, and teardown.
- Eight existing language-extension sources run at both frontend profiles,
  compared with Node script execution (16 contracts).
- Fourteen existing module graphs run at both frontend profiles (28 contracts).
  The two previously documented specification-directed Node qualifications remain.
- Pending, fulfilled, and rejected module entries have explicit expected outcomes
  (three contracts).

Existing AOT/native regression gates pass core 22/22 and extensions 66/66. The
extension receipt confirms unchanged inputs. The optional-off build was checked
at configuration time with an invalid LLVM discovery path; that was not a second
complete build. The current qualification build is not sanitizer-enabled.

A retained execve trace shows only the host executable during source compilation
and execution. A small incremental workload measured median compile/materialize
times around 2.6–4.2 ms and peak process RSS around 65–67 MiB across fresh processes
with 1, 20, and 100 increments. These are illustrative single-run smoke numbers,
including compiler/runtime effects, not comparative benchmarks or leak proofs.
The exact records and commands are in the ticket evidence and measurement script.
