# Strata native compiler

Strata parses a JavaScript subset, builds its own IR, promotes local cells, assigns checked root homes, and emits real LLVM IR. LLVM compiles it; the existing Hermes runtime supplies managed values and JavaScript operations. This path never invokes the Hermes frontend.

```sh
node strata/tools/strata-native.js run strata/test/fixtures/ledger.js -O 2
node strata/tools/strata-native.js emit strata/test/fixtures/closures.js -o /tmp/closures
node strata/tools/strata-native.js build strata/test/fixtures/ledger.js --roots distinct -o /tmp/ledger
```

Run these commands from the repository root. The default runtime build is `hermes/build-llvm`; the default LLVM tool directory is `/usr/lib/llvm-18/bin`. Override them with `--build-dir` and `--llvm-bin`. The build directory must contain `libshllvm_runtime.a`, `libhermesvm.so`, and `libshermes_console.so`. There is no dependency-install step: the pinned Acorn parser and license are included. The Node loader assembles `src/core` and the frontend into ignored `lib/` files.

`emit` assembles and verifies IR. `build` additionally links it; `run` executes it. Outputs include `.ll`, `.bc`, `.ir`, and `.build.json`, plus the executable for build/run. `-O` controls LLVM optimization. `--runtime-arg=-gc-sanitize-handles=1` forwards an explicit runtime option. Manifests contain compiler/runtime/configuration hashes, root counts, LLVM version and commands. Failed compilation/verification does not replace prior published output files. Tool subprocesses and program execution have time limits.

## Source ownership

- `src/core` and `src/frontend.js` originate in the Strata workbench. Corrections are tracked here; its educational/model pipeline remains available.
- `native/frontend.js` selects the native frontend path and cell promotion, without speculative rewrites.
- `native/abi.js` derives helper prototypes and enum values from the actual bridge header.
- `native/roots.js` computes full-lifetime interference and checks home assignments.
- `native/emitter.js` implements the real native path, including unit data, environments, calls and longjmp restoration.
- `tools/strata-native.js` manages LLVM verification/linking and records build evidence.

The original imported workbench, documents, and examples remain under `ttmp/2026/10/29/STRATA-PORT-001--strata-workspace-import-and-hermes-llvm-port-assessment/source/`. Reconstruct that reference tree from its ticket's preserved ZIP using `scripts/01-import-workspace.py` if absent. It is not the working implementation.

## Admitted profile

The native subset covers numbers, booleans, null/undefined and exact UTF-16 strings; arithmetic and strict comparisons; conditional/loop control; plain objects/arrays and property calls; functions, arrow captures, recursion and shared mutable cells; try/catch/finally; and the provided console runtime's print, timers, microtasks and Promises. Runtime standard-library methods are ordinary calls. The original ledger and eight J programs are included as unchanged fixtures.

This is an experimental subset, not a general JavaScript compiler. In particular:

- Classes, generators, async syntax, BigInt literals, regex literals, destructuring and direct lexical eval are rejected. General `new` is not implemented; the frontend has an Error-constructor form.
- Named function expressions and implicit `arguments` are explicitly rejected until current-callee and argument-object lowering exist.
- `for...of` retains the imported array-index lowering. Its admitted form is ordinary arrays with unmodified iteration behavior; it does not implement arbitrary iterator protocols or iterator closing. Avoid custom iterators, array subclasses and strings in this form.
- `print`, `queueMicrotask`, `setTimeout`, `Promise.resolve`, and Error-constructor frontend forms assume the normal host globals. Replacing those bindings/getters is outside this profile. Source modules are not accepted.
- The emitter takes frontend-produced IR; arbitrary IR files, custom operators, and the workbench's `statusReturn`/arena strategies are not native inputs.
- The runtime is host64 Linux x86-64. Static strings passed to `Function` or other runtime dynamic compilation are not translated by Strata; no lexical-eval interoperability is claimed.
- This tier has no speculative optimization, deoptimization, per-unit unloading or native embedding API. It is an AOT native path; existing repository JIT work remains separate.

`reuse` is the default root policy; `distinct` is a comparison policy. Both keep all value homes visible to the collector. Reuse covers complete value lifetimes, helper outputs and exception paths, rather than only safepoints. Literals, scratch and global homes remain distinct. The existing combined 1,024 root/argument-slot limit remains; functions with many constants or genuinely large simultaneous live sets can still be rejected.

## Validation commands

```sh
node strata/test/boundaries.test.js
node strata/test/roots.test.js
node strata/test/driver.test.js
node strata/test/native.test.js /tmp/strata-native-tests
# Explicit aggressive moving-GC runtime configuration:
node strata/test/native.test.js /tmp/strata-native-stress hermes/build-strata-gcstress stress
node strata/test/gc-negative.test.js hermes/build-strata-gcstress
```

The differential runner compares script execution with Node at LLVM O0/O2 under both root policies. Imported J-07 deliberately exits with `Error: missing field price`; it is classified as an expected language error. The root checker includes a deliberately invalid assignment; a generated 1,200-value case checks admission and reuse. Stress mode requires libraries actually compiled with `HERMESVM_SANITIZE_HANDLES=ON`; setting the runtime flag on a normal build is not equivalent. Sanitizer link flags follow the selected CMake cache.

The ticket contains the detailed guide, diary, upload receipt, and dated execution evidence. Historical workbench results and newly recorded native results are separate.
