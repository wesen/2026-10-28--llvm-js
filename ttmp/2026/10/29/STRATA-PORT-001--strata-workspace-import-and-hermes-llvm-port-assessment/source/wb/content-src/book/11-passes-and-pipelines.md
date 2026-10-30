# Passes and pipelines

A compiler is not one algorithm but a sequence of them, each consuming what the previous ones produced. This chapter makes that sequence a value you can read, check, branch and change. A **pass** is a named step from one IR level to another that declares what it needs and what it provides; a **pipeline** is an immutable value that resolves every choice (rewrites, strategies, checks, the passes themselves) and can say before compiling anything whether its passes fit together. By the end you will be able to insert a pass of your own, write a strategy as a lambda that wraps the default, package choices as presets, and explain why a pipeline of correct passes is correct.

[Chapter 10](lab:book?ch=10) ended with refinement being transitive. That fact carries this chapter.

## 11.1 What a pass is

Every pass is built the same way:

```js
// core.js
class Pass {
  constructor(spec) { Object.assign(this, { src: null, dst: null, needs: [], gives: [], kills: [], body: null }, spec); Object.freeze(this); }
  with(p) { return new Pass({ ...this, ...p }); }
  from(l) { return this.with({ src: l }); }
  to(l) { return this.with({ dst: l }); }
  requires(...f) { return this.with({ needs: f.flat() }); }
  provides(...f) { return this.with({ gives: f.flat() }); }
  invalidates(...f) { return this.with({ kills: f.flat() }); }
  run(f) { return this.with({ body: f }); }
  then(next) { return seqPass([this, next]); }
```

A pass has a name, the IR level it reads (`src`) and the level it leaves (`dst`), three lists of **products** (names of facts or properties: `core-ir`, `verified`, `liveness`) that it needs, gives and kills, and a body that runs on the compilation state. Each method returns a new pass, so a pass is a value like the rewrites of Chapter 10: `g.pass('count-ops').from('L1').to('L1').requires('verified')` is a description, inert until a pipeline runs it. `then` sequences two passes into one.

The default pipeline runs nine passes, and their declarations are the shape of the whole compiler:

| pass | levels | requires | provides |
|---|---|---|---|
| `frontend` | L0 → L1 | | core-ir |
| `promote-cells` | L1 | core-ir | ssa |
| `verify` | L1 | core-ir | verified |
| `rewrite` | L1 | verified | (invalidates the analyses) |
| `analyze` | L1 | verified | liveness, safepoints, types, dominators |
| `lower-runtime` | L1 → L2 | verified, types | runtime-bound |
| `plan-roots` | L2 → L3 | runtime-bound, liveness, safepoints | root-plan, unwind-plan |
| `check-plan` | L3 | root-plan | |
| `emit-llvm` | L3 → LLVM | root-plan | |

Read down the columns. The frontend turns source text into core IR ([Chapter 4](lab:book?ch=4)); promotion turns cells into SSA; the verifier checks the rules of [Chapter 3](lab:book?ch=3); the rewrites of Chapter 10 change the program, which makes any earlier analysis stale; the analyses of [Chapter 9](lab:book?ch=9) then run once on the final L1; lowering binds each operation to an inline instruction, a helper or a direct call (L2, [Chapter 12](lab:book?ch=12)); the root planner assigns slots (L3, [Chapter 13](lab:book?ch=13)); the checker verifies the plan; and the emitter prints LLVM IR ([Chapter 16](lab:book?ch=16)). Figure 11.1 draws the same chain.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 400">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="20" y="14" width="150" height="28" class="f-fill"/><rect x="20" y="56" width="150" height="28" class="f-paper"/><rect x="20" y="98" width="150" height="28" class="f-paper"/>
    <rect x="20" y="140" width="150" height="28" class="f-paper"/><rect x="20" y="182" width="150" height="28" class="f-paper"/><rect x="20" y="224" width="150" height="28" class="f-fill"/>
    <rect x="20" y="266" width="150" height="28" class="f-fill"/><rect x="20" y="308" width="150" height="28" class="f-paper"/><rect x="20" y="350" width="150" height="28" class="f-fill"/>
    <path d="M95,42 L95,54" marker-end="url(#arrow)"/><path d="M95,84 L95,96" marker-end="url(#arrow)"/><path d="M95,126 L95,138" marker-end="url(#arrow)"/>
    <path d="M95,168 L95,180" marker-end="url(#arrow)"/><path d="M95,210 L95,222" marker-end="url(#arrow)"/><path d="M95,252 L95,264" marker-end="url(#arrow)"/>
    <path d="M95,294 L95,306" marker-end="url(#arrow)"/><path d="M95,336 L95,348" marker-end="url(#arrow)"/>
    <path d="M560,14 L570,14 L570,42 L560,42"/><path d="M560,56 L570,56 L570,210 L560,210"/><path d="M560,224 L570,224 L570,252 L560,252"/>
    <path d="M560,266 L570,266 L570,336 L560,336"/><path d="M560,350 L570,350 L570,378 L560,378"/>
  </g>
  <g font-size="11" class="f-ink">
    <text x="30" y="33" class="b">frontend</text><text x="30" y="75" class="b">promote-cells</text><text x="30" y="117" class="b">verify</text>
    <text x="30" y="159" class="b">rewrite</text><text x="30" y="201" class="b">analyze</text><text x="30" y="243" class="b">lower-runtime</text>
    <text x="30" y="285" class="b">plan-roots</text><text x="30" y="327" class="b">check-plan</text><text x="30" y="369" class="b">emit-llvm</text>
  </g>
  <g font-size="10" class="f-mut">
    <text x="186" y="33">gives core-ir</text>
    <text x="186" y="75">needs core-ir · gives ssa</text>
    <text x="186" y="117">needs core-ir · gives verified</text>
    <text x="186" y="159">needs verified · kills the analyses</text>
    <text x="186" y="201">needs verified · gives liveness, safepoints, types, dominators</text>
    <text x="186" y="243">needs verified, types · gives runtime-bound</text>
    <text x="186" y="285">needs runtime-bound, liveness, safepoints · gives root-plan</text>
    <text x="186" y="327">needs root-plan · errors for missing roots</text>
    <text x="186" y="369">needs root-plan</text>
  </g>
  <g font-size="11" class="f-ink">
    <text x="578" y="32">L0 → L1</text><text x="578" y="137">L1</text><text x="578" y="242">L1 → L2</text><text x="578" y="305">L2 → L3</text><text x="578" y="368">L3 → LLVM</text>
  </g>
</svg>
```

**Figure 11.1.** The default pipeline, with what each pass needs and gives and the IR level it works at (brackets on the right). Shaded passes change the level. `rewrite` kills the analyses because it changes the program they describe, which is why `analyze` comes after it.

## 11.2 Requirements and products

The declarations are checked before anything runs. `pipeline.check()` walks the pass list keeping the set of products available so far:

```js
// core.js
  check() {
    const diags = [], have = new Set(), inserted = [];
    for (const p of this.passList()) {
      const missing = p.needs.filter(n => !have.has(n));
      if (missing.length) diags.push({ severity: 'error', kind: 'pass-requirements', pass: p.name, missing, message: `${p.name} needs ${missing.join(', ')}, which no earlier pass provides` });
      for (const g of p.gives) have.add(g);
      for (const k of p.kills) { if (k === 'analyses') ['liveness', 'safepoints', 'types', 'dominators'].forEach(x => have.delete(x)); else have.delete(k); }
    }
```

A pass whose requirement is not yet available is an error; a pass's products join the set; its kills leave it. Two broken pipelines show what this catches. `g.pipeline().passes([g.pass.frontend, g.pass.verify, g.pass.planRoots])` skips the analyses and lowering, and check reports `plan-roots needs runtime-bound, liveness, safepoints, which no earlier pass provides`. Subtler: inserting a second `rewrite` after `analyze` reports `lower-runtime needs types, which no earlier pass provides` and the same for `plan-roots`, because the late rewrite invalidated the facts the lowering would have used. A compiler without this bookkeeping would run the lowering on stale liveness and produce a root plan for a program that no longer exists. `g.compile` runs the check first and compiles nothing when it fails: the broken pipeline above returns a Program with `ok: false`, the diagnostic, and an empty trace.

The same check covers strategy choices ([Chapter 14](lab:book?ch=14)): `exceptions('statusReturn')` with the Hermes providers is refused here, before any code is lowered, for the reason [Chapter 6](lab:book?ch=6) quoted.

## 11.3 Pipelines are values

`g.pipeline()` with no arguments is the default pipeline, and every choice in it is visible. `pipeline.summary()` resolves them all into an object; condensed, the default's reads:

```text
rewrites:     copy-propagation, const-fold, simplify-branch, remove-unreachable, erase-dead-result
strategies:   representation tagged · roots stackReuse · exceptions setjmp
providers:    core reference · js.value, js.object, js.function, js.control hermes
materializer: llvm.orc · x86_64-linux-gnu · textual LLVM IR
checks:       verify true · gcSafety true · llvm true
passes:       frontend, promote-cells, verify, rewrite, analyze, lower-runtime, plan-roots, check-plan, emit-llvm
```

Each method returns a new pipeline and leaves the old one alone, so `const fast = base.rewrites(g.rewrites.standard())` is a branch, not an edit, and both can be compiled side by side. Every pipeline has a `hash()` of its resolved choices. The default hashes to `f7e93356`; asking for the default explicitly, `base.roots('stackReuse')`, gives the same hash, because a pipeline is identified by what it resolves to, not by how it was written.

Every strategy slot (`roots`, `exceptions`, `representation`) takes four forms, and one function turns each into a strategy:

```js
// core.js
function slotValue(slot, x, prev) {
  if (x === undefined || x === null) return null;
  if (x instanceof Strategy) return x;
  if (typeof x === 'function') return new Strategy(slot, x.strategyName || 'custom', {}, x, (prev && !prev.fnImpl ? prev.name : null) || defaultStrategy(slot).name);
  if (typeof x === 'string') return strat(slot, x);
```

Nothing means the default. A string names a library strategy (`'distinct'`). An object adjusts the parameters of the current one, and for roots `{ reuse: false }` means `distinct`. A function is a **lambda strategy**: it receives the function being lowered and a context whose `ctx.default()` runs the strategy it wraps, so it can refine the opinion instead of replacing it. The lambda records which strategy it wraps, and the compatibility checks of Chapter 14 use that. Here is one (ours) that keeps the default everywhere except `total`, where it asks for one slot per value:

```js
const pipe = g.pipeline().roots((fn, ctx) => (fn.name === 'total' ? ctx.run('distinct') : ctx.default()));
```

On the ledger it compiles; `total` gets 7 root slots instead of 3, and the program's total rises from 15 to 19. Whatever plan a lambda returns, the plan checker of Chapter 13 verifies it, so a lambda can make a plan worse but cannot make a wrong one pass. [B-02 One default at a time](lab:preset?id=B-02) walks through the four forms side by side.

> **Try it.** [Load B-02](lab:preset?id=B-02), [open main.js](lab:open?file=main.js&find=g.pipeline()) to read the four pipelines it builds, one from the next, and [show the Experiments](lab:show?view=experiments) for their root slots compared.

## 11.4 Inserting a pass

A pass of our own counts the operations after the rewrites:

```js
const countOps = g.pass('count-ops').from('L1').to('L1').requires('verified').run(st => {
  let n = 0;
  for (const f of st.module.functions.values()) for (const b of f.blocks) n += b.ops.length;
  return `${n} operations`;
});
const program = g.compile(g.pipeline().insert(countOps, { after: 'rewrite' }), source('program.js'));
```

`insert` places it in the default list; the body receives the compilation state (the module, the diagnostics, the decisions, and the facts and plans once they exist) and returns a note for the trace. On the ledger the trace gains a line `count-ops L1 63 operations` between `rewrite` and `analyze`; 63 operations plus 15 terminators are the 78 that `program.metrics().ops` reports. Inserted `before: 'verify'`, the same pass fails the check with `count-ops needs verified`: the declaration says the body assumes verified IR, and the pipeline will not run it on anything else. `stopAfter('L1')` cuts the list at a level: the ledger then compiles through `analyze` and `program.ir('L3')` reports `; L3 was not produced`. [T-06 Passes and their requirements](lab:preset?id=T-06) builds and breaks such pipelines.

## 11.5 Presets as functions

A group of choices that belong together is a **preset**: a function from a pipeline to a pipeline.

```js
const lean = p => p.rewrites(g.rewrites.standard()).roots('stackReuse');
const strict = p => p.checks({ verify: true, gcSafety: true, llvm: true });
const pipe = g.pipeline().use(lean, strict);
```

`use` applies them left to right; `with(p => …)` applies one inline function; `set(key, value)` stores a raw value for passes that want one. Because presets are functions on values, they compose and they are honest about what they do: `g.pipeline().use(lean, strict)` hashes to `cbe33fa7`, exactly the hash of `g.pipeline().rewrites(g.rewrites.standard())`, since the other choices restate defaults. Figure 11.2 shows a few branches of the default pipeline with their hashes, measured in the engine.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 240">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="20" y="96" width="150" height="44" class="f-fill" stroke-width="1.6"/>
    <rect x="260" y="20" width="190" height="44" class="f-paper"/>
    <rect x="260" y="96" width="190" height="44" class="f-paper"/>
    <rect x="260" y="172" width="190" height="44" class="f-paper"/>
    <rect x="500" y="96" width="160" height="44" class="f-paper"/>
    <path d="M170,110 L258,46" marker-end="url(#arrow)"/>
    <path d="M170,118 L258,118" marker-end="url(#arrow)"/>
    <path d="M170,126 L258,190" marker-end="url(#arrow)"/>
    <path d="M450,118 L498,118" marker-end="url(#arrow)"/>
    <path d="M355,216 C355,236 95,236 95,142" class="dash" stroke-dasharray="4 3" marker-end="url(#arrow)"/>
  </g>
  <g font-size="11" class="f-ink">
    <text x="30" y="114" class="b">g.pipeline()</text><text x="30" y="130" font-size="10" class="f-mut">f7e93356 · 15 root slots</text>
    <text x="270" y="38">.roots('distinct')</text><text x="270" y="54" font-size="10" class="f-mut">d16b952e · 52 root slots</text>
    <text x="270" y="114">.rewrites(standard)</text><text x="270" y="130" font-size="10" class="f-mut">cbe33fa7 · 15 root slots</text>
    <text x="270" y="190">.roots('stackReuse')</text><text x="270" y="206" font-size="10" class="f-mut">f7e93356 · the same value</text>
    <text x="510" y="114">.roots('distinct')</text><text x="510" y="130" font-size="10" class="f-mut">bf0c81eb · 51 root slots</text>
  </g>
</svg>
```

**Figure 11.2.** Pipelines as values: each method returns a new pipeline, identified by the hash of what it resolves to, with the total root slots it gives the ledger. Asking for the default strategy by name returns the default pipeline itself (dashed). The standard rewrites save one slot under `distinct` (51 against 52), in `main`, where store-to-load forwarding removed a `cell.load` and with it one managed value.

[T-07 Pipelines as values](lab:preset?id=T-07) compares branches like these side by side.

## 11.6 Why correct passes compose

Each pass makes one of three kinds of promise. An **analysis** pass (`analyze`) does not change the program: it adds facts, and its correctness is that the facts are true, which for the solver of [Chapter 8](lab:book?ch=8) follows from monotone transfer functions and the least fixed point. A **transforming** pass (`promote-cells`, `rewrite`) changes the program at the same level, and its correctness is refinement: the result refines its input. A **lowering** pass changes the level, and its correctness is refinement across levels: the lowered program, run by its own machine, shows only behaviours of the input. In the workbench that machine is the L3 executor with the simulated collector, and the criterion is that `program.run({ mode: 'plan', gc: 'stress' })` is observationally equal to `program.run({ mode: 'spec' })`.

Because refinement is transitive, these promises chain. If $P_1 \sqsubseteq P_0$ (promotion), $P_2 \sqsubseteq P_1$ (rewrites) and $P_3 \sqsubseteq P_2$ (lowering and planning), then $P_3 \sqsubseteq P_0$: the lowered program shows only behaviours of the source. No pass needs to know what the others did, only that its own input is a program at its level with the products it requires. That is why the requirement check of Section 11.2 and refinement are two halves of one contract: requirements make sure each pass gets an input it understands, refinement makes sure it does not change what that input means. A third check guards the strategies themselves, since an exception strategy and a root strategy can each be correct and still be wrong together ([Chapter 14](lab:book?ch=14)).

The engine tests the chained claim directly. `g.law.refines(pipeline, { corpus, samples })` compiles each program with the pipeline, runs the lowered result in plan mode with GC stress, and compares it with the specification of the unrewritten source. It tests the composition end to end, which catches what no single pass's check could: a correct rewrite that produces IR the planner mishandles, for instance.

## 11.7 The running example: the ledger through nine passes

The trace of [B-01](lab:preset?id=B-01) records one line per pass (FACTS.md has the full table):

| pass | note |
|---|---|
| `frontend` | 6 functions |
| `promote-cells` | 11 cells promoted |
| `verify` | ok |
| `rewrite` | 0 rewrites fired |
| `analyze` | liveness 20 block visits |
| `lower-runtime` | bound to providers |
| `plan-roots` | 15 root slots in 6 functions |
| `check-plan` | every collecting point roots what it needs |
| `emit-llvm` | textual LLVM IR, structurally checked |

The notes are the pipeline's account of itself, and each refers to a chapter: the 11 promoted cells to [Chapter 4](lab:book?ch=4), the 20 liveness visits (8 of them in `total`) to Chapter 9, the 15 slots to Chapter 13. Change one choice and the trace changes where it should: with the standard rewrites the `rewrite` line reports the four firings of [Chapter 10](lab:book?ch=10), the slots stay at 15, and `g.law.refines(g.pipeline().rewrites(g.rewrites.standard()), { corpus: [ledger], samples: 40 })` passes on all 41 programs, each run lowered under GC stress against its specification.

> **Try it.** [Load B-01](lab:preset?id=B-01), [open main.js](lab:open?file=main.js&find=g.pipeline()) and replace `g.pipeline()` with `g.pipeline().insert(countOps, { after: 'rewrite' })`, defining `countOps` as in Section 11.4 above it. [Rerun](lab:build) and [show the Events](lab:show?view=events): the trace has a tenth line, `count-ops`.

## 11.8 Key points

A pass is a named, immutable step between IR levels that declares the products it requires, provides and invalidates; the default pipeline runs nine of them from source to LLVM text. `pipeline.check()` verifies before compiling that every requirement is provided by an earlier pass and not invalidated since, and `g.compile` refuses a pipeline that fails it. Pipelines are values with visible defaults and hashes of their resolved choices; every strategy slot accepts nothing, a name or parameters, a strategy, or a lambda that can call `ctx.default()`. Presets are functions from pipelines to pipelines and compose with `use`. Analysis passes add true facts, transforming and lowering passes refine their input, and because refinement is transitive the whole pipeline refines the source; the refinement law checks that claim end to end on generated programs.

## Exercises

1. In [T-06](lab:preset?id=T-06) or B-01, build `g.pipeline().passes([g.pass.frontend, g.pass.promoteCells, g.pass.verify, g.pass.analyze, g.pass.lowerRuntime, g.pass.planRoots, g.pass.checkPlan, g.pass.emitLLVM])`. Does it pass `check()`? What did you leave out, and what does the ledger lose?
2. Write a pass `count-safepoints` that requires `safepoints` and reports how many safepoints each function has. Where must it go in the list, and what does `check()` say if you put it before `analyze`?
3. Write a lambda root strategy that uses `distinct` for any function with more than one block and the default otherwise. Compare its total root slots on the ledger with Figure 11.2.
4. Make two presets, `debug` (no rewrites, every check) and `fast` (standard rewrites, `stackReuse`), and compute the hashes of `use(debug, fast)` and `use(fast, debug)`. Are they equal? Explain from what each preset sets.
5. A project: write a pass that runs `g.law.refines` on the program being compiled (comparing the module before and after `rewrite`) and adds a diagnostic when the observations differ. What does it require and provide, and what would it cost on every compile?

[Chapter 12](lab:book?ch=12) begins the lowering: how values become machine words, and how each operation is bound to an instruction or a helper.
