---
Title: Research informed redesign and graduate seminar handoff
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
      Note: Root admission and emitter architecture evidence
    - Path: repo://hermes/lib/LLVMJIT/Engine.cpp
      Note: Code ownership and execution lifecycle evidence
    - Path: repo://hermes/lib/VM/StaticH.cpp
      Note: Runtime exception and root restoration evidence
ExternalSources: []
Summary: 'Design-only seminar brief: semantic foundations, architecture alternatives, reusable subsystems, and staged custom-system design.'
LastUpdated: 2026-10-29T14:56:18.872940444-04:00
WhatFor: Hand off current source and proposed architecture for critical research and redesign.
WhenToUse: Before committing to implementation of the proposed engine-v2 framework.
---

# Research-informed redesign and graduate seminar handoff

## 1. Purpose and status

This project asks a researcher to revise, simplify, or replace the proposed compiler framework after studying its foundations and the existing implementation. Its primary result is a defensible design. It is not an assignment to implement the earlier plans. Both earlier guides remain available as historical proposals; their implementation sequences are suspended for this research assignment. In particular, neither a custom intermediate representation nor a runtime-owned root arena is a settled requirement.

A compiler transforms a program into another representation while preserving specified behavior. An intermediate representation (IR) makes program structure explicit so that transformations can analyze and change it. A runtime supplies operations that generated code needs during execution, including object allocation and garbage collection. A just-in-time compiler (JIT) also manages the creation and lifetime of executable code inside a running process. These responsibilities overlap at concrete boundaries: a generated call can allocate, move an object, throw an exception, publish a closure, or schedule later work.

The existing implementation uses Hermes for JavaScript parsing, intermediate operations, and managed execution services, and LLVM for native compilation. The proposed framework tries to make these boundaries explicit and composable. The research question is whether its abstractions are sufficient, necessary, and economical—and which should change before implementation begins.

The assignment has three connected tracks:

1. Derive the design from semantic and mathematical foundations, stating what the definitions establish and what remains an engineering assumption.
2. Compare concrete architecture alternatives using existing code and carefully worked examples, then produce revised design documents.
3. Identify independently useful subsystems and describe a staged route toward a fully custom system, without making either extensive extraction or complete replacement a prerequisite for progress.

All code-like examples below are proposed notation or pseudocode. No new framework, verifier, root allocator, or compiler pass was implemented for this handoff. Historical tests describe the current system, not the proposed one.

## 2. The starting evidence

The source snapshot is commit `87d4658c4ed27aee42ddf4e023f9e9666ef3a2a1`. It contains the compiler, runtime changes, test suites, module host, application fixtures, tickets, diaries, and both previous design guides. It does not include local build products or installed dependencies. The package manifest records the source archive and document hashes so that a reviewer can distinguish the implementation baseline from this later research brief.

Read these guides in order:

- `design-doc/01-engine-v2-architecture-and-intern-implementation-guide.md` proposes execution ownership, native activations, a root arena, and a module registry.
- `design-doc/02-composable-compiler-language-grammar-effects-ownership-and-hermes-llvm-integration.md` proposes a canonical graph, operation contracts, effect descriptions, lowering stages, and authoring APIs.
- This document changes the decision status of those proposals and defines the research deliverables. A seminar report may reject substantial portions of either earlier guide.

The application campaign recorded 96 successful executions and nine known unoptimized archive-library admission boundaries, with zero unexpected failures after the fixture correction. The boundary is concrete: the unoptimized fflate module factory requested 1,084 root slots and three argument slots against a combined limit of 1,024. This is evidence of a storage/admission problem in the current emitter. It does not establish that a heap arena is the optimal solution, that peak liveness is 1,084, or that raising the threshold is safe. See the LLVM-APPS-001 diary and `reference/evidence/final-application-campaign.json.gz` in that ticket.

The current engine's public entry points are `Engine::create`, `compile`, `loadIR`, `execute`, `drain`, `collect`, and `close` in `hermes/include/hermes/LLVMJIT/Engine.h`. Its result includes success, phase, diagnostic text, and a unit identifier. The API separates compilation from execution. An initializer can fail after publishing a callable object, which is one reason native code remains retained until engine teardown. A revised design must account for that observable intermediate state.

```text
Static JavaScript
  -> request-scoped Hermes frontend
  -> Hermes IR and lowering
  -> LLVM emitter -> native artifact -> engine admission
                                      -> Hermes managed runtime
Dynamic eval/Function source ----------> runtime bytecode compiler

Module host -> prepared module graph -> generated JavaScript -> static path
Jobs/timers -> managed runtime callbacks -> previously admitted native code
```

The distinction between static and dynamic compilation is part of the present architecture. Direct lexical evaluation has supported and rejected contexts recorded in the regression suite. A proposal must preserve shared mutable bindings and source-context restrictions, or explicitly revise the supported language profile. It must not infer that a new IR automatically makes dynamic source use LLVM.

## 3. Refinements recommended now

### 3.1 Establish the semantic contract before choosing the builder

A fluent API describes how a client constructs a program representation. It does not determine what programs mean, which transformations are correct, or whether constructed graphs are well formed. Define the observable behavior first, then derive the minimum operations and checks required to preserve it.

Use a small operational semantics as the first research artifact. An operational semantics specifies how a machine state takes one execution step. For a manageable core, let the state be `(block, environment, heap, continuation, jobs, trace)`. The environment maps local identifiers to values; the heap maps locations to cells or objects; the continuation identifies the normal or exceptional destination; the job sequence records deferred work; and the trace records selected external observations. These components are a starting hypothesis, not a mandated implementation layout.

```text
state --label--> next_state
label ::= silent | output(value) | host_call(name, args) | settle(job, outcome)
outcome ::= normal(value) | throw(value) | diverge
```

Define which observations the admitted profile preserves. Printed text alone is too weak: object identity, mutation visible to later code, thrown values, job ordering, and termination can matter. Numerical comparison needs explicit handling of NaN and signed zero. Heap locations may be renamed only through a correspondence preserving aliasing and identity observations. Do not compare addresses from separate executions directly.

An equivalence claim should name its domain and observations. A simulation argument can relate each source step to zero or more target steps. Whether one-way refinement is sufficient depends on nondeterminism and the host contract; do not silently substitute it for two-way behavioral equivalence. Keep functional behavior separate from a resource profile specifying finite memory and admission failures. Otherwise a storage optimization can appear incorrect merely because one implementation exhausts its budget earlier, or can hide an actual failure-mode change.

Software Foundations provides concrete exercises in behavioral equivalence and transformation correctness; use those methods on the selected core rather than claiming a proof for all JavaScript. [Behavioral Equivalence](https://softwarefoundations.cis.upenn.edu/plf-current/Equiv.html).

### 3.2 Replace a single purity label with explicit transformation permissions

An effect summary states potential interactions with execution state. A transformation permission answers a different question: may an operation be erased, duplicated, reordered, or evaluated earlier? These questions need separate justification.

| Operation or behavior | Why a simplistic purity rule fails | Required design question |
|---|---|---|
| Nonterminating computation with no writes | Erasing it may permit later output | Is termination observable, and is termination established? |
| Object allocation | Combining two allocations can change identity | Does the operation produce a fresh identity? |
| Property access | A getter can execute arbitrary user code | What is known about the receiver and descriptor? |
| Runtime helper call | It may allocate or throw despite an innocuous name | Where is its reviewed contract defined? |
| Division lowered to an integer instruction | Target undefined behavior may differ from source behavior | What preconditions or guards establish legality? |
| Job enqueue | Moving it changes reaction order | What ordering resource is affected? |

MLIR explicitly separates memory effects, speculation concerns, and non-local control flow; its current rationale also states that non-local control flow is not fully modeled. This supports separating the questions, but it does not supply our exception/GC protocol. [Side Effects and Speculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/).

The proposed operation contract should expose semantic behavior and runtime obligations independently:

```text
OperationContract:
  operand_and_result_types
  memory_resources_read_and_written
  may_throw, may_diverge, produces_fresh_identity
  host_and_job_observations
  runtime_obligations: may_collect, borrowed_values, returned_value_protection
  preconditions
  exceptional_successors

can_move(op, across, facts): derive permission from contracts and facts
can_erase(op, facts): derive permission; unused result alone is insufficient
```

The contract should be conservative when facts are unavailable. `may_collect` is not itself a source-language write, but it imposes requirements on lowered values. Conversely, a semantic operation can become several runtime calls, each with its own collection boundary. Determine where those facts become authoritative and how later passes invalidate them.

### 3.3 Compare explicit state tokens with ordered operations

The second guide proposes a conservative state token. Such a token makes ordering dependencies visible as graph edges. Another design keeps operations ordered in blocks and consults operation interfaces when transformations move them. Neither representation eliminates the need for sound effect contracts.

The researcher should encode the same throwing getter and job enqueue examples in both forms. Count the additional block parameters, exceptional edges, verification rules, and explanations needed to justify a transformation. A global token may simplify conservative sequencing but create considerable administrative structure. Resource-specific tokens can recover independence while increasing alias and join complexity. Ordered blocks may be simpler initially but place more responsibility on transformation APIs.

Do not equate an SSA token with a fully established linear type system. Mutually exclusive branches can receive corresponding state without duplicating a resource at runtime. Loops require consistent joins. Exceptions must expose state after any effects already performed. The research report must give explicit typing or well-formedness rules for whichever interpretation it adopts.

### 3.4 Choose the representation after comparing three candidates

The new framework does not yet justify maintaining its own graph library, operation schema, parser, serializer, verifier, rewrite engine, and analysis manager. Compare a small custom CFG, a custom MLIR dialect using existing infrastructure, and a more modest extension of Hermes IR with explicit runtime-lowering contracts.

| Candidate | Potential advantage to substantiate | Cost or uncertainty to investigate |
|---|---|---|
| Custom CFG and verifier | Small surface tailored to our execution contract | Every graph mutation, analysis invalidation, serialization rule, and diagnostic becomes ours |
| MLIR dialect and interfaces | Existing typed operations, blocks, verification and conversion infrastructure | Integration size, LLVM version alignment, exceptions, GC contracts, and learning cost |
| Hermes IR plus explicit boundaries | Maximum reuse of current semantics and tests | Coupling to existing instruction forms, missing abstractions, and generality outside JavaScript |

Use identical examples and comparison criteria. Do not decide by DSL aesthetics or number of methods. Record the installed LLVM baseline separately from current online MLIR documentation; a feasibility analysis must pin the candidate revision and check which APIs actually exist there. Investigate Hermes's `llvh` use and CMake integration before assuming a second compiler infrastructure can be included without consequences.

MLIR conversion distinguishes partial legalization from full legalization. Require an explicit legality condition at each proposed executable-artifact boundary; unknown operations must not survive by accident. This is a structural condition, not proof that legal operations preserve source meaning. [Dialect Conversion](https://mlir.llvm.org/docs/DialectConversion/).

### 3.5 Reopen root storage without losing exception ownership

A root is a runtime-visible location that keeps a managed value reachable and, where required, allows its representation to be updated during collection. Liveness asks whether a value can still be needed by future execution. The emitter currently reserves many separate locations based on IR use, not a full peak-liveness allocation. Slot count therefore differs from simultaneous live-value count.

Compare three policies: explicit native-stack roots with liveness-based slot reuse; stable runtime-owned activation storage; and LLVM statepoint-based integration. These are not necessarily mutually exclusive at every level, but each candidate must define one coherent baseline. Statepoints communicate live GC values and relocation requirements to LLVM; they are not a drop-in replacement for the Hermes collector or its calling convention. [LLVM Statepoints](https://llvm.org/docs/Statepoints.html).

For each policy, trace normal return, throwing call, nested catch, collection, reentrant native calls, and suspended generators. Existing `_sh_enter`, `_sh_leave`, and `_sh_catch_no_pop` demonstrate that root chains and managed execution state are restored together. Longjmp can bypass C++ cleanup; an arena mark restored only by a destructor is insufficient. An activation arena also does not eliminate native argument storage, spills, or recursion limits.

A paper design should define the safety obligation before proposing a layout:

```text
At every collecting boundary:
  every managed value needed after the boundary is reachable by the collector;
  each subsequent use observes the appropriate post-collection representation;
  borrowed references satisfy their lifetime contract.
At every exceptional transfer:
  the handler receives the thrown value and post-effect heap;
  abandoned activation roots and execution frames are restored consistently.
```

Do not assume allocation can always be removed merely because the reference is unused. Identity, exception behavior, weak references, and finalization may change that argument. State which of these features are admitted in the study's language profile.

## 4. Worked example: effects, identity, exceptional state, and roots

Consider this JavaScript fragment. The intended printed result is derived here from the program; it is not a newly recorded test execution.

```javascript
let cell = {n: 0};
const receiver = {
  get x() { cell.n += 1; throw cell; }
};
try { receiver.x; }
catch (caught) { print(caught === cell, cell.n); }
// Intended observation: true 1
```

The getter's result is unused, yet the access cannot be erased. The getter mutates a shared object and throws that same object. The catch observes both identity and the mutation. There is no rollback to the heap preceding the access. A moving collector may also run during a general property helper, so the runtime lowering must protect values that remain needed.

A proposed semantic graph can make the two continuations explicit:

```text
entry(cell, receiver, state0):
  invoke get_property(receiver, "x", state0)
    normal(unused, state1) -> done(state1)
    exceptional(thrown, state1) -> caught(cell, thrown, state1)

caught(cell, thrown, state1):
  same = reference_equal(cell, thrown)
  invoke get_property(cell, "n", state1)
    normal(n, state2) -> output(same, n, state2)
    exceptional(e, state2) -> propagate(e, state2)
```

This notation deliberately leaves the root plan unspecified. The intern must describe how `cell` survives the first invocation, how `thrown` reaches the handler, whether `receiver` is live afterwards, and where runtime entry/exit restoration occurs. Repeat the trace after replacing the getter body with a normal return, a nonterminating loop, and a job enqueue followed by a throw. Show which contracts change and which invariants remain.

Then derive a counterexample to an invalid optimization. For example, dead-result elimination applied to `get_property` produces no catch output. The counterexample is small enough to inspect and addresses an actual compiler decision. A large application regression alone is less useful for explaining the rule.

## 5. Fundamental underpinnings and the route to a custom system

The research must expose the conceptual machinery so that we can eventually replace dependencies deliberately. A survey naming monads, lattices, or category theory without using them to explain an API decision is inadequate. For every concept, provide a definition, a small derivation, a concrete mapping to this code, and a limitation.

### 5.1 Syntax, binding, and interpretation

An abstract syntax is the set of program forms and their composition rules. Binding determines which declaration an occurrence names. An interpreter assigns meaning to syntax. A compiler can be understood as another interpretation only after specifying what it preserves and how binding survives translation.

Study initial representations, where programs are explicit data, and final representations, where programs are built through an interpretation interface. Typed tagless-final work shows how a suitable host type system can enforce object-language properties. A JavaScript builder does not acquire those guarantees merely by using similarly named combinators. The canonical verifier must remain authoritative unless a separate static argument establishes otherwise. [Typed Tagless Final Interpreters, introductory sections](https://okmij.org/ftp/tagless-final/course/lecture.pdf).

Produce two tiny encodings of constants, addition, binding, and conditional choice, written as design notation. Explain the consequences for serialization, traversal, multiple interpretations, diagnostics, and malformed input. Then introduce closures and mutable captured cells. Determine whether the chosen representation still makes scope and aliasing evident. Do not confuse a syntactic variable with its mutable storage cell.

### 5.2 Control flow, continuations, and SSA

A continuation describes the remaining computation. In a CFG, a branch selects a successor and transfers arguments; SSA gives each defined value a unique definition. Block parameters can expose merge values directly. The relation to functional forms can clarify joins, but JavaScript mutation and exception state still require explicit treatment.

Study Appel's *SSA Is Functional Programming* as a foundational reading, then translate one loop and one exception join by hand. Explain dominance, the rule that a definition must be available on paths to its use, and show an invalid graph rejected by the proposed verifier. The author's PDF endpoint was inaccessible during preparation; the intern must obtain and read the paper before attributing detailed conclusions to it. [Publication record](https://collaborate.princeton.edu/en/publications/ssa-is-functional-programming/).

### 5.3 Dataflow, lattices, and abstract interpretation

A dataflow analysis approximates facts at program points. A lattice supplies an ordering of information and a way to combine facts; monotonic transfer functions support fixed-point iteration. For finite powersets, a backward liveness analysis grows sets until no equation changes. Termination follows from finite height and monotonic growth, rather than an arbitrary iteration timeout.

```text
live_out(block) = union(edge_live(successor, edge_arguments))
live_in(block)  = uses_before_definition(block)
                 union (live_out(block) minus definitions(block))
repeat affected blocks until no live set changes
```

Block parameters require edge-specific substitution: the successor's needed parameter corresponds to the argument passed on that edge. Exceptional edges and values needed by runtime protocols must also participate. Derive the equations on a loop with a throwing call. State exactly where the approximation may retain unnecessary roots and why it cannot omit a required one.

Read Kildall for a framework for global analysis and Cousot's materials for abstraction, soundness, and fixed points. A finite liveness example does not establish termination for every future analysis; an infinite-height domain may need additional machinery. [Kildall paper](https://courses.cs.washington.edu/courses/cse501/15sp/papers/kildall.pdf), [Cousot's abstract interpretation resources](https://www.di.ens.fr/~cousot/AI/). These are assigned deeper readings, not claims of completed paper review during package preparation.

### 5.4 Effects, capabilities, and ownership

An effect description approximates a computation's behavior. An effect handler supplies an interpretation of certain operations. A static effect annotation does not require a new runtime handler language. Study this distinction before proposing extensible handlers for the compiler framework. Koka offers a concrete effect-typing research reference; our current operation metadata does not constitute such a sound type system. [Koka publication](https://www.microsoft.com/en-us/research/publication/koka-programming-with-row-polymorphic-effect-types/).

A capability represents permission to perform an operation on a resource. Region and capability research can clarify when storage may be accessed or reclaimed, but a root activation's lifetime differs from the lifetime of a JavaScript object retained by a closure. Describe both lifetimes separately. The capability-calculus research is an invitation to study static guarantees, not evidence that Hermes objects can be region-freed. [Capability calculus abstract and paper links](https://www.cs.cmu.edu/~dpw/papers/capabilities-toplas-abstract.html).

### 5.5 Replacement stages and proof obligations

A fully custom system could eventually own the frontend, semantic IR, optimizer, runtime, collector, scheduler, module host, and native code manager. These are distinct replacement decisions. A custom IR over Hermes and LLVM is already a custom compiler layer; replacing LLVM's machine backend is a much larger undertaking and is not required for owning JavaScript semantics.

| Replacement stage | What becomes ours | What can remain reused | Required design evidence |
|---|---|---|---|
| A: semantic core | Syntax, verifier, small interpreter specification | Existing compiler/runtime as reference | Rules, examples, malformed programs, observation relation |
| B: frontend boundary | Binding and import contract, later parser choices | Hermes parser initially | Preserved metadata, lexical eval, classes, source locations |
| C: analyses and lowering | Effect rules, dataflow, runtime ABI planning | LLVM native compilation, Hermes heap | Pass contracts, exception/root traces, legality checks |
| D: execution ownership | Activation, code, jobs, modules | Selected Hermes services | Lifecycle state machines, failure semantics, reentrancy |
| E: managed runtime | Values, objects, collector, call/exception protocol | LLVM and an external oracle | Object model and GC invariants, language-profile coverage |
| F: independent backend, optional | Instruction selection, register allocation, machine code | Platform ABI/toolchain pieces as chosen | Explicit benefit relative to scope and maintenance cost |

The seminar deliverable is a dependency map and design for these stages, not their implementation. Identify a minimal educational language that exercises the hard contracts, and distinguish it from a useful JavaScript profile. General objects, coercions, prototypes, descriptors, closures, modules, jobs, and dynamic evaluation can interact; replacing only arithmetic is insufficient evidence for a complete runtime design.

## 6. Reusable subsystems with explicit boundaries

The intern must identify components that could serve other projects, not merely rename internal directories as libraries. For each candidate, specify inputs, outputs, laws or invariants, errors, dependencies, serialization/versioning needs, and two plausible consumers. Mark consumers as proposed unless an actual project integration has been inspected. Compare extraction cost with the cost of retaining a local implementation.

| Candidate | Minimal independent contract | Proposed consumers | Coupling to investigate |
|---|---|---|---|
| Worklist fixed-point solver | Finite graph, lattice operations, monotone transfer, scheduling | Compiler liveness; workflow reachability analysis | Node identity, termination assumptions, diagnostics |
| CFG verification and dominance | Blocks, edges, definitions, uses, entry | JS compiler; query-plan/control-flow tool | Exceptional edges, nested regions, unreachable nodes |
| Rewrite legality and provenance | Pattern preconditions, replacement, evidence and locations | IR optimizer; expression simplifier | Identity/effects, mutation API, analysis invalidation |
| Pass dependency manager | Declared requirements, products, invalidation and revision | Compiler pipeline; static-analysis pipeline | Hidden global state, caching, nondeterminism |
| Artifact and capability descriptions | Typed artifact kind, target facts, explicit admission checks | JIT host; plugin loader | Platform ABI, trust boundary, code lifetime |
| Differential trace comparison | Observation schema, normalization, declared equivalence | Runtime regression; protocol simulator | Nondeterminism and over-permissive normalization |
| Resource lifetime state machines | Acquire/use/release transitions, exceptional exits | Native activation design; task-resource management | GC tracing and longjmp remain runtime-specific |
| Module graph algorithms | Resolution result graph, SCC decomposition, graph diagnostics | Module host; build dependency planner | Live bindings and top-level await are JS-specific layers |

Strongly connected component (SCC) decomposition groups mutually reachable nodes. It is a useful reusable graph operation. JavaScript module linking requires additional rules about bindings and initialization; top-level await adds asynchronous evaluation dependencies. An SCC utility must not claim to implement those semantics. This example should guide the distinction between reusable algorithm and language-specific policy throughout the report.

Choose two candidates for full API design and give each a worked example in two domains. One should be the fixed-point analysis substrate or CFG analysis; the other should come from a different concern. Include a dependency diagram that identifies the minimum layer with no Hermes or LLVM imports. If the proposed extraction needs most of the runtime, explain why it is not yet a self-contained subsystem.

```text
Generic graph + lattice contracts
    -> fixed-point solver
        -> JS liveness facts -> root-plan policy -> Hermes/LLVM lowering
        -> workflow facts   -> domain-specific diagnostics

Generic dependency graph -> SCC algorithm
    -> JS module linking policy + binding cells + async evaluation
    -> build dependency diagnostics
```

A reusable API should keep the domain's transfer function visible. It should not hide it behind dozens of framework callbacks. Mathematical generality is valuable when it removes duplication or makes correctness review simpler. Require concrete examples before introducing extensibility mechanisms, plugin registries, or universal effect hierarchies.

## 7. Source-reading route and integration questions

Read in dependency order, following one source function into execution before studying every feature. Repository-relative paths below refer to the packaged code snapshot.

| File | What to inspect | Question to answer in the report |
|---|---|---|
| `hermes/include/hermes/LLVMJIT/Engine.h` | `Result`, `SourceOptions`, engine methods | Which transitions are public and which failure states are distinguishable? |
| `hermes/lib/LLVMJIT/Frontend.cpp` | Request-scoped source compilation | Which source context reaches emission and what has already been lowered? |
| `hermes/lib/LLVMJIT/Engine.cpp` | Compilation, admission, execution, teardown | What may remain published after failure, and who owns executable memory? |
| `hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` | `FunctionEmitter`, slot assignment, emission | Which decisions belong to semantics, representation, or allocation policy? |
| `hermes/lib/BCGen/SH/LLVMNative/eval_extensions.cpp` | Dynamic-source integration metadata | Which bindings/context facts must survive a replacement IR? |
| `hermes/include/hermes/VM/static_h.h` | Native/runtime ABI and local roots | What must callers establish before allocating helpers? |
| `hermes/lib/VM/StaticH.cpp` | Helper semantics and exception restoration | What state must a new activation protocol restore? |
| `hermes/utils/module-host/compiler.cjs` | Module preparation and binding transformation | What assumes a complete graph before execution? |
| `hermes/utils/module-host/runtime.js` | Registry and evaluation behavior | What prevents independently prepared bundles sharing one live registry? |
| `hermes/utils/qualify_shllvm_apps.py` | Campaign matrix and boundary classification | Which architectural claims are actually exercised? |

Use `hermes/docs/llvm/DRIVER.md`, `JIT.md`, `MODULES.md`, `LANGUAGE_EXTENSIONS.md`, and `TEST262.md` for existing operational instructions. Consult the LLVM-ENGINE-001, LLVM-JIT-001, LLVM-APPS-001, and module-related ticket directories in `ttmp` for decisions and evidence. The diaries are historical observations, not a substitute for inspecting the current source at the recorded commit.

Produce a table with columns `requirement`, `current owner`, `proposed owner`, `metadata crossing boundary`, `failure contract`, and `unresolved evidence`. Include exact BigInt serialization, UTF-16 strings, lexical eval sharing, private-field brands, Promise job order, module live bindings, and root restoration. These are integration constraints even if the seminar's formal core omits their full semantics.

## 8. Reading plan and evidence discipline

Preparation reviewed selected documentation and introductory/abstract material, not every paper in full. The following ledger records that distinction. Access date is 2026-10-29. Online documentation may change; record the version or retrieval identity used for the returned report. Links are supplied instead of redistributing third-party papers.

| Resource | Preparation coverage | Study assignment |
|---|---|---|
| [MLIR interfaces](https://mlir.llvm.org/docs/Interfaces/) | Selected interface documentation | Map one proposed operation contract to an interface and identify missing semantic obligations |
| [MLIR conversion](https://mlir.llvm.org/docs/DialectConversion/) | Conversion modes and legality sections | Define admissible operations at three boundaries, including unknown-operation failure |
| [MLIR effects](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/) | Categories and modeling sections | Separate movement, erasure, duplication and speculation; explain non-local control gap |
| [LLVM statepoints](https://llvm.org/docs/Statepoints.html) | Overview of live values and relocation | Compare with explicit roots against current Hermes collector and exception protocol |
| [Tagless-final lecture](https://okmij.org/ftp/tagless-final/course/lecture.pdf) | Introductory initial/final comparison | Read the typed encodings and explain which guarantees require the host type system |
| [SSA is Functional Programming](https://collaborate.princeton.edu/en/publications/ssa-is-functional-programming/) | Metadata; author PDF inaccessible | Read full paper; derive loop and exceptional join examples, marking any extensions as yours |
| [Kildall](https://courses.cs.washington.edu/courses/cse501/15sp/papers/kildall.pdf) | Assigned reading | Derive monotonicity and termination conditions for the selected analysis |
| [Cousot resources](https://www.di.ens.fr/~cousot/AI/) | Assigned reading | Explain abstraction/concretization and sound approximation using an actual compiler fact |
| [Koka](https://www.microsoft.com/en-us/research/publication/koka-programming-with-row-polymorphic-effect-types/) | Publication overview | Distinguish type-system guarantees from conservative operation annotations |
| [Capability calculus](https://www.cs.cmu.edu/~dpw/papers/capabilities-toplas-abstract.html) | Abstract | Explain permissions, region lifetime, and why reachable JS objects require a different lifetime argument |
| [Software Foundations](https://softwarefoundations.cis.upenn.edu/plf-current/Equiv.html) | Behavioral-equivalence material | Write a small simulation/equivalence argument and a failing transformation counterexample |
| [CompCert overview](https://compcert.org/man/manual001.html) | Overview | Distinguish verified preservation, verified structure, differential testing, and unsupported claims |

For each important design claim, maintain a ledger entry containing the claim, its status, source section or code symbol, assumptions, counterexample sought, and verification method. Use statuses such as `observed in code`, `historical execution`, `derived argument`, `proposed`, and `unresolved`. A citation is evidence of what a source establishes; it is not automatic evidence that our integration meets its assumptions.

Advanced optional readings include [Lightweight Modular Staging](https://scala-lms.github.io/tutorials/index.html), [Moggi on computations](https://www.cs.cmu.edu/~crary/819-f09/Moggi91.pdf), and [Tofte and Talpin on region-based memory management](https://web.cs.ucla.edu/~palsberg/tba/papers/tofte-talpin-iandc97.pdf). These were not deeply reviewed for this handoff. Use them only if they answer an explicit question about staging, computation composition, or storage lifetime. Do not add a new abstraction merely to reproduce a paper's terminology.

## 9. Seminar plan and expected return

Plan for eight weeks of design research. The schedule can be shortened by reducing the number of deep alternatives, rather than replacing careful arguments with broad unsupported claims. No production code changes are required. Existing tests may be run to understand the baseline, but any result must name its toolchain, revision, command, and classification.

| Week | Main work | Reviewable result |
|---|---|---|
| 1 | Read the engine path, both guides, and evidence | Current-system map, terminology, claim ledger, unresolved questions |
| 2 | Study semantics, binding, SSA, and observations | Small language definition and three complete execution derivations |
| 3 | Study effects, exceptional control, and legality | Transformation-permission table, counterexamples, candidate contracts |
| 4 | Compare custom CFG, MLIR, and Hermes extension | Same five examples in each candidate; decision matrix and recommendation |
| 5 | Study liveness, roots, ownership and unwind | Root-policy comparison with normal/throw/GC/suspension traces |
| 6 | Identify reusable components and custom-system stages | Two independent API designs, two consumers each, dependency/replacement map |
| 7 | Rewrite the proposed architecture | Revised guide, decision records, removed abstractions, remaining risks |
| 8 | Adversarial review and synthesis | Final seminar paper, presentation, corrected examples, handback manifest |

Use these five comparison examples: scalar branch and merge; loop with block arguments; mutable captured cell shared with a dynamic closure; throwing getter with collection obligations; and ordered job enqueue with deferred continuation. Document where each example exceeds the formal core and therefore receives an interface contract rather than a full derivation. A representation that handles arithmetic attractively but obscures the last three examples is insufficient for this project.

The returned package should include:

- A 20–30 page technical paper explaining the question, foundations, alternatives, findings, limitations, and recommended design. Detailed appendices can exceed that range.
- A revised version of the framework design, with accepted, changed, deferred, and rejected decisions explicitly distinguished. Include a minimal API and its invariants before an extension catalog.
- At least six decision records: IR infrastructure; effect/control representation; root/storage policy; semantic observations; reusable subsystem boundaries; and staged dependency replacement.
- Two reusable subsystem designs with dependency lists, laws, failure behavior, pseudocode, and examples from two domains each.
- A foundations chapter that derives the relevant concepts and explains a path from a small independent language/runtime specification toward a custom system.
- Worked semantic traces, counterexamples, source-reading annotations, a claim/evidence ledger, and a bibliography with sections actually read.
- A future implementation plan that is explicitly a proposal. List prerequisite research and acceptance criteria; do not implement that plan during this assignment.

Recommended assessment weights are 25% semantic clarity, 20% grounded analysis of current code, 20% quality of architecture comparisons, 15% reusable subsystem contracts, 10% custom-system roadmap, and 10% reproducibility and exposition. Novel terminology and large API surfaces receive no credit by themselves. A well-supported recommendation to remove an abstraction is a successful result.

For the final review, ask another reader to find a counterexample to one transformation rule, an ownership path missed by one state machine, and a proposed reusable component whose dependencies defeat its claimed independence. Record the objections and resulting changes. Where no second reader is available, label the review as self-review instead of implying independent validation.

## 10. Decision gate after the seminar

The next engineering decision should be narrow: choose the representation and execution contract for one vertical slice, justified by the report. Possible outcomes include simplifying the current Hermes path, using an MLIR dialect, building a small custom core, or combining a generic analysis substrate with a runtime-specific lowering layer. The research should identify what each choice allows us to delete as well as what it requires us to build.

Implementation authorization belongs after that decision. The current package preserves the source baseline and earlier proposals so that the researcher can challenge them, derive better alternatives, and return a coherent design without being obligated to make the previous architecture work.
