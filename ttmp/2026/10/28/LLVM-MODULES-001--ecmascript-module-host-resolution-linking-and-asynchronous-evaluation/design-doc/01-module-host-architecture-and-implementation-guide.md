---
Title: Module host architecture and implementation guide
Ticket: LLVM-MODULES-001
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/lib/VM/JSProxy.cpp
      Note: Namespace numeric-key invariant correction
    - Path: repo://hermes/tools/shermes/ConsoleBindings.cpp
      Note: Async exception evidence protocol
    - Path: repo://hermes/utils/module-host/compiler.cjs
      Note: Graph discovery and lexical source transformation
    - Path: repo://hermes/utils/module-host/runtime.js
      Note: Linking namespaces cyclic and asynchronous evaluation
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T21:47:56.294132829-04:00
WhatFor: ""
WhenToUse: ""
---

# Module host architecture and implementation guide

## 1. Objective and execution model

Implement a JavaScript source-text module host for the existing direct LLVM driver. The host must resolve module requests, link imports to exports before execution, preserve live bindings and lexical initialization, execute cyclic graphs once, return Promises from dynamic import, and schedule top-level await dependencies. Module bodies and the host itself compile through Hermes IR to LLVM. Node is a build-time parser/code-generation dependency and independent oracle, not the deployed execution engine.

A module record represents one canonical source identity and its lifecycle state. Resolution maps a referring module and a specifier to that identity. Linking constructs its environment and connects references without executing source statements. Evaluation executes statements after dependency constraints are satisfied. These are distinct operations: evaluating dependencies as soon as an import is encountered cannot detect all linking errors before side effects.

The implementation will provide an explicit closed filesystem graph. Relative specifiers identify exact files; no extension search, package lookup, network fetching, or CommonJS fallback is implicit. The entry file and statically reachable dependencies are included automatically. Literal dynamic imports are discovered at build time; additional roots can be included explicitly for computed dynamic imports. A runtime request outside the included graph rejects its Promise. This is a host policy, not a claim that ECMAScript requires filesystem or package resolution.

## 2. Existing code and why a new module path is required

`hermes/utils/shllvm.py` emits a script through shermes and verifies the resulting LLVM module. `hermes/lib/IRGen/ESTreeIRGen-stmt.cpp::genImportDeclaration` currently expects CommonJS mode and loads imported property values into local variables. That representation does not preserve subsequent exporter writes. Its export lowering writes values onto an ordinary exports object. Reusing it as an ESM host would leave linking and namespace semantics incorrect.

The runtime already supports generators, Promises, lexical environments, TDZ checks, and the native garbage-collector roots required by suspended functions. The new path will use those mechanisms rather than introducing another collector or executing module bodies in Node. The compiler will parse module syntax with Babel, use binding-aware transformation, and generate strict generator factories whose suspended lexical frames are the module environments.

Proposed files:

| File | Responsibility |
|---|---|
| `hermes/utils/module-host/compiler.cjs` | Graph discovery, source parsing, scope-aware lowering, manifest generation |
| `hermes/utils/module-host/runtime.js` | Module records, linking, namespace objects, evaluation and import jobs |
| `hermes/utils/module-host/package.json` and lock | Pinned build-time parser and generator dependencies |
| `hermes/utils/shllvm.py` | Explicit module-mode invocation and build manifest integration |
| `hermes/utils/test_shllvm_modules.py` | Native/lli/Node graph comparisons and host-boundary contracts |
| `hermes/test/LLVMModules/` | Multi-file regression fixtures |
| `hermes/docs/llvm/MODULES.md` | Commands, supported host policy, validation and limits |

## 3. Lexical storage and the instantiation suspension

A generator starts executing when its next method is first called and retains local storage while suspended. Each module factory will create export getter closures, then yield one private instantiation marker before any source statement. Function declarations are initialized by ordinary function instantiation; var bindings contain undefined; lexical declarations remain uninitialized until execution reaches them. Export getters capture those actual bindings.

For example, an exporter with `export let count = 0; export function increment() { count++; }` becomes conceptually:

```javascript
function* factory(context) {
  'use strict';
  context.bind('count', () => count);
  context.bind('increment', () => increment);
  yield context.instantiated;
  let count = 0;
  function increment() { count++; }
}
```

This is a design sketch; generated names must be hygienic and getters are keyed by local binding identity separately from external export names. Linking advances each reachable factory to the marker, registers cells, and validates every import/export. Evaluation resumes after the marker. An early cyclic read of count throws ReferenceError through its getter; an early call of increment is permitted as a function binding, though reading count inside it can still throw.

Imported identifiers are rewritten using the parser's binding information. A local parameter that shadows an imported name must not be rewritten. Reads request the resolved cell, so later writes by the exporter remain visible. Imported calls must have an undefined receiver: rewriting `fn()` to `namespace.fn()` would incorrectly supply the namespace as this. Assignment to an imported binding throws TypeError at runtime after the required operand evaluation. The compiler lowers assignment targets to internal accessor references that read the live cell and reject writes, preserving compound assignments, increments, destructuring targets, and right-hand-side effects.

The generated wrapper is an implementation detail and must not expose its own arguments object or receiver as module state. Top-level this, including arrows that capture it, is undefined. Unbound top-level arguments must not become the wrapper's arguments. Direct string eval in a transformed module cannot currently reconstruct imported source bindings after rewriting; it needs an explicit unsupported-context diagnostic rather than silently evaluating a different environment. This boundary must be documented and tested.

## 4. Resolution and graph identity

The build compiler records the entry identity, source hashes, static requested-module order, explicit import/export entries, star exports, and literal dynamic targets. The graph has one record per canonical identity. Repeated requests share that record. Distinct spellings normalized to the same identity must not execute twice.

Resolution has two interfaces: a build-time resolver that reads files and a runtime resolver limited to the included manifest. Both use the same path normalization policy. Relative segments are normalized against the referring file's directory. Bare package names and unsupported URL schemes fail explicitly. The host must not concatenate unchecked strings into shell commands. Resolver failures during dynamic import are Promise rejections, including conversion failures in the import argument.

Dynamic-only modules must not be linked or executed merely because the compiler discovered them. Their parse or linkage failures must reject when requested, while a broken static dependency prevents the entry body from executing. The compiler must therefore preserve errors as records where deferred loading requires them.

## 5. Export resolution and live imports

An export entry can designate a local cell, a re-exported binding, a namespace export, or a star-export source. ResolveExport recursively follows entries, with a visited set of module/name pairs to terminate cycles. Explicit exports take precedence over stars. Default is never supplied by export-star. When two stars resolve a name to different cells, the name is ambiguous; two routes to the same cell are not ambiguous.

```text
resolveExport(module, name, visited):
    if module/name already visited: return missing
    if explicit local export: return its cell identity
    if explicit indirect export: resolve target/name
    if namespace export: return target namespace cell
    if name is default: return missing
    combine all star resolutions
    return unique cell, missing, or ambiguous
```

Linking validates named imports and explicit indirect exports before bodies run. Namespace enumeration includes unambiguous exported names in lexical order. Reads use the final cell, preserving both live values and TDZ behavior. Cyclic re-export traversal must terminate without treating a repeated pair as a successful binding.

## 6. Namespace object behavior

A namespace is a stable, non-extensible object with null prototype and lexically ordered string export keys. Its exported properties appear enumerable, non-configurable, and writable in descriptors, but assignment through the namespace fails. The descriptor's value is the binding's current value. Symbol.toStringTag is Module. These details differ from freezing an ordinary object containing copied values.

The proposed host uses a Proxy over a non-extensible null-prototype target with matching non-configurable keys. The get and getOwnPropertyDescriptor traps read live cells. The set trap fails; defineProperty accepts only changes that leave the namespace contract unchanged. The target's writable data descriptors permit live descriptor values without violating Proxy invariants. Tests must cover descriptor shape, failed writes/deletes/redefinitions, ownKeys order, prototype, identity, and reads before initialization. If an underlying Hermes Proxy defect prevents a required behavior, preserve that failure and correct the runtime or state the boundary explicitly.

## 7. Synchronous cycles and evaluation errors

Evaluation uses a depth-first traversal with an evaluation stack and ancestor indices. A back edge to a currently evaluating record does not recursively wait for that record to finish. Strongly connected components receive a cycle root when traversal completes. This permits cyclic functions to be called before every body has run while preserving lexical TDZ errors.

```mermaid
flowchart LR
    A[Entry A] --> B[Dependency B]
    B --> A
    B --> C[Dependency C]
    C --> BC[Execute C]
    BC --> BB[Execute B]
    BB --> BA[Execute A]
```

If B reads an uninitialized lexical binding from A, evaluation fails and the error is retained. Repeated imports must reject with the retained error rather than rerun side effects. Linking errors are also retained consistently. An error in a deferred dynamic-only graph must not invalidate an unrelated already-evaluated graph.

## 8. Top-level await and asynchronous dependencies

Top-level await suspends module evaluation and postpones dependants. The compiler rewrites awaits belonging to the module's top-level lexical execution into generator yields. Awaits inside nested async functions remain ordinary async-function awaits. The runtime resumes the generator with fulfillment values or throws rejection values into it, preserving source try/catch/finally regions.

The evaluation algorithm follows the specification's DFS and async dependency ordering. Each record tracks pending async dependencies, async parent modules, async evaluation order, cycle root, completion capability, and cached error. A Promise per recursive call followed by Promise.all is insufficient: cycles and sibling ordering require explicit state.

```text
visit each static dependency in source request order
if dependency remains on DFS stack: update ancestor index
otherwise use its cycle root
if dependency has pending asynchronous evaluation:
    increment this module's pending count
    register this module as an async parent
if pending count > 0 or module contains top-level await:
    assign async evaluation order
    start body only if pending count == 0
else execute body synchronously
finish strongly connected component when ancestor index closes
```

On asynchronous fulfillment, decrement affected parents' pending counts, gather newly runnable ancestors, and execute them in async evaluation order. On rejection, propagate the same error through async parents and reject any waiting top-level capabilities. A cyclic graph awaiting its own dynamic import may remain pending; the host must not invent a successful completion or an artificial language error.

Top-level `for await` also requires lowering that preserves iterator cleanup and awaiting rules. It must receive explicit implementation or an honest admission rejection, with a test preventing silent miscompilation. The implemented lowering isolates this transformation from ordinary nested async functions and preserves iterator closing, async-from-sync values, labels, and abrupt-completion precedence.

## 9. Dynamic import and job ordering

Import evaluates its specifier expression and returns a fresh Promise. Runtime resolution, linking, and evaluation complete that Promise with the stable namespace or reject it with the failure. Repeated imports share module state and namespace identity while returning distinct public Promise objects. Import of a module still awaiting evaluation joins the existing completion.

The host performs import work in a Promise job so body execution does not synchronously occur inside the initiating expression. The ordering tests must compare actual traces against Node's native module loader; native Promise job ordering is already a sensitive part of this runtime. A namespace with an exported callable named then participates in Promise resolution when returned from dynamic import, so the implementation must use ordinary Promise fulfillment rather than treating that namespace as an opaque value.

`import.meta` can provide a stable per-module null-prototype object with the file URL under this filesystem host. Its identity must be retained across reads. Resolution conveniences beyond that property are host policy and must not be implied by the source language.

## 10. Driver integration and artifact evidence

Add explicit `--module` mode to emit, build, run, and jit. The driver invokes the build-time compiler into its temporary directory, then sends the generated script through the existing LLVM verification and linking path. Script mode remains unchanged. The build manifest records module source identities and hashes, compiler/runtime host source hashes, dependency lock hash, selected entry, and inclusion policy. Output protection must include all graph inputs, not just the entry file.

The module compiler needs pinned parser/traversal/code-generator dependencies and an installation command in documentation. Generated JavaScript and LLVM artifacts belong under the configured build directory. No generated bundle or node_modules directory should be committed. Source maps and native module-aware stack display are follow-up tooling work; generated-source locations must not be presented as original source positions.

## 11. Validation plan

The test harness will compile independent multi-file fixtures, compare successful traces with Node's native ESM loader, and distinguish expected parse/link/runtime failures from host boundary rejections. It will test all four frontend/LLVM optimization combinations and real lli for representative graphs. Compile-time build tooling tests cover deterministic resolution and output safety.

Required contracts include live named/default/re-export bindings, shadowed imports, destructuring exports, ambiguous and duplicate star routes, missing exports before side effects, self imports, diamonds, synchronous cycles, hoisted functions, lexical TDZ cycles, cached evaluation errors, namespace descriptors, import.meta identity, repeated and computed dynamic imports, missing dynamic targets, independent dynamic graphs, top-level await fulfillment/rejection, asynchronous dependency diamonds, cycles containing await, and cleanup through finally.

After targeted qualification, run a selected pinned Test262 module subset through an explicit module-host mode. Preserve unsupported cases and phase qualifications; do not rewrite the previous baseline. The earlier 843 module rejections are the pre-implementation evidence, not a pass target to manufacture through broad skipping.

## 12. Primary references and acceptance

The architecture follows the [ECMAScript scripts and modules specification](https://tc39.es/ecma262/2026/multipage/ecmascript-language-scripts-and-modules.html), particularly Source Text Module Records, ResolveExport, InnerModuleEvaluation, and asynchronous completion handling. Namespace operations are defined in the specification's ordinary and exotic objects chapter. [Babel parser documentation](https://babeljs.io/docs/babel-parser) defines module parsing and syntax flags; binding traversal must use actual scope identities rather than identifier text substitution.

Acceptance requires runnable native graphs in all requested areas, retained evidence for the tested semantics, documented filesystem and syntax boundaries, a clean script-regression gate, and commits with a chronological diary. It does not establish all ECMAScript conformance, a network loader, package compatibility, runtime native compilation, or physical PicoCalc execution.

## 13. Implemented checkpoint and evidence

The implementation resides in `hermes/utils/module-host/compiler.cjs` and
`runtime.js`, with CLI integration in `hermes/utils/shllvm.py`. The operational
contract and exact validation totals are maintained in
`hermes/docs/llvm/MODULES.md`. Read that contract before extending resolver policy.
The ticket's `reference/evidence/` directory retains both the initial failed
selection and the final qualification; large JSON receipts use deterministic gzip.
`receipt-hashes.json` identifies their uncompressed bytes, and
`initial-to-final.json` compares the same variants and source hashes.

The runtime adds an intrinsic `moduleThen` reaction operation in
`lib/InternalJavaScript/01-Promise.js`, registered through Builtins.def,
PredefinedStrings.def, and `ESTreeIRGen::genSHBuiltin`. This prevents module
scheduling from invoking user-visible Promise.then or species construction.
Proxy integrity operations in JSObject.cpp and JSLib/Object.cpp now invoke the
Proxy internal methods, and JSProxy.cpp normalizes numeric target keys before
ownKeys invariant comparisons. These shared changes have a standalone script
regression in `test/LLVMNativeExtensions/proxy_integrity.js`.

The public host entry is `run(id, onComplete, onError)`; `check(id)` performs
link-only validation. An unresolved await retains incomplete evaluation state.
The inherited console loop may terminate when it has no queued tasks even if
that state remains pending. No Node-style exit-code-13 policy is implemented.
Consequently the conformance runner requires an explicit completion marker;
a successful operating-system exit alone is not an evaluation assertion. A
future embedding should connect onComplete/onError to its lifecycle policy.

Remaining boundaries are direct eval in transformed modules, non-empty import
attributes, source/deferred phases, runtime loading outside the compiled graph,
script-mode dynamic imports, and the existing combined root/argument-slot limit.
These are explicit limits, not inferred successful conformance results.
