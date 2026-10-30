# strata: a builder API for a composable JS-to-native compiler

**Status: examples only. Nothing here is implemented.** This is a proposed JavaScript API, `g`, for defining and studying the compiler framework described in *Semantics-first architecture for a composable JS compiler and JIT* (LLVM-ENGINE-002). Every `// →` result in the examples shows the *illustrative shape* of a result, not a recorded execution.

The API has one job: let a person state a compiler as **values** — semantics, operations, analyses, passes, strategies, engines — so that each part can be inspected, checked against the specification, swapped, compared and studied. It is a design notation that could later become a real library (the examples would then become its acceptance tests).

```js
import { g, bytes, kib, mib, slots, jobs, ms, count } from 'strata'   // proposed package

const program = g.compile(g.pipeline(), g.source.text('print(1 + 2)'))
program.summary()          // → every resolved default, provider and strategy, with provenance
```

## How the API maps onto the architecture

| Layer (note) | API area | Main constructors |
|---|---|---|
| 1 Semantics | `g.semantics`, `g.profile`, `g.observe` | `g.semantics().profile('js-sync')`, `.run(fn, { args })` |
| 2 Core IR | `g.fn`, `g.ir`, `g.verify` | `g.fn(name, params, result, f => …)`, `g.ir.parse(text)` |
| 3 Operations | `g.op`, `g.opset`, `g.provider`, `g.perm` | `g.op('js.get').behaviour(…).obligations(…)` |
| Composition | `g.rewrite`, `g.pass`, `g.pipeline`, `g.law`, `g.refines` | `g.pipeline().insert(pass, { after })`, `g.law.refines(pass, { corpus, profile })` |
| 4 Analyses | `g.lattice`, `g.analysis`, `g.solve` | `g.analysis('liveness').backward().lattice(…)` |
| 5 Lowering | `g.roots`, `g.exceptions`, `g.representation`, `g.suspension`, `g.calls` | `.roots(g.roots.stackReuse())` |
| 6 Execution | `g.engine`, `g.machine` | `await g.engine()`, `await engine.admit(artifact)` |
| 7 Materialization | `g.llvm`, `g.target`, `g.artifact`, `g.emit` | `g.llvm.orc()`, `await g.emit(g.pipeline().materialize(g.llvm.aot({ output })), src)` |
| Study | `g.design`, `g.param`, `g.metric`, `g.objective`, `g.search`, `g.study`, `g.process`, `g.decision` | `g.design(params, p => pipeline)` |

## The five conventions

| # | Convention | What it means here |
|---|---|---|
| 1 | **Builders are immutable values; there is no `.build()`.** | `const fast = base.roots('arena')` branches a pipeline. Pipelines, op sets and analyses can be hashed, diffed, cached and stored. |
| 2 | **Every slot accepts four things.** | Nothing (the opinionated default), partial params, a named library strategy, or a lambda `(input, ctx) => strategy` that returns a strategy for that input, often `ctx.default`. Whatever strategy is chosen, its plan passes **the same checker** as a built-in one. A custom planning function is wrapped as a strategy with `g.roots.custom(name, planFn)`. |
| 3 | **Pure unless declared.** | Parsing a text, verifying, analysing, rewriting, lowering, emitting LLVM IR and producing a relocatable artifact (`g.compile`) are pure and cached by content. Reading files, writing an object file (`await g.emit`), materializing code into memory (inside `await engine.admit`), execution, GC and jobs are effects and are `await`ed. |
| 4 | **Laws are executable.** | `g.law.join(g.fx)`, `g.law.monotone(analysis)`, `g.law.antitone(g.perm)`, `g.law.refines(pass, { corpus, profile })`, `g.law.contract(provider, opset)` run as property tests. A law that fails returns a minimized counterexample. |
| 5 | **Every quantity has a unit.** | `bytes`, `kib`, `mib`, `slots`, `jobs`, `ms`, `count`. `slots(3).add(bytes(8))` is a `DimensionError`; slots become bytes only through a layout: `g.layout.host64.bytes(slots(3))`. |

Also: **presets are functions `pipeline → pipeline`** (`.use(g.preset.debug, g.preset.strictChecks)`), `.with(p => …)` is a local transformation, and `.set(key, value)` is the raw escape hatch. **Every default is visible** in `summary()` and in IR provenance ("this root slot came from strategy `stackReuse`, value v42 live across c7").

## Grammar: the sorts

| Sort | Constructors | Operators | Laws / structure |
|---|---|---|---|
| **Quantity** | `bytes(n)` `kib(n)` `mib(n)` `slots(n)` `jobs(n)` `ms(n)` `count(n)` | `add sub mul div min max lt le gt ge eq` | Vector space per unit; conversion only through a `layout` |
| **Type** | `g.t.bottom` `g.t.boolean` `g.t.int32` `g.t.number` `g.t.bigint` `g.t.string` `g.t.object` `g.t.callable` `g.t.propertyKey` `g.t.any` `g.t.union(…)` | `join meet le` | Lattice, `bottom ≤ … ≤ any` |
| **Representation** | `g.rep.tagged` `g.rep.f64` `g.rep.i32` `g.rep.bool` `g.rep.raw` | `box unbox` (checked conversions) | Boxing back is exact |
| **Fact** | `g.fact.type(v, t)` `g.fact.shape(v, id)` `g.fact.dataProperty(v, key)` | `and`, `origin`, `invalidatedBy` | Lattice of knowledge; every fact has an origin and dies with it |
| **Behaviour** (effects) | `g.fx.none` `g.fx.reads(r)` `g.fx.writes(r)` `g.fx.fresh` `g.fx.throws` `g.fx.diverges` `g.fx.callsUser` `g.fx.host(name)` `g.fx.unknown` | `join le has expand` | Join-semilattice: associative, commutative, idempotent; `unknown` is top; `callsUser` (everything user code can reach) is strictly below it |
| **Obligation** | `g.ob.none` `g.ob.mayCollect` `g.ob.nonlocalThrow` `g.ob.writeBarrier` `g.ob.borrows(i, …)` `g.ob.protectsResult` `g.ob.needsHost(cap)` `g.ob.sharesBindingCells` | `join` | Set union. A collecting operation borrows its operands: they must stay rooted while it runs |
| **Permission** (derived) | `g.perm(op, facts)` | `erase merge move duplicate hoist speculate`, `g.perm.explain` | **Antitone**: more behaviour, fewer permissions |
| **Operation / OpSet** | `g.op(name)` `g.ops[name]` (standard registry) `g.opset(name)` `g.opsets` | `.variant(nameOrOp, {when})` `.ops()` `.rename()` `.size` `.version()` | A variant is any operation (new, like `js.get.own_data`, or existing, like `num.add` for `js.add`) whose contract refines the general op under its fact; `g.op.narrow` picks it |
| **Provider** | `g.hermes.provider(set)` `g.reference.provider(set)` `g.provider(name).implements(set)` | `.lowers(op, fn)` `.steps(op, fn)` `.delegate(p)` `.covers(set)` `.lowering(op)` `.contract(op)` `.version(v)` | Must satisfy every contract of the set (Law 2) |
| **Program** (core IR) | `g.fn(…)` `f.entry` `f.block` `$.op` `$.invoke` `$.jump` `$.branch` `$.ret` `$.throw` `g.ir.parse(text)` | sequencing, branching, joins by block params; `fn.edit(e => e.retarget(…))` | Flat SSA: every name defined once per function, terminators take values; dominance; edge arity and types; one terminator; a may-throw op only in `invoke` or a block with `onThrow`; alpha-renaming invariance |
| **Profile / Observation** | `g.profile(name)` `g.observe.*` | `le` (inclusion), `g.observe.equal(a, b, {upTo})` | Refinement `⊑` is a preorder within a profile |
| **Lattice / Analysis** | `g.lattice.powerset()` `.flat()` `.map()` `.product()` `.interval()`; `g.analysis(name)` | `.forward() .backward() .transfer() .edge()`, `g.analysis.product` | Monotone framework; least fixed point; products stay monotone |
| **Rewrite** | `g.rewrite(name).match(…).when(…).to(…)` | `g.rewrites(…)` (a set, also of sets), `.canonical()` | Side condition reads permissions and facts; canonicalization is idempotent |
| **Pass / Pipeline** | `g.pass(name)` `g.pipeline()` | `.then` `.passes` (replace) `.insert(pass, {after})` `.materialize` `.checks` `.boundaryChecks` | Monoid with identity; correct passes compose (refinement is transitive) |
| **Strategy** | `g.roots.*` `g.exceptions.*` `g.representation.*` `g.suspension.*` `g.calls.*` | four-way slots, `g.compat(a, b)` | Product space restricted by a compatibility relation; each meets its invariant |
| **Machine** (lifecycle) | `g.machine(name)` `g.engine()` | `.vars .state .on(label, to, {set}) .final .retarget .invariant(s)`, `g.machine.product` | Labelled transition systems with variables; the product synchronizes on shared labels; invariants checked on it |
| **Design / Study** | `g.design` `g.param.*` `g.metric` `g.objective.*` `g.search.*` `g.study` `g.process` `g.decision` | `at sample where`, `weighted lexicographic require` | Product space of pipelines; orders for ranking |

Seventeen sorts, but the user-facing core is eight: **Type, Behaviour, Operation, Program, Analysis, Pass, Strategy, Engine.** The rest are the algebra those eight are made of, or the study layer on top.

**Frame accounting, one rule for every strategy** (it matches today's emitter, `LLVMBackend.cpp`): rooted values (live across a collecting call, or borrowed as its operand) + distinct managed constants used as operands + **2 fixed slots** (scratch and discard) + **outgoing argument slots**, `max(1, largest call's argument count without this)`. The emitter's admission limit is 1,024 for the whole sum; it reports "roots" including the 2 fixed slots, so fflate's factory reads as 1,084 roots + 3 arguments.

**Checks** take one key set: `.checks({ verify, interpretVsHermes, translationValidation, gcSafety, forcedGC, differential, lawSuite })`. What runs at each level boundary is named separately with `.boundaryChecks({ 'L0→L1': [...], … })`.

## Namespace reference

Every name used in the examples, grouped by layer. All are proposed.

| Area | Names |
|---|---|
| Quantities, layouts | `bytes kib mib slots jobs ms count` with `add sub mul div min max lt le gt ge eq` · `g.layout.host64` · `g.limit(name, {measure, max, why})` |
| Specification | `g.semantics().profile().delegate().run().behaviours().coverage()` · `g.profile(name)`, `.and`, `.le`, `g.profile.define` · `g.observe.equal(a, b, {upTo, numbers})` · `g.refines(target, source, {profile, via})` · `g.value.*`, `g.values.js` |
| Core IR | `g.fn(name, params, result, (f, params) => …)` with `f.entry`, `f.block(name, params, body, {onThrow})`, `f.to(block, ...args)`, `$.op`, `$.invoke`, `$.const`, `$.jump`, `$.branch`, `$.ret`, `$.throw` · `fn.edit(e => e.retarget(…))` · `g.ir.parse`, `g.ir.text`, `g.ir.json` · `g.verify(fn, {facts})` · `g.graph`, `g.graph.fromModules`, `g.graph.scc` |
| Types, facts, behaviour | `g.t.*`, `g.t.union`, `g.t.propertyKey` · `g.rep.*` · `g.fact.type`, `g.fact.valid` · `g.origin.assumption` · `g.fx.*` (`join le has expand`) · `g.ob.*`, `g.ob.borrows`, `g.ob.sharesBindingCells` · `g.resource(name, {within, scope})` |
| Operations and providers | `g.op(name)` with `.operands .results .behaviour .obligations .step((s, args) => …) .laws .variant .attrs` · `g.op.narrow`, `g.op.opaque` · `g.ops[name]` · `g.opset(name).ops(…)`, `.rename`, `.size`, `g.opset.union`, `g.opsets` · `g.perm`, `g.perm.explain`, `g.perm.commute` · `g.contract.table` · `g.provider(name, {version, runtime}).implements().lowers().delegate()`, `.covers .lowering .contract .version` · `g.reference.provider` · `g.hermes.frontend`, `g.hermes.provider`, `g.hermes.oracle`, `g.hermes.inventory`, `g.hermes.bytecode` |
| Analyses | `g.lattice.powerset/flat/map/product/interval` · `g.analysis(name).lattice().forward()/backward().transfer().edge().exceptional().widen()` · `g.analysis.liveness/safepoints/behaviour/typeFacts/product` · `g.solve(analysis, graph, {budget, from})` · `g.edge.substituteBlockArgs/ignoreBlockArgs` · `g.widen.thresholds` |
| Rewrites and passes | `g.rewrite(name).match().when().to()`, `g.rewrite.tryMove` · `g.rewrites(...)`, `.canonical()`, `.standard()`, `.reassociate()` · `g.pass(name).from().to().requires().provides().invalidates()`, `.then` · `g.pass.analyze/identity/lowerRuntime/planRoots/version` |
| Pipelines | `g.pipeline()` with `.profile .frontend .provide .modules .ordering .analyses .rewrites .representation .roots .exceptions .suspension .calls .dynamic .tiers .materialize .checks .boundaryChecks .budget .passes .insert .stopAfter .onUnsupported .use .with .set .check .summary .hash` · `g.compile(pipeline, source)` (pure) · `await g.emit(pipeline, source)` (writes the AOT file) · `g.preset.debug/strictChecks` · `g.diff(a, b)` (pipelines, programs, facts, plans; `.levels` is an object per level) · `g.workspace(name)` · `g.ordering.blocks/tokens` |
| Lowering | `g.roots.distinct/stackReuse/arena/statepoints/custom/needed` · `g.exceptions.setjmp/statusReturn/landingPads` · `g.representation.tagged/unboxWhenProven` · `g.suspension.hermes/continuationObjects` · `g.calls.hermesNative/engineLocal` · `g.compat`, `g.compat.declare` · `g.lower.edges` · `g.strategy.name(name, fn)` · `g.dynamic.delegate/compile` · `g.shapes.declared` · FUTURE: `g.tier.*`, `g.speculate.*` |
| Materialization | `g.llvm.orc({target})`, `g.llvm.aot({target, output})` · `g.target.host64/linuxX64/riscv32` · `artifact.describe()`, `.audit()` (artifacts are relocatable; `engine.admit` materializes) · `g.artifact.diff` · `await g.emit(pipeline, source)` |
| Engine | `g.engine(opts)` → `admit run(program, {budget}) defineModule evaluateModule evaluateScript runJobs({budget}) evaluationState sameEvaluation moduleNamespace call collect metrics output snapshot capabilities close` · `g.machine(name).vars().state().on(label, to, {set}).final().invariant()`, `.invariants`, `.retarget` · `g.machine.product` (synchronizes on shared labels) · `g.check.machine` · `g.resolve.relative` · `g.js.moduleLinking` |
| Sources and frontends | `g.source.text(text, {name})`, `g.source.modules({...})`, `.pick(...keys)` · `g.frontend(name, {parse, lower})` with `f.fromSexpr` · `g.frontend.coreText()` · `g.parsers.*` |
| Laws and testing | `g.law.vectorSpace/lattice/join/antitone/monotone/variant/refines/idempotent/terminates/roundTrip/parallelTransfer/alphaRenaming/contract/declared` · `g.laws([...])`, `g.laws.standard` · `g.gen.coreIR/jsSource/values` · `g.fuzz.differential` · `g.differential({pipelines, corpus, observe})` · `g.mutant`, `g.mutants` · `g.check.differential/admitted/killsAll` · `g.oracle.external` · `g.acceptance` · `g.corpus.five/ladder/apps/fixtures/test262` (apps: 'data-pipeline', 'async-queue', 'persistent-host', 'fflate-0.8.2') |
| Study | `g.design(params, fn, {constraints})` · `g.param.choice/range` · `g.constraint.compatible` · `g.metric`, `g.metrics.list` · `g.objective.require/weighted/lexicographic/pareto/minimize` · `g.rank`, `g.rank.disagreement` · `g.results`, `g.table`, `g.table.count` · `g.search.grid/random/lhs/replay` · `g.study(name)` · `g.measurement(name)` · `g.candidate`, `g.encode.*`, `g.criteria`, `g.compare(candidates, inputs, criteria)` |
| Process and records | `g.process(name).step().diverge().converge().critique().loop()`, `.check()`, `.decision(question)`, `g.process.compare` · `g.decision(question)` · `g.ref.study/search/laws/differential` · `g.ledger` · `g.subsystem` · `g.export.bundle` |

**Reading the examples.** Each file opens with a header: the title, the *model* (what the example is about), and what to *notice*. Code reads as real usage. `// →` comments show the illustrative shape of a result; numbers in them are placeholders unless they come from the LLVM-ENGINE-002 evidence (the 1,084 + 3 slot count, the 1,024 limit, the 96/9 campaign). Every file parses with `node --check`.

## IR levels and inspection

| Level | Name | Question it answers | Dump |
|---|---|---|---|
| L0 | source | What did we receive (texts, module keys, options)? | `program.ir('L0')` |
| L1 | core IR | What does it mean, with stable value ids? | `program.ir('L1', { format: 'text' })` |
| L2 | runtime IR | Which provider implements each operation, under which contract? | `program.ir('L2')` |
| L3 | execution plan | Which values are rooted where, how does unwinding restore state? | `program.ir('L3', { fn: 'factory' })` |
| L4 | native artifact | What LLVM IR / object code and descriptors were produced? | `program.ir('L4')`, `program.artifact` |
| L5 | engine admission | What did the engine register (live state; snapshot only)? | `engine.snapshot()` |

**The Program object** returned by `g.compile` is the inspection API:
`name · summary() · metrics() · diagnostics · trace · decisions · ir(level, opts) · node(id) · find(pred) · facts(siteOrValue) · contract(opName) · perm(siteId) · plan(fn) · why(target) · checks() · cache · artifact · lineage(id)`.

`why()` answers across levels: `program.why('slot:factory/5')` returns the value, its source location, the collecting call it is live across, the obligation that made that call collecting, and the strategy that chose the slot.

## Staging rule (compile time vs run time)

| Input | Work | Where |
|---|---|---|
| Known source, pure work | Parse, verify, analyse, rewrite, lower, emit LLVM IR | Compile time, cached per function by content hash |
| Unknown but from a small finite set (a few receiver shapes) | Several guarded versions | Compile time, selected at run time by a guard (the first step toward tiers) |
| Unknown and open (`eval` strings, dynamic `import()`) | The same pipeline, invoked later, or a declared provider (Hermes bytecode) | Run time |
| Effects (materialize into memory, admission, execution, GC, jobs, timers) | Engine operations | Run time, engine-owned, always `await`ed |

Cache keys include the function's IR hash, every op-set and provider version, pass configuration, strategy identity (a lambda's identity included), target and profile. An unnamed lambda makes its work non-persistently cacheable.

## Opinionated defaults

| Decision | Default | Why | One-line override |
|---|---|---|---|
| Profile | `js-sync + js-async + js-modules`; `js-dynamic` delegated | Matches today's admitted behaviour | `.profile('core')` |
| Frontend | Hermes, importing Hermes IR before lowering | Reuses proven binding analysis | `.frontend(g.frontend.coreText())` |
| Operation providers | Hermes for every `js.*` set; `core` is the reference provider | Preserves current semantics | `.provide('js.value', myValueProvider)` |
| Effect ordering | Ordered blocks + contracts | Smaller IR (a lean, open in the seminar) | `.ordering(g.ordering.tokens())` |
| Analyses | Liveness, safepoints, behaviour, type facts, in one product solver | Lowering needs them | `.analyses(a => [...a, escape])` |
| Rewrites | Canonicalization only | Correctness before speed | `.rewrites(g.rewrites.standard())` |
| Representation | Tagged everywhere | Exact JS values | `.representation('unboxWhenProven')` |
| Roots | Stack slots with liveness reuse | Smallest change; whether it admits fflate at O0 depends on a peak liveness nobody has measured yet | `.roots(g.roots.arena({ chunk: kib(16) }))` |
| Exceptions | `setjmp` (Hermes protocol) | Reuses every throwing helper | `.exceptions('statusReturn')` (needs compatible helpers) |
| Suspension | Hermes generator lowering | Reuse first | `.suspension('continuationObjects')` |
| Materializer | LLVM ORC, textual IR, host x86-64 | Existing integration | `.materialize(g.llvm.aot({ output: 'app.o' }))` |
| Floating point | Strict; no fast-math, no reassociation | JS Number semantics | none for JS; a numeric dialect may opt in |
| Checks | `.checks({ verify: true })`; differential vs interpreter in `check` mode | Cost | `.checks({ translationValidation: true, forcedGC: 'every-safepoint' })` |
| Budgets | No hidden caps; budgets come from the strategy | No accidental admission limits | `.budget({ activeRoots: mib(4) })` |
| Code lifetime | Until engine close | Initializers can publish closures, then throw | (no override in v1) |
| Jobs | `runJobs({ budget: jobs(100) })`, no preemption | Hard interruption needs polling points | `{ budget: jobs(10), deadline: ms(5) }` |
| Unsupported input | Reject with a structured diagnostic (sloppy direct eval included) | No silent fallback counts as success | `.onUnsupported('delegate')` (explicit, reported) |

## Example map

| Section | Files | Content |
|---|---|---|
| **A. The maths, simple → complex** | 01–15 | quantities · types and facts · behaviour summaries · contracts and permissions · op sets and providers · blocks, branches, loops · exceptions and continuations · semantics and observations · lattices and fixed points · rewrites and refinement · passes and pipelines · lowering strategies · staging and tiers · materialize and admit · engine lifecycles |
| **B. Real-world scenarios** | 20–28 | quick start · two module roots · the fflate root budget · the throwing getter end to end · captured cell shared with eval · ordered jobs and async · persistent plugin host · replacing a provider · a non-JS numeric language |
| **C. Design process** | 30–34 | design spaces · metrics and objectives · search · property testing and fuzzing · variants, branches, diffs |
| **D. Scientific study** | 40–42 | factorial root/exception study · IR infrastructure comparison · corpus measurement of contract precision |
| **E. Meta-design and capstone** | 50, 51, 60 | the seminar as a process value · designing the checks · end to end |

The five comparison examples from doc 03 appear as: scalar branch and merge (06), loop with block arguments (06), captured cell shared with a dynamic closure (24), throwing getter with collection obligations (23), ordered job enqueue with deferred continuation (25).

Reused sample sources: `readAfterCall` (doc 02), the throwing getter (doc 03), the two-module counter (doc 01), the loop-carried swap, the fflate archive application, and the async retry queue.
