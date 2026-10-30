# Laws, fuzzing and shrinking

A compiler is correct when every program it accepts behaves as its specification says, and no finite set of hand-written tests covers every program. This chapter shows how the workbench tests the claims earlier chapters made: by stating each claim as a **law** that can be run, checking it on inputs the workbench generates itself, and cutting a failing input down to a small one a person can read. It ends with differential testing, which compares whole executions instead of checking a stated property, and with the bug in the workbench's own specification that such a comparison found. By the end you will know how to turn a sentence such as "this rewrite preserves behaviour" into a check, how to read its counterexample, and why the smallest counterexample is not always the right one.

## 19.1 A law is a property you can run

A **property** is a statement that should hold for every input of some kind: for all behaviours $a$ and $b$, $a \sqcup b = b \sqcup a$. A law in the workbench is a property packaged with a way to draw inputs and a report. Every law returns the same shape, `{ name, ok, samples, counterexample?, minimized?, note? }`, so the Laws view can show any of them and the agent can read any of them. Testing properties on random inputs is the method of QuickCheck (Claessen and Hughes, 2000); the workbench follows it closely.

Most laws in the engine check the algebra that earlier chapters relied on. The measured results are in FACTS.md:

| law | samples | ok | what it protects |
|---|---|---|---|
| `lattice(types)` | 2,000 | yes | the type facts of [Chapter 9](lab:book?ch=9) are joins in a lattice |
| `join(fx)` | 2,000 | yes | behaviours form a join-semilattice ([Chapter 6](lab:book?ch=6)) |
| `antitone(perm)` | 5,000 | yes | more behaviour never grants a permission ([Chapter 7](lab:book?ch=7)) |
| `monotone(liveness)` | 500 | yes | the solver's fixed point exists ([Chapter 8](lab:book?ch=8)) |
| `roundTrip(text and JSON)` | 100 | yes | printing and parsing IR lose nothing |
| `idempotent(rewrites)` | 50 | yes | the canonical form is a fixed point of the rewrites |
| `associative(num.add)` | 1 | no | floating-point addition is not associative |
| `variant(i32.add of num.add)` | 2 | no | 32-bit addition wraps; double addition does not |

The two failures are true statements about arithmetic, and they are in the table on purpose: a law that cannot fail tests nothing. The associativity law is short enough to read whole:

```js
// core.js
  algebra(d, which, { samples = 2000, seed = 1 } = {}) {
    const r = rng(seed), m = new Machine(new Module([]));
    const val = () => (d.operands[0].le(t.int32) ? r.int(-2147483648, 2147483647) : r.pick([0.1, 0.2, 0.3, 1e16, -1e16, 1, 3, -0, 0.5]));
    for (let i = 0; i < samples; i++) {
      const a = val(), b = val(), c = val(), f = (x, y) => d.step(m, [x, y], { attrs: {} });
      const ok = which === 'commutative' ? Object.is(f(a, b), f(b, a)) : Object.is(f(f(a, b), c), f(a, f(b, c)));
```

It draws operands from the operation's own operand type: any 32-bit integer for `i32` operations, and for doubles a pool chosen to cause trouble ($0.1$, $10^{16}$, $-0$). It evaluates both sides with the operation's reference step, the same function the interpreter uses, and compares with `Object.is`, which is SameValue, so $-0$ and $+0$ differ. With seed 1 the first sample fails: $(1 + 0.1) + (-10^{16})$ is $-9999999999999998$ and $1 + (0.1 + (-10^{16}))$ is $-10^{16}$. A rewrite that reassociated `num.add` would change printed output, and this is the evidence that the contract of `num.add` must not declare associativity. The same law on `i32.add` passes 2,000 samples, because addition modulo $2^{32}$ is associative.

> **Try it.** [Load M-01 Laws as tests](lab:preset?id=M-01) and [show the Laws](lab:show?view=laws): twelve of the engine's laws in one report, eleven passing, and [the failing one](lab:law?name=associative%28num.add%29) with the counterexample above.

The seed matters. A law with a fixed seed is a deterministic test: the same run produces the same counterexample tomorrow, so a failure can be reported, reproduced and fixed. Changing the seed explores other inputs.

## 19.2 Generators

Algebraic laws need values. Laws about the compiler need programs, and the workbench has two **generators**.

`g.gen.coreIR({ seed, size })` builds a numeric function in core IR: a few arithmetic operations on two parameters, a branch into two blocks, a bounded loop carrying an accumulator, and prints. Every generated function is in the core profile, so it runs in the interpreter, in the L3 executor and as WebAssembly. Seed 2 gives:

```text
fn gen2(a: number, b: number) -> number {
entry:
  v1 = num.add(a, b)
  v2 = num.sub(b, a)
  v3 = num.add(b, v1)
  v4 = num.lt(v2, b)
  branch v4, left(v3), right(a)
left(x: number):
  v5 = num.mul(x, 1)
  jump loop(0, v5)
right(y: number):
  jump loop(0, y)
loop(i: number, acc: number):
  v6 = num.lt(i, 1)
  branch v6, body(i, acc), done(acc)
body(i1: number, acc1: number):
  v7 = num.add(acc1, i1)
  v8 = num.add(i1, 1)
  jump loop(v8, v7)
done(z: number):
  host.print(z)
  return z
}
```

`g.gen.js({ seed, size })` builds JavaScript instead, from statement templates aimed at the hard cases of this book: an object with a getter that increments a counter and, depending on the seed, returns or throws; `try` with `catch` and with `finally`; loops; closures; a queued job. The generator keeps the statements as a list beside the text, because the list is what shrinking works on (section 19.4). These programs leave the core profile almost at once, so they test the JavaScript half of the compiler: contracts, permissions, cells, exceptions, roots.

A generator is a bet about where bugs are. Uniformly random programs are mostly uninteresting; these templates put a side-effecting getter into nearly every program because the throwing getter of [Chapter 7](lab:book?ch=7) is the case that separates a sound optimiser from an unsound one.

## 19.3 Refinement on generated programs

The central law is `g.law.refines(target, { corpus, samples })`, the executable form of the refinement criterion of [Chapter 10](lab:book?ch=10): the transformed program's observations must equal the original's. For each input it calls this function:

```js
// core.js
function refinesOne(target, item, { mode, gc, base } = {}) {
  const p0 = (base || pipeline()).rewrites(rewrites.none());
  const before = compile(p0, item).run({ mode: 'spec' });
  let after;
  if (target instanceof Rewrite || (target && target.kind === 'rewrites')) after = compile(p0.rewrites(target instanceof Rewrite ? rewriteSet(target) : target), item).run({ mode: 'spec' });
  else if (target instanceof Pipeline) after = compile(target, item).run({ mode: mode || 'plan', gc });
  else if (target instanceof Strategy) after = compile(p0.roots(target), item).run({ mode: 'plan', gc });
  else throw new StrataError('refines takes a rewrite, a rewrite set, a pipeline or a root strategy');
  if (before.outcome.kind === 'error') return { ok: true, skipped: true };
  const eq = observeEqual(after, before);
```

The reference is always the same: the program with no rewrites, run by the interpreter. What is compared depends on the target. A rewrite or a set of rewrites is run in spec mode, so the law isolates what the rewrites did. A whole pipeline or a root strategy is run in plan mode with GC stress by default, so the law also covers lowering: the root plan, the simulated collector and the stale-reference check of [Chapter 13](lab:book?ch=13). Inputs whose reference run ends in an engine error are skipped, since there is nothing to compare against. The comparison is `observe.equal` from [Chapter 2](lab:book?ch=2): printed values by SameValue, outcomes, thrown values and object identity up to renaming.

Two measurements show the law working in both directions. On 100 programs from `g.gen.js` (seeds 1 to 100), the pipeline with the standard rewrites refines the specification on every one, plan mode under GC stress included; the check took 4,175 ms in Node. With `g.rewrites.naiveDce` the law fails on the first generated program. Its reference run prints `2`, `no throw`, `finally 2`, `job 9`; after naive dead-code elimination the same program prints `0`, `no throw`, `finally 0`, `job 7`, because the rewrite deleted every `r.x` whose result nobody used, and with it every increment the getter performs.

> **Try it.** [Load M-02 Fuzzing a pipeline](lab:preset?id=M-02) and [show the Laws](lab:show?view=laws): four refinement laws on 20 generated programs each, the pipelines and root strategies holding and naive DCE failing on the first program. Or [load B-01](lab:preset?id=B-01) and [ask the agent to run the refinement law](lab:ask?q=Run%20g.law.refines(g.rewrites.naiveDce%2C%20%7B%20samples%3A%2020%20%7D)%20and%20explain%20the%20counterexample%20and%20its%20minimized%20form.) for naive DCE on 20 generated programs.

## 19.4 Shrinking a counterexample

A generated counterexample is a valid failure but rarely a clear one. The one above has nine statements, most of them irrelevant. **Shrinking** searches for a smaller input that still fails. The workbench uses the simplest form of delta debugging (Zeller's method, restricted to single deletions):

```js
// core.js
function shrink(items, fails) {
  let cur = items.slice(), changed = true;
  while (changed) {
    changed = false;
    for (let i = 0; i < cur.length; i++) {
      const trial = cur.slice(0, i).concat(cur.slice(i + 1));
      if (trial.length && fails(trial)) { cur = trial; changed = true; break; }
    }
  }
  return cur;
}
```

It tries deleting each statement in turn. The first deletion after which the program still fails is kept, and the scan starts again from the first statement. When no single deletion preserves the failure, the result is **1-minimal**: removing any one statement makes the failure disappear. The cost is at most $n$ trials per accepted deletion, so $O(n^2)$ runs of the law for $n$ statements; for programs of ten statements that is a few dozen runs.

`law.refines` shrinks with the predicate "refinement still fails". For the counterexample above it returns one statement:

```js
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
```

That program does fail refinement, but for a different reason. With the declarations of `cell` and `r` deleted, both names are undeclared globals. The reference run throws a ReferenceError at `r.x` and then another from the `finally` block, printing nothing. Naive DCE deletes the unused global read `r.x`, so the rewritten program prints `no throw` before the `finally` block throws. The shrinker removed the getter, the very thing the bug is about, and found a second bug instead (deleting a read that throws). This drift from one failure to another is called **slippage**, and it is the main weakness of shrinking by a yes-or-no predicate.

The remedy is a sharper predicate. Requiring the reference run to end normally, so that only programs which really compute something count, gives three statements after 25 trials:

```js
let cell = { n: 0 };
const r = { get x() { cell.n += 1; return cell.n; } };
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
```

The reference prints `no throw`, `finally 1`; after naive DCE it prints `no throw`, `finally 0`. This is the throwing-getter argument of [Chapter 7](lab:book?ch=7) found by a machine: a getter's side effect made visible by a later read. Figure 19.1 plots both shrinks trial by trial, and [M-03 Shrinking a counterexample](lab:preset?id=M-03) runs both in the page: [load it](lab:preset?id=M-03) and [show the Laws](lab:show?view=laws).

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 240">
  <line x1="60" y1="200" x2="620" y2="200" stroke="currentColor" class="ink"/>
  <line x1="60" y1="200" x2="60" y2="28" stroke="currentColor" class="ink"/>
  <g font-size="9" class="mut">
    <text x="57" y="214">0</text><text x="166" y="214">5</text><text x="274" y="214">10</text><text x="384" y="214">15</text><text x="494" y="214">20</text><text x="604" y="214">25</text>
    <text x="48" y="203">0</text><text x="48" y="149">3</text><text x="48" y="95">6</text><text x="48" y="41">9</text>
  </g>
  <g stroke="currentColor" class="hair" stroke-width="0.6">
    <line x1="60" y1="146" x2="620" y2="146"/><line x1="60" y1="92" x2="620" y2="92"/><line x1="60" y1="38" x2="620" y2="38"/>
  </g>
  <text x="300" y="232" font-size="10" class="lbl">trial</text>
  <text x="6" y="24" font-size="10" class="lbl">statements</text>
  <polyline fill="none" stroke="currentColor" class="ink" stroke-width="1.6" points="60,38 126,38 126,56 192,56 192,74 280,74 280,92 368,92 368,110 456,110 456,128 544,128 544,146 610,146"/>
  <polyline fill="none" stroke="currentColor" class="acc dash" stroke-width="1.6" points="60,38 104,38 104,56 148,56 148,74 192,74 192,92 214,92 214,110 258,110 258,128 302,128 302,146 346,146 346,164 390,164 390,182"/>
  <text x="480" y="164" font-size="10">3: the getter&#8217;s effect</text>
  <text x="400" y="186" font-size="10">1: a different failure</text>
</svg>
```

**Figure 19.1.** Size of the current counterexample after each trial, measured on the naive-DCE failure from `g.gen.js` seed 1 (nine statements). Solid: the predicate requires the reference run to end normally; 25 trials, three statements. Dashed: the law's own predicate; 15 trials, one statement that fails for another reason.

## 19.5 Differential testing

A law checks one stated property. **Differential testing** runs the same input through two or more implementations that should agree and compares everything they observe, without stating why they should agree. The workbench has three implementations of the core profile: the interpreter on L1, the L3 executor with the simulated collector, and the WebAssembly binary of [Chapter 15](lab:book?ch=15). For 200 functions from `g.gen.coreIR` (seeds 1 to 200), each run with four argument pairs (including $-0$ and $2.5$), all three agreed on all 800 runs: return values by SameValue and 1,924 printed lines. The comparison took 2,676 ms. Figure 19.2 shows its structure.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 220">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="85" width="120" height="44" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="30" y="104" font-size="11" class="b">gen.coreIR</text>
  <text x="30" y="120" font-size="10">seed, arguments</text>
  <rect x="230" y="20" width="170" height="40" class="ink f-fill2" stroke="currentColor"/>
  <text x="240" y="44" font-size="10">interpreter on L1 (spec)</text>
  <rect x="230" y="88" width="170" height="40" class="ink f-fill2" stroke="currentColor"/>
  <text x="240" y="112" font-size="10">L3 executor, GC stress</text>
  <rect x="230" y="156" width="170" height="40" class="ink f-fill2" stroke="currentColor"/>
  <text x="240" y="180" font-size="10">Wasm binary in the page</text>
  <line x1="140" y1="100" x2="228" y2="44" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="140" y1="107" x2="228" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="140" y1="114" x2="228" y2="172" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <rect x="490" y="80" width="170" height="56" class="acc f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="500" y="100" font-size="11" class="b">observe.equal</text>
  <text x="500" y="116" font-size="10">output, value, outcome</text>
  <text x="500" y="130" font-size="10">800 of 800 agree</text>
  <line x1="400" y1="40" x2="488" y2="96" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="400" y1="108" x2="488" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="400" y1="176" x2="488" y2="122" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
</svg>
```

**Figure 19.2.** Three-way differential testing of the core profile. One generated function and its arguments go to three implementations; their observations are compared pairwise with `observe.equal`. The count is from the run described in section 19.5.

Agreement among the workbench's own implementations says nothing about whether the specification matches JavaScript. For that the comparison has to leave the workbench. Running the promise programs of [Chapter 17](lab:book?ch=17) in Node beside the interpreter showed one disagreement: when a `then` handler returns a promise, the workbench adopts it one job earlier than the standard requires. Differential testing found the difference; it could not say which side was wrong. Reading the standard settled that the workbench was, and the chapter documents the defect. Every differential test ends the same way: a disagreement is a question, and the answer comes from a specification that someone has to read.

[M-04 Differential testing](lab:preset?id=M-04) runs the three-way comparison in the page, [M-02 Fuzzing a pipeline](lab:preset?id=M-02) runs the refinement law on generated programs, and [J-08 A generated program](lab:preset?id=J-08) shows one output of `g.gen.js` compiled and checked.

## 19.6 The running example: the ledger as a test

The ledger is a hand-written program, and the laws accept a corpus of hand-written programs as well as generated ones. Two measurements make it a regression test. `g.law.refines(g.pipeline(), { corpus: [ledger] })` passes: under GC stress the lowered ledger prints the same three lines as the specification, and FACTS.md records `observe.equal` as equal on 3 observations. `g.law.refines(g.rewrites.naiveDce, { corpus: [ledger] })` fails at once, and the failure is worse than the generated one. Naive DCE fires three times in `main`, at `main/entry/5`, `main/entry/7` and `main/try3/1`, the three `ledger.deposit(…)` calls whose results the script ignores. The rewritten ledger prints `main 0 0` and `audit 0`: no deposit happens and no rejection is printed.

> **Try it.** [Load B-01](lab:preset?id=B-01), [select the first deposit call](lab:node?id=main/entry/5), and read the Inspector's permissions: `erase` is refused with five reasons. [M-01 Laws as tests](lab:preset?id=M-01) collects the engine's laws into one report, and [M-03 Shrinking a counterexample](lab:preset?id=M-03) repeats section 19.4 step by step.

A test suite for a real compiler is this pattern repeated: a corpus of programs that matter, generators aimed at the hard cases, laws for every algebraic claim, and a differential comparison against an independent implementation. The shelf doc [Property testing and shrinking](lab:doc?id=property-testing) summarises the method on one page.

## 19.7 Key points

- A law is a property with a sampler and a report; a fixed seed makes it a deterministic test, and a law that cannot fail tests nothing.
- The engine's laws check its algebra (lattices, behaviours, permissions, monotonicity, round trips, idempotence) and record two true failures of arithmetic: floating-point associativity and 32-bit wrapping.
- `g.law.refines` compares a transformed program with the unrewritten one run by the interpreter; pipelines and root strategies are checked in plan mode under GC stress.
- Shrinking deletes statements while the failure persists and returns a 1-minimal input; a coarse predicate lets the failure slip to a different bug, and a sharper predicate keeps it.
- Differential testing compares implementations without stating a property; agreement among the workbench's own executions is not agreement with JavaScript, and a disagreement still needs a specification to resolve.

## Exercises

1. Run `g.law.algebra(g.ops['num.mul'], 'associative')` and `g.law.algebra(g.ops['num.add'], 'commutative')`. Which fails, and what is the smallest counterexample you can find by hand?
2. Change the seed of the refinement law for naive DCE from 1 to 2, 3 and 4. Does each fail on its first program? Shrink each with the sharper predicate of section 19.4 and compare the results.
3. Write a predicate for `g.shrink` that also requires the first differing observation to be a printed number, and shrink the seed 1 counterexample with it. Is the result different from the three statements above?
4. Extend the three-way comparison of section 19.5 to 1,000 generated functions and to arguments drawn from `g.gen.values()` that are numbers. Report the agreement count and the run time.
5. Project: add a template to a copy of `g.gen.js` that writes through a setter, and check whether `g.rewrites.standard()` still refines the specification on 100 programs. If it fails, shrink the counterexample and explain it.

The next chapter turns from checking a single design to comparing many: design spaces of pipelines, the metrics that measure them, and the objectives that rank them.
