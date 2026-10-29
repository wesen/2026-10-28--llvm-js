---
Title: Engine v2 architecture and intern implementation guide
Ticket: LLVM-ENGINE-002
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/include/hermes/VM/static_h.h
      Note: Native frame and root chain contracts
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
      Note: Emitter semantics and current frame allocation
    - Path: repo://hermes/lib/LLVMJIT/Engine.cpp
      Note: Reference engine ownership and materialization
    - Path: repo://hermes/lib/VM/StaticH.cpp
      Note: Nonlocal exception restoration
    - Path: repo://hermes/lib/VM/StaticHUnit.cpp
      Note: Existing process-global unit identity
    - Path: repo://hermes/utils/module-host/runtime.js
      Note: Existing module evaluation algorithms
    - Path: repo://hermes/utils/qualify_shllvm_apps.py
      Note: Independent application acceptance contracts
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T12:12:00.522267475-04:00
WhatFor: ""
WhenToUse: ""
---

# Engine v2: a unified native JavaScript engine

## 1. Decision and scope

Build a parallel implementation in `engine-v2/` within the existing repository. Keep the current implementation runnable at source checkpoint `d715f43` as a behavioral reference. Reuse the Hermes parser, semantic analysis, IR, optimizer, object model, garbage collector, and language operations. Replace the integration decisions that currently govern native activation storage, unit identity, module registry ownership, and host execution.

This is a design and implementation guide, not a claim that the proposed API or directory already exists. The current ticket delivers the guide and its reMarkable copy. Implementation tasks remain open. Every API below marked proposed belongs to v2 and has no compatibility obligation to the current Engine API, emitted IR, native unit descriptors, or command-line formats.

The central design rule is: **one Engine owns one JavaScript execution domain**. Its runtime, native activations, code, module records, jobs, and external value handles have explicit lifetimes under that owner. Compiler output is a description of code and bindings; it does not create a second independent runtime or module registry.

The objective is a small, understandable engine that admits useful applications and makes its behavior explicit. It is not a replacement for every Hermes subsystem, a browser, a Node implementation, an adaptive optimizer, or a compatibility framework. Simplicity means a small number of strong contracts, not hiding lifetime work behind generic abstractions.

## 2. Why a parallel implementation is appropriate

The current implementation proves valuable behavior, including 96 successful application executions and a retained real-world failure: the unoptimized fflate module factory requires 1,084 root slots and three argument slots against the 1,024 combined bound. It also exposes structural decisions that would be awkward to change one compatibility-preserving step at a time. Generated code reads unit identities from native metadata, roots reside in native stack frames, and independent module bundles instantiate separate registries.

A parallel implementation lets us change these contracts together without making the existing working engine unusable during the experiment. Keeping both in one repository preserves test access, source history, pinned dependencies, and a single shared Hermes source tree. A separate repository or copied Hermes tree would introduce synchronization work before proving that the new architecture is worthwhile.

Do not archive or move `hermes/` now. Its paths are referenced by build rules, fixtures, reports, and receipts. Moving it would create unrelated churn and weaken the reference baseline. A worktree is useful for isolation during concurrent work, but it is optional operational tooling rather than a second source of truth.

### Decision: parallel integration, shared language implementation

- **Context:** We can break old interfaces, but still need a reliable language/runtime foundation and a comparison implementation.
- **Options considered:** Incremental mutation of the old Engine; a full copied repository; a new integration directory sharing Hermes.
- **Decision:** Use `engine-v2/`, new symbols and build targets, and a separate build directory. Shared runtime changes are allowed when they express a necessary v2 primitive.
- **Rationale:** This isolates the new design without duplicating the most complex semantic code.
- **Consequences:** Some changes necessarily touch Hermes. The directory boundary is an ownership convention, not an assertion that the old runtime is a perfectly encapsulated library.
- **Status:** Proposed direction for implementation.

We will not implement a wrapper that presents the old Engine API over the new engine. We will not load old native artifacts into v2. The old and new engines are compared in separate processes. When v2 meets its acceptance criteria, users can explicitly switch commands and regenerate artifacts; obsolete paths can then be removed.

## 3. Orientation for a new contributor

JavaScript source first passes through a frontend that parses syntax, resolves names, and constructs an intermediate representation, or IR. The backend turns that IR into native code. LLVM supplies the final native compilation. Hermes supplies the managed runtime: objects, function environments, strings, arrays, exceptions, and garbage collection.

A managed value may refer to an object whose memory the collector manages. A root is storage the collector visits to discover values still needed by execution. An activation is the state of one currently executing function call. A closure is a callable value that retains both code and its captured environment. A module record describes one module's identity, bindings, dependencies, and evaluation state; it is not the same as a native compilation unit.

The Engine ties these parts together. It owns code until close, but activation storage exists only while a call is active. A suspended generator keeps its necessary continuation state in managed objects, not in an activation that has already returned. Module records live for the engine lifetime and may refer to code, binding cells, and pending evaluation promises.

The following diagram uses text so it remains readable in the uploaded PDF without requiring a diagram-specific renderer:

```text
                         Engine
  +--------------------------------------------------+
  | owner thread, execution state, resource policy    |
  |                                                  |
  | Compiler --> CodeStore --> generated functions    |
  |                 |                  |             |
  | ModuleRegistry  |           ActivationArena       |
  |        |        |                  |             |
  |        +--------+---- Hermes runtime/GC ----------|
  |                            |                     |
  |                    jobs and host timers          |
  +--------------------------------------------------+
               |                         |
         module sources             host API calls
```

A small example establishes the desired behavior:

```javascript
// counter.mjs
export let count = 0;
export function increment() { count += 1; }

// main.mjs
import {count, increment} from './counter.mjs';
increment();
await Promise.resolve();
print(count);
```

The host supplies or resolves both sources. The registry creates one record for `counter.mjs`, links the imported names to its binding cells, and starts evaluation. Calling `increment` creates a native activation, updates the cell, and returns. The activation is released. The top-level await retains module evaluation state through the managed promise machinery. After the relevant job executes, the output is `1` and the evaluation handle reports fulfillment. A later import of the same canonical identity returns the same module namespace and observes the same count.

No standalone generated bundle is permitted to create another copy of the registry silently. Identity is an Engine contract, so both AOT-supplied and JIT-supplied module code use the same records.

## 4. Current source map and reusable evidence

Read the current implementation before writing its replacement. These are existing files; the proposed directory layout later in the guide is not.

| Existing file | What it establishes | v2 treatment |
|---|---|---|
| `hermes/include/hermes/LLVMJIT/Engine.h` | Small compile/load/execute/drain API | Reference only; define a new API |
| `hermes/lib/LLVMJIT/Frontend.cpp` | Request-scoped frontend through `generateLLVM` | Reuse extraction approach; select v2 backend explicitly |
| `hermes/lib/LLVMJIT/Engine.cpp` | LLJIT setup, materialization, target checks, retention | Reuse proven LLVM integration concepts, remove old unit assumptions |
| `hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | Instruction lowering, root slots, phi transfers, exception dispatch | Port semantic cases deliberately to new ABI |
| `hermes/lib/BCGen/SH/LLVMNative/runtime.c` | Tagged-value helpers and native-frame integration | Reuse semantic operations; replace activation/unit plumbing |
| `hermes/include/hermes/VM/static_h.h` | `_sh_enter`, `_sh_leave`, locals and exception interfaces | Understand exact collector/stack contracts |
| `hermes/lib/VM/StaticH.cpp` | `_sh_catch_no_pop`, throwing and runtime helpers | Required unwind integration point |
| `hermes/lib/VM/StaticHUnit.cpp` | Global unit index, registration and initialization | Do not inherit global indexing in v2 |
| `hermes/lib/VM/Runtime.cpp` | Strong/weak root traversal and destruction | Extend traversal for new owners where necessary |
| `hermes/utils/module-host/compiler.cjs` | Module analysis and generator-factory transformation | Reuse semantic analysis, change emitted registration format |
| `hermes/utils/module-host/runtime.js` | Linking, namespace and evaluation algorithms | Port algorithms under one engine-owned registry |
| `hermes/tools/shermes/JITHost.cpp` | Console lifetime and entry notifications | Reference; completion becomes engine-owned evaluation state |
| `hermes/utils/qualify_shllvm_apps.py` | Four application contracts and independent oracles | Extend with v2 mode without weakening existing expectations |

The important measured facts are bounded. The native activation cap rejects fflate under the unoptimized frontend; optimized compilation works. The persistent application successfully uses 310 admitted units across 344 submissions, including 34 parse errors and 34 initializer errors. This validates useful lifetime behavior, not unbounded memory. The code table grows but its index assignment remains process-global. `Engine::close` destroys the runtime before native code, which is a lifetime invariant we retain.

The reference implementation also contains fixes for generators, promises, dynamic eval bindings, typed arrays, and module cycles. A clean integration design is not permission to forget these semantic cases. Port with source-level contracts, not only arithmetic smoke tests.

## 5. Opinionated architecture

Choose a small concrete set of components. Do not introduce a service container, plugin framework, generic execution graph, or event bus.

**Engine** owns lifecycle and rejects calls from the wrong thread. It is the only public execution entry. **Compiler** turns source plus explicit options into a code artifact and diagnostics. It has request-local mutable state. **CodeStore** materializes JIT artifacts or registers AOT descriptors and retains them until engine close. **ActivationArena** owns native root-frame storage and accounts for active memory. **ModuleRegistry** owns canonical identities, bindings, and evaluation records. **HostServices** provides source resolution/loading and basic timers; it does not define JavaScript semantics.

The managed runtime remains the authority for JavaScript values and garbage collection. Native code must not create a second object model. Compiler code may run before runtime admission, but executable artifacts must match the exact runtime ABI and target. Initially support Linux x86-64 host64 and one creating thread per Engine. Broad portability and concurrent execution are excluded from the first experiment.

```text
Host -> Engine -> Compiler -> Artifact
                    |
Engine -> CodeStore.admit(Artifact) -> CodeId
Engine -> ModuleRegistry.link(ModuleId)
Engine -> ModuleRegistry.evaluate(ModuleId) -> EvaluationId
Engine -> runJobs(JobBudget) -> progress + evaluation outcomes
```

AOT and JIT differ at artifact production/materialization. They do not differ in module identity, host completion, error handling, root ownership, or the meaning of a function call. This is the main composability contract.

## 6. Proposed repository layout and build boundary

```text
engine-v2/
  CMakeLists.txt
  include/engine2/
    Engine.h           public engine and result contracts
    Artifact.h         versioned native metadata contract
    HostServices.h     source resolution and timer contracts
  src/
    Engine.cpp
    Compiler.cpp
    LLVMEmitter.cpp
    CodeStore.cpp
    ActivationArena.cpp
    ModuleRegistry.cpp
    RuntimeIntegration.cpp
  tools/
    main.cpp           one runner
  tests/
    activation.cpp
    ownership.cpp
    modules/
    applications/
  docs/
    ABI.md
    RUNNING.md
```

This is a proposed layout, not a requirement to create empty files. Add a file when it owns real behavior. The v2 emitter can be split later if its instruction cases become too large. Keep the current semantic emitter nearby as a reading reference rather than creating an elaborate shared emitter abstraction before discovering the useful common boundary.

Build v2 through an explicit CMake option and separate output directory, for example `hermes/build-engine-v2`. Its targets use distinct names such as `engine2` and `engine2-run`. Reuse the existing LLVM 18 discovery approach, which avoids imported target collisions with bundled llvh. No generated v1 artifact is accepted; use an ABI version and target descriptor and reject mismatches before registration.

Shared changes to Hermes must identify their owner and be justified by a v2 integration requirement. Do not insert scattered `if (v2)` branches into every semantic helper. Prefer a narrow runtime extension point for native callable dispatch, root traversal, and unwind restoration. If that extension point is genuinely shared, document its invariant once.

## 7. Native ABI and runtime-local identity

The proposed native entry is conceptually:

```cpp
using NativeEntry = TaggedValue (*)(ExecutionContext *, Activation *);

struct ExecutionContext {
  Runtime *runtime;
  EngineState *engine;
};

struct FunctionDescriptor {
  AbiVersion abi;
  NativeEntry entry;
  uint32_t rootCount;
  uint32_t argumentCount;
  FunctionFlags flags;
  SourceLocation location;
};
```

These signatures are design sketches, not compilable headers. `TaggedValue` must use the selected Hermes representation and be audited at each native boundary. The closure carries the environment and a reference to engine-local code metadata. The activation contains the incoming receiver, arguments, environment, `new.target` where relevant, and root storage. Do not expose arbitrary raw tagged values to host applications.

The Engine allocates local code and module identifiers. Their meaning ends at Engine destruction. AOT descriptors are immutable data shared by an executable; registration creates fresh per-engine records without mutating a process-global index embedded in that descriptor. A JIT artifact follows exactly the same registration contract after materialization.

Native-to-native and managed-to-native calls must use one v2 callable dispatch path. Existing `SHFunction`/Static Hermes invocation conventions cannot simply be assumed to accept the new signature. Add a clearly identified runtime callable representation or dispatch branch for v2, including GC tracing of its captured environment and descriptor lifetime. Do not route calls through a v1 public API wrapper merely to keep the old entry convention alive.

### Decision: explicit context rather than embedded global unit indices

- **Context:** The current global index is stored through native unit metadata and influences every runtime's table capacity.
- **Options considered:** Recycle global indices; keep indices but increase tables; pass explicit engine/code context.
- **Decision:** Use engine-local registration and explicit context in v2.
- **Rationale:** Identity and memory accounting follow the owner directly.
- **Consequences:** New emitted code, callable dispatch, and descriptors must be implemented together; old artifacts are rejected.
- **Status:** Proposed.

## 8. Runtime-owned activation storage

Replace native-stack root arrays with an arena of stable-address chunks owned by the Engine/runtime integration. An arena is a concrete allocator that advances through chunks and restores an earlier position when nested activations finish. It is not the managed object heap: the collector visits the tagged root payloads but does not relocate the arena's storage itself.

Each activation has a frame header and a variable-sized tagged payload. Frame headers record the previous activation, allocation mark, descriptor, and sufficient managed-frame restoration data. Root count and argument count come from validated metadata. Check size arithmetic before allocation. Initialize every collector-visible slot before publishing the frame to the root chain.

```text
enter(descriptor, incoming arguments):
    checkedBytes = header + checked payload size
    require active root bytes + checkedBytes <= configured budget
    mark = arena.mark()
    frame = arena.allocateStable(checkedBytes)
    initialize all tagged slots to undefined
    populate receiver, arguments, environment and metadata
    publish frame in runtime root chain
    return frame

leave(frame, result):
    move result into a caller-owned root before releasing frame
    restore managed-frame bookkeeping
    unlink frame from root chain
    arena.rewind(frame.mark)
```

The sequence matters. Allocating or collecting while a half-initialized frame is visible can make the collector read invalid values. Releasing a frame before the result is rooted can lose the returned object. Reusing freed storage while it remains linked can make the collector scan unrelated data.

Use the existing `SHLocals` layout and visitor conventions where that is demonstrably sufficient; otherwise add a focused v2 root visitor. This is reuse of a collector contract, not a compatibility promise for old emitted code. Audit strong roots, weak references where applicable, runtime destruction, and memory reporting together. The first implementation should keep one slot per logical intermediate: removing the native-stack cap is the initial experiment, while liveness-based reuse is a later memory optimization.

Avoid one general-purpose heap allocation per call. Start with a small reusable chunk and geometrically sized additional chunks, bounded by a configurable active-byte budget. A frame larger than the normal chunk gets a stable large allocation released or boundedly cached on rewind. Keep a bounded cache after execution so a single exceptional workload does not permanently retain its maximum reservation. Report active bytes, reserved bytes, and high-water active bytes separately.

The arena does not remove native call-stack limits. Native recursion, runtime helpers, and LLVM spills still use the native stack, so stack overflow checks remain. Nor does it make arbitrary argument counts free: outgoing managed argument-frame allocation and checked arithmetic must be audited independently. The first success criterion is admitting the real fflate function without blindly increasing a native `alloca` size.

## 9. Exceptions, collection, and suspended execution

The existing runtime's throws use nonlocal transfer. `StaticH.cpp::_sh_catch_no_pop` restores runtime frame state, and the emitter uses `_setjmp` with `returns_twice`. Moving roots to an arena without extending unwind restoration would leak or retain discarded frames after a throw.

Retain the existing exception mechanism for the first v2 implementation, but make the arena mark part of each relevant exception checkpoint. A catch checkpoint records the surviving activation, its arena mark, and the corresponding managed stack/root state. On a throw, restore all three coherently. A catch within the current function preserves that function's activation; a host boundary discards all activations created inside the guarded call.

```text
checkpoint = {rootHead, managedStackState, arenaMark}
try boundary:
    execute native code
catch transfer:
    retain thrown value in runtime-owned exception root
    unlink activations above checkpoint.rootHead
    restore managed stack and local-root state
    rewind arena to checkpoint.arenaMark
    dispatch catch or return a rooted error handle
```

This sketch requires validation against actual Hermes unwinding order. Arena rewind must not invalidate the exception value, a catch-visible binding, or a finally continuation. Do not rely on C++ destructors in scopes skipped by a nonlocal jump. Keep the protected execution region compatible with the runtime's control-transfer rules; ordinary C++ RAII remains useful outside it.

Generators and async functions reuse Hermes lowering. Their suspended state already belongs in managed continuation objects. Returning to the caller releases the current native activation; resumption creates a new activation and reloads continuation state. No raw pointer into a released arena frame may be captured by a closure, generator, host callback, or job. Audit address-taking and environment stores before claiming the new ABI is safe.

### Decision: keep exception semantics, replace storage restoration

- **Context:** Replacing every throwing runtime operation would expand the project into a second language runtime integration effort.
- **Options considered:** Status returns everywhere; LLVM exception landing pads; existing nonlocal transfer with explicit arena checkpoints.
- **Decision:** Prototype the third option first.
- **Rationale:** It reuses proven language error behavior while concentrating the new proof obligation in activation and unwind ownership.
- **Consequences:** All escape paths need inspection; unsupported unwinding assumptions are an experiment-stopping defect, not a reason to add ad hoc cleanup patches.
- **Status:** Proposed, gated by the first prototype.

## 10. Engine API and value ownership

The proposed public API uses opaque engine-local identifiers and rooted handles. Exact C++ spelling can change during implementation; the semantic distinctions must not.

```cpp
Outcome<ModuleId> defineModule(ModuleKey key, Source source);
Outcome<EvaluationId> evaluateModule(ModuleId module);
Outcome<ScriptResult> evaluateScript(Source source);
Outcome<PumpResult> runJobs(JobBudget budget);
EvaluationState evaluationState(EvaluationId evaluation);
Outcome<ValueHandle> moduleNamespace(ModuleId module);
Outcome<void> collect();
Outcome<void> close();
```

`Outcome` distinguishes host/compile/link errors from successful submission. JavaScript evaluation failure is represented by a rejected evaluation or a script result with a rooted thrown value. Do not conflate parse failure, registration failure, initialization failure, and pending asynchronous work. Diagnostics include phase, original source identity where available, generated location, and a message.

A `ValueHandle` is an engine-owned root referenced through a generation-checked handle table. Releasing it removes that root. Handles cannot be used after close or with another engine. The first prototype can expose only printable errors and module completion, then add handles when a concrete host operation needs values; do not expose temporary raw values in the meantime.

A successful `evaluateScript` means the synchronous body completed. It does not mean all promises it started have settled. `evaluateModule` returns an evaluation identity that can remain pending. A module that awaits a promise forever remains pending even when the job queue is empty. `runJobs` reports progress and available scheduling information without manufacturing completion.

`JobBudget` bounds the number of jobs executed in one pump call. A deadline can be checked between jobs, but this is not preemption of an infinite-running JavaScript callback. Hard execution interruption is deferred until safe polling points and interruption semantics are designed. The first host can expose ready-job pumping and the next timer deadline; a convenience CLI loop may wait, but the Engine API should not secretly sleep until every timer completes.

All Engine operations occur on the owner thread. Close releases host roots, destroys the runtime while code remains valid, and then releases executable memory. Native code remains retained until close in the first version. Simplicity does not require premature code unloading.

## 11. One module registry

A module key is the canonical identity chosen by the resolver. The initial resolver supports exact local relative paths within an explicit root, preserving a narrow understandable policy. A host may supply source through an in-memory map. Do not add package manifests, URL fetching, or CommonJS fallback to prove incremental identity.

A module record contains its key, source identity, dependencies, exported binding cells, namespace object, code reference, linking state, and evaluation state. Binding cells hold live values and initialization/constness information; imported reads access the existing exporter cell rather than a copied value. Export aliases and star exports are resolved during linking, with ambiguity and missing exports reported before body execution where required.

```text
Registration:  absent -> registered
Linking:       unlinked -> linking -> linked | link-error
Evaluation:    not-started -> evaluating -> pending -> fulfilled | rejected
                                      \-----------> fulfilled | rejected
```

These states are conceptual; they do not prescribe one flat enum. Separate link and evaluation state avoids impossible combinations and makes cycles explicit. Encountering a record already being linked participates in cycle handling; it must not recursively create another record. Repeated evaluation requests share the record's evaluation result. Each dynamic import call still returns its own Promise with the required settlement behavior.

Reuse the existing module evaluation algorithm and tests before simplifying its internals. Async cycles and dependency completion cannot be implemented by a naive topological sort. The existing runtime has relevant logic for evaluation order and asynchronous parents; the new ownership arrangement must preserve those semantics.

Initially retain generator-factory lowering if it provides the cleanest declaration/evaluation split. Change its output from a self-contained registry plus graph into module definitions admitted to the Engine registry. A record's managed state can live in traced Hermes objects while C++ owns canonical lookup and source/code metadata. Do not hold raw unrooted managed pointers in C++ containers.

A module definition needs two conceptual operations: instantiate its binding environment and evaluate its body. Imported binding cells are connected by the registry. Public JavaScript globals such as `__shllvmModuleBegin` are not the new completion API; internal callbacks or runtime-owned evaluation records carry that state directly. The host observes the evaluation identity through Engine methods.

An initial load failure must not leave a half-published usable module. Define which phase is cached: link/evaluation errors belong to the admitted record and are stable for that record; a resolver/source retrieval failure can be retried by a later explicit load request if no record was published. Hot replacement is excluded. Attempting to redefine an existing canonical key with different source returns an explicit error.

Direct eval in transformed modules is deferred until the registry's binding representation can be supplied to the dynamic lexical compiler. Do not claim that centralizing the registry alone implements that feature. The same applies to class-private and derived-constructor eval contexts. Preserve existing supported dynamic bytecode evaluation rather than making native eval a prerequisite.

## 12. Artifact and compilation contracts

A compiled artifact contains a target/ABI identity, immutable function descriptors, constants and strings, source metadata, and module declaration information where applicable. Runtime-local registration supplies the engine-specific references. It must not serialize live managed pointers, process-global unit indices, or native addresses intended for a different process.

For the first experiment keep textual LLVM IR as the boundary between Hermes's compiler infrastructure and installed LLVM. It is simple and inspectable, and avoids confusing bundled llvh types with system LLVM types. If profiling later identifies meaningful parse overhead, replace the representation then. Do not solve an unmeasured cost before proving the new runtime contract.

Compilation is eager and request-scoped. Invalid compilation does not execute code or publish a usable module. Materialization errors return diagnostics and release unadmitted resources. Once code has been admitted and execution can publish closures, retain it until Engine close even if initialization fails.

AOT descriptors and JIT-generated descriptors use one ABI version. AOT registration receives a descriptor whose native function addresses are valid in the current executable; JIT registration receives addresses materialized in this Engine's CodeStore. Both produce engine-local code records. No cross-version native cache is part of the initial design.

## 13. Implementation phases and acceptance gates

### Phase 0: isolate and record the baseline

Add the optional v2 build target and minimal runner without changing the old CLI. Record the existing application receipt and its toolchain identities. Establish separate artifact directories so the old runner cannot load new descriptors accidentally. The initial commit should build an empty Engine and close it without compiling JavaScript.

### Phase 1: prove the activation model

Implement stable arena allocation, root publication, return rooting, and exception checkpoints with small handwritten or minimally emitted native functions. Force GC while rooted objects are live. Exercise nested calls, a caught throw within the same activation, an uncaught throw to the host, and repeated recovery. Check that active bytes return to their baseline after both success and failure.

Run deep recursion to distinguish arena exhaustion from native stack overflow. Deliberately exceed an active-byte budget and verify a defined error outcome without a corrupt root chain. Do not port the whole emitter until this ownership model passes. If runtime unwinding cannot restore the arena coherently, revise the design here.

### Phase 2: port the emitter and callable dispatch

Implement the v2 entry ABI, runtime-local code records, and closure dispatch. Port existing instruction semantics without attempting broad optimization. Keep roots conservative, preserve parallel phi transfers, and audit address-like operands. Qualify generators, async functions, exceptions, typed arrays, private fields, BigInt, and lexical eval through existing source contracts.

The key gate is unmodified fflate under the unoptimized frontend in both JIT and AOT v2 modes. No source trimming, profile substitution, or hidden fallback should count as passing that acceptance criterion. Record active/reserved arena bytes and compilation time as well as output.

### Phase 3: unify module ownership

Change module preparation to emit definitions, add the Engine registry, and implement canonical resolution and linking against one shared record store. Test importing one dependency from two separately submitted roots, live mutation through both importers, cached evaluation failure, static cycles, dynamic import, top-level await, and unresolved entries. Retain existing module behavior qualifications rather than silently changing the oracle.

### Phase 4: expose job pumping and complete the host API

Separate ready-job pumping from CLI waiting. Define result and handle lifetime behavior, validate wrong-thread use, and exercise host close with pending work. Add only the host-value operations needed by an example. Keep hard interruption, simultaneous execution, and broad host APIs explicitly deferred.

### Phase 5: qualify and choose the default

Run all four applications in v2 and the reference engine with the same fixtures and independent expectations. Run thousands of submissions and repeated engine lifecycles, measuring active roots, arena reservations, code bytes, unit/module counts, and process RSS separately. Confirm that engine-local indices do not inherit previous engine high-water marks.

Switch the default runner only when the documented acceptance set passes and the new implementation is simpler to explain and maintain. Preserve historical receipts and a source reference, then remove superseded integration paths in an explicit cleanup commit. No indefinite dual-backend compatibility promise is introduced.

## 14. Test strategy and proof obligations

| Invariant | Required exercise | Failure to detect |
|---|---|---|
| Roots visible before collection | GC in callee and allocation helpers | Object loss or stale value |
| Return rooted before frame release | Return newly allocated object, then collect | Returned value invalidated |
| Unwind restores all storage owners | Nested throw, catch, finally, repeat | Leaked active frames or corrupted roots |
| Suspended state does not point into arena | Generator/async suspend, rewind, GC, resume | Dangling activation reference |
| Phi transfers remain simultaneous | Loop-carried swaps across reused temporaries | Overwritten incoming value |
| Identity belongs to Engine | Repeated engines and simultaneous independent engines | Cross-engine references or table growth from prior indices |
| Modules share one identity | Two separately loaded importers | Duplicate dependency execution/state |
| Pending differs from completion | Never-settling top-level await | False successful completion |
| Artifact ABI enforced | Wrong target/version/layout | Invalid native call or metadata traversal |
| Reference coverage retained | Existing source contracts and all applications | A clean API hiding semantic regressions |

Do not use process RSS alone as a leak test. Expected code retention, arena caching, allocator behavior, and managed heap reservation are different quantities. Instrument each owner directly. A repeated throw test should restore active activation counts even if reserved arena memory remains intentionally cached below its bound.

Do not test only the new code against itself. Keep Node comparisons, independent Python expectations, independent archive decoding, and exact prior fixtures. The old backend is useful for diagnosis but shares the frontend and runtime, so agreement with it is not independent proof of language semantics.

## 15. Costs, alternatives, and explicit deferrals

The main risk is the activation/unwind integration, not creating a new directory. Runtime-owned roots make large functions practical without a large native `alloca`, but add allocator and root-chain work to calls. We must measure whether chunk reuse keeps that cost acceptable. Native stack usage still exists. A finite configured activation budget replaces the accidental fixed function-size barrier; it does not imply unlimited memory.

An alternative is to keep stack-backed roots and implement liveness reuse first. That is a smaller change and remains a useful fallback experiment. It does not directly unify unwind ownership or remove the representation's dependence on bounded native frames. The proposed v2 branch should demonstrate its advantages through the first activation prototype rather than assuming every larger refactor is better.

We deliberately retain code until close, single-thread ownership, the Hermes collector, current dynamic bytecode eval, eager compilation, and the initial host64 target. We defer individual unloading, speculative optimization, deoptimization, browser workers, package ecosystems, hot module replacement, and hard interruption. These decisions keep the redesign focused on execution ownership and composability.

A new abstraction is justified only when it owns a real invariant. Do not introduce a universal scheduler before ready-job pumping exists, a plugin system before one concrete host works, or a generic backend interface before AOT/JIT share a working descriptor contract.

## 16. First-day intern workflow

Start with the two-file counter example and explain the difference between a module record, a native code record, and an activation. Read the current Engine API and one successful application receipt. Then trace `FunctionEmitter::generate` into `shllvm_enter`, and read `_sh_catch_no_pop` before changing any frame storage.

Next inspect `StaticHUnit.cpp` to understand why the old index is process-global, and inspect Runtime.cpp's root traversal to see what the collector actually visits. Read the persistent application host to understand why an initializer failure cannot imply code unloading. Finally read the module compiler/runtime pair and identify which state is currently recreated per bundle.

Your first implementation change should be a tiny v2 Engine plus a directly testable arena, not a copied thousand-line emitter. Keep a diary entry for each ownership decision and any failed GC/unwind experiment. At each phase, commit a working slice with the invariant it establishes and the cases it does not yet support.

## 17. Reference anchors and completion definition

Primary anchors are the existing files in Section 4, the operational guides `hermes/docs/llvm/JIT.md`, `DRIVER.md`, and `MODULES.md`, and these tickets:

- LLVM-ENGINE-001 and LLVM-JIT-001 explain the current persistent engine and its lifetime evidence.
- LLVM-APPS-001 contains application source contracts, first failures, corrected results, and independent oracles.
- LLVM-MODULES-002 records module ownership and root-storage follow-ups; M08 is the current measured frame problem.

This design is delivered when the guide, task plan, source relations, diary, and requested reMarkable upload exist. Engine v2 is implemented only when its phase gates pass. Keep those completion statements separate. The old implementation remains usable throughout the experiment, but it does not constrain the new ABI or public API.
