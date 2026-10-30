# Reference

This page is the whole API of the Strata workbench: what a preset's `main.js` can call, what each call returns, and what the views read. The agent receives this page as its briefing, so it is also the agent's map of the engine. Everything here runs in the page; nothing calls Hermes or LLVM. LLVM IR is printed as text and checked structurally, and WebAssembly is encoded to real bytes and run by the browser.

## 1. Conventions

**Values are immutable.** Pipelines, passes, strategies, rewrites, analyses, designs and machines are values: every method returns a new value and leaves the old one alone, so `const b = a.roots('distinct')` is a branch, not an edit. There is no `.build()`.

**Every slot takes four forms.** A pipeline slot (`roots`, `exceptions`, `representation`, `rewrites`) accepts nothing (the default), a name or partial parameters, a library strategy, or a lambda `(input, ctx) => …` whose `ctx.default()` runs the default, so a lambda can wrap the opinion instead of replacing it.

**Pure unless declared.** Every operation carries a **behaviour** (what it may read, write, allocate, throw, run) and **obligations** (what the lowering must provide: roots, unwinding, barriers). Every optimisation permission is derived from the behaviour, never declared.

**Laws are executable.** Claims such as "this rewrite preserves behaviour" or "this analysis is monotone" are functions that sample inputs and return a report with a counterexample when they fail.

**Units.** Sizes are quantities with units: `slots(3)`, `bytes(24)`, `kib(8)`. `layout.host64.bytes(slots(3))` is `24 B`. Mixing dimensions throws a `DimensionError`.

**Operation ids.** An operation is named `fn/block/index` (`fib/body2/0`); a block's terminator is `fn/block/term`; a block is `fn/block`.

## 2. A preset's script

A preset is a folder of files. `main.js` is the body of an async function; whatever it returns is shown by the views. Its scope:

| name | is |
|---|---|
| `g` | the whole API (sections 3 to 15) |
| `strata` | the engine object: `strata.version`, `strata.yaml(x)`, `strata.frontend`, `strata.internals` |
| `source(name = 'program.js')` | a preset file as a source; a name ending `.ir`, or text whose first line is `fn name(`, is core IR |
| `files` | every file of the preset, `{ 'program.js': '…' }`, read-only |
| `print(...xs)`, `log(...xs)`, `console.log` | lines in the Events view |
| `t` | the types (`t.number`, `t.any`, …) |
| `bytes kib mib slots jobs ms count` | unit constructors |

`print` here writes to the Events log of the workbench; `print` inside a JavaScript program is the program's own output.

What `main.js` returns decides what the views show:

| return | shown in |
|---|---|
| a Program (`g.compile(…)`) | Stage, IR, Facts, Plan, Machine (it is run in the header's mode), Events |
| a RunResult (`program.run(…)`) | Machine and Events |
| a LawReport (`g.laws([...])`, or a single law result) | Laws |
| Results (`g.search.grid(…)`, `g.table(rows)`) | Experiments |
| an object with any of `program`, `run`, `laws`, `results` | each in its view; other keys in Events |

A typical script:

```js
const program = g.compile(g.pipeline(), source());
return program;
```

The header's Run (Ctrl or ⌘ + Enter) reruns `main.js`. Mode (Spec, Plan, Wasm) and GC (Off, Alloc, Stress) choose how the returned program is run for the Machine view.

## 3. Sources and the JavaScript subset

`g.source.text(text, { name, lang })` makes a source; `lang` is `'js'` or `'ir'` and is guessed when left out. `g.source.ir(text)` forces core IR. `g.compile(pipeline, text)` also accepts a plain string.

The frontend (`strata.frontend.compile(text)`, used by the `frontend` pass) accepts this JavaScript:

- `function` declarations and expressions, arrow functions, closures over any variable; `var`, `let`, `const` with block scope and the temporal dead zone (reading a `let` before its declaration throws a ReferenceError).
- Numbers, strings, booleans, `null`, `undefined`, template literals; `+ - * / %`, `< <= > >=`, `=== !==`, `! typeof void`, unary `+ -`, `++ --`, `+= -= *= /= %=`, `&& || ??`, `?:`, comma.
- Object literals with data properties, methods, getters and setters; array literals; `o.k`, `o[k]`, assignment to both; `a.length`; method calls with `this`.
- `if`, `while`, `do … while`, `for`, `for … of` over arrays, `break`, `continue`, `return`, `throw`, `try`/`catch`/`finally`.
- `new Error(m)`, `new TypeError(m)`, `new RangeError(m)` and their `.message` and `.name`.
- Builtins: `print(...)`, `queueMicrotask(f)`, `setTimeout(f, ms)` (virtual time), `Promise.resolve(v)` and `.then(f)`.

Outside the subset (the frontend reports where): classes, `==` and `!=` (use `===`), destructuring, spread, default and rest parameters, labels, `switch`, `for … in`, regular expressions, BigInt, optional chaining, `break` or `continue` through `finally`, `new` of anything else.

Every variable starts as a **cell** (`cell.new`, `cell.load`, `cell.store`); the `promote-cells` pass turns the cells no other function captures into SSA values with block parameters. A function from the frontend takes its captured cells first, then `this`, then its JavaScript parameters: `fn deposit(c_balance: cell, c_log: cell, this: any, x: any)`.

## 4. Core IR

A function is a list of blocks. A block has parameters, operations and one terminator; values are defined once (SSA). Control passes arguments along edges to block parameters, which is how a loop carries `i` from one turn to the next.

```text
fn fib(n: number) -> number {
entry:
  jump head(0, 0, 1)
head(i: number, a: number, b: number):
  v1 = num.lt(i, n)
  branch v1, body(i, a, b), exit(a)
body(i1: number, a1: number, b1: number):
  v2 = num.add(i1, 1)
  v3 = num.add(a1, b1)
  jump head(v2, b1, v3)
exit(r: number):
  return r
}
```

Terminators: `jump B(args)`, `branch c, T(args), F(args)`, `return v`, `throw v`, `unreachable`, and `invoke op(args) normal N(args) throw H(args)`, whose normal target receives the result as an implicit first parameter and whose throw target receives the thrown value. A block header may end in `throws to H(args)`: any operation in the block that throws goes to `H`, which receives the thrown value first and then `args` (evaluated at the block's head). `throws unwind` propagates to the caller. A block with neither has no exceptional exit, so the verifier refuses any operation in it that may throw (`may-throw-without-exit`); the frontend writes `throws unwind` or `throws to` on every block it makes, and hand-written IR must say it too. Comments start with `;` or `//`. Literals: numbers, `"strings"`, `true`, `false`, `null`, `undefined`. Attributes: `js.closure(@callee)`, `core.call(@f, x)`, `js.new_error[TypeError](msg)`.

| call | does |
|---|---|
| `g.ir.parse(text)` | text to a function, or a Module when there are several |
| `g.ir.text(fnOrModule)` | the printed form (`parse(text(f))` gives `f` back; `g.law.roundTrip()` checks it) |
| `g.ir.json.encode(fn)`, `.decode(s)` | the JSON form |
| `g.fn(name, params, result, (f, params) => …)` | the builder, below |
| `g.module(...fns)` | a module; the first function is `main` |
| `g.verify(fn)` | `{ ok, diagnostics }`: single definition, terminators, known blocks and ops, arity, edge arity and types, dominance (with a counter-path), may-throw operations without an exit, unknown callees; unreachable blocks are warnings |
| `g.dominators(fn)` | `{ idom, dominates(a, b), reachable, rounds }` |
| `g.promoteCells(fn)` | mem2reg in place: `{ promoted, params, removedParams }` |

The builder. `f.entry(cb)` and `f.block(name, params, cb, { onThrow, throwArgs })` add blocks; `cb` receives a cursor `$` and the block's parameters by the names you gave (a repeated name is freshened, `i` becomes `i1`, so always use the names the callback hands you). `f.to(block, ...args)` makes an edge.

```js
const fib = g.fn('fib', { n: t.number }, t.number, (f, { n }) => {
  f.entry($ => $.jump(f.to('head', $.const(0), $.const(0), $.const(1))));
  f.block('head', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.branch($.op('num.lt', i, n), f.to('body', i, a, b), f.to('exit', a)));
  f.block('body', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.jump(f.to('head', $.op('num.add', i, $.const(1)), b, $.op('num.add', a, b))));
  f.block('exit', { r: t.number }, ($, { r }) => $.ret(r));
});
```

Cursor: `$.op(name, [attrs,] ...args)` returns the result's name; `$.call(callee, ...args)`, `$.closure(callee, ...caps)`, `$.const(v)`, `$.jump(edge)`, `$.branch(c, t, f)`, `$.ret(v)`, `$.throw(v)`, `$.unreachable()`, `$.invoke(op, args, { normal, throw, attrs })`.

A Module has `functions` (a Map), `main`, `fn(name)`, `names()`, `clone()`, `hash()`, `toString()`. A function (`Fn`) has `name`, `params`, `result`, `blocks`, `entry`, `block(name)`, `values()`, `clone()`, `hash()`.

## 5. Types, behaviours and operations

**Types** form a lattice of sets of kinds: `undefined null boolean int32 double string object function cell completion`. Named types: `t.bottom`, `t.number` (`int32|double`), `t.int32`, `t.double`, `t.boolean`, `t.string`, `t.object`, `t.function`, `t.cell`, `t.completion`, `t.null`, `t.undefined`, `t.propertyKey`, `t.any` (every JavaScript value), `t.top` (also cells and completions). `a.join(b)`, `a.meet(b)`, `a.minus(b)`, `a.le(b)`, `a.eq(b)`, `a.has('string')`, `a.managed` (holds a heap reference). `t.parse('number|string')`, `t.union(...)`, `t.ofValue(v)`.

**Representations** (`g.rep.tagged`, `f64`, `i32`, `bool`): how a value is stored after lowering. Tagged is the 64-bit NaN-boxed word Hermes uses; `f64` and `i32` are unboxed.

**Behaviours** (`g.fx`): `fx.none`, `fx.reads('heap')`, `fx.writes('heap')`, `fx.fresh` (allocates a new identity), `fx.throws`, `fx.diverges`, `fx.callsUser` (may run getters, `valueOf`, any user function: it reads and writes every user resource), `fx.host('print')`, `fx.unknown` (the top), `fx.join(a, b, …)`. Resources: `heap cells jobs timers globals` and `engine`. A behaviour has `.join`, `.eq`, `.le` and prints as `reads heap, throws`.

**Obligations** (`g.ob`): `ob.mayCollect` (a collection may move objects, so live references need roots), `ob.nonlocalThrow` (an exception may unwind past this call), `ob.writeBarrier`, `ob.protectsResult`, `ob.sharesBindingCells`, `ob.needsHost(cap)`; `ob.join(...)`.

**Operations.** `g.ops` holds the standard ones by name; `g.opsets` groups them:

| set | operations |
|---|---|
| `core` | `num.add sub mul div mod neg lt le gt ge eq ne`, `i32.add sub mul lt eq`, `bool.not and or`, `core.copy ref_eq is_number is_int32`, `core.call(@f)`, `host.print` |
| `js.value` | `js.add sub mul div mod neg lt le gt ge` (call user code through `valueOf`), `js.strict_eq strict_ne not truthy typeof` (pure), `str.concat` |
| `js.object` | `obj.new`, `arr.new`, `js.define`, `js.define_getter`, `js.define_setter`, `js.get`, `js.put`, `js.get_own_data`, `js.new_error[kind]` |
| `js.function` | `js.closure(@f)`, `js.call`, `js.call_method`, `cell.new load load_checked store`, `js.global_get put`, `js.type_error` |
| `js.control` | `job.enqueue`, `timer.set`, `promise.resolve`, `completion.normal return throw is[kind] value` |

`g.contract.table(['js.get', 'num.add'])` lists behaviour, obligations and permissions per operation. A `js.*` arithmetic operation has a **variant** for numbers: `js.add` narrows to `num.add` when both operands are known numbers (`g.op.narrow('js.add', [t.number, t.number])`).

**Permissions** (`g.perm(op, facts?)`): `{ erase, merge, move, duplicate, hoist, speculate, because }`, each `true`, `false` or a condition, with the reasons. `g.perm.explain(op, 'erase')` gives one answer and its reasons; `g.perm.commute(a, b)` says whether two operations may swap. More behaviour never grants a permission (`g.law.antitone()` checks it). `js.get` cannot be erased even when its result is unused: a getter may print or throw.

**Your own operations:**

```js
const square = g.op('num.square').operands(t.number).results(t.number)
  .behaviour(g.fx.none).step((machine, [x]) => x * x)
  .about('x times x').build();
g.opset('mine').ops(square).register();     // now the parser, verifier and interpreter know it
```

Builder methods: `operands`, `results`, `behaviour`, `obligations`, `step(fn(machine, args, op))`, `resultType(fn(types))`, `lower({ inline | helper | direct, code })`, `narrow(fn(types))`, `laws({ commutative, associative })`, `variadic()`, `about(text)`, `build()`. `g.op.opaque(name)` is an escape with unknown behaviour and every obligation. Registration is global for the page: pick names that will not clash.

## 6. Meaning: the reference interpreter

The **specification** is an interpreter over core IR. Every other mode is compared with it.

| call | does |
|---|---|
| `g.semantics()` | the interpreter for the `js` profile; `.profile('core')` for another |
| `sem.run(target, { args, entry, steps })` | run a function, module, Program or source: a RunResult |
| `g.profile(name)` | `core`, `js-sync`, `js-async` (= `js`); `.check(module)` lists operations outside it; `.and(other)` |
| `g.profile.define(name, { admits: [sets], observes })` | a new profile |
| `g.observe.equal(runA, runB)` | `{ equal, at, rule }`: every printed value in order, the outcome's kind, and an uncaught value by what it prints as; objects by identity up to a one-to-one renaming, numbers by SameValue, so `-0` differs from `0`; a run that stopped with an engine error gives `equal: 'unknown'` |
| `g.refines(target, source)` | runs both and compares them |

**RunResult** (`kind: 'run'`): `mode`, `gc`, `outcome` (`{ kind: 'normal' \| 'throw' \| 'diverge' \| 'error', value, display, message }`), `output` (the printed lines), `trace` (observations), `events` (`{ n, type, … }`: `print`, `throw`, `catch`, `job`, `timer`, `collect`, `stale`, `error`), `steps`, `records` (the first 4,000 steps: `{ n, fn, block, op, text, value, depth }`), `metrics` (`calls`, `allocations`, `collections`, `moved`, `maxDepth`, `peakRootSlots`, `rootBytes`, `jobs`), `error` (`{ message, at, stale }`), `jobsRun`.

A program's main runs first, then microtasks until the queue is empty, then timers in virtual time. The step budget is 200,000 unless `budget` says otherwise; running out gives `outcome.kind === 'diverge'`.

## 7. Analyses and the fixed-point solver

There is one solver. An **analysis** is a lattice, a direction and a transfer function; the solver iterates a worklist to a fixed point and records every step.

| lattice | elements |
|---|---|
| `g.lattice.powerset({ universe })` | sets; join is union |
| `g.lattice.flat(values)` | `BOT`, one value, `TOP` (constants) |
| `g.lattice.map(inner)` | maps from names to inner elements, pointwise |
| `g.lattice.types()` | the type lattice |
| `g.lattice.product(a, b, …)` | tuples |
| `g.lattice.interval()` | `[lo, hi]`, infinite height: needs `g.widen.thresholds([...])` |

Each has `bottom()`, `join(a, b)`, `le(a, b)`, `eq(a, b)`, `show(a)`.

Built in: `g.analysis.liveness` (backward), `g.analysis.typeFacts` (forward, refined on branches: after `branch core.is_number(x)` the true edge knows `x: number`, and `typeof x === "string"` refines too; `!==` does not refine yet, which is why `amount` stays `any` in the ledger's `deposit`; a direct call's result has the callee's declared type), `g.analysis.safepoints`, `g.analysis.dominators`. `g.solve(analysis, fn)` returns facts with `in`, `out`, `steps` (`{ i, block, before, after, changed }`, numbered from 1) and `iterations`.

Your own:

```js
const flat = g.lattice.flat();
const constants = g.analysis('constants').forward().lattice(g.lattice.map(flat))
  .transfer((op, state) => {
    if (!op.result) return state;
    const out = new Map(state);
    const val = a => (typeof a === 'string' ? (state.has(a) ? state.get(a) : flat.TOP) : a.lit);
    const [x, y] = op.args.map(val);
    out.set(op.result, op.op === 'num.add' && typeof x === 'number' && typeof y === 'number' ? x + y : flat.TOP);
    return out;
  });
const facts = g.solve(constants, fn);       // facts.out.entry.v2 === 9
```

An operand is a value name (a string) or a literal (`{ lit }`). Methods: `.forward()`, `.backward()`, `.lattice(l)`, `.transfer((op, state, { fn, block }) => state)`, `.edge(rule)` (`g.edge.substituteBlockArgs()` maps a target's parameters to the edge's arguments), `.widen(w)`, `.init(fn => boundaryState)`. `g.graph` and `g.solve(analysis, { kind: 'graph', nodes, edges })` run the same solver on any graph; `g.graph.scc(graph)` gives strongly connected components.

## 8. Rewrites

A **rewrite** matches operations, checks a side condition and returns an action. It fires only when the condition holds, and every attempt is logged in `program.decisions` with its reason.

```js
const mulOne = g.rewrite('mul-one')
  .match((m, site) => site.op.op === 'num.mul' && site.op.args[1] && site.op.args[1].lit === 1)
  .to(site => g.act.replaceWith(site.op.args[0]));
```

`match((m, site) => boolean | pattern)`: `m.op('js.*').resultUnused()`, `.inLoop()`, `.hasVariants()`, `.noResult()`. `when((site, ctx) => ({ ok, because }))`; `ctx.perm(op, facts)`, `ctx.typeAt(site, operand)`, `ctx.variantFor(site)`, `ctx.noWritesBetween(resource, block, i, j)`, `ctx.facts`. `to((site, ctx) => action)`: `g.act.erase()`, `g.act.replaceWith(operand)`, `g.act.replaceOp(name, args?)`. A `site` has `fn`, `block`, `index`, `op` (`{ op, args, result, attrs }`), `id`, `def` (the operation's definition) and `unused`.

Sets: `g.rewrites.canonical()` (copy propagation, constant folding, branch simplification, unreachable-block removal, erasing dead results that `perm.erase` allows), `g.rewrites.standard()` (adds narrowing by type facts and forwarding a cell store to the next load), `g.rewrites.none()`, `g.rewrites(r1, r2, …)`, `set.with(r)`. Single rewrites: `g.rewrites.constFold`, `copyProp`, `eraseDead`, `narrow`, `forwardCells`, and `g.rewrites.naiveDce`, which erases any unused result with no side condition: it is wrong on purpose (it deletes a throwing getter) and the laws catch it.

## 9. Pipelines, passes and programs

```js
const pipe = g.pipeline()
  .rewrites(g.rewrites.standard())
  .roots('stackReuse')                       // or roots(g.roots.distinct()), roots((fn, ctx) => …)
  .exceptions('setjmp')
  .assume({ fib: { n: 'number' } });         // what a JIT would speculate; unchecked
const program = g.compile(pipe, source());
```

| method | sets |
|---|---|
| `.profile(name)` | the language profile |
| `.frontend({ promote })` | `promote: false` keeps every variable a cell |
| `.assume({ fn: { param: type } })` | parameter types the facts may use; recorded in decisions as unchecked |
| `.provide(set, provider)` | `g.hermes.provider(set)` or `g.reference.provider(set)` |
| `.rewrites(set \| rewrite \| (defaultSet) => set)` | the rewrite set |
| `.representation(x)`, `.roots(x)`, `.exceptions(x)` | strategies (section 10) |
| `.materialize(g.llvm.orc() \| g.llvm.aot({ target }))` | the materialiser and target triple |
| `.checks({ verify, gcSafety, llvm })` | turn checks off (`gcSafety: false` makes missing roots warnings, so a broken plan can run and fail) |
| `.passes(list)`, `.insert(pass, { after \| before })`, `.stopAfter('L1')` | the pass list |
| `.use(preset, …)`, `.with(p => p…)`, `.set(key, value)` | presets as functions, a raw escape |
| `.check()` | `{ ok, diagnostics }`: pass requirements, strategy compatibility |
| `.summary()`, `.hash()`, `.resolved()` | what will run |

`g.pipeline({ roots: 'none', rewrites: g.rewrites.standard() })` is the same as the chained calls.

The default passes, in order: `frontend` (L0 → L1), `promote-cells`, `verify`, `rewrite`, `analyze` (liveness, safepoints, types, dominators), `lower-runtime` (L1 → L2: bind each operation to an inline instruction, a runtime helper or a direct call), `plan-roots` (L2 → L3), `check-plan`, `emit-llvm` (L3 → LLVM). Each pass declares what it requires and provides; `.check()` reports a pass whose requirement no earlier pass provides. `g.pass(name).from('L1').to('L1').requires(...).provides(...).invalidates(...).run((st, cfg) => note)` makes a pass; `st` holds `module`, `diagnostics`, `decisions`, `facts`, `plans`. `p1.then(p2)` sequences passes. `g.pass.verify`, `g.pass.rewrite` and the rest are the standard ones.

**Program** (`kind: 'program'`), from `g.compile(pipeline, source)`:

| member | is |
|---|---|
| `ok`, `name`, `source`, `module`, `compileMs` | |
| `functions()` | names, main first |
| `ir(level, { fn, format })` | text (or `format: 'json'`) of `L0` (source), `L1.cells` (before promotion), `L1` (core IR after rewrites), `L2` (bound to helpers), `L3` (with the root plan), `LLVM`, `WAT` |
| `cfg(fn)` | blocks, ops (`id`, `text`, `op`, `args`, `results`, `mayThrow`, `safepoint`), terminators and edges (`kind`: `jump`, `true`, `false`, `normal`, `throw`, `handler`) |
| `facts(fn)` | `{ live: { in, out, across }, types, safepoints, idom, iterations }`; `across['fn/block/i']` lists values live across that operation |
| `steps(fn, 'liveness' \| 'types')` | the solver's steps |
| `plan(fn)` | the L3 plan (section 10) |
| `perm(opId)` | the contract and permissions of one operation, with `resultUnused` |
| `why(target)` | an operation's contract, liveness, safepoint and every decision about it; `why('slot:fn/2')` explains a root slot |
| `find(pred)` | the operations whose summary `{ id, fn, block, index, op, text, result }` (`op` is the name) satisfies `pred`; returns those summaries |
| `diagnostics`, `trace` (`{ pass, level, ms, note }`), `decisions` (`{ by, at, op, fired, because }`) | |
| `summary()`, `metrics()` (`rootSlots`, `maxFrameSlots`, `peakLive`, `ops`, `rewritesFired`, `cellsPromoted`, `errors`, `compileMs`) | |
| `run({ mode, gc, entry, args, budget, jobs })` | a RunResult (section 12) |
| `wasm()` | `{ ok: [names], reasons, wat, bytes }` |
| `artifact` | a relocatable description for `engine.admit` |

## 10. Lowering: representations, roots and unwinding

A **safepoint** is an operation that may collect (its obligations include `mayCollect`). A moving collector may relocate every object at a safepoint, so each managed value the code still needs afterwards must sit in a **root slot** the collector updates. A value needs a slot at a safepoint when it is live across it, or when the safepoint's helper borrows it as an operand.

Root strategies (`g.roots.*`, or their names):

| strategy | plan |
|---|---|
| `distinct` | one slot per managed value, as the Hermes LLVM backend does today |
| `stackReuse` (default) | values never needed at the same safepoint share a slot (greedy colouring) |
| `arena` | slots in a growable arena instead of the native frame |
| `none` | no roots: the checker reports every missing one (a demonstration) |

A lambda strategy receives `(fn, ctx)` with `ctx.default()` (the plan of the strategy it wraps), `ctx.run(name)`, `ctx.types`, `ctx.live`, `ctx.sites`, `ctx.required(site)`, and returns `{ slotOf: { value: slot }, rootSlots, storage }` or a strategy. The checker verifies whatever plan comes back.

Exceptions (`g.exceptions.*`): `setjmp` (the Hermes protocol: a jump buffer per protected region, a `catch.dispatch` switch on a try state), `statusReturn` (helpers return a status the caller tests), `landingPads`. `g.compat(roots, exceptions)` says whether a pair is declared compatible; `g.compat.declare(r, e, { requires, evidence })` declares one. A non-setjmp strategy needs helpers that do not throw nonlocally, so it is refused while Hermes provides the JavaScript sets.

**Plan** (`program.plan(fn)`): `strategy`, `storage`, `rootSlots`, `fixedSlots` (2: scratch and discard), `argSlots` (the largest outgoing call), `frameSlots` (`rootSlots + 2 + argSlots` on the native stack), `frameBytes`, `peakLive`, `slots` (`[{ slot, values }]`), `safepoints` (a map from opId to `{ op, live, required, rooted, missing }`), `missing` (`[{ value, at, op, how, why }]`), `limit` (the native frame limit: 1,024 slots, as in the Hermes backend), `unwind`, `reps`.

**The L3 executor.** `program.run({ mode: 'plan', gc: 'stress' })` runs the lowered program with a simulated moving collector: at every safepoint (`stress`) or every 16 allocations (`alloc`) it copies every object reachable from the plan's rooted slots, the globals and the queues to new addresses, and frees the rest. A value read from a register that was not rooted then points at a freed or old address, and the run stops with `outcome.kind === 'error'`, a `stale` event and a message naming the value, the collection and the use. Runtime helpers hold their operands through handles, as a real runtime does, so only the compiled code's own registers can go stale.

## 11. Backends

**LLVM IR text.** `program.ir('LLVM')` prints the module in the shape of the Hermes LLVM backend: `define internal i64 @f(ptr %shr)`, `%frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 <slots>, i32 <args>, i32 0)`, root slots as `getelementptr i64, ptr %roots, i32 N`, helpers called with an out pointer first (`call void @shllvm_get(ptr %s2, ptr %shr, ptr %s2, ptr %scratch)`), numbers inline as `fadd double` on bitcast words, a string table indexed by `shllvm_constant`, literal operands written to `%scratch`, then `%discard`, then stack temporaries `%lit2`…, and for a function with a `try` a `setjmp` prologue with a `catch.dispatch` switch, every block storing its region's number in `%try_state` (0 outside every region). The text leaves out parts of the real protocol (`shllvm_catch_prepare`, `shllvm_try_end`), NaN canonicalisation after inline arithmetic, and any difference between exception strategies: `statusReturn` changes the plan, not the text. `g.llvm.check(text, declarations)` checks it structurally: labels defined once, every block terminated, locals defined before use, callees declared. It is not run: LLVM itself is not in the page.

**WebAssembly.** Functions in the core profile (numbers, booleans, direct calls, `host.print` of numbers) compile to a real Wasm binary: one `f64` local per value, block parameters as locals, and a dispatch loop with `br_table` over the blocks. `program.ir('WAT')` shows the text; `program.run({ mode: 'wasm', entry, args })` instantiates and runs it. A JavaScript function reaches the core profile when its parameters are known numbers: `.assume({ fib: { n: 'number' } })` with `g.rewrites.standard()` narrows `js.lt` to `num.lt` and so on. `g.wasm.eligible(module, fn, types)` gives the reason a function is refused.

## 12. Running

`program.run(opts)`:

| option | values |
|---|---|
| `mode` | `'spec'` (the interpreter on L1), `'plan'` (the L3 executor), `'wasm'` |
| `gc` | `'off'`, `'alloc'`, `'stress'` (plan mode only) |
| `entry`, `args` | a function other than main, with JavaScript arguments; captured cells and `this` are filled in, and a function that captures variables cannot run on its own |
| `budget` | a step budget (default 200,000) |
| `jobs` | how many queued jobs to run after main (default 10,000) |

`g.observe.equal(program.run(), program.run({ mode: 'plan', gc: 'stress' }))` is the check that lowering preserved behaviour on this input.

## 13. Engines and lifecycles

`g.engine({ mode, gc, strategies })` owns one execution domain: a heap, the job queues and the code it admitted.

| call | does |
|---|---|
| `engine.admit(programOrArtifact)` | checks before any code runs (compile errors, strategy mismatch: `AdmissionError` with `reason` and `ranCode: false`); returns a code handle; units are renamed `u1.main`, `u2.main` |
| `engine.evaluateScript(code)` | runs its main: `{ state: 'fulfilled' \| 'rejected', value, error }` |
| `engine.runJobs({ budget })` | `{ ran, remaining }` |
| `engine.run(program)` | admit, evaluate, run jobs |
| `engine.output()`, `.metrics()`, `.snapshot()` | |
| `engine.close()` | the runtime first, then the code; afterwards every call throws `EngineClosed` |

Lifecycles as labelled transition systems:

```js
const runtime = g.machine('runtime').state('alive').on('collect', 'alive').on('destroy', 'dead').final('dead');
const code = g.machine('code').state('loaded').on('call', 'loaded').on('release', 'freed')
  .state('freed').on('call', 'crash');
const both = g.machine.product(runtime, code).invariant('no call after free', s => s.code !== 'crash');
g.check.machine(both, { depth: 8 });   // { ok: false, violated, trace: ['release → alive, freed', 'call → alive, crash'] }
```

Machines synchronise on the labels they share; a label only one machine knows moves that machine alone. `check.machine` searches breadth-first to `depth` and returns the shortest trace to a violated invariant, or `{ ok: true, states, transitions }`.

## 14. Laws, generators and shrinking

Every law returns `{ name, ok, samples, counterexample?, minimized?, note? }`. `g.laws([law1, law2, …])` makes a LawReport for the Laws view.

| law | checks |
|---|---|
| `g.law.lattice(L)` | join commutative, associative, idempotent, order agreeing with join; `L` is `t` or any `g.lattice.*` |
| `g.law.join()` | behaviours form a join-semilattice with `fx.none` as unit and `fx.unknown` as top |
| `g.law.antitone()` | more behaviour never grants a permission |
| `g.law.monotone(analysis)` | `x ⊑ y` implies `f(x) ⊑ f(y)` on generated IR, for analyses over sets of value names (liveness and the like) |
| `g.law.refines(target, { corpus, samples, seed, gc })` | a rewrite, rewrite set, pipeline or root strategy preserves the observations of the specification, on a corpus of sources and `samples` generated programs; a failure is shrunk statement by statement |
| `g.law.idempotent(set)` | running a rewrite set twice changes nothing more (each run stops after 8 rounds, so two rules that undo each other can look stable: [T-08](lab:preset?id=T-08)) |
| `g.law.roundTrip()` | text and JSON of generated IR parse back to the same function |
| `g.law.variant('num.add', 'js.add')` | a variant agrees with the general operation on its operand types (`-0`, `NaN`, `2³¹` included) |
| `g.law.algebra(op, 'commutative' \| 'associative')`, `g.law.declared(opset)` | algebraic laws an operation declares (floating-point addition is not associative, and the law finds the counterexample) |
| `g.law.vectorSpace(unit)` | units add and scale |

Generators: `g.gen.coreIR({ seed, size })` (numeric IR with a diamond and a bounded loop), `g.gen.js({ seed, size })` (JavaScript statements over a throwing getter, loops, closures, jobs; `.statements` for shrinking; an occasional program repeats a declaration and does not compile, and laws skip it), `g.gen.fromStatements(list)`, `g.gen.values()`. `g.shrink(items, fails)` deletes items while `fails(items)` stays true.

## 15. Experiments and method

A **design** is a space of pipelines:

```js
const d = g.design({
  roots: g.param.choice(['distinct', 'stackReuse', 'arena']),
  rewrites: g.param.choice(['canonical', 'standard']),
}, p => g.pipeline().roots(p.roots).rewrites(g.rewrites[p.rewrites]()));
const results = g.search.grid(d, { corpus: [source()], objective: g.objective.minimize('rootSlots') });
return results;            // the Experiments view
```

`g.param.choice(values, { default, when })`, `g.param.range(lo, hi, { step })`. A design has `defaults()`, `points()`, `size()` (`{ raw, points }`), `at(point)`, `where(pred)`, `map(f)`, `sample({ n, seed })`. `g.constraint.compatible()` keeps points whose pipeline passes `.check()`.

`g.search.grid(design, { corpus, objective, run: { mode, gc } })` and `g.search.random(design, { budget, seed, … })` compile every point on every corpus item, run it in plan mode with GC stress and in the specification, and fill a row: `admitted`, `correct` (observations equal), `rootSlots`, `maxFrameSlots`, `peakLive`, `peakRootSlots`, `rootBytes`, `collections`, `steps`, `ops`, `rewritesFired`, `compileMs`. **Results** (`kind: 'results'`): `title`, `objective`, `columns` (`{ key, label, unit }`), `rows`, `best`, `frontier`, `note`. Under a Pareto objective every row is kept: the frontier first, each marked `onFrontier: true`, then the dominated points; each metric counts in its own direction (`rewritesFired` larger is better). `correct` compares the plan run with the specification run of the same compiled program, so it checks the lowering, not the rewrites (use `g.law.refines` for those).

Objectives: `g.objective.minimize(metric)`, `.maximize(metric)`, `.weighted({ rootSlots: 1, steps: 0.01 })`, `.lexicographic(['rootSlots', ['steps', { tolerance: 10 }]])`, `.pareto(['rootSlots', 'steps'])`, `.require('correct', 'admitted')` (feasibility; infeasible points rank last; `.require('correct').then(g.objective.minimize('steps'))` combines it with a ranking). `g.rank(results, objective)`, `g.rank.disagreement(results, a, b)` (where two objectives pick different winners). `g.metric(name, ({ program, run }) => number, { dir, unit })` adds a metric; `g.metrics.list()`. `g.table(rows, { title, columns })` makes Results from any rows.

`g.limit(name, { measure, max })` makes a check: `g.limit('native frame', { measure: p => slots(p.metrics().maxFrameSlots), max: slots(1024) }).check(program)`.

Decisions and processes are values too. `g.decision(question).context(text).options([...]).evidence([...]).counterexampleSought(text).choose(option).overturnIf(text)`; `.check()` lists what is missing (fewer than two options, no evidence, no counterexample sought, nothing that would overturn it). `g.process(name).step(n, spec).diverge(n).converge(n).critique(n).loop(n)`; `.check({ requires })` reports a divergence that never converges and required outputs no step produces.

## 16. lab: links

Notes, docs, the book and the agent's answers link into the workbench with `[text](lab:…)`.

| link | does |
|---|---|
| `lab:preset?id=I-03` | load a preset |
| `lab:book?ch=4&at=slug` | open a chapter (`P`, a number, `A`, `B`) at a heading |
| `lab:doc?id=ssa&at=slug` | open a shelf doc |
| `lab:open?file=main.js&line=12` (or `&find=text`) | open a file of the loaded preset in Code |
| `lab:fn?name=total` | show a function on the Stage |
| `lab:node?id=total/body/2` | select an operation, or a block (`total/body`) |
| `lab:level?l=L3` | the Stage and IR level |
| `lab:overlay?name=live&on=1` | an overlay: `live`, `safepoints`, `types`, `roots`, `path`, `exceptional`, `stale`, `iteration` |
| `lab:run?mode=plan&gc=stress` | set the run mode and rerun |
| `lab:step?n=40` | the Machine view at step 40 |
| `lab:analysis?name=liveness&i=2` | fixed-point step 2 in Facts and on the Stage |
| `lab:law?name=…` | run the preset's script and show that law |
| `lab:show?view=plan` | bring a view forward: `notes code agent docs book reference stage ir facts plan machine events laws experiments` |
| `lab:build` | rerun `main.js` |
| `lab:ask?q=…` | put a question in the agent's composer (it never sends) |

## 17. The agent's eval tool

The agent has one tool, `eval`, which runs JavaScript (an async function body; `return` a value) with this scope. Results come back as YAML, cut at 9,000 characters; a step times out after 25 s. Before each step the files are snapshotted, so any step can be reverted.

| group | names |
|---|---|
| files | `files.list()`, `files.read(path, from?, to?)` (numbered lines), `files.grep(pattern, path?)`, `files.edit(path, find, replace)` (the find text must match once), `files.write(path, text)` |
| the program | `run()` (rerun main.js: `{ ok, ms, kind, errors }`), `program()` (the current Program), `ir(level, fn)`, `cfg(fn)`, `facts(fn)`, `steps(fn, analysis)`, `plan(fn)`, `perm(opId)`, `why(target)`, `diagnostics()`, `exec(opts)` (run the current program: a RunResult summary) |
| the engine | `g`, `strata`, `t`, the units, `compile(src, pipeline?)` (`src` is text or a `g.source`) |
| presets | `presets.list()`, `presets.get(id)`, `presets.save({ title, group?, about, files, notes, tries? })` (a new U preset, its id returned), `presets.edit(id, patch)` and `presets.remove(id)` (U presets only), `presets.load(id)` |
| the bench | `notes()`, `setNotes(md)`, `doc(id)`, `book.contents()`, `book.chapter(n)`, `book.search(text)`, `book.open(n, at?)`, `link(href)`, `select(id)`, `show(view)`, `overlay(name, on)` |
| helpers | `console`, `log`, `lab` |

In Read-only mode `files.edit`, `files.write`, `run`, `setNotes` and `presets.save`, `edit` and `remove` throw. In Ask mode each step waits for approval.

A preset the agent saves is a folder like the built-in ones: `files` must hold a `main.js` that returns something from section 2, usually with a `program.js`; `notes` is Markdown that opens with a `#` title, says what is on the screen, and links into the workbench. Saved presets get ids `U-01`, `U-02`… and are kept in the artifact's storage for this viewer.
