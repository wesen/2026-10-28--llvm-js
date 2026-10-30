# Values and representations

Up to this chapter a value has been a name in the IR and a JavaScript value in the interpreter. A machine has neither: it has 64-bit words in registers and memory. This chapter is about the step from one to the other. It explains how a single word can hold any JavaScript value (NaN-boxing), when a value can live unboxed as a plain double or a boolean, how each operation is bound to an inline instruction, a runtime helper or a direct call (the L2 level), and how the workbench counts the memory all of this needs with quantities that carry units. By the end you will be able to read the L2 view of any function and say, for each operation, what machine code it will become and why.

## 12.1 One word for every value

The type lattice of [Chapter 9](lab:book?ch=9) says which kinds a value may have: `undefined`, `null`, `boolean`, `int32`, `double`, `string`, `object`, `function` and the engine's own `cell` and `completion`. A value whose type is `any` may turn out to be any of them, and the code that holds it does not know which. So the lowered program needs a **representation**: a rule that says how a value of a given type is stored in machine words.

The workbench offers four, as `g.rep`:

| representation | holds | width |
|---|---|---|
| `tagged` | any value | 64 bits |
| `f64` | numbers | 64 bits |
| `i32` | int32 values | 32 bits |
| `bool` | booleans | 32 bits |

`tagged` is the universal one. Every other representation is a promise that the value has a narrower type, and each comes with a test, `canHold(type)`, that says when the promise is safe: `f64` can hold a value of type `number`, `bool` one of type `boolean`, and `tagged` anything. The default pipeline stores every value tagged, which is what Hermes does for every JavaScript value; the rest of this chapter is about what tagging costs and when the compiler may avoid it.

## 12.2 NaN-boxing

A 64-bit IEEE 754 double has a sign bit, an 11-bit exponent and a 52-bit fraction. When the exponent bits are all ones and the fraction is not zero, the word is a NaN, and arithmetic treats every such pattern the same way: nearly $2^{53}$ bit patterns, counting both signs, all mean "not a number". **NaN-boxing** spends that space. A number is stored as its own double bits; every other kind of value is stored in a NaN pattern whose high bits say which kind it is and whose low bits carry the payload (a pointer, or a boolean). One word holds any value, and a double needs no conversion at all.

The workbench writes literal words with `boxBits`:

```js
// core.js
function boxBits(v) {                              // Hermes NaN-boxing: doubles as themselves, the rest tagged
  if (typeof v === 'number') { const b = new DataView(new ArrayBuffer(8)); b.setFloat64(0, v); return '0x' + b.getBigUint64(0).toString(16).toUpperCase().padStart(16, '0'); }
  if (v === true) return '0xFFF9000000000001';
  if (v === false) return '0xFFF9000000000000';
  if (v === null) return '0xFFF8C00000000000';
  return '0xFFF8800000000000';                     // undefined
}
```

The first line writes a number's own bits through a `DataView`; the other lines give each immediate a NaN pattern whose top twelve bits are all ones (the sign and the whole exponent). Booleans share one tag and differ in the lowest bit. The tag values are the workbench's own; they follow the scheme Hermes uses, not its exact bit assignments. Strings and objects are pointers placed in the same space with their own tags, and the workbench never builds those words itself: the runtime helpers return them.

| value | word |
|---|---|
| `10` | `0x4024000000000000` |
| `32` | `0x4040000000000000` |
| `0.5` | `0x3FE0000000000000` |
| `-0` | `0x8000000000000000` |
| `NaN` | `0x7FF8000000000000` |
| `true` | `0xFFF9000000000001` |
| `undefined` | `0xFFF8800000000000` |

The table also shows the one rule the scheme imposes on arithmetic. Hardware is free to produce a NaN with other bits (x86 produces `0xFFF8000000000000` for `0 / 0`), and such a word sits in the region the tags use. So every NaN a program produces must be **canonicalised** to the single pattern `0x7FF8000000000000` before it is stored as a value. JavaScript cannot observe which NaN it has, so this costs nothing in meaning.

Figure 12.1 lays out the word; the shelf doc [Tagged values and NaN-boxing](lab:doc?id=nan-boxing) goes through more of the bit patterns.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 250">
  <text x="20" y="22" font-size="10" class="lbl">a 64-bit word</text>
  <rect x="20" y="32" width="20" height="34" fill="none" stroke="currentColor" class="ink"/>
  <rect x="40" y="32" width="140" height="34" class="f-fill2" stroke="currentColor"/>
  <rect x="180" y="32" width="480" height="34" class="f-fill" stroke="currentColor"/>
  <text x="25" y="54" font-size="11">s</text>
  <text x="70" y="54" font-size="11">exponent · 11 bits</text>
  <text x="350" y="54" font-size="11">fraction · 52 bits</text>
  <text x="20" y="96" font-size="10" class="lbl">a number: its own bits</text>
  <text x="20" y="114" font-size="11" class="it">10</text>
  <text x="80" y="114" font-size="11">0 · 10000000010 · 0100 0000 … 0000</text>
  <text x="440" y="114" font-size="11">= 0x4024000000000000</text>
  <text x="20" y="146" font-size="10" class="lbl">another value: a NaN pattern reserved for tags</text>
  <rect x="20" y="156" width="160" height="30" class="f-acc" stroke="currentColor" opacity="0.25"/>
  <rect x="20" y="156" width="160" height="30" fill="none" stroke="currentColor" class="acc"/>
  <rect x="180" y="156" width="60" height="30" fill="none" stroke="currentColor" class="acc"/>
  <rect x="240" y="156" width="420" height="30" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="176" font-size="11">all ones (sign + exponent)</text>
  <text x="190" y="176" font-size="11">tag</text>
  <text x="300" y="176" font-size="11">payload: a pointer, or 0 / 1 for a boolean</text>
  <text x="20" y="212" font-size="11">true  0xFFF9000000000001</text>
  <text x="240" y="212" font-size="11">null  0xFFF8C00000000000</text>
  <text x="460" y="212" font-size="11">undefined  0xFFF8800000000000</text>
  <text x="20" y="234" font-size="11" class="mut">a NaN the program computes is stored as 0x7FF8000000000000, so it never meets a tag</text>
</svg>
```

**Figure 12.1.** The tagged word. Numbers keep their IEEE 754 bits; immediates and pointers live in NaN patterns whose top twelve bits are set, a region computed NaNs are kept out of by canonicalisation. Schematic; the hexadecimal words are the ones `boxBits` prints.

## 12.3 Unboxed values and the representation choice

Tagging is cheap for numbers, but not free. An operation that receives two tagged words must check their kinds before it can add them, and that check is the job of a runtime helper: `js.add` may meet strings, objects with `valueOf` and so on. When the type facts prove that both operands are numbers, the compiler can skip the check, and the value no longer needs a tag at all. That is what an **unboxed** representation means: the word holds a double (or a boolean) and the compiler has proved it will never hold anything else.

The choice is made per value by `chooseReps`, from the type facts:

```js
// core.js
function chooseReps(fn, types, strategy = 'tagged') {
  const reps = {};
  for (const v of fn.values()) {
    const ty = types.typeOf(v);
    if (strategy === 'unboxWhenProven' && !ty.isBottom && ty.le(t.boolean)) reps[v] = 'bool';
    else if (strategy === 'unboxWhenProven' && !ty.isBottom && ty.le(t.number)) reps[v] = ty.le(t.int32) && false ? 'i32' : 'f64';
    else reps[v] = 'tagged';
  }
  return reps;
}
```

The default strategy, `tagged`, takes the last branch for every value. The strategy `unboxWhenProven` asks the type lattice: a value whose type is at most `boolean` becomes `bool`, a value whose type is at most `number` becomes `f64`, and everything else stays tagged. The test `!ty.isBottom` excludes values the analysis never reached. The `&& false` is deliberate: the workbench never picks `i32` today. An `int32` fact for a loop counter rarely survives its own increment, because `i32.add` wraps where JavaScript addition does not, and the law `g.law.variant('i32.add', 'num.add')` finds the counterexample `117884139 + 2066098173`, which is `-2110984984` in 32 bits and `2183982312` as a double. Choosing `i32` needs an overflow-checked add or range facts, and [C-06 Variants and narrowing](lab:preset?id=C-06) shows the difference.

Here is the companion function `fib` (from FACTS.md) compiled with `g.pipeline().assume({ fib: { n: 'number' } }).rewrites(g.rewrites.standard()).representation('unboxWhenProven')`, at L2:

```text
fn fib(this: any, n: number) -> any {
entry throws unwind:
  jump for1(0, 1, 0)
for1(a3_1: any, b4_1: any, i5_1: any) throws unwind:
  v8 = num.lt(i5_1, n)                       ; inline fcmp olt · v8: bool
  branch v8, body2(), endfor4()
body2() throws unwind:
  v12 = num.add(a3_1, b4_1)                  ; inline fadd · v12: f64
  jump next3()
next3() throws unwind:
  n16 = num.mul(i5_1, 1)                     ; inline fmul · n16: f64
  v17 = num.add(n16, 1)                      ; inline fadd · v17: f64
  jump for1(b4_1, v12, v17)
endfor4() throws unwind:
  return a3_1
}
```

The block parameters are still declared `any`, but the facts proved them numbers, so the plan records `a3_1`, `b4_1` and `i5_1` as `f64` too. Only `this`, which nothing proves anything about, stays tagged. [L-02 Representations](lab:preset?id=L-02) puts the two strategies side by side.

> **Try it.** [Load L-02](lab:preset?id=L-02), [show hyp](lab:fn?name=hyp) at [level L2](lab:level?l=L2) and read the representation after each inline operation; then [load L-01](lab:preset?id=L-01) and [show area](lab:fn?name=area), where every binding is listed with its helper or instruction.

## 12.4 Binding operations: inline, helper, direct

The `lower-runtime` pass takes each operation of L1 and decides how the machine will perform it. There are three answers, and every operation's definition says which one applies through its `lower` field.

- An **inline** binding is an instruction the backend writes directly: `num.add` becomes `fadd`, `num.lt` becomes `fcmp olt`, `i32.add` becomes `add i32`.
- A **helper** binding is a call to a function of the runtime library: `js.get` becomes `shllvm_get`, `js.add` becomes `shllvm_binary` with an operation code. The helper does what the reference interpreter does, on tagged words.
- A **direct** binding is a call to another compiled function whose name is known: `core.call(@sq, n)` becomes `call i64 @sq`.

The pass also copies two facts from the contract onto each binding, because lowering needs them: whether the operation may collect (`collects`) and whether it may throw past the caller (`throws (setjmp)`). The code is short:

```js
// core.js
function bindOps(fn, providers = {}) {
  const bindings = {};
  const bind = (o, id) => {
    const d = lookupOp(o.op), set = SET_OF(o.op);
    const provider = providers[set] || (set === 'core' ? 'reference' : 'hermes');
    const l = d.lower || {};
    bindings[id] = {
      op: o.op, provider, kind: l.inline ? 'inline' : l.direct ? 'direct' : 'helper',
      name: l.inline || (l.direct ? '@' + o.attrs.callee : l.helper || 'shllvm_' + o.op.replace(/\W/g, '_')), code: l.code,
      collects: d.mayCollect, throws: d.mayThrow, nonlocal: d.obligations.has('nonlocalThrow'),
    };
  };
```

The provider comes first: each operation belongs to a set (`core`, `js.value`, `js.object`, `js.function`, `js.control`), and a pipeline can say who implements each set. By default the `core` set is implemented by the workbench's reference code and the four JavaScript sets by Hermes, which is why the helper names follow the `shllvm_*` convention of the Hermes LLVM backend. [C-08 Providers and operation sets](lab:preset?id=C-08) swaps them, and [L-01 Bound to helpers](lab:preset?id=L-01) lists every binding of a program with its helper name. Then the kind, the name (an inline instruction, `@callee` for a direct call, or the helper name), and the obligations that later passes read.

Figure 12.2 shows the same loop header bound two ways.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="22" font-size="10" class="lbl">default pipeline: n may be anything</text>
  <rect x="20" y="32" width="310" height="70" fill="none" stroke="currentColor" class="ink"/>
  <text x="32" y="52" font-size="11" class="b">for1(a3_1, b4_1, i5_1)</text>
  <text x="32" y="72" font-size="11">v8 = js.lt(i5_1, n)</text>
  <text x="32" y="90" font-size="11">branch v8, body2(), endfor4()</text>
  <line x1="200" y1="68" x2="370" y2="68" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <rect x="372" y="44" width="310" height="48" class="f-acc" opacity="0.18" stroke="none"/>
  <rect x="372" y="44" width="310" height="48" fill="none" stroke="currentColor" class="acc"/>
  <text x="384" y="64" font-size="11">call shllvm_binary(lt)</text>
  <text x="384" y="82" font-size="11" class="mut">collects · throws (setjmp) · a safepoint</text>
  <text x="20" y="140" font-size="10" class="lbl">assume n: number, standard rewrites</text>
  <rect x="20" y="150" width="310" height="70" fill="none" stroke="currentColor" class="ink"/>
  <text x="32" y="170" font-size="11" class="b">for1(a3_1, b4_1, i5_1)</text>
  <text x="32" y="190" font-size="11">v8 = num.lt(i5_1, n)</text>
  <text x="32" y="208" font-size="11">branch v8, body2(), endfor4()</text>
  <line x1="200" y1="186" x2="370" y2="186" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <rect x="372" y="162" width="310" height="48" fill="none" stroke="currentColor" class="ink"/>
  <text x="384" y="182" font-size="11">inline fcmp olt</text>
  <text x="384" y="200" font-size="11" class="mut">no call, no collection, nothing to root</text>
  <text x="20" y="242" font-size="11" class="mut">fib: 4 safepoints and 1 root slot before; 0 and 0 after (frame 4 slots, then 3)</text>
</svg>
```

**Figure 12.2.** The binding follows the facts. With `n` unknown, the comparison is a helper call that may run user code and collect; once `n` is a number and the rewrite has narrowed `js.lt` to `num.lt`, it is one instruction. The counts are from `program.plan('fib')` for both pipelines.

> **Try it.** [Load B-01](lab:preset?id=B-01), [switch the IR view to L2](lab:level?l=L2) and [select deposit](lab:fn?name=deposit). Every operation of `deposit` is a helper; [the js.add](lab:node?id=deposit/endif2/1) is marked `collects · throws (setjmp)`.

## 12.5 What the representation buys

The difference is not only speed. A helper call that may collect is a **safepoint** ([Chapter 9](lab:book?ch=9)), and every managed value live across a safepoint needs a root slot ([Chapter 13](lab:book?ch=13)). An inline instruction cannot collect, so narrowing an operation removes a safepoint, and with it the need to root what is live across it. Measured on `fib`:

| pipeline | `js.*` helpers in fib | safepoints | root slots | frame slots |
|---|---|---|---|---|
| default | 4 | 4 | 1 | 4 |
| assume `n: number` + standard rewrites | 0 | 0 | 0 | 3 |

The three frame slots that remain are the two fixed slots every function has and one slot for outgoing arguments. The function's whole state lives in unboxed doubles that the collector never needs to see. This is the chain of reasoning the book has been building: a fact (from an assumption or an analysis) earns a variant ([Chapter 7](lab:book?ch=7)), the variant is a pure operation, a pure operation binds inline, and an inline operation is not a safepoint. [T-04 Narrowing by facts](lab:preset?id=T-04) shows the same chain on the ledger.

## 12.6 Quantities, units and layouts

A lowered program is also a set of memory demands: so many slots in a frame, so many bytes of arena, a limit of so many slots per native frame. The workbench counts them with **quantities**, numbers that carry a unit, because a count of slots and a count of bytes are easy to confuse and the confusion produces wrong limits rather than errors.

```js
// core.js
class Quantity {
  constructor(n, unit) { this.n = n; this.unit = unit; Object.freeze(this); }
  same(q, verb) {
    if (!(q instanceof Quantity)) throw new DimensionError(`cannot ${verb} a plain number and ${this.unit}; give it a unit`);
    if (q.unit !== this.unit) throw new DimensionError(`cannot ${verb} ${q.unit} and ${this.unit}; convert through a layout`);
    return q.n;
  }
  add(q) { return new Quantity(this.n + this.same(q, 'add'), this.unit); }
```

Every operation that combines two quantities goes through `same`, which refuses a plain number and refuses a different unit. `slots(3).add(slots(4))` is `7 slots`; `slots(3).add(bytes(8))` throws a `DimensionError` that says to convert through a layout. Quantities of one unit form a vector space: they add, subtract and scale by plain numbers, and `g.law.vectorSpace(slots)` checks associativity, commutativity and distributivity on 1,000 samples.

The only way from slots to bytes is a **layout**, which knows the size of a slot on a target:

```js
// core.js
const layout = {
  host64: {
    name: 'host64', slotBytes: 8, align: 16,
    bytes(q) { if (q.unit !== 'slots') throw new DimensionError('layout.bytes takes slots'); return bytes(q.n * 8); },
```

On a 64-bit host a slot is one tagged word, 8 bytes, so `g.layout.host64.bytes(slots(7))` is `56 B`, the frame of `deposit`. The plan's `frameBytes` is computed the same way, and a limit is a quantity too: `g.limit('native frame', { measure: p => slots(p.metrics().maxFrameSlots), max: slots(1024) })` compares slots with slots and reports both in bytes (`8 KiB` for the limit). [B-05 Quantities and layouts](lab:preset?id=B-05) has the examples.

## 12.7 The running example: the ledger at L2

The ledger's values are almost all `any`: `amount` comes from a caller, `balance` and `log` from cells, `sum` from adding array elements. So under the default pipeline every operation of `deposit` and `total` binds to a helper, and the representation strategy changes nothing, because no value of theirs has a type below `number` except the loop counter. Here is `total` at L2:

```text
fn total(c_log: cell, this: any) -> any {
entry throws unwind:
  jump for1(0, 0)
for1(sum2_1: any, i3_1: any) throws unwind:
  log5 = cell.load_checked(c_log)            ; call shllvm_check_tdz · throws (setjmp)
  length6 = js.get(log5, "length")           ; call shllvm_get · collects · throws (setjmp)
  v7 = js.lt(i3_1, length6)                  ; call shllvm_binary(lt) · collects · throws (setjmp)
  branch v7, body2(), endfor4()
body2() throws unwind:
  log9 = cell.load_checked(c_log)            ; call shllvm_check_tdz · throws (setjmp)
  v11 = js.get(log9, i3_1)                   ; call shllvm_get · collects · throws (setjmp)
  v12 = js.add(sum2_1, v11)                  ; call shllvm_binary(add) · collects · throws (setjmp)
  jump next3()
next3() throws unwind:
  n14 = js.mul(i3_1, 1)                      ; call shllvm_binary(mul) · collects · throws (setjmp)
  v15 = js.add(n14, 1)                       ; call shllvm_binary(add) · collects · throws (setjmp)
  jump for1(v12, v15)
endfor4() throws unwind:
  return sum2_1
}
```

The type facts already know that `i3_1` is a `number` (it starts at `0` and only ever grows by `js.add(n14, 1)` where `n14` is the result of `js.mul`, which always returns a number). The default rewrites do not use that fact; the standard set does. With `g.rewrites.standard()`, `n14 = js.mul(i3_1, 1)` becomes `num.mul` bound to `inline fmul` and `v15` becomes `inline fadd`, and the safepoints of `total` drop from 6 to 4. The other four stay, because `log[i]` and `sum + log[i]` really may run user code: an element of the array could be an object with a `valueOf`. The ledger's 15 root slots do not change, since the values the two narrowed operations had to root are rooted at the remaining safepoints anyway.

> **Try it.** [Load B-01](lab:preset?id=B-01), [select n14 = js.mul in total](lab:node?id=total/next3/0) and [show the plan](lab:show?view=plan). Then change `main.js` to `g.pipeline().rewrites(g.rewrites.standard())`, [rerun](lab:build), and select the same operation again: it is now `num.mul`, inline, and no longer a safepoint.

## 12.8 Key points

A machine holds values in 64-bit words, and the tagged representation stores any JavaScript value in one word by NaN-boxing: numbers keep their double bits, and everything else lives in NaN patterns no computed double can take, provided computed NaNs are canonicalised. An unboxed representation (`f64`, `bool`) is a promise backed by a type fact, chosen per value by the representation strategy; the workbench does not choose `i32` because 32-bit addition wraps. The `lower-runtime` pass binds each operation to an inline instruction, a runtime helper or a direct call, and copies the obligations that matter to lowering: whether it may collect and whether it may throw past the caller. Narrowing an operation turns a helper into an instruction and removes a safepoint, which is the main reason facts matter to a JavaScript compiler. Sizes are quantities with units, and slots become bytes only through a layout.

## Exercises

1. In [B-01](lab:preset?id=B-01), find the operations of `deposit` whose L2 annotation has neither `collects` nor `throws`. What do their contracts say, and why are they still helper calls rather than inline instructions?
2. Compute by hand the tagged words of `42`, `-1` and `Infinity`, then check them against the `store i64` lines of a program that uses them as literals (look at the LLVM level).
3. In [L-02](lab:preset?id=L-02), compile `fib` with `representation('unboxWhenProven')` but without the assumption on `n`. Which values become `f64`, and why are there so few?
4. Write `g.layout.host64.slots(bytes(20))` and explain the answer. Then write an expression that throws a `DimensionError` and read its message.
5. A short project: write a script that lists, for every function of a program, the values whose type in `program.facts(fn).types` is `int32` (the map prints types as text). Run it on the J presets. For each value, decide whether a 32-bit representation would be safe, using `g.law.variant('i32.add', 'num.add')` as the reason it usually is not.

The next chapter takes the managed values that stayed tagged and asks what a moving garbage collector needs from the compiled code to keep them correct.
