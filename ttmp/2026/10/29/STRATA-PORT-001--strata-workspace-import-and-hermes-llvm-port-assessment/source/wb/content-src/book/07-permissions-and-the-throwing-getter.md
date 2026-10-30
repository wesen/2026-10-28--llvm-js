# Permissions and the throwing getter

A rewrite that deletes, merges or moves an operation needs permission to do it, and in the workbench that permission is never written down by hand: it is computed from the operation's behaviour. This chapter defines the six permissions every rewrite asks for, shows the function that derives them, proves the property that makes the derivation safe to extend (more behaviour never grants a permission), and follows one getter that prints and throws from source to the rewrite that must leave it alone. It ends with the one legitimate way to gain permissions: proving, with facts, that a cheaper operation does the same thing.

[Chapter 6](lab:book?ch=6) defined behaviours and their join. Here they start to decide things.

## 7.1 Six questions a rewrite asks

Every transformation in an optimiser reduces to a handful of questions about the operations it touches. The workbench names six:

| permission | the rewrite wants to | typical user |
|---|---|---|
| **erase** | delete the operation when its result is unused | dead-code elimination |
| **merge** | replace a second evaluation with the first one's result | common-subexpression elimination |
| **move** | reorder the operation with its neighbours | scheduling, sinking |
| **duplicate** | evaluate it twice where it ran once | tail duplication, splitting a block |
| **hoist** | evaluate it once before a loop instead of once per turn | loop-invariant code motion |
| **speculate** | evaluate it on a path where it would not have run | if-conversion, hoisting out of a branch |

Each answer is `true`, `false`, or a **condition**: a sentence naming what must also hold, such as `if nothing writes cells between them`. Each comes with its reasons. A permission that is a condition is not a refusal: it tells the rewrite what else to check, and a rewrite that can check it (with facts about the surrounding code) may go ahead.

Why derive these instead of declaring them? Because a declared permission can disagree with the behaviour beside it. An operation table that says `js.get` is erasable and also says it may run user code is contradictory, and nothing in a hand-written table catches the contradiction. Derived permissions cannot contradict their behaviour, and adding an operation (as in [Chapter 6](lab:book?ch=6)) costs only its contract.

## 7.2 Deriving permissions

`g.perm(op)` calls one function on the operation's behaviour. Its first lines collect the **blockers**, the parts of the behaviour that make an operation observable:

```js
// core.js
function derivePermissions(behaviour, facts = {}) {
  const b = behaviour, out = {}, because = {};
  const blockers = [];
  if (b.callsUser) blockers.push('may run user code');
  if (b.throws) blockers.push('may throw');
  if (b.diverges) blockers.push('may diverge');
  const writes = [...b.writes].filter(r => r !== 'engine' || b.isUnknown);
  if (writes.length) blockers.push(`writes ${writes.join(', ')}`);
  if (b.host.size) blockers.push('talks to the host');
  if (b.isUnknown) blockers.unshift('behaviour unknown');
  const reads = [...b.reads];
  const quiet = blockers.length === 0;           // total, silent, no observable writes
// …
  if (quiet && (!b.fresh || facts.identityObserved === false)) out.erase = true;
  else if (quiet && b.fresh) out.erase = 'if its new identity is never observed';
  else out.erase = false;
```

An operation is **quiet** when it has no blocker: it always returns, never throws, writes nothing a program can read and says nothing to the host. Reads do not block: reading the heap is invisible unless the value is used. Allocation does not block either, but it creates an identity, and a program can observe identity (`a === b` on two objects). So erasing a quiet allocation is a condition: allowed if the new object's identity is never observed, which holds when its result is unused. The other five permissions follow the same pattern with different extra requirements: merging needs no reads (or nothing writing what was read in between) and no fresh identity, because two `obj.new` calls make two different objects; hoisting needs everything merging needs plus loop invariance of the operands.

Figure 7.1 is the table the function produces for seven operations, measured with `g.perm` in the engine.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 280">
  <g font-size="11" class="f-ink">
    <text x="232" y="30" text-anchor="middle" class="lbl">erase</text><text x="292" y="30" text-anchor="middle" class="lbl">merge</text><text x="352" y="30" text-anchor="middle" class="lbl">move</text>
    <text x="412" y="30" text-anchor="middle" class="lbl">duplicate</text><text x="472" y="30" text-anchor="middle" class="lbl">hoist</text><text x="532" y="30" text-anchor="middle" class="lbl">speculate</text>
    <text x="24" y="59">num.add</text><text x="24" y="87">cell.load</text><text x="24" y="115">js.get_own_data</text><text x="24" y="143">obj.new</text>
    <text x="24" y="171">cell.store</text><text x="24" y="199">cell.load_checked</text><text x="24" y="227">js.get</text>
  </g>
  <g stroke="currentColor" stroke-width="1" class="ink">
    <rect x="222" y="45" width="20" height="20" class="f-ink"/><rect x="282" y="45" width="20" height="20" class="f-ink"/><rect x="342" y="45" width="20" height="20" class="f-ink"/><rect x="402" y="45" width="20" height="20" class="f-ink"/><rect x="462" y="45" width="20" height="20" class="f-ink"/><rect x="522" y="45" width="20" height="20" class="f-ink"/>
    <rect x="222" y="73" width="20" height="20" class="f-ink"/><rect x="282" y="73" width="20" height="20" class="f-fill2"/><rect x="342" y="73" width="20" height="20" class="f-fill2"/><rect x="402" y="73" width="20" height="20" class="f-ink"/><rect x="462" y="73" width="20" height="20" class="f-fill2"/><rect x="522" y="73" width="20" height="20" class="f-fill2"/>
    <rect x="222" y="101" width="20" height="20" class="f-ink"/><rect x="282" y="101" width="20" height="20" class="f-fill2"/><rect x="342" y="101" width="20" height="20" class="f-fill2"/><rect x="402" y="101" width="20" height="20" class="f-ink"/><rect x="462" y="101" width="20" height="20" class="f-fill2"/><rect x="522" y="101" width="20" height="20" class="f-fill2"/>
    <rect x="222" y="129" width="20" height="20" class="f-fill2"/><rect x="282" y="129" width="20" height="20" class="f-paper"/><rect x="342" y="129" width="20" height="20" class="f-ink"/><rect x="402" y="129" width="20" height="20" class="f-paper"/><rect x="462" y="129" width="20" height="20" class="f-paper"/><rect x="522" y="129" width="20" height="20" class="f-ink"/>
    <rect x="222" y="157" width="20" height="20" class="f-paper"/><rect x="282" y="157" width="20" height="20" class="f-paper"/><rect x="342" y="157" width="20" height="20" class="f-fill2"/><rect x="402" y="157" width="20" height="20" class="f-paper"/><rect x="462" y="157" width="20" height="20" class="f-paper"/><rect x="522" y="157" width="20" height="20" class="f-paper"/>
    <rect x="222" y="185" width="20" height="20" class="f-paper"/><rect x="282" y="185" width="20" height="20" class="f-paper"/><rect x="342" y="185" width="20" height="20" class="f-fill2"/><rect x="402" y="185" width="20" height="20" class="f-paper"/><rect x="462" y="185" width="20" height="20" class="f-paper"/><rect x="522" y="185" width="20" height="20" class="f-paper"/>
    <rect x="222" y="213" width="20" height="20" class="f-paper"/><rect x="282" y="213" width="20" height="20" class="f-paper"/><rect x="342" y="213" width="20" height="20" class="f-paper"/><rect x="402" y="213" width="20" height="20" class="f-paper"/><rect x="462" y="213" width="20" height="20" class="f-paper"/><rect x="522" y="213" width="20" height="20" class="f-paper"/>
    <rect x="24" y="252" width="14" height="14" class="f-ink"/><rect x="134" y="252" width="14" height="14" class="f-fill2"/><rect x="274" y="252" width="14" height="14" class="f-paper"/>
  </g>
  <g font-size="10" class="f-ink">
    <text x="44" y="263">granted</text><text x="154" y="263">a condition</text><text x="294" y="263">refused</text>
    <text x="570" y="59" class="f-mut">none</text><text x="570" y="87" class="f-mut">reads(cells)</text><text x="570" y="115" class="f-mut">reads(heap)</text><text x="570" y="143" class="f-mut">fresh</text>
    <text x="570" y="171" class="f-mut">reads+writes(cells)</text><text x="570" y="199" class="f-mut">reads(cells), throws</text><text x="570" y="227" class="f-mut">callsUser</text>
  </g>
</svg>
```

**Figure 7.1.** The six permissions of seven standard operations, as `g.perm` derives them, with each operation's behaviour on the right. Reading a resource turns merge, move, hoist and speculate into conditions; allocating refuses merge, duplicate and hoist and makes erase a condition; writing, throwing or running user code refuses almost everything.

The rows read as a staircase. `num.add` is pure and gets everything. `cell.load` reads a cell, so it may be merged with an earlier load only `if nothing writes cells between them`; `js.get_own_data`, which reads an object's own data property without running any getter, gets the same answers with `heap` in place of `cells`. `cell.store` writes, so it can only be moved, and only `not across operations that read or write cells`. `js.get` may run user code and gets nothing.

> **Try it.** [Load B-01](lab:preset?id=B-01) and [select the js.get of log.length in deposit](lab:node?id=deposit/endif2/5). The Inspector lists the six refusals with their reasons: `may run user code`, `may throw`, `may diverge`, `writes heap, cells, jobs, timers, globals`, `talks to the host`. [C-03 Derived permissions](lab:preset?id=C-03) prints the whole table.

## 7.3 More behaviour, fewer permissions

Order the three answers `false < condition < true`. The derivation has a property that makes the whole design safe to change: if behaviour $a$ allows no more than behaviour $b$, then every permission of $b$ is at most the same permission of $a$:

$$a \sqsubseteq b \implies \mathrm{perm}_k(b) \le \mathrm{perm}_k(a) \quad \text{for each of the six } k.$$

A function with this property is **antitone**. The proof follows the code. Each blocker is a test that can only become true as the behaviour grows: the flags of $b$ include those of $a$, and its written resources and host capabilities are supersets. So if $b$ is quiet, $a$ is quiet; and $a$'s reads and fresh flag are included in $b$'s. Take erase: `true` needs quiet and (not fresh, or an unobserved identity). If $b$ satisfies that, so does $a$. If $b$ gets the condition, $b$ is quiet and fresh, so $a$ is quiet and gets at least the condition. The other five permissions are built from the same tests joined by "and", so the same argument applies to each.

The consequence is practical. Correcting a contract upwards (finding that an operation can throw after all) can only take permissions away, never grant one, so a fix to a contract cannot make an optimisation unsound. `g.law.antitone()` checks the property on 5,000 random pairs $a \sqsubseteq a \sqcup c$ and reports `more behaviour never grants a permission`. The law compares the coarse order of answers; it does not rank one condition against another. [C-07 More behaviour, fewer permissions](lab:preset?id=C-07) runs it.

Reordering two operations is a question about a pair, so it gets its own function, `g.perm.commute(a, b)`:

```js
// core.js
  commute: (a, b) => {
    const A = (typeof a === 'string' ? lookupOp(a) : a.def || a).behaviour, B = (typeof b === 'string' ? lookupOp(b) : b.def || b).behaviour;
    const clash = [...A.writes].filter(r => B.writes.has(r) || B.reads.has(r)).concat([...B.writes].filter(r => A.reads.has(r)));
    if (A.callsUser || B.callsUser) return { allowed: false, because: 'one of them may run user code' };
    if (clash.length) return { allowed: false, because: `they conflict on ${[...new Set(clash)].join(', ')}` };
    if (A.throws && B.throws) return { allowed: false, because: 'both may throw: swapping changes which error escapes' };
    return { allowed: true, because: 'no shared resource is written' };
  },
```

Two operations commute when neither writes what the other reads or writes, neither runs user code, and they cannot both throw (if both may throw, swapping them changes which error escapes). Two `cell.load`s commute; `cell.load` and `cell.store` do not (`they conflict on cells`); `cell.load` and `js.get_own_data` commute, because one reads cells and the other the heap; `js.get` commutes with nothing.

## 7.4 The throwing getter, end to end

Here is the smallest program in the book that a careless optimiser breaks:

```js
const o = { get x() { print("getter ran"); throw new Error("boom"); } };
try { const y = o.x; } catch (e) { print("caught " + e.message); }
print("end");
```

It prints `getter ran`, `caught boom`, `end`. The frontend compiles the getter to its own function and the read `o.x` to a `js.get` inside a block protected by the handler:

```text
try3() throws to catch1:
  x8 = js.get(o3, "x")
  jump endtry2()
}

fn get_x(this: any) -> any {
entry throws unwind:
  host.print("getter ran")
  err2 = js.new_error[Error]("boom")
  throw err2
}
```

The variable `y` is never read, so after `promote-cells` nothing uses `x8`. To a rule that only asks "is the result used?", `js.get` at `main/try3/0` is dead. The canonical rewrite `erase-dead-result` asks for the erase permission instead, and the engine logs its refusal: `perm.erase = false: may run user code; may throw; may diverge; writes heap, cells, jobs, timers, globals; talks to the host`. Three of the five reasons are real here: the getter runs user code, talks to the host (it prints) and throws. The other two (divergence and the writes) are what user code could do in general, and the compiler has no way to tell this getter from a worse one.

`g.rewrites.naiveDce` is the same match with the side condition removed. Added to the canonical set, it fires at `main/try3/0` and the program prints only `end`: the getter never runs, nothing throws, the handler is never reached. `g.law.refines(g.rewrites.naiveDce, { corpus: [program] })` finds the difference at once, comparing the specification's observations before (`getter ran`, `caught boom`, `end`) and after (`end`). Figure 7.2 shows what was lost.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 240">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="20" y="20" width="240" height="56" class="f-paper"/><line x1="20" y1="40" x2="260" y2="40" class="hair"/>
    <rect x="360" y="20" width="320" height="76" class="f-paper"/><line x1="360" y1="40" x2="680" y2="40" class="hair"/>
    <rect x="20" y="170" width="220" height="48" class="f-paper"/><line x1="20" y1="190" x2="240" y2="190" class="hair"/>
    <rect x="360" y="150" width="320" height="76" class="f-paper"/><line x1="360" y1="170" x2="680" y2="170" class="hair"/>
    <rect x="28" y="46" width="168" height="20" class="acc" stroke-width="1.6"/>
    <path d="M196,56 L358,56" marker-end="url(#arrow)"/>
    <path d="M520,96 L520,148" class="dash" stroke-dasharray="5 3" marker-end="url(#arrow)"/>
    <path d="M220,76 L220,168" marker-end="url(#arrow)"/>
    <path d="M360,194 L242,194" marker-end="url(#arrow)"/>
  </g>
  <g font-size="11" class="f-ink">
    <text x="28" y="34" class="b">try3() throws to catch1</text>
    <text x="34" y="60" font-size="10">x8 = js.get(o3, "x")</text>
    <text x="368" y="34" class="b">get_x(this)</text>
    <text x="368" y="56" font-size="10">host.print("getter ran")</text>
    <text x="368" y="72" font-size="10">err2 = js.new_error[Error]("boom")</text>
    <text x="368" y="88" font-size="10">throw err2</text>
    <text x="28" y="184" class="b">endtry2()</text>
    <text x="28" y="208" font-size="10">host.print("end")</text>
    <text x="368" y="164" class="b">catch1(e5)</text>
    <text x="368" y="186" font-size="10">message11 = js.get(e5, "message")</text>
    <text x="368" y="202" font-size="10">v12 = js.add("caught ", message11)</text>
    <text x="368" y="218" font-size="10">host.print(v12)</text>
    <text x="268" y="50" font-size="10" class="f-mut">runs the getter</text>
    <text x="528" y="128" font-size="10" class="f-mut">throws</text>
    <text x="228" y="128" font-size="10" class="f-mut">normal</text>
    <text x="28" y="100" font-size="10" class="f-acc">naive-dce erases this</text>
    <text x="28" y="114" font-size="10" class="f-acc">operation: get_x and</text>
    <text x="28" y="128" font-size="10" class="f-acc">catch1 never run</text>
  </g>
</svg>
```

**Figure 7.2.** The throwing getter in core IR. The unused `js.get` in `try3` runs `get_x`, which prints and throws to `catch1`; erasing it leaves only the normal edge to `endtry2`, so two of the three printed lines disappear.

> **Try it.** [Load C-04 The throwing getter](lab:preset?id=C-04), [select the unused js.get in load](lab:node?id=load/entry/1) and read its six refusals, then [show the Events](lab:show?view=events) for the refused decision and what the naive rewrite prints instead. [T-02 Dead code that is not dead](lab:preset?id=T-02) runs the refinement law on the same mistake.

Notice where the knowledge lives. The rewrite knows nothing about getters. The operation table says `js.get` is `callsUser`, the derivation turns that into six refusals, and the decision log records which one stopped the rewrite and why. A program with a getter that neither prints nor throws would get the same refusal: the compiler cannot see through `js.get` to the getter, so it must assume the worst one.

## 7.5 Earning permissions: variants and narrowing

Refusing everything to `js.add` is right when its operands might be objects, and wasteful when they are both numbers. The way out is not to weaken the contract of `js.add` but to replace the operation with a **variant**: another operation whose behaviour is smaller and whose result is the same whenever the operands have certain types. The general operation names its variants in its table entry:

```js
// core.js
  { name: 'js.add', operands: [A, A], results: [A], behaviour: USER, obligations: CALLING, step: (s, [a, b]) => s.add(a, b), resultType: addType,
    narrow: ts => numeric(ts) ? 'num.add' : ts.every(x => x.le(t.string)) ? 'str.concat' : null, lower: { helper: 'shllvm_binary', code: 'add' } },
```

Given the operand types, `narrow` picks `num.add` when both are numbers, `str.concat` when both are strings, and nothing otherwise. The rewrite `narrow-by-facts` (in `g.rewrites.standard()`) asks the type facts of [Chapter 9](lab:book?ch=9) for the operand types at each site and swaps the operation when a variant applies:

```js
// core.js
  narrow: rewrite('narrow-by-facts')
    .match(m => m.op('*').hasVariants())
    .when((s, ctx) => { const v = ctx.variantFor(s); return { ok: !!v, because: v ? `operand types ${s.op.args.map(a => ctx.typeAt(s, a)).join(', ')} select ${v}` : `operand types ${s.op.args.map(a => ctx.typeAt(s, a)).join(', ')} select no variant` }; })
    .to((s, ctx) => act.replaceOp(ctx.variantFor(s))),
```

The swap is sound only if the variant really computes what the general operation computes on those types, and that claim is a law: `g.law.variant('num.add', 'js.add')` runs both steps on 3,000 pairs drawn from numbers chosen to break things ($-0$, NaN, $\pm\infty$, $2^{31}-1$, $2^{53}$, $10^{-300}$) and finds no difference. The same law catches a variant that is wrong. `i32.add` wraps on overflow, so `g.law.variant('i32.add', 'num.add')` fails on its second sample: $117884139 + 2066098173$ is $2183982312$ as a double and $-2110984984$ in 32 bits. Narrowing to `i32.add` needs a fact stronger than "both operands are int32": that their sum stays in range. [C-06 Variants and narrowing](lab:preset?id=C-06) runs both laws.

A narrowed operation keeps nothing of the general one's contract. `num.add` is pure, so every permission of Figure 7.1's first row now applies, and the operation is no longer a safepoint.

## 7.6 The running example: three refusals and two narrowings

With the default pipeline the ledger's rewrite pass fires nothing, and the decision log in [B-01](lab:preset?id=B-01) says why: `erase-dead-result` was refused three times, at `main/entry/5`, `main/entry/7` and `main/try3/1`, the three `ledger.deposit(…)` calls whose results the script ignores. Each refusal carries the five reasons of a `callsUser` operation. Erasing any one would change the printed balance, which is the situation of Section 6.1 seen from the rewrite's side.

With `g.rewrites.standard()` the facts get a say. In `total`, the loop counter `i3_1` is known to be a number (it starts at 0 and is only ever incremented), so the two operations of the `i++` in `next3` narrow: `js.mul(i3_1, 1)` becomes `num.mul` and `js.add(n14, 1)` becomes `num.add`. The other candidates are refused with their operand types in the reason: `js.lt(i3_1, length6)` sees `number, any` (the array's `length` comes from a `js.get`, which could return anything), and `js.add(sum2_1, v11)` sees `number|string, any`. In `main`, one string concatenation narrows to `str.concat`. Measured on the ledger:

| | canonical rewrites | standard rewrites |
|---|---|---|
| safepoints in `total` | 6 | 4 |
| permissions of `total/next3/0` | none | all six |
| collections in plan mode with GC stress | 68 | 60 |
| steps in the specification | 134 | 133 |

The two narrowed operations stop being safepoints, which removes eight collections from a stress run; the step count drops by one because `forward-store-to-load` also replaced a `cell.load` in `main` with the value just stored.

> **Try it.** [Load B-01](lab:preset?id=B-01), [select the js.mul in total](lab:node?id=total/next3/0) and note its refusals. Then [open main.js](lab:open?file=main.js&line=3), change the pipeline to `g.pipeline().rewrites(g.rewrites.standard())`, [rerun](lab:build) and select it again: it is now `num.mul`, with every permission granted. [J-02 Getters and setters](lab:preset?id=J-02) does the same for a program whose accessors validate their arguments.

## 7.7 Key points

The six permissions (erase, merge, move, duplicate, hoist, speculate) are derived from an operation's behaviour, each as `true`, `false` or a condition with its reasons. An operation is quiet when it cannot throw, diverge, write observable state, run user code or talk to the host; reads and allocation do not make it loud, but they turn some permissions into conditions. The derivation is antitone: a larger behaviour never gets a larger permission, so correcting a contract upwards can never make an optimisation unsound. An unused `js.get` cannot be erased because it may run a getter that prints or throws, and the decision log records the refusal; naive dead-code elimination deletes it and a refinement law catches the change. Permissions are earned by narrowing to a variant, a smaller operation that the variant law shows to agree with the general one on the operand types the facts establish.

## Exercises

1. In [C-03](lab:preset?id=C-03), print `g.perm(g.ops['obj.new'], { identityObserved: false })` and `g.perm(g.ops['obj.new'])`. Which answer changes, and why does an unused allocation still get no merge permission?
2. Use `g.perm.commute` to decide which pairs among `cell.load`, `cell.store`, `js.get_own_data`, `js.define` and `job.enqueue` may be swapped. Draw the result as a graph and explain the one pair you find surprising.
3. Change the getter of Section 7.4 so that it neither prints nor throws (`get x() { return 1; }`). Does `erase-dead-result` fire now? Explain the answer from the contract of `js.get`, not from the getter.
4. Run `g.law.variant('i32.add', 'num.add', { values: [0, 1, -1, 1000] })`. Why does it fail even with small values, and what does that tell you about how the law draws int32 operands?
5. A project: write a rewrite `erase-quiet-getter` that erases an unused `js.get` when the object is created in the same function by `obj.new` and only `js.define` (never `js.define_getter`) touches it before the read. What facts does its side condition need, and which law would you run to test it?

[Chapter 8](lab:book?ch=8) introduces the mathematics behind the facts that narrowing relies on: lattices, monotone functions and their least fixed points.
