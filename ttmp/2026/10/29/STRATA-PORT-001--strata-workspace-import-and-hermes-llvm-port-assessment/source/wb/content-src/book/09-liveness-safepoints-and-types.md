# Liveness, safepoints and types

The lowering of [Part VI](lab:book?ch=12) has one hard job: when the garbage collector may run, every object the compiled code still needs must be somewhere the collector can find and update it. Deciding that takes three facts about every point of a function. Which operations may collect (the **safepoints**); which values are still needed after each of them (liveness, and from it the **live-across** sets); and which of those values are heap references at all (types). This chapter computes all three with the solver of [Chapter 8](lab:book?ch=8), shows how block parameters and exceptional edges enter the equations, and reads the results on the ledger's `total` loop, where they decide that three of its values need a root and one does not.

## 9.1 Three facts the lowering needs

A moving collector, of the kind [Chapter 13](lab:book?ch=13) simulates, copies every reachable object to a new address and frees the rest. Compiled code that holds an object's old address in a register and reads it after the collection reads freed memory. The remedy is a **root slot**: a frame slot the collector knows about and rewrites when it moves the object. Rooting every value everywhere would be correct and wasteful; rooting too few is a crash. The precise rule needs three facts. A collection can only happen at an operation whose obligations include `mayCollect` ([Chapter 6](lab:book?ch=6)), so those are the places to look. At each such place, only values used later matter. And of those, only managed values (objects, functions, cells, strings, completion records) can move: a number in a register is the same number after a collection.

Each fact is an analysis. Safepoints need no iteration at all; liveness is backward, because whether a value is needed depends on what comes after; types are forward, because what a value can be depends on what came before. All three run in the `analyze` pass, and `program.facts(fn)` returns them.

## 9.2 Liveness over block parameters

Chapter 8's equations treated an edge as passing every live value straight through. With block parameters that is wrong. On the back edge of `total`, `jump for1(v12, v15)`, the target's parameters `sum2_1` and `i3_1` are bound to the edge's arguments. If `sum2_1` is live on entry to `for1`, what must be live at the end of `next3` is `v12`, the argument passed for it, and not `sum2_1`, which `next3` never sees. The engine's edge rule does that substitution:

```js
// core.js
  substituteBlockArgs: () => (fn, from, e, x) => {
    const target = fn.block(e.block), implicit = implicitCount(fn, from, e);
    const out = new Set();
    for (const v of x) {
      const pi = target.params.findIndex(p => p.id === v);
      if (pi < 0) out.add(v);
      else if (pi >= implicit) { const a = e.args[pi - implicit]; if (a !== undefined && !isLit(a)) out.add(a); }
    }
    return out;
  },
```

`x` is the live-in set of the target. A live value that is not one of the target's parameters (`c_log`, defined before the loop) passes through unchanged. A live parameter is replaced by the argument in its position, unless that argument is a literal, which needs no storage. The `implicit` count covers parameters no argument fills: the result of an `invoke` on its normal edge and the thrown value on an exceptional one ([Chapter 5](lab:book?ch=5)). The edge itself defines those, so nothing before it needs to keep them alive.

With the rule in place, $\mathrm{OUT}(b)$ is the union over $b$'s edges of the substituted live-in sets of their targets, and the entry edge of `total`, `jump for1(0, 0)`, contributes nothing: both arguments are literals.

## 9.3 Inside a block, and the edges a throw takes

The transfer function walks a block backwards from its live-out set, and records along the way the set live just after each operation, which is that operation's **live-across** set:

```js
// core.js
function livenessBlock(fn, b, liveOut, liveInOf, edgeRule, record) {
  let live = new Set(liveOut);
  const handler = b.onThrow && b.onThrow !== 'unwind' ? fn.block(b.onThrow) : null;
  const handlerLive = handler ? edgeRule(fn, b, { block: handler.name, args: b.throwArgs || [], kind: 'handler' }, liveInOf(handler.name)) : new Set();
  for (const a of termOperands(b.term)) live.add(a);
  if (record) record(`${fn.name}/${b.name}/term`, new Set([...liveOut]));
  for (let i = b.ops.length - 1; i >= 0; i--) {
    const o = b.ops[i];
    const d = opRegistry[o.op];
    if (o.result) live.delete(o.result);
    if (handler && d && d.mayThrow) for (const v of handlerLive) live.add(v);
    if (record) record(`${fn.name}/${b.name}/${i}`, new Set(live));
    for (const a of operandsOf(o)) live.add(a);
  }
  if (handler) for (const v of handlerLive) live.add(v);    // the handler's arguments are read at the head
  return live;
}
```

Start from the live-out set and add what the terminator reads. Then, for each operation from last to first: its result is defined here, so it is not live before; what is live at this moment is the operation's live-across set, recorded under its id; then its operands become live, since it reads them. That is the equation $\mathrm{IN} = \mathrm{use} \cup (\mathrm{OUT} \setminus \mathrm{def})$ applied one operation at a time.

The handler lines are the part a plain textbook version leaves out. A block protected by `throws to H` can leave at any operation that may throw, and when it does, control goes to `H` with whatever `H` needs. So at every may-throw operation of a protected block, the handler's live-in set is added to the live set. Without this, a value used only in the handler would look dead inside the protected block. Here is a function where that matters (the source is ours):

```js
function f(o) { const tag = "t" + o.k; try { o.x; } catch (e) { print(tag); } return 1; }
```

In core IR, `tag` is `v6`, computed in `entry`, and the read `o.x` is `x9 = js.get(o, "x")` in the protected block `try3`, whose handler `catch1` prints `v6`. The engine reports `v6` live across `f/try3/0` and requires a root for it there, together with `o`, which the `js.get` borrows. If the analysis ignored the handler, `v6` would be dead after `jump try3()`; a collection inside the getter could free the string; and the handler would print through a stale pointer. The rule runs both ways: an operation that cannot throw does not pull the handler's values in, so a protected block of pure arithmetic keeps nothing extra alive.

## 9.4 Safepoints and live-across sets

Safepoints are the one fact that needs no fixed point. The analysis is a scan:

```js
// core.js
function solveSafepoints(fn) {
  const list = [];
  for (const b of fn.blocks) {
    b.ops.forEach((o, i) => { const d = opRegistry[o.op]; if (d && d.mayCollect) list.push(`${fn.name}/${b.name}/${i}`); });
    if (b.term && b.term.kind === 'invoke') { const d = opRegistry[b.term.op.op]; if (d && d.mayCollect) list.push(`${fn.name}/${b.name}/term`); }
  }
```

`d.mayCollect` reads the operation's obligations, so this is where Chapter 6's contracts first decide something in the lowering. In `total`, 6 of the 8 operations are safepoints: both `js.get`s, `js.lt`, and the three arithmetic operations, all `callsUser` and so all `mayCollect`. The two `cell.load_checked` reads and the five terminators are not.

What a safepoint needs rooted is a little more than its live-across set. The helper that implements the operation reads its operands after it may have collected (a `js.get` might run a getter that allocates before the helper looks at the property it found), so the operation **borrows** its managed operands: they must be rooted too, even when nothing needs them afterwards. The plan's **required** set at a safepoint is therefore the managed values that are live across it, plus its managed operands. Figure 9.1 marks the safepoints of `total` with what is live across each one.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 392">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="60" y="10" width="200" height="40" class="f-paper"/><line x1="60" y1="28" x2="260" y2="28" class="hair"/>
    <rect x="60" y="76" width="420" height="88" class="f-paper"/><line x1="60" y1="94" x2="480" y2="94" class="hair"/>
    <rect x="60" y="192" width="420" height="88" class="f-paper"/><line x1="60" y1="210" x2="480" y2="210" class="hair"/>
    <rect x="60" y="306" width="420" height="76" class="f-paper"/><line x1="60" y1="324" x2="480" y2="324" class="hair"/>
    <rect x="530" y="108" width="150" height="40" class="f-paper"/><line x1="530" y1="126" x2="680" y2="126" class="hair"/>
    <path d="M160,50 L160,74" marker-end="url(#arrow)"/>
    <path d="M160,164 L160,190" marker-end="url(#arrow)"/>
    <path d="M480,128 L528,128" marker-end="url(#arrow)"/>
    <path d="M160,280 L160,304" marker-end="url(#arrow)"/>
    <path d="M60,367 L30,367 L30,100 L58,100" stroke-width="1.6" marker-end="url(#arrow)"/>
  </g>
  <g class="f-acc">
    <circle cx="72" cy="122" r="3.5"/><circle cx="72" cy="138" r="3.5"/>
    <circle cx="72" cy="238" r="3.5"/><circle cx="72" cy="254" r="3.5"/>
    <circle cx="72" cy="336" r="3.5"/><circle cx="72" cy="352" r="3.5"/>
  </g>
  <g font-size="10" class="f-ink">
    <text x="68" y="23" class="b">entry</text><text x="68" y="43">jump for1(0, 0)</text>
    <text x="68" y="89" class="b">for1(sum2_1, i3_1)</text>
    <text x="82" y="109">log5 = cell.load_checked(c_log)</text>
    <text x="82" y="125">length6 = js.get(log5, "length")</text>
    <text x="82" y="141">v7 = js.lt(i3_1, length6)</text>
    <text x="82" y="157">branch v7, body2(), endfor4()</text>
    <text x="68" y="205" class="b">body2()</text>
    <text x="82" y="225">log9 = cell.load_checked(c_log)</text>
    <text x="82" y="241">v11 = js.get(log9, i3_1)</text>
    <text x="82" y="257">v12 = js.add(sum2_1, v11)</text>
    <text x="82" y="273">jump next3()</text>
    <text x="68" y="319" class="b">next3()</text>
    <text x="82" y="339">n14 = js.mul(i3_1, 1)</text>
    <text x="82" y="355">v15 = js.add(n14, 1)</text>
    <text x="82" y="371">jump for1(v12, v15)</text>
    <text x="538" y="121" class="b">endfor4()</text><text x="538" y="141">return sum2_1</text>
    <text x="300" y="125" class="f-mut">across: c_log i3_1 sum2_1</text>
    <text x="300" y="141" class="f-mut">across: c_log i3_1 sum2_1</text>
    <text x="300" y="241" class="f-mut">across: c_log i3_1 sum2_1</text>
    <text x="300" y="257" class="f-mut">across: c_log i3_1</text>
    <text x="300" y="339" class="f-mut">across: c_log v12</text>
    <text x="300" y="355" class="f-mut">across: c_log v12</text>
    <text x="166" y="180" class="f-mut">true</text><text x="486" y="122" class="f-mut">false</text>
    <text x="34" y="386" class="f-mut">back edge</text>
  </g>
</svg>
```

**Figure 9.1.** The loop of `total` with its six safepoints (dots) and the values live across each, as the engine computes them. `c_log` is live across every safepoint because every turn of the loop reads it again; `sum2_1` stops being live across the `js.add` that consumes it, and its new value `v12` takes its place until the back edge rebinds it.

## 9.5 Type facts and branch refinement

The third fact is a type for each value at each point, computed forward over the map lattice from values to the type lattice of [Chapter 8](lab:book?ch=8) (sets of the ten value kinds). Parameters start at their declared types (`any` for JavaScript parameters), literals have the type of their value (0 is `int32`), and each operation's result type comes from its table entry: `js.mul` always returns a number, `js.add` returns a string if either operand is one and `number|string` if it cannot tell, `js.get` returns `any`. Along an edge, each target parameter receives the join of the types of the arguments passed to it.

Branches are where forward facts earn their keep. After `if (typeof x === "number")`, the true edge knows that `x` is a number. The engine looks at the condition's definition to find such tests:

```js
// core.js
function refinementOf(fn, defs, cond) {
  if (isLit(cond)) return null;
  const d = defs.get(cond);
  if (!d || d.kind !== 'op') return null;
  const o = d.op;
  if (o.op === 'core.is_number' && !isLit(o.args[0])) return { value: o.args[0], type: t.number };
  if (o.op === 'core.is_int32' && !isLit(o.args[0])) return { value: o.args[0], type: t.int32, onlyTrue: true };
  if (o.op === 'js.strict_eq' || o.op === 'num.eq') {
    const [a, b] = o.args;
    const ty = x => { if (isLit(x)) return null; const dx = defs.get(x); return dx && dx.kind === 'op' && dx.op.op === 'js.typeof' ? dx.op.args[0] : null; };
    for (const [subject, text] of [[ty(a), b], [ty(b), a]]) if (subject && !isLit(subject) && isLit(text) && TYPE_TESTS[text.lit]) return { value: subject, type: TYPE_TESTS[text.lit] };
  }
  if (o.op === 'js.truthy' || o.op === 'core.copy') return refinementOf(fn, defs, o.args[0]);
  return null;
}
```

A refinement is a value and a type. The solver meets the value's type with it on the true edge and subtracts it on the false edge (except for `core.is_int32`, whose false edge says nothing: a value that is not an int32 may still be a number). The `js.strict_eq` case recognises the pattern the frontend emits for `typeof x === "number"`, a `js.typeof` compared with a string literal, in either order.

The effect shows in a two-line function. With the standard rewrites, `function f(x) { if (typeof x === "number") { return x * 2; } return 0; }` compiles its multiplication to `v7 = num.mul(x, 2)`: on the true edge `x` is a number, so `js.mul` narrows. The rule as written has a gap worth knowing. It handles `===` and not `!==`, so the same function written with the test inverted, `if (typeof x !== "number") { return 0; } return x * 2;`, keeps `v7 = js.mul(x, 2)`. The ledger's `deposit` guards with `!==`, so after its guard `amount` is still `any` as far as the engine knows. Handling `js.strict_ne` means swapping which edge gets the meet and which the subtraction; [Exercise 4](lab:book?ch=9&at=exercises) asks for it. [A-03 Type facts and branch refinement](lab:preset?id=A-03) is the preset for this section: [load it](lab:preset?id=A-03) and [select the multiplication in label](lab:node?id=label/then1/0), which the facts narrowed to `num.mul` on the edge where `typeof x === "number"` held.

## 9.6 The running example: the facts of total

Run all three analyses on `total` ([B-01](lab:preset?id=B-01)). Liveness reaches its fixed point in 8 visits (the steps are tabulated in [Chapter 8](lab:book?ch=8) and replayed by [A-02 Liveness, one step at a time](lab:preset?id=A-02)). Types take 10 visits. On the first visit to `for1`, both parameters have only seen the literal 0 from `entry`, so both are `int32`. The loop body then computes `v15 = js.add(n14, 1)`, a number, and `v12 = js.add(sum2_1, v11)`, which is `number|string` because `v11` came from a `js.get` and could be anything. The second visit to `for1` joins these into its parameters: `i3_1` rises from `int32` to `number` and `sum2_1` from `int32` to `number|string`. A third visit changes nothing. Figure 9.2 draws the two climbs in the type lattice.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 260">
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <line x1="300" y1="226" x2="180" y2="180"/><line x1="300" y1="226" x2="300" y2="180"/><line x1="300" y1="226" x2="440" y2="180"/>
    <line x1="180" y1="158" x2="240" y2="112"/><line x1="300" y1="158" x2="240" y2="112"/>
    <line x1="240" y1="90" x2="340" y2="46"/><line x1="440" y1="158" x2="340" y2="46"/>
    <line x1="340" y1="24" x2="340" y2="10" class="dot" stroke-dasharray="1 3"/>
    <rect x="140" y="158" width="80" height="22" class="f-fill"/>
    <rect x="200" y="90" width="80" height="22" class="f-fill" stroke-width="1.6"/>
    <rect x="290" y="24" width="100" height="22" class="f-sel" stroke-width="1.6"/>
    <rect x="260" y="158" width="80" height="22" class="f-paper"/>
    <rect x="400" y="158" width="80" height="22" class="f-paper"/>
    <rect x="270" y="226" width="60" height="22" class="f-paper"/>
  </g>
  <g font-size="11" text-anchor="middle" class="f-ink">
    <text x="300" y="241">⊥</text>
    <text x="180" y="173">int32</text><text x="300" y="173">double</text><text x="440" y="173">string</text>
    <text x="240" y="105" class="b">number</text>
    <text x="340" y="39" class="b">number|string</text>
  </g>
  <g font-size="10" class="f-mut">
    <text x="54" y="166">visit 2:</text><text x="54" y="178">i3_1, sum2_1</text>
    <text x="54" y="100">visit 6: i3_1</text>
    <text x="408" y="32">visit 6: sum2_1</text>
    <text x="352" y="14">towards any</text>
  </g>
</svg>
```

**Figure 9.2.** Part of the type lattice, with the types of `total`'s loop parameters on the solver's visits to `for1`. On visit 2 both are `int32` (the literal 0); on visit 6 the back edge joins in the loop's results, lifting `i3_1` to `number` and `sum2_1` to `number|string`. Visit 10 changes nothing.

Put the facts together at each safepoint, and the plan's required sets come out (from `program.plan('total')`):

| safepoint | live across | required (managed, live across or borrowed) |
|---|---|---|
| `total/for1/1` js.get | c_log, i3_1, sum2_1 | c_log, log5, sum2_1 |
| `total/for1/2` js.lt | c_log, i3_1, sum2_1 | c_log, length6, sum2_1 |
| `total/body2/1` js.get | c_log, i3_1, sum2_1 | c_log, log9, sum2_1 |
| `total/body2/2` js.add | c_log, i3_1 | c_log, sum2_1, v11 |
| `total/next3/0` js.mul | c_log, v12 | c_log, v12 |
| `total/next3/1` js.add | c_log, v12 | c_log, v12 |

Two things stand out. `i3_1` is live across four safepoints and required at none: it is a number, and numbers do not move. And the borrowed operands (`log5`, `length6`, `log9`, `v11`) appear in the required sets although nothing needs them afterwards. Never more than three values are required at once, which is why the default plan for `total` uses three root slots. `sum2_1` is required although it could be a number, because `number|string` includes strings and strings are heap objects; a sharper type for `v11` (knowing that the log holds only numbers) would free that slot. [A-08 Safepoints and live-across](lab:preset?id=A-08) lists these sets for any function, and [J-04 A tokenizer](lab:preset?id=J-04) shows them on a loop over a string.

> **Try it.** [Load B-01](lab:preset?id=B-01), [show total](lab:fn?name=total), [turn on the live overlay](lab:overlay?name=live&on=1) and [the safepoints](lab:overlay?name=safepoints&on=1), then [select the js.add in body2](lab:node?id=total/body2/2): the Inspector shows `c_log` and `i3_1` live across it, and `sum2_1` and `v11` required because the helper borrows them.

## 9.7 Key points

The lowering needs three facts at every collecting point: whether it is a safepoint, which values are live across it, and which of those are managed. Safepoints are a scan for the `mayCollect` obligation. Liveness is backward; its edge rule maps a target's live parameters to the arguments of the edge, ignores literals, and leaves implicit parameters to the edge that defines them. Inside a protected block, every may-throw operation also keeps alive what the handler needs. Types are forward over the type lattice, with result types from the operation table and refinement on branches that test `typeof` with `===` or call `core.is_number`. A safepoint requires its managed live-across values and the managed operands its helper borrows. On `total`, six safepoints require at most three values at once, the number `i3_1` never needs a root, and `sum2_1` needs one only because its type includes strings.

## Exercises

1. In [A-08](lab:preset?id=A-08) or B-01, list the live-across sets of `deposit` with `program.facts('deposit').live.across` and find the safepoint with the largest required set. Which of its values are borrowed rather than live?
2. Compile the function `f` of Section 9.3 and check that `v6` is required at `f/try3/0`. Then remove the `try`/`catch` (keep `o.x;` and `print(tag)` after it) and compare the required set at the `js.get`. Why does `v6` still need a root?
3. Write `total` with `for (const x of log) sum = sum + x;` instead of the indexed loop, in a preset of your own, and compare the safepoints, live-across sets and types with Section 9.6.
4. Extend branch refinement to `!==` on paper: write the lines you would add to `refinementOf` and to the edge function so that `if (typeof amount !== "number") throw …` refines `amount` to `number` on the false edge. Which line of `deposit` would then narrow under the standard rewrites, and which still would not?
5. A project: make `sum2_1` a number. Add a check `if (typeof amount === "number")` around the store into `log` in `deposit` and ask whether the facts of `total` can ever learn what `log` holds. What kind of analysis (across functions, over the heap) would that take?

[Chapter 10](lab:book?ch=10) uses these facts to rewrite programs, and asks what it means for a rewrite to be correct.
