# Rewrites and refinement

An optimiser is a collection of small local changes to a program, each of which must leave the program's meaning alone. This chapter makes both halves precise. A **rewrite** is a match, a side condition and an action, and every attempt to apply one is logged with its reason. **Refinement** is what "leaves the meaning alone" means: the rewritten program shows no behaviour the original could not show. You will see the standard rewrites at work on a small program and on the ledger, watch naive dead-code elimination fail and the refinement law catch it, write a rewrite of your own and catch a subtly wrong one, and learn why the standard sets are run to a fixed point that does not change when run again.

[Chapter 7](lab:book?ch=7) supplied the permissions rewrites ask for and [Chapter 9](lab:book?ch=9) the facts. Here they are used.

## 10.1 A rewrite is a match, a side condition and an action

Every rewrite in the engine is built from three functions. `match(m, site)` says whether an operation is a candidate; `when(site, ctx)` checks the **side condition** and returns `{ ok, because }`; `to(site, ctx)` returns an **action**: erase the operation, replace its result with an operand, or replace the operation with another. The driver that applies one rewrite to a function is short:

```js
// core.js
function applyRewrite(fn, rw, facts, decisions) {
  let fired = 0;
  const ctx = siteContext(fn, facts, decisions);
  for (const site of sitesOf(fn).reverse()) {
    if (!site.block.ops.includes(site.op)) continue;
    const m = rw.matchFn(M, site);
    const hit = m === true || (m && m.test && m.test(site));
    if (!hit) continue;
    let ok = true, because = 'matched';
    if (rw.whenFn) {
      const r = rw.whenFn(site, ctx);
      ok = r === true || (r && r.ok === true);
      because = (r && r.because) || (ok ? 'side condition holds' : reasonFor(rw, site, ctx));
    }
    if (ok) {
      const action = rw.toFn(site, ctx);
      const done = performAction(fn, site, action);
      if (done) { fired++; decisions.push({ by: rw.name, at: site.id, op: site.op.op, fired: true, because: done === true ? because : done }); }
    } else decisions.push({ by: rw.name, at: site.id, op: site.op.op, fired: false, because });
  }
  return fired;
}
```

The driver visits operations from last to first, so that erasing one does not shift the indices of those still to be visited, and it skips an operation an earlier action already removed. A match is a boolean or a pattern (`m.op('*').resultUnused()`). The important lines are the two `decisions.push` calls: whether a rewrite fires or is refused, the engine records which rule, at which operation, and why. That log is `program.decisions`, the Events view shows it, and `program.why(opId)` filters it to one operation. A compiler that only records what it did leaves a reader guessing why it did not do something else; this one answers both questions.

The `ctx` passed to the side condition is the rewrite's view of the facts: `ctx.perm(op)` for permissions, `ctx.typeAt(site, operand)` for the type of an operand just before the operation, `ctx.variantFor(site)` for a narrower variant, `ctx.noWritesBetween(resource, block, i, j)` for a quick check that nothing in between writes a resource.

## 10.2 The standard rewrites

`g.rewrites.canonical()` holds five rewrites, run in this order: copy propagation, constant folding, branch simplification, removal of unreachable blocks and erasure of dead results. `g.rewrites.standard()` adds narrowing by facts and forwarding a cell store to the next load. On a small program of ours they do this:

```js
const k = 2 * 3; const s = k + 1;
if (s > 5) { print("big " + s); } else { print("small"); }
```

With no rewrites the frontend's output, after promotion, computes everything at run time:

```text
fn main() -> any {
entry throws unwind:
  v4 = js.mul(2, 3)
  v6 = js.add(v4, 1)
  v8 = js.gt(v6, 5)
  branch v8, then1(), else3()
then1() throws unwind:
  v10 = js.add("big ", v6)
  host.print(v10)
  jump endif2()
endif2() throws unwind:
  return undefined
else3() throws unwind:
  host.print("small")
  jump endif2()
}
```

With the canonical set, six rewrites fire and the program is two prints short of nothing:

```text
fn main() -> any {
entry throws unwind:
  jump then1()
then1() throws unwind:
  host.print("big 7")
  jump endif2()
endif2() throws unwind:
  return undefined
}
```

The decision log tells the story. **Constant folding** fired four times, at `js.mul`, at the `js.add` that used its result, at `js.gt`, and at the string concatenation, each with the reason `primitive literal operands: no user code can run`. That reason is the side condition. A `js.add` is `callsUser` in general, but when both operands are literal numbers or strings no `valueOf` exists to call, so evaluating it at compile time with the interpreter's own step gives exactly the run-time answer. **Branch simplification** then saw `branch true, …` (`condition is the literal true; always goes to then1`), and **unreachable-block removal** deleted `else3` (`no path from entry`). Each rewrite enabled the next; Figure 10.2 below draws the two shapes. [T-01 Folding and propagation](lab:preset?id=T-01) does the same on a larger program, where 14 operations become 5.

**Narrowing** replaces an operation by its variant when the facts allow ([Chapter 7](lab:book?ch=7); [T-04 Narrowing by facts](lab:preset?id=T-04)). **Store-to-load forwarding** removes a `cell.load` that reads a value stored earlier in the same block, provided nothing in between may write cells:

```js
// core.js
  forwardCells: rewrite('forward-store-to-load')
    .match((m, s) => s.op.op === 'cell.load' && !isLit(s.op.args[0]))
    .when((s) => {
      const c = s.op.args[0], ops = s.block.ops;
      for (let j = s.index - 1; j >= 0; j--) {
        const o = ops[j];
        if ((o.op === 'cell.store' && o.args[0] === c) || (o.op === 'cell.new' && o.result === c && o.args.length)) return { ok: true, because: `stored at ${s.fn.name}/${s.block.name}/${j}; nothing writes cells in between`, value: o.op === 'cell.store' ? o.args[1] : o.args[0] };
        const b = lookupOp(o.op).behaviour;
        if (b.writes.has('cells')) return { ok: false, because: `${o.op} at ${s.fn.name}/${s.block.name}/${j} may write cells (${b})` };
      }
      return { ok: false, because: 'no store to this cell earlier in the block' };
    })
```

The side condition walks backwards from the load. It succeeds at the first store to the same cell, and it fails at the first operation whose behaviour writes cells, which includes every `callsUser` operation, since user code can assign any captured variable. Here the behaviour does the work again: the rewrite never mentions calls or getters. [T-05 Forwarding stores to loads](lab:preset?id=T-05) shows both outcomes.

## 10.3 What correct means: refinement

When is a rewrite correct? Not when the program "does the same thing" in some loose sense: the folded program above executes fewer operations, allocates no intermediate numbers and never evaluates `s > 5`. What must stay the same is what a user can observe. [Chapter 2](lab:book?ch=2) defined the **observations** of a run: the printed output, the outcome (normal, a thrown value, divergence), and object identity as far as the output reveals it, compared up to a renaming of objects and with numbers compared by SameValue, so that $-0$ and $0$ differ and NaN equals itself.

A program $P'$ **refines** a program $P$ if every behaviour $P'$ can show is one $P$ can show:

$$P' \sqsubseteq P \iff \mathrm{Obs}(P') \subseteq \mathrm{Obs}(P).$$

In general $\mathrm{Obs}(P)$ is a set: a program can legally behave in more than one way (with `Math.random`, the clock, or the timing of finalisers in a real engine), and a compiler may narrow the choice, so refinement is inclusion, not equality. The workbench's interpreter is deterministic: each program has exactly one behaviour on a given input, and refinement becomes equality of the observation traces. The check `g.observe.equal(before, after)` compares them observation by observation and reports the first difference with the rule it broke.

Refinement has the property that makes optimisers possible: it is transitive. If $P_1 \sqsubseteq P_0$ and $P_2 \sqsubseteq P_1$, then $\mathrm{Obs}(P_2) \subseteq \mathrm{Obs}(P_1) \subseteq \mathrm{Obs}(P_0)$. So a pipeline of rewrites, each of which refines its input, refines the original program, however many there are and in whatever order they fire. Correctness is checked one rewrite at a time and composes for free; [Chapter 11](lab:book?ch=11) builds on this for whole passes.

## 10.4 Naive dead-code elimination, and the law that catches it

`g.rewrites.naiveDce` is the rewrite everyone writes first: erase any operation whose result is unused. It has no side condition. [Chapter 7](lab:book?ch=7) followed what it does to a getter that prints and throws: the program printed `getter ran`, `caught boom`, `end` before, and only `end` after. The refinement law finds that without being told where to look:

```js
g.law.refines(g.rewrites.naiveDce, { samples: 30, seed: 1 })
```

The law compiles each program twice, once with no rewrites and once with the rewrite under test, runs both in the specification and compares the observations. Its corpus is the programs you pass plus `samples` programs from `g.gen.js`, a generator that strings together statements around a getter that counts its calls, `try`/`catch`, `finally`, loops and a queued job. The first generated program already fails: before the rewrite its first line is `2` (twice the count of one getter call), after it `0`, because the getter never ran. Because a generated program is a list of statements, the law then **shrinks** it, deleting statements one at a time while the failure persists. The minimised counterexample is one line:

```js
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
```

With its declarations deleted, `r` is undeclared, so before the rewrite `r.x` throws `ReferenceError: r is not defined` at the read of the global `r`, nothing is printed, and the `finally` block's own read of `cell` throws again. After the rewrite both the unused `js.get` and the unused `js.global_get` are gone, and the program prints `no throw`. The shrinker kept a different failure than the one it started from (a missing variable instead of a getter), which is legitimate: it preserves "the rewrite changes the observations", not the original cause. [Chapter 19](lab:book?ch=19) studies generators and shrinking in depth.

Figure 10.1 shows the comparison the law makes on the getter program of Chapter 7.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 210">
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="30" y="50" width="160" height="26" class="f-paper"/><rect x="30" y="90" width="160" height="26" class="f-paper"/><rect x="30" y="130" width="160" height="26" class="f-paper"/>
    <rect x="240" y="50" width="160" height="26" class="f-paper"/><rect x="240" y="90" width="160" height="26" class="f-paper"/><rect x="240" y="130" width="160" height="26" class="f-paper"/>
    <rect x="450" y="50" width="160" height="26" class="f-paper acc" stroke-width="1.6"/>
    <line x1="190" y1="63" x2="240" y2="63"/><line x1="190" y1="103" x2="240" y2="103"/><line x1="190" y1="143" x2="240" y2="143"/>
    <line x1="400" y1="63" x2="450" y2="63" class="acc" stroke-width="1.6"/>
    <rect x="450" y="90" width="160" height="26" class="dash" stroke-dasharray="4 3"/>
  </g>
  <g font-size="11" class="f-ink">
    <text x="30" y="34" class="lbl">no rewrites</text><text x="240" y="34" class="lbl">canonical</text><text x="450" y="34" class="lbl">canonical + naive-dce</text>
    <text x="40" y="68">print "getter ran"</text><text x="40" y="108">print "caught boom"</text><text x="40" y="148">print "end"</text>
    <text x="250" y="68">print "getter ran"</text><text x="250" y="108">print "caught boom"</text><text x="250" y="148">print "end"</text>
    <text x="460" y="68">print "end"</text><text x="460" y="108" class="f-mut">(nothing)</text>
    <text x="30" y="186" font-size="10" class="f-mut">one row per observation, in order</text>
    <text x="240" y="186" font-size="10">equal: refines</text>
    <text x="450" y="186" font-size="10" class="f-acc">trace[0] differs: does not refine</text>
  </g>
</svg>
```

**Figure 10.1.** Refinement checked observation by observation. The canonical rewrites leave the three printed lines as they were; with naive dead-code elimination the first observation is already different, and the trace is two observations short. A deterministic specification has one trace per program, so refinement is equality of traces.

A law that samples programs is not a proof: it can only fail to find a counterexample. Its strength comes from the generator aiming at the hazards that matter (here a getter with a side effect, which a uniform random generator would rarely produce) and from running in the Laws view on every change. [T-02 Dead code that is not dead](lab:preset?id=T-02) puts the law and the getter side by side.

> **Try it.** [Load T-02](lab:preset?id=T-02), [run the refinement law on naive-dce](lab:law?name=refines%28naive-dce%29) and [show the Laws](lab:show?view=laws): the counterexample and its shrunk form are listed under the failing law, next to `refines(erase-dead-result)`, which passes.

## 10.5 Writing a rewrite of your own, and catching a wrong one

Here is a rewrite of ours that removes multiplications by one:

```js
const mulOne = g.rewrite('mul-one')
  .match((m, site) => site.op.op === 'num.mul' && site.op.args[1] && site.op.args[1].lit === 1)
  .to(site => g.act.replaceWith(site.op.args[0]));
```

It has no side condition because none is needed: for every double $x$, $x \times 1$ is $x$ under SameValue, including $-0$, NaN and the infinities. In the ledger's `total` it removes `n14 = num.mul(i3_1, 1)` (the `ToNumeric` step of `i++`) once the standard rewrites have narrowed it, and the loop counter goes straight into `v15 = num.add(i3_1, 1)`. [T-03 Your own rewrite](lab:preset?id=T-03) builds the version that matches `js.mul` instead, where a side condition is needed: the operand must be known to be a number, or `"5" * 1 + 1` (which is 6) would become `"5" + 1` (which is `"51"`).

Now a rewrite that looks just as harmless: replace `num.add(x, 0)` with `x`. It is wrong. $-0 + 0$ is $+0$, so for $x = -0$ the rewrite changes the result's sign, which `1 / x` turns into a visible difference: $\infty$ against $-\infty$. Testing it takes care. `g.law.refines(addZero, …)` on JavaScript source reports no failure, because the frontend emits `js.add`, never `num.add`, and the rewrite under test never matches. A rewrite has to be tested with the rewrites that produce its input. With the standard set and an assumption that makes `x` a number:

```js
const base = g.pipeline().assume({ f: { x: 'number' } });
g.law.refines(g.rewrites.standard().with(addZero), {
  corpus: ['function f(x) { return x + 0; }\nprint(1 / f(-0));'], pipeline: base });
```

the law fails on its one sample, with `before: ["Infinity"]`, `after: ["-Infinity"]` and the rule `SameValue distinguishes -0 and +0`. The same law with `mulOne` in place of `addZero`, on the same corpus extended with `x * 1`, passes.

## 10.6 Canonical forms and idempotence

A set of rewrites is run to a fixed point. The driver applies the rewrites of the set in order, recomputing type facts before each, and repeats the round until a round changes nothing, with a limit of eight rounds. The order matters for speed (folding before branch simplification lets one round do what would otherwise take two) but should not matter for the result. A set is **idempotent** when running it again on its own output changes nothing, and that is what makes its output a **canonical form**: two programs that canonicalise to the same text can be treated as the same, and a later pass can assume that the easy simplifications have been done. `g.law.idempotent(set)` runs a set once and then again on 50 generated core IR functions and compares the hashes; it passes for both `canonical` and `standard`. [T-08 Idempotent canonical form](lab:preset?id=T-08) is the preset for this section.

Figure 10.2 shows the canonical form of Section 10.2's program next to its input.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="20" y="20" width="200" height="74" class="f-paper"/>
    <rect x="20" y="130" width="140" height="50" class="f-paper"/>
    <rect x="180" y="130" width="130" height="50" class="f-paper"/>
    <rect x="100" y="206" width="140" height="36" class="f-paper"/>
    <path d="M90,94 L90,128" marker-end="url(#arrow)"/><path d="M200,94 L240,128" marker-end="url(#arrow)"/>
    <path d="M90,180 L150,204" marker-end="url(#arrow)"/><path d="M245,180 L200,204" marker-end="url(#arrow)"/>
    <rect x="420" y="20" width="160" height="34" class="f-paper"/>
    <rect x="420" y="90" width="160" height="44" class="f-fill" stroke-width="1.6"/>
    <rect x="600" y="90" width="70" height="44" class="dash" stroke-dasharray="4 3"/>
    <rect x="420" y="170" width="160" height="36" class="f-paper"/>
    <path d="M500,54 L500,88" marker-end="url(#arrow)"/><path d="M500,134 L500,168" marker-end="url(#arrow)"/>
    <line x1="350" y1="10" x2="350" y2="240" class="hair"/>
  </g>
  <g font-size="10" class="f-ink">
    <text x="28" y="34" class="b">entry</text><text x="28" y="50">v4 = js.mul(2, 3)</text><text x="28" y="64">v6 = js.add(v4, 1)</text><text x="28" y="78">v8 = js.gt(v6, 5)</text><text x="28" y="90">branch v8, then1(), else3()</text>
    <text x="28" y="144" class="b">then1</text><text x="28" y="160">v10 = js.add("big ", v6)</text><text x="28" y="171">host.print(v10)</text>
    <text x="188" y="144" class="b">else3</text><text x="188" y="160">host.print("small")</text>
    <text x="108" y="220" class="b">endif2</text><text x="108" y="236">return undefined</text>
    <text x="428" y="34" class="b">entry</text><text x="428" y="48">jump then1()</text>
    <text x="428" y="104" class="b">then1</text><text x="428" y="120">host.print("big 7")</text>
    <text x="606" y="108" class="f-mut">else3</text><text x="606" y="122" class="f-mut">removed</text>
    <text x="428" y="184" class="b">endif2</text><text x="428" y="200">return undefined</text>
    <text x="20" y="12" class="lbl">no rewrites: 4 blocks, 6 operations</text>
    <text x="420" y="12" class="lbl">canonical: 3 blocks, 1 operation</text>
  </g>
</svg>
```

**Figure 10.2.** The program of Section 10.2 before and after the canonical rewrites. Folding turned the condition into the literal `true`, branch simplification made `entry` jump straight to `then1`, and `else3` lost its only predecessor and was removed. Running the canonical set again on the right-hand program changes nothing.

## 10.7 The running example: what the rewrites do to the ledger

On the ledger the canonical set fires nothing: the program has no literal arithmetic, no copies and no constant branches, and its three candidates for erasure (the ignored `ledger.deposit` results at `main/entry/5`, `main/entry/7` and `main/try3/1`) are refused for the reasons of [Chapter 7](lab:book?ch=7). The standard set fires four times, measured in [B-01](lab:preset?id=B-01) with `g.rewrites.standard()`:

| rewrite | at | decision |
|---|---|---|
| narrow-by-facts | `total/next3/0` | `js.mul → num.mul` |
| narrow-by-facts | `total/next3/1` | `js.add → num.add` |
| narrow-by-facts | `main/endtry2/6` | `js.add → str.concat` |
| forward-store-to-load | `main/entry/4` | `stored at main/entry/3; nothing writes cells in between` |

The refusals say as much as the firings. `forward-store-to-load` was refused at `main/entry/6` because `js.call_method at main/entry/5 may write cells (callsUser)`: between storing the ledger and reading it again, the script called `deposit`, which could in principle reassign the variable. Narrowing was refused at `total/for1/2` because the operand types were `number, any`. Is the standard set correct on the ledger? `g.law.refines(g.pipeline().rewrites(g.rewrites.standard()), { corpus: [ledger], samples: 40 })` compiles the ledger and 40 generated programs, runs each lowered program in plan mode with GC stress against the specification, and reports 41 samples with no difference.

> **Try it.** [Load B-01](lab:preset?id=B-01), [open main.js](lab:open?file=main.js&line=3), change the pipeline to `g.pipeline().rewrites(g.rewrites.standard())`, [rerun it](lab:build) and [show the Events](lab:show?view=events): the decisions above are listed with their reasons. Then [select the load the forwarding removed](lab:node?id=main/entry/4) in the unmodified program to see the `cell.load` it replaced.

## 10.8 Key points

A rewrite is a match, a side condition that returns a verdict with its reason, and an action; every attempt is logged, fired or refused. Constant folding of JavaScript operators is allowed when every operand is a primitive literal, because no user code can then run; branch simplification and unreachable-block removal finish the job. Store-to-load forwarding is refused across any operation whose behaviour writes cells, which includes every call. A rewrite is correct when the rewritten program refines the original: it shows no observation the original could not, which for the deterministic specification means equal traces under SameValue and object renaming. Refinement is transitive, so rewrites that are each correct compose. The refinement law samples programs aimed at known hazards and shrinks failures; it must test a rewrite together with the rewrites that produce its input. A rewrite set run to a fixed point is idempotent, and its output is a canonical form.

## Exercises

1. In [T-01](lab:preset?id=T-01), change `2 * 3` to `2 * x` where `x` is a parameter of a function. Which of the six decisions of Section 10.2 still fire, which are refused, and with what reasons?
2. Write the rewrite `add-zero` of Section 10.5 and reproduce the failure. Then add a side condition that makes it correct, using `ctx.typeAt` (hint: which types of `x` make $x + 0 = x$ under SameValue?).
3. Find a program where `forward-store-to-load` fires inside a loop body. Then insert a `print` between the store and the load: does the rewrite still fire? Explain from the behaviour of `host.print`.
4. Run `g.law.refines(g.rewrites.naiveDce, { samples: 30, seed: 2 })` and `seed: 3`. Do the minimised counterexamples fail for the same reason as the one in Section 10.4?
5. A project: write a rewrite `erase-pure-dead` that erases an unused result only when `ctx.perm(site.op).erase === true`, and compare it with `erase-dead-result`. Are they the same rewrite? Use `g.law.refines` and `g.law.idempotent` to argue your answer.

[Chapter 11](lab:book?ch=11) assembles rewrites, analyses and lowerings into passes and pipelines, and shows why refinement makes them composable.
