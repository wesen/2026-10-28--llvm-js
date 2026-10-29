---
Title: Composable compiler language grammar effects ownership and Hermes LLVM integration
Ticket: LLVM-ENGINE-002
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
      Note: Instruction semantics root placement and phi transfer
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/runtime.c
      Note: Runtime operation bindings and obligations
    - Path: repo://hermes/lib/LLVMJIT/Engine.cpp
      Note: Materialization and artifact ownership
    - Path: repo://hermes/lib/LLVMJIT/Frontend.cpp
      Note: Hermes source import boundary
    - Path: repo://hermes/lib/VM/StaticH.cpp
      Note: Exceptional restoration contracts
    - Path: repo://hermes/utils/module-host/runtime.js
      Note: Module identity and evaluation behavior
    - Path: repo://hermes/utils/qualify_shllvm_apps.py
      Note: Application acceptance and independent oracles
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T14:32:24.995044035-04:00
WhatFor: ""
WhenToUse: ""
---

# A composable language for JavaScript compilation and execution

## 1. Purpose and relation to the first design

This document defines the proposed compiler language for Engine v2. The first guide in LLVM-ENGINE-002 describes execution ownership: one Engine, runtime-owned activation storage, engine-local code identity, one module registry, and explicit job pumping. This second guide describes how computations and compiler decisions become inspectable, composable values within that architecture.

The design is deliberately opinionated. Start with a small typed control-flow language, explicit effects, verified representation and storage plans, and a linear sequence of compiler passes. Hermes supplies the initial JavaScript frontend and managed semantics; LLVM supplies native materialization. These are complementary roles, not interchangeable implementations of the same interface. A reference interpreter covers the small core language first, while managed operations require an explicit semantic provider.

All API examples and IR syntax below are proposed. There is no implemented `g` package, compiler-language parser, or v2 execution engine in the repository at this checkpoint. The current implementation and its application receipts are the source of requirements. This document specifies an implementation route without claiming that its prospective abstractions have already been validated.

The practical goal is to make a difficult fact easy to locate: what a computation means, what it can affect, which values must survive, why a transformation is legal, and how that computation reaches execution. Fluent syntax is an authoring convenience. The underlying grammar, verifiers, and runtime contracts are the actual design.

## 2. Orientation: one example across the layers

Consider this JavaScript function:

```javascript
function readAfterCall(object, callback) {
  callback();
  return object.value;
}
```

The callback can mutate the object, collect garbage, throw, or call more JavaScript. Reading `object.value` can invoke a getter or proxy. Therefore an optimizer cannot move the property read before the callback simply because both operations return values. The object must remain reachable across the callback, and an exception must follow the correct control path.

The semantic representation records a call followed by a property read. A runtime lowering chooses Hermes operations and records which calls can collect. Lifetime analysis establishes that `object` is needed after the callback. Storage assignment gives it collector-visible storage. LLVM lowering emits native calls and transfers control to the appropriate success or exception continuation.

```text
JavaScript source
    |
    v
Semantic operations + explicit control flow
    |  meaning: call, then property read
    v
Runtime operations + representation contracts
    |  tagged values, collecting calls, exception protocol
    v
Execution plan
    |  roots, activation layout, ABI, unwind checkpoints
    v
LLVM IR / native artifact
    |  materialization and engine-local registration
    v
Execution and observable result
```

A semantic value is a result in a program. A physical slot is one location holding its selected representation. A root is storage the collector visits. A block is a control-flow destination with parameters. An effect describes an operation's possible interaction with state or control. A pass transforms one verified representation into another. An artifact contains executable code or materializable code plus its requirements. These concepts are related but must not be represented by one overloaded “node” API.

## 3. Design rules

1. Meaning precedes representation. `js.add` is not an integer addition merely because a sample input happens to be numeric.
2. Every effectful operation has explicit sequencing and failure behavior. Unknown behavior is conservative, never silently pure.
3. Runtime requirements are contracts. GC, exception transfer, activation restoration, and native callable dispatch are not optional annotations.
4. Builders are immutable descriptions. Executing a compiler or engine is an explicit operation separate from constructing a description.
5. Every level is inspectable. Stable identities, text/JSON dumps, diagnostics, pass traces, and source provenance are first-class outputs.
6. Unsupported combinations fail before execution. No implicit interpreter fallback, source trimming, or semantic approximation is counted as native success.
7. Start concrete. One Hermes provider, one LLVM provider, one target profile, and one execution model are sufficient to validate the grammar.
8. Algebraic laws have conditions. Tests exercise them; a law name is not a proof that an arbitrary rewrite is correct.

These rules intentionally exclude a universal plugin framework. A new extension must name its operations, capabilities, validation, and observable behavior. A configuration object with arbitrary hooks is not automatically composable.

## 4. Grammar: the small set of sorts

A sort is a category of values in the description language. Each sort has constructors, operations, and rules determining valid composition.

| Sort | Constructors/examples | Composition | Governing rule |
|---|---|---|---|
| Type | Bool, I32, F64, JSValue, JSString, Ref(region, T) | products, alternatives, functions | Explicit representation and conversion |
| Operation | constant, numeric add, property read, call | operand/result wiring | Signature and effect contract |
| EffectSummary | read/write resource, fresh identity, throw, call unknown, suspend | conservative join | Upper bound on possible behavior |
| Block | parameters, operations, terminator | branch/jump arguments | SSA dominance and edge typing |
| Function | signature, entry block, body | calls and return continuations | Declared completion/effects |
| Lifetime | activation, captured, engine-owned | borrow/promote/root operations | No reference outlives its owner |
| RepresentationPlan | tagged value, unboxed number, managed reference | checked conversion | Semantics-preserving representation |
| StoragePlan | roots, slots, activation layout | allocation and interference constraints | Visibility at every relevant safepoint |
| Pass | requirements, transformation, guarantees | ordered pipeline | Preconditions and invalidation |
| Provider | semantic/runtime/materializer capabilities | checked linking | Required capabilities are satisfied |
| Artifact | ABI, target, code, descriptors, metadata | admission/registration | No invalid cross-runtime identity |
| Execution | ready, running, pending, fulfilled, rejected, closed | explicit transitions | Owner and completion rules |

Not every sort needs a user-facing class on day one. Some are tagged records in the canonical representation. Avoid a class hierarchy for every operation; a versioned operation registry and structurally checked nodes are sufficient initially.

Numeric widths, bytes, slot counts, milliseconds, and job counts are distinct quantities. A root budget in bytes must not be confused with an argument count. Provide constructors such as `bytes(4096)`, `slots(32)`, and `jobs(100)`, and require explicit conversion through the selected layout. This prevents target-dependent assumptions from being hidden in arithmetic.

## 5. Canonical representation and authoring API

The canonical representation is a versioned graph of records, with explicit operation names, typed references, block arguments, attributes, and provenance. JSON is a useful interchange and inspection format for the prototype; C++ in-memory objects execute the compiler work. Native pointers and engine-local handles do not appear in serialized semantic graphs.

A JavaScript package can provide the ergonomic authoring API for experiments and pipeline descriptions. It should produce canonical data, not execute the user's JavaScript program by evaluating DSL callbacks. The production source compiler can construct the same graph directly from Hermes IR in C++; it need not launch Node or load a JavaScript configuration evaluator on every request.

```javascript
// Proposed authoring syntax; not an existing package.
const numericAdd = g.operation('number.add')
  .inputs(g.F64, g.F64)
  .outputs(g.F64)
  .effects(g.effects.none());

const jsAdd = g.operation('js.add')
  .inputs(g.JSValue, g.JSValue)
  .outputs(g.JSValue)
  .effects(g.effects.jsCoercion());
```

Each fluent method returns a new description. There is no mandatory `.build()` call: a description is already a value and can be inspected, transformed, or compiled. Local graph-construction callbacks may use an internal mutable cursor for convenience, but the returned graph snapshot is immutable and the cursor must not escape.

A strategy slot accepts the default, explicit parameters, a named strategy, or a lambda. Lambdas are host-side customization of compilation, not serializable program semantics. Registered operations and named strategies have stable schema/version identities. An unregistered lambda makes the affected work nonpersistently cacheable by default; adding a display name does not prove purity or stable identity.

```javascript
const roots = g.rootPlacement();
const compact = roots.strategy('interference-coloring');
const inspectable = roots.strategy({name: 'distinct-slots'});
const experimental = roots.strategy((input, ctx) => {
  const baseline = ctx.default(input);
  return revisePlan(baseline); // Must still pass the storage verifier.
});
```

No lambda may disable post-verification and still produce an artifact labeled verified. Escape hatches should remain explicit experimental modes with diagnostics. The simplest first implementation supports named strategies and in-process callbacks, with no distributed callback serialization.

## 6. Types and JavaScript semantic distinctions

Keep the semantic type system small. `JSValue` represents a general JavaScript value. More precise facts can identify Number, BigInt, String, Object, or Callable, but facts must be justified by source semantics or guards. `F64` is a representation type with defined floating-point behavior; it is not a promise that arbitrary JavaScript conversion has occurred.

`js.add` may concatenate strings and perform coercions. `number.add` operates on numeric values with specified semantics. `i32.add.wrap` is a different operation again. Do not reuse one operation name and let backends silently choose different meanings.

Floating-point arithmetic does not obey all real-number algebraic laws. Reassociation is invalid by default, and rewrites involving NaN, infinities, and signed zero need their actual preconditions. In particular, do not declare numeric addition associative merely to obtain a convenient monoid example. LLVM emission starts without permissive fast-math assumptions.

Strings preserve JavaScript UTF-16 code units, including the dynamic-evaluation behavior already supported by the runtime. Source file decoding and runtime string representation are different contracts. BigInt literals use exact integer serialization, not a conversion through F64. Typed arrays retain element-kind and indexed-access semantics supplied by the runtime rather than being replaced with unqualified native pointer loads.

A type refinement is a fact with an origin: a proven producer, a dominating guard, or a verified analysis. If a pass changes the CFG or invalidates the guard relationship, it must invalidate dependent facts. A debug-mode verifier should catch uses of facts outside their valid region.

## 7. Effects: summaries, sequencing, and implementation obligations

Use two related descriptions. **Semantic effects** describe observable interactions: reading or writing a binding or heap resource, creating observable identity, throwing, invoking unknown code, or suspending. **Runtime obligations** describe implementation behavior: may collect, uses a native activation, can nonlocally transfer control, requires a write barrier, or requires a host capability.

Allocation illustrates the distinction. Creating a fresh object has observable identity even if no user callback runs. A helper might also allocate internal storage and trigger GC without creating a directly observable new language object. Both facts matter, but for different transformations. A fresh object constructor cannot be common-subexpression-eliminated simply because its fields are initially equal.

Effects combine conservatively. Let `E1 <= E2` mean every behavior admitted by E1 is included in E2. The join `E1 join E2` is an upper bound. Join is associative, commutative, and idempotent; unknown behavior is a top element. These are laws for summaries, not a license to commute the operations they summarize.

Initially use coarse resources such as lexical cells, managed heap, module registry, and host I/O. Unknown JavaScript calls conservatively affect all reachable relevant state, can throw, and may collect. Region-specific alias analysis can refine this later. A property access involving a getter or proxy remains conservatively capable of executing user code.

Sequencing is explicit. Start with one abstract state token for effectful operations within a function. A token is a compiler ordering value, not an allocated runtime object. A conditional branch passes state into mutually exclusive successors; a join receives state as a block parameter. Do not model this by duplicating state into simultaneously executable paths. Token verification uses CFG path structure.

```text
entry(object, callback, state0):
    invoke js.call(callback, undefined, [], state0)
        normal afterCall(ignored, state1)
        throw failed(error, state1e)

afterCall(ignored, state1):
    invoke js.get(object, "value", state1)
        normal done(value, state2)
        throw failed(error, state2e)

done(value, state2):
    return value, state2

failed(error, stateE):
    raise error, stateE
```

Failure edges carry the state after partial effects, not the state before the operation. An initializer can publish a closure before throwing. The grammar must preserve that fact and must not imply rollback. Pure total operations need no state token. Operations that can fail use an explicit exceptional successor even when they have no heap-write effect.

The single token deliberately limits reordering. That is an acceptable starting point: it makes correctness inspectable. Split resource tokens only when an optimization needs it and alias/effect information can justify the split.

## 8. Control flow, SSA, and exceptional completion

Use block parameters as the only user-facing merge mechanism. Each value has one definition. Definitions must dominate their uses, except that incoming values are supplied along predecessor edges to destination block parameters.

```text
entry(condition):
    branch condition, left(), right()
left():
    jump join(10)
right():
    jump join(20)
join(value: F64):
    return value
```

A loop is an ordinary cycle whose header has parameters for loop-carried values. The graph is not a DAG. Forward block references are resolved when the function graph is finalized. The verifier checks that every block has exactly one terminator, each edge supplies the right arity/types, and every use is valid.

`invoke` has distinct normal and exceptional destinations. The semantic graph does not decide whether the target uses return-status checks, setjmp/longjmp, or another exception protocol. Runtime lowering makes that choice and emits the needed checkpoint/restore operations. An LLVM `invoke` instruction is not automatically implied by a semantic `invoke` node; the current runtime uses nonlocal transfer.

Control transfers for `finally` require preserving pending completion. Use an internal tagged completion value with variants Normal, Return(value), Throw(error), and applicable Break/Continue targets during structured lowering. A finally body can replace that completion. Lower this explicit state to CFG before native emission instead of treating all exits as normal returns plus cleanup text.

Phi lowering must preserve simultaneous edge transfer. For a loop carrying two swapped values, loading an incoming value after overwriting its source slot is wrong. The existing emitter's `emitEdges` already loads all incoming values before destination stores. The v2 graph and storage verifier must preserve that invariant when slots are shared.

## 9. IR levels and the smallest useful pipeline

Use these named levels as contracts, not mandatory copies of every graph:

| Level | Contents | Verifier boundary |
|---|---|---|
| L0 Source package | sources, module keys, options, provenance | encoding and source identity |
| L1 Semantic CFG | operations, block parameters, effects, completion | typing, dominance, control/effects |
| L2 Runtime CFG | Hermes operation bindings, representations, runtime obligations | capability and representation compatibility |
| L3 Execution plan | roots, activation layout, checkpoints, ABI calls | GC visibility, ownership, unwind restoration |
| L4 Native artifact | LLVM IR/object code, descriptors, target/ABI | LLVM checks plus descriptor validation |
| L5 Engine admission | engine-local records and rooted runtime objects | ownership and registration state |

L5 is live runtime state, not a pure serializable compiler IR. Its inspection snapshot may be exported, but it cannot be replayed as if native addresses or managed handles were portable.

Liveness is computed after lowering reveals collecting calls. Additional lowering after root placement must either prove it introduces no new safepoints or invalidate/recompute the root plan. This ordering prevents a common error: rooting according to high-level effects while a later helper implementation secretly allocates.

```javascript
const nativeJS = g.pipeline()
  .from(g.frontend.hermes())
  .through(g.pass.importSemanticCFG())
  .through(g.pass.verifySemantic())
  .through(g.pass.lowerRuntime(g.runtime.hermes()))
  .through(g.pass.analyzeLiveness())
  .through(g.pass.placeRoots())
  .through(g.pass.planUnwinding())
  .through(g.pass.verifyExecution())
  .through(g.pass.emitLLVM())
  .to(g.materializer.orc());
```

This is a readable specification, not evidence that all those functions exist. The implementation can fuse work where useful while preserving named inspection/validation boundaries. Do not build a general pass scheduler initially; explicit ordering plus requirements checking is enough.

## 10. Passes, analyses, laws, and invalidation

A pass declares its input/output level, required facts, changed structures, invalidated analyses, provided guarantees, configuration identity, and diagnostics. An analysis computes facts without changing semantic behavior. A verifier rejects a graph or plan that violates a contract.

```javascript
const rootPass = g.pass('roots/place')
  .requires('runtime-representations', 'safepoints', 'liveness')
  .provides('collector-visible-storage')
  .invalidates('activation-layout')
  .run(placeRoots);
```

Composition is defined only when one pass's output satisfies the next pass's preconditions. The identity pass preserves a verified graph. Compatible pass composition is associative at the level of resulting transformation, but diagnostics, instrumentation, and execution timing must have a defined ordering and are not erased by this algebraic observation.

Typical executable laws include:

- Alpha-renaming local IDs preserves interpretation.
- Effect-summary join is associative, commutative, and idempotent.
- A declared canonicalization reaches a fixed point: applying it twice yields the same normalized graph.
- Serialization round-trips preserve canonical graph structure and exact literal payloads.
- A lowering preserves admitted outputs and effect traces under its stated assumptions.
- Storage reassignment preserves values at uses and visibility at collecting points.

These are property-test targets. Passing generated examples does not prove universal correctness. Preserve counterexamples as minimized source/IR fixtures and identify which precondition or implementation was wrong.

A CFG rewrite invalidates dominance and liveness unless it supplies verified updated analyses. A runtime-helper change can invalidate may-collect information even when the semantic graph is unchanged. Analyses must be keyed by the structures and provider versions they depend on. Start by recomputing inexpensive analyses rather than maintaining a clever incremental cache with unclear validity.

## 11. Liveness and storage planning

Liveness is a finite dataflow analysis over values and control-flow edges. A value is live at a point when a reachable future use requires its current value. Normal and exceptional successors both participate. Block arguments require edge-specific substitution: a destination parameter's liveness implies liveness of the corresponding incoming operand on that edge.

```text
initialize live sets to empty
repeat until no set changes:
    for each block in reverse worklist order:
        liveOut = union(edgeTransfer(successor liveIn))
        liveIn = usesBeforeDefinition union (liveOut - definitions)
        enqueue predecessors whose sets may change
```

The framework should expose the lattice, transfer function, and worklist driver as a reusable analysis primitive. Monotone growth on a finite powerset lattice establishes termination for this analysis. An arbitrary iteration cap must not be treated as a valid solution; resource exhaustion yields a diagnostic or a sound conservative fallback, never silently incomplete liveness.

Root planning asks which managed values must be visible across every collecting operation. Roots may also be needed while passing arguments, constructing results, and handling exceptional transfer. The first runtime implementation can root all selected tagged values in distinct slots. A later allocator builds an interference relation and assigns shared slots to compatible values whose required lifetimes do not overlap.

```text
for each collecting point:
    require a valid root for each managed value live across the point
for each slot:
    require no conflicting simultaneously live assignments
for each return:
    require result transferred to caller-owned protection before release
for each exceptional edge:
    require catch-visible values survive checkpoint restoration
```

Constants need representation-specific handling. A number may be an immediate, but a string/BigInt materialization can allocate a managed value. Address-like stack storage cannot be treated like an ordinary temporary without proving that aliases do not outlive it. The storage verifier should initially exclude these difficult classes from reuse rather than pretending the interference graph alone resolves all ownership.

The fflate case is a concrete inspection example. The old unoptimized factory uses 1,084 roots plus three arguments. The new system should show the values, lifetimes, storage assignment, and runtime budget behind its result. Runtime-owned activations can admit more roots without a large native stack allocation; slot reuse reduces memory but is not the same mechanism. Report both separately.

## 12. Ownership, regions, and continuations

A region describes a lifetime boundary, not necessarily a physical allocator. Use activation, captured/managed, and engine-owned regions initially. An activation borrow is valid only while the activation survives. A captured environment or continuation stores managed values in GC-traced memory. A host handle retains a value through an engine-owned root table.

The ownership relation forbids a longer-lived object from retaining a raw reference to shorter-lived activation storage. Copying a tagged value into a traced managed field can be valid; storing a pointer to the activation slot is not equivalent. A promotion operation must state the representation conversion, allocation/write-barrier obligations, and resulting owner.

```text
activation-local value
    | capture(value) with managed-store semantics
    v
managed environment or continuation field
    | read during a later invocation/resumption
    v
fresh activation-local value
```

A semantic suspend operation lists the values needed after resumption and its resume destinations. Runtime lowering stores them in a managed continuation, registers the appropriate promise/iterator behavior, and releases the current activation. Resumption creates a new activation and loads captured state. A returned activation is never kept alive accidentally because a generator has suspended.

The first production integration should reuse Hermes generator/async lowering rather than introducing another competing implementation immediately. The core grammar can represent suspension in hand-authored examples and future frontends; the Hermes importer must accurately describe whether it sees pre-lowered suspension or already-lowered continuation operations. Never label an ordinary call graph as suspension-aware without preserving the necessary metadata.

## 13. Exception strategy and activation restoration

The first design proposed arena checkpoints integrated with the current nonlocal exception mechanism. This language makes that compatibility requirement explicit:

```text
ActivationProvider provides:
    allocate, publishRoots, release, mark, restore

ExceptionProvider requires:
    checkpoint stores root/managed-stack/arena restoration state
    thrown value survives restoration
    catch activation remains valid
```

A provider combination is rejected if either side cannot satisfy those obligations. These are concrete integration contracts, not arbitrary string capability labels that bypass inspection. Initial tests must exercise nested calls, catches within the same activation, outer catches, finally behavior, and host escape.

The current `_sh_catch_no_pop` restores local-root and managed-frame state. The new path additionally restores activation ownership. C++ destructors cannot be assumed to run across nonlocal jumps. A root plan that is correct on normal CFG edges can still be invalid if exceptional restoration discards a catch-visible slot.

The semantic graph remains independent of the physical transfer mechanism. Later experimenting with explicit error-result lowering is possible, but switching that strategy requires a compatible runtime helper boundary. It is not a one-line configuration change while helpers still throw through the old mechanism.

## 14. Providers and valid compositions

Separate three provider roles:

| Provider role | Responsibility | Initial implementation |
|---|---|---|
| Frontend | Source syntax, binding resolution, initial semantic IR | Hermes frontend |
| Semantic/runtime | JS operations, managed representations, GC, calls, exceptions | Hermes runtime integration |
| Materializer | Convert native artifact to executable addresses or object files | LLVM ORC / LLVM AOT tooling |

A reference core interpreter is a fourth execution option for L1 operations it implements. It can execute numeric/control examples without Hermes. It cannot claim full JavaScript semantics merely because it supports `js.call` in its operation registry; managed operations must be implemented or delegated to an explicitly connected runtime provider.

Provider compatibility includes target, pointer width, tagged-value representation, calling convention, descriptor version, GC strategy, exception strategy, and supported operations. Plan resolution produces either a complete binding for every required operation or an actionable diagnostic identifying the missing contract.

```text
resolve(program requirements, provider set):
    bind operation definitions to implementations
    validate types and representation conversions
    validate GC/exception/activation contracts
    validate target and ABI identities
    reject unresolved or contradictory requirements
    produce resolved plan with explicit defaults and provenance
```

Do not support arbitrary cross-products. Start with Hermes plus the arena model plus the chosen exception mechanism plus Linux x86-64 LLVM. A second implementation is added when a concrete experiment can use it. This keeps the API expressive without making the implementation a speculative platform.

## 15. Concrete integration with the existing source tree

The first adapter is a one-way importer from existing Hermes IR to the new canonical CFG. This is a compiler boundary, not a backwards-compatibility wrapper for the old Engine. It selects a defined point in the Hermes pipeline and explicitly enumerates admitted instructions. If an earlier pass has lost needed source or effect information, preserve that metadata before the loss or move the import boundary.

| Current implementation | New framework location | Integration detail |
|---|---|---|
| `hermes/lib/LLVMJIT/Frontend.cpp` | L0 frontend and L1 import entry | Keep request-local contexts and filename diagnostics |
| `hermes/include/hermes/IR` and native optimization pipeline | Input representation and semantic facts | Do not assume lowered instructions retain all original source context |
| `hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | Instruction inventory, lowering rules, L4 emission reference | Port cases explicitly; retain rejection diagnostics |
| Adjacent `runtime.c` | Runtime-operation bindings and obligation declarations | Audit may-collect, may-throw and output-root behavior |
| `hermes/include/hermes/VM/static_h.h` | Existing frame/root integration contracts | Replace activation plumbing under v2 rules |
| `hermes/lib/VM/StaticH.cpp` | Exception-provider implementation | Extend restoration coherently |
| `hermes/lib/VM/StaticHUnit.cpp` | Registration reference | Replace global indices with engine-local admission |
| `hermes/lib/VM/Runtime.cpp` | GC root traversal and teardown | Trace new owners and account for storage |
| `hermes/lib/LLVMJIT/Engine.cpp` | Materializer and CodeStore reference | Preserve verification and runtime-before-code destruction |
| `hermes/utils/module-host/compiler.cjs` | Module preparation and declaration metadata | Emit definitions for one registry |
| `hermes/utils/module-host/runtime.js` | Module semantic algorithms | Preserve cycles and async evaluation while changing ownership |
| `hermes/utils/qualify_shllvm_apps.py` | Qualification corpus and independent results | Add an explicit v2 mode, retain old evidence |

The new directory can add `grammar/`, `analysis/`, and `lowering/` under the first guide's proposed `engine-v2/src/` when implementation needs them. Avoid creating a separate package for every sort. A small core graph library, verifier, pass runner, runtime binding table, and emitter are enough for the first vertical slice.

## 16. Mapping the implemented language features

The grammar must account for the actual complexity already present, not just numeric expressions.

**Closures and lexical environments.** Represent environment allocation, binding initialization, loads, stores, and closure construction explicitly. Preserve TDZ and constness checks. Binding cells can be shared with dynamic evaluation; a native value cached outside a cell cannot silently become authoritative after eval mutates that binding.

**Generators.** Capture continuation state and completion modes, including `next`, `throw`, `return`, delegation, and cleanup. Retain pending return/throw state through finally. Suspension must not retain activation pointers. Reuse existing lowering initially and validate observable iterator behavior rather than inspecting only yielded values.

**Async functions and promises.** Await is not an ordinary blocking call. Promise reaction ordering and thenable assimilation belong to the semantic/runtime provider. A lowerer must not move user-observable property access or thenable invocation across their required stages. Jobs and resumptions are explicit runtime effects.

**BigInt and strings.** Preserve exact BigInt literal bytes and UTF-16 runtime strings. Arithmetic operations and conversions remain distinct from F64 operations. Constant folding must use the same specified semantic domain, including exceptional cases.

**RegExp.** Literal evaluation creates a fresh runtime object where required; pattern/flags can be immutable metadata, but the object itself is not a globally reusable pure constant.

**Private fields.** Distinguish private-name creation, initialization, membership and brand checks from ordinary property access. Specialized internal fixed-slot IR is a separate representation feature; it is not evidence that all JavaScript private fields are unsupported.

**Typed arrays.** Indexed access includes canonical numeric-index rules, receiver behavior, bounds, and conversion semantics. Lowering to raw memory requires proven conditions; begin with runtime operations that preserve existing corrections.

**Dynamic eval and Function.** Keep runtime bytecode compilation as an explicit operation with environment/context inputs and conservative effects. Native compilation is not required for correct composition. Existing restrictions for general sloppy direct eval and missing class/derived-constructor/module contexts remain until deliberately implemented. A strict directive in evaluated source is supported by the current source path and must not regress.

**Modules.** Identity and evaluation live in the Engine registry. The compiler emits binding declarations and body code, not a second registry. Live imports remain cell references. Dynamic import has resolution and job behavior; it cannot be treated as an eager ordinary function call.

Every feature should have a semantic-operation inventory, runtime binding inventory, and existing acceptance fixtures. This is the bridge between an elegant small core and substantial JavaScript complexity.

## 17. Modules, jobs, and completion are related state machines

The compiler grammar describes programs; the Engine manages execution state. Do not encode host lifecycle as a sequence of optimizer passes.

```text
Module: registered -> linking -> linked
                    \-> link-error

Evaluation: not-started -> running -> pending -> fulfilled
                                      \-------> rejected

Engine: ready -> executing -> ready -> closed
```

These are simplified views of separate state dimensions. Reentrant requests, repeated evaluation, and errors require explicit transitions. The module registry owns canonical identities and cached evaluation state. The job runner consumes ready work and reports progress. Neither an empty queue nor a returned initializer proves fulfillment of a module evaluation.

A scheduler description can eventually be a configurable value, but the initial runtime uses the existing promise semantics and a concrete host job pump. `jobs(100)` bounds how many jobs are started; it does not preempt an infinite callback. Hard interruption needs polling points and an effect/error contract that the compiler and runtime jointly implement.

The DSL's host API should expose opaque EvaluationId, ModuleId, and ValueHandle types rather than interchangeable integers. Identifiers are engine-scoped; serialized compilation graphs contain symbolic references, not live engine identities.

## 18. Artifacts, staging, and caching

Separate pure planning from effects. Reading files, discovering a toolchain, loading libraries, materializing native code, registering a module, executing code, and collecting garbage are explicit actions. Constant analysis and graph transformation can be pure relative to a complete input snapshot.

A pure known computation may be performed during compilation only if doing so preserves semantics, diagnostics policy, and resource limits. Do not constant-fold arbitrary JavaScript callbacks by running them in the host compiler. Partial evaluation is an optional later pass over admitted pure operations with defined semantics.

Cache keys include source/graph identity, semantic operation versions, pass configuration and implementation identity, provider/ABI versions, target layout, optimization settings, and relevant inputs to each analysis. Exact literals and source-context rules affecting eval must participate. Named lambdas without implementation identity are not safe persistent cache keys.

Native artifacts cache code and immutable descriptors, never live Hermes values, arena pointers, module records, or engine-local registration IDs. Loading the same AOT descriptor into two engines creates two local registrations. Code sharing across engines requires an explicit immutable-code and per-engine-data design; it is not assumed merely because a hash matches.

Use a manifest to record resolved defaults and dependencies. An artifact must fail admission when ABI/target requirements do not match. Verification of LLVM IR is necessary but does not validate our runtime calling and rooting contracts; L3 and descriptor checks remain distinct.

## 19. Inspection, provenance, and diagnostics

The result of compilation is a Program object with artifacts and inspection data. Proposed methods are:

```javascript
program.summary();
program.ir('semantic', {format: 'text'});
program.ir('execution', {format: 'json'});
program.node(valueId);
program.find({operation: 'js.call'});
program.why(slotId);
program.trace();
program.metrics();
program.diagnostics();
```

Every transformed node links to source provenance and predecessor nodes where meaningful. IDs need not remain numerically identical after every rewrite, but the lineage mapping must let an explanation cross levels. Generated module locations should retain the original module identity and available source spans; do not claim full source maps before they exist.

A root explanation could report:

```text
value: v42 (managed object)
source: main.mjs, readAfterCall parameter object
reason: live across call c7
runtime obligation: c7 may collect
storage: activation a3, root slot 5
non-sharing reason: overlaps v18 at c7
```

Diagnostics are structured data with severity, phase, code, source/generated location, related nodes, and message. Do not make users infer whether a failure is a parser rejection, unsupported operation, invalid provider combination, resource bound, or runtime exception from one generic error string.

A future workbench and agent can use the same Program inspection methods. They should not have a separate undocumented query language with different facts. This is an expansion path, not a requirement to build a UI before the compiler works.

## 20. Defaults and customization

| Decision | Initial default | Reason | Explicit variation |
|---|---|---|---|
| Semantic source | Hermes IR importer | Reuse proven JS analysis | Hand-authored core CFG |
| Runtime semantics | Hermes managed operations | Preserve existing feature behavior | Implement another provider against contracts |
| Effect sequencing | One conservative state token | Simple ordering proof | Refine resources after alias analysis |
| Roots | Distinct slots in runtime-owned activation | Establish ownership before optimization | Verified interference-based reuse |
| Exceptions | Existing nonlocal transfer plus arena restoration | Reuse throwing helpers | Different strategy requires compatible helper boundary |
| Code lifetime | Until Engine close | Closures/jobs may retain code | Unloading requires separate reachability design |
| Materialization | LLVM ORC, host64 Linux x86-64 | Existing working integration | LLVM AOT with same descriptors |
| Floating point | Strict defined semantics | Preserve JS Number behavior | Explicitly restricted non-JS numeric dialect |
| Analysis cache | Small/disabled initially | Avoid invalidation errors | Content-addressed verified inputs |
| Unsupported behavior | Diagnostic and rejection | Preserve truthful coverage | Explicit alternative execution mode |

`summary()` and the artifact manifest show the fully resolved choices. A preset is a function from a pipeline description to a pipeline description. A preset cannot hide a provider substitution that changes semantic coverage without appearing in the manifest and diagnostics.

## 21. Experimentation as data

Once the compiler works, configuration variants can be immutable values over a small design space. Compare distinct-root and reuse strategies, arena chunk sizes, or selected optimization passes while holding language semantics and application contracts fixed.

```javascript
const study = g.study({
  roots: g.choice(['distinct', 'reuse'], {default: 'distinct'}),
  chunkBytes: g.choice([KiB(16), KiB(64)], {default: KiB(16)})
}, p => base.roots(p.roots).activation({chunkBytes: p.chunkBytes}));
```

Every candidate must first satisfy correctness and resource constraints. A faster wrong compiler is infeasible, not a poor weighted score. Metrics have names, units, scopes, and direction: compile milliseconds, execution milliseconds, active-root bytes, reserved-arena bytes, code bytes, and admitted-program count.

Weighted and lexicographic objectives answer different questions. A weighted objective might trade a modest latency increase for reduced memory; a lexicographic objective could minimize latency first among memory-feasible candidates and consider memory only on ties. Neither is universally better. Record the objective, warm/cold conditions, repetition policy, and environment with results.

Do not cache timing observations as if they were deterministic pure outputs. Cache compilation artifacts where valid; measurements remain observations tied to a run. Preserve counterexamples and minimized failing graphs as reusable study inputs. A future experiment agent may propose candidates, but verification and feasibility gates remain authoritative.

## 22. Example ladder for learning and acceptance

These are planned example subjects, not files already implemented. The first five are the mandatory initial slice; the rest extend the same grammar rather than inventing a new abstraction for each feature.

| Example | Concept and expected lesson |
|---|---|
| 01 numeric sum | Typed pure operations and strict numeric semantics |
| 02 conditional merge | Block parameters and edge typing |
| 03 loop-carried swap | Cyclic CFG and parallel transfer |
| 04 object across callback | Effects, liveness, safepoints, roots |
| 05 throw across activations | Exceptional state and arena restoration |
| 06 closure capture | Managed environment versus activation borrow |
| 07 TDZ and const | Binding state and catchable language errors |
| 08 fresh RegExp literal | Allocation identity is not pure constant reuse |
| 09 exact BigInt | Semantic numeric domain and serialization |
| 10 typed-array index | Runtime semantics before raw-memory specialization |
| 11 private brand check | Private identity and failure behavior |
| 12 generator resume | Captured continuation and new activation |
| 13 generator finally | Pending completion through suspension |
| 14 async rejection | Promise jobs and exceptional resumption |
| 15 thenable conversion | User-observable sequencing during assimilation |
| 16 shared eval cell | Runtime dynamic source and native environment identity |
| 17 two module roots | One dependency identity in the Engine registry |
| 18 cyclic live bindings | Linking versus evaluation |
| 19 pending module | Empty queue differs from fulfillment |
| 20 archive library | Real factory size and binary output comparison |
| 21 data pipeline | Independent expected values across execution modes |
| 22 retry queue | Cleanup, attempt counts, cancellation points |
| 23 persistent plugins | Code lifetime after failing initialization |
| 24 root strategy study | Same semantics, different verified storage plans |
| 25 pass ordering study | Requirements and invalidation detect illegal pipelines |
| 26 provenance inspection | Explain one result from source to artifact |

An example should include a short explanation, source or core IR, required capabilities, expected outcome, and the relevant inspection command. Expected failures must identify their phase. Illustrative output is labeled until executed. These examples can later become a workbench's presets and documentation tests.

## 23. Implementation sequence within Engine v2

**Slice A: grammar and verifier.** Implement canonical records, operation registry, block parameters, text/JSON dumps, and structural/type/dominance validation. Add a tiny interpreter for numeric/control operations. No Hermes or LLVM integration is required to establish these contracts. Keep unsupported managed operations explicit.

**Slice B: effects and runtime descriptions.** Add conservative effect summaries, sequencing, exceptional edges, provider requirements, and pass contracts. Verify that moving a property read across an unknown call is rejected by the transformation's prerequisites. Add invalid-graph fixtures and provenance.

**Slice C: activation vertical slice.** Combine the first guide's arena prototype with a small set of Hermes runtime operations. Import or construct the object-across-call and throw examples, compute liveness, create an execution plan, and emit LLVM. Force collection and exceptional restoration. This is the first full semantic-to-native path.

**Slice D: production Hermes importer and feature inventory.** Enumerate instructions at the chosen Hermes pipeline boundary. Port supported operations with explicit runtime obligations, retain rejection cases, and expand generator/async/environment coverage. Reuse existing source contracts. Do not migrate the whole emitter by blindly wrapping every old case as opaque `native.call`.

**Slice E: module and host composition.** Connect the Engine-owned registry, AOT/JIT descriptor contract, evaluation handles, and ready-job pumping. Maintain one binding model across module records and compiled code. Continue to reject unsupported dynamic module eval until its context mapping is implemented.

**Slice F: application qualification and optimization.** Run all four application workloads with independent oracles. Require unmodified unoptimized fflate to execute under v2. Then add slot reuse or performance experiments with the same acceptance suite and inspectable plan differences. Compare active/reserved/code memory separately during repeated sessions.

This refines the first guide's implementation order: establish a small grammar before the arena/emitter integration, while keeping the arena correctness experiment as the first major runtime gate. It does not add a new requirement to rewrite Hermes parsing or build a graphical workbench.

## 24. Validation and failure-oriented tests

Structural tests reject undefined values, wrong edge arity, invalid dominance, absent terminators, inconsistent effects, unresolved capabilities, and references to closed engine handles. Analysis tests compare liveness against small manually checked graphs, including loops, exception edges, and block-parameter substitution. Storage tests force GC at every admitted collecting point in targeted fixtures where feasible.

Differential tests compare the core interpreter and compiled core programs for the supported subset. Managed JavaScript compares against existing fixtures and independent Node/Python oracles. The interpreter and native execution sharing a runtime helper is useful for control/storage testing but is not independent proof of that helper's language semantics.

Property tests generate well-typed small graphs, apply a rewrite, and compare allowed results/effect traces. Floating-point comparisons use the declared semantic equivalence, including signed zero and NaN treatment, rather than approximate equality by default. Tests for fresh identities must observe identity relationships, not just printed field values.

Cache tests change each relevant input independently and ensure invalidation. Serialization tests retain exact BigInt bytes, UTF-16 payloads, and provider identities. Admission tests reject wrong ABI, wrong target, missing root obligations, and unsupported exception/activation combinations before executing native code.

Keep the current 96 application passes and nine known v1 boundaries as historical evidence. They are not v2 results. The new acceptance claim requires its own fingerprints, commands, diagnostics, and receipts. Do not erase an old failure when a later configuration succeeds.

## 25. Risks and deliberate limits

The largest design risk is an abstraction that merely renames old implementation details while claiming portability. If every semantic operation lowers to an opaque helper with unknown effects, the grammar remains useful for inspection but enables little optimization. Improve precision where a real transformation needs it, rather than inventing false purity.

The opposite risk is a second JavaScript semantics implementation created accidentally in the DSL. Reuse Hermes resolution and runtime operations initially. The core interpreter is intentionally small. A new semantic provider has a substantial conformance obligation and should not be marketed as a lightweight materializer plug-in.

A third risk is excessive meta-programming. Typed pass composition and immutable descriptions are sufficient to begin. Automated search, agent integration, distributed compilation, multi-target inference, and generic scheduling can wait. An extension that cannot explain its invariants in concrete terms should not enter the core grammar merely because it sounds mathematically general.

Native code remains trusted, owner-thread execution remains the baseline, and code remains retained until Engine close. The grammar makes these contracts visible; it does not remove them by naming effects or regions. Progress is measured by clearer explanations, fewer hidden conventions, admitted real programs, and preserved semantics.

## 26. Expansion paths

A new frontend can produce L1 if it satisfies operation and binding semantics. A restricted non-JavaScript numeric language can use the pure core without inheriting JavaScript coercion. Another materializer can consume a compatible execution plan if it implements the runtime ABI and obligation contracts. These are distinct extension points.

Liveness-based allocation, alias refinement, constant evaluation, and narrow type specialization can be added as verified passes. Speculative specialization would additionally require guards, recovery state, and a deoptimization representation; the current grammar does not claim that adding a guard node alone implements deoptimization.

Parallel compilation may operate on independent immutable compilation inputs, but it must respect the underlying frontend/provider thread-safety rules and keep runtime admission on the owner thread. Incremental compilation requires dependency identities and invalidation; it does not justify sharing live module records across engines.

A workbench could display IR levels, root interference, pass diffs, provenance, and measurement tables using Program APIs. An agent could edit pipeline descriptions, run bounded studies, and inspect diagnostics through the same interface. Begin with command-line dumps and stable JSON, which are already enough for human and automated inspection.

## 27. Compact decision records

### Decision: canonical data before fluent syntax

- **Context:** JS authoring and the C++ production compiler must agree on the same program without requiring Node during every compilation.
- **Options considered:** Executable JS callbacks as the program, an embedded C++-only builder, or a canonical graph with multiple producers.
- **Decision:** Use a versioned canonical graph; fluent JS and direct Hermes import are producers of it.
- **Rationale:** Inspection, validation, serialization, and alternative producers share one semantic representation.
- **Consequences:** Callback-based compiler customization is distinct from serialized program meaning and needs an explicit cache policy.
- **Status:** Proposed.

### Decision: conservative sequencing before resource partitioning

- **Context:** JavaScript callbacks, getters, proxies, and coercions make fine-grained independence difficult to establish.
- **Options considered:** Assume common operations pure, implement alias analysis immediately, or use one conservative effect state.
- **Decision:** Start with one state token and conservative unknown-call effects.
- **Rationale:** Correct ordering and explicit failure state are more valuable than premature reordering.
- **Consequences:** Some legal optimizations remain unavailable until facts justify finer resource separation.
- **Status:** Proposed.

### Decision: capabilities describe contracts, not interchangeable brands

- **Context:** Hermes implements managed semantics while LLVM implements native materialization; treating them as alternative backends obscures requirements.
- **Options considered:** One generic backend interface or separate frontend, runtime, and materializer roles.
- **Decision:** Separate the roles and verify their concrete ABI, GC, exception, and operation contracts.
- **Rationale:** Unsupported compositions can be rejected before native execution.
- **Consequences:** The first supported combination is narrow; additional providers require real implementation and validation.
- **Status:** Proposed.

## 28. Decisions and first-day reading route

The chosen core is a typed CFG with block parameters, explicit exceptional control, conservative effects, separate runtime obligations, immutable descriptions, and verified pass composition. We retain textual LLVM emission initially. We start with one state token and distinct root slots in runtime-owned activations. We expose no backwards-compatible v1 ABI and no universal backend plug-in promise.

A new intern should first trace the `readAfterCall` example through Sections 2, 7, 9, and 11. Then read the current `FunctionEmitter` constructor and `emitEdges` in `hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp`, the root/try helpers in its adjacent `runtime.c`, and `_sh_catch_no_pop` in `hermes/lib/VM/StaticH.cpp`. These connect the proposed concepts to actual current code.

Next read `hermes/lib/LLVMJIT/Frontend.cpp` and `Engine.cpp` to understand the existing source/materialization boundary, then the module compiler/runtime pair. Finally inspect `hermes/utils/qualify_shllvm_apps.py` and the LLVM-APPS-001 results. The first guide in this ticket supplies the execution-owner architecture; this guide supplies its compiler-language contract.

The next deliverable is a small executable core plus the five initial examples, not the entire framework. If those examples need numerous opaque escapes or incompatible special cases, revise the grammar before expanding it. If their types, effects, lifetimes, and lowering become easy to inspect and explain, extend the same contracts toward the already working JavaScript applications.
