# Garbage collection and roots

A JavaScript program allocates objects and never frees them; a garbage collector finds the ones nothing can reach and reuses their memory. A moving collector also relocates the survivors, which keeps the heap compact and allocation fast, and it is what Hermes uses. Relocation creates the central obligation of lowering: compiled code that holds a reference to an object across a collection must hold it somewhere the collector can see and update. This chapter explains that obligation, how the workbench plans for it with root slots, the three strategies that choose the slots, the one checker that judges every plan, and the simulated collector that turns a missing root into a reported stale reference instead of a crash. It ends with the limit that made the whole question concrete: a native frame of at most 1,024 slots.

## 13.1 Moving collection and stale references

A **moving collector** copies every object it can reach from a set of starting points, the **roots**, into fresh memory, and then treats the old memory as free. Each object it copies gets a new address, and the collector rewrites every reference it knows about: the fields of copied objects, the global variables, the job queues and the roots. It cannot rewrite a reference it does not know about. A machine register, or a stack location the collector was not told about, still holds the old address after the collection, and the next instruction that uses it reads freed memory.

That stale address is the bug this chapter is about. It does not fail at once: the old memory often still holds the old bytes for a while, so the program may run correctly until the memory is reused. A compiler cannot test its way out of it; it has to prove, for every point where a collection can happen, that every reference the code still needs is in a place the collector updates. Figure 13.1 shows the two cases, and the shelf doc [Moving collectors and root slots](lab:doc?id=gc-roots) collects the vocabulary of this chapter.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 270">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="22" font-size="10" class="lbl">before the collection</text>
  <text x="370" y="22" font-size="10" class="lbl">after the collection</text>
  <rect x="20" y="40" width="90" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="58" font-size="11">slot s1 · 0x10</text>
  <rect x="20" y="96" width="90" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="114" font-size="11">register · 0x10</text>
  <rect x="190" y="60" width="120" height="44" class="f-fill" stroke="currentColor"/>
  <text x="200" y="78" font-size="11" class="b">object #9</text>
  <text x="200" y="94" font-size="11" class="mut">at 0x10</text>
  <line x1="110" y1="54" x2="188" y2="72" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="110" y1="110" x2="188" y2="94" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <rect x="370" y="40" width="90" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="380" y="58" font-size="11">slot s1 · 0x40</text>
  <rect x="370" y="96" width="90" height="28" fill="none" stroke="currentColor" class="acc"/>
  <text x="380" y="114" font-size="11" class="acc">register · 0x10</text>
  <rect x="560" y="40" width="120" height="44" class="f-fill" stroke="currentColor"/>
  <text x="570" y="58" font-size="11" class="b">object #9</text>
  <text x="570" y="74" font-size="11" class="mut">moved to 0x40</text>
  <rect x="560" y="110" width="120" height="44" fill="none" stroke="currentColor" class="mut dash"/>
  <text x="570" y="128" font-size="11" class="mut">0x10: freed</text>
  <line x1="460" y1="54" x2="558" y2="58" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="460" y1="110" x2="558" y2="128" stroke="currentColor" class="acc dash" marker-end="url(#arrow)"/>
  <line x1="340" y1="30" x2="340" y2="170" stroke="currentColor" class="hair"/>
  <text x="20" y="200" font-size="11">The collector copies object #9 and rewrites the root slot it was told about.</text>
  <text x="20" y="220" font-size="11">The register still holds 0x10; the next use of it is a stale reference.</text>
  <text x="20" y="250" font-size="10" class="lbl">schematic: addresses are illustrative</text>
</svg>
```

**Figure 13.1.** A moving collection rewrites the roots it knows and nothing else. The object keeps its identity (#9) and changes its address; a copy of the old address outside the roots is left pointing at freed memory. Schematic.

## 13.2 Root slots and the frame

The workbench's answer, like the Hermes LLVM backend's, is a **root slot**: a word in the function's frame that the runtime registers with the collector. The compiled code keeps each managed value that must survive a collection in a slot, passes helpers pointers to slots, and reads the value back from the slot after any call that may have collected. A **safepoint**, from [Chapter 9](lab:book?ch=9), is exactly such a call: an operation whose contract carries the obligation `mayCollect`.

The frame of a function on the native stack has three parts after its root slots: two fixed slots, `scratch` (for literal operands and fetched callees) and `discard` (for results nobody reads), and an outgoing argument area big enough for the largest call. So the size is

$$
\mathrm{frameSlots} = \mathrm{rootSlots} + 2 + \mathrm{argSlots},
$$

and on a 64-bit host each slot is 8 bytes ([Chapter 12](lab:book?ch=12)). For `deposit` the plan has 4 root slots and 1 argument slot, so $4 + 2 + 1 = 7$ slots, 56 B. Figure 13.2 draws it from the plan.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 220">
  <text x="20" y="22" font-size="10" class="lbl">frame of deposit · stackReuse · 7 slots · 56 B</text>
  <rect x="20" y="36" width="90" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="110" y="36" width="90" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="200" y="36" width="90" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="290" y="36" width="90" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="380" y="36" width="90" height="40" class="f-fill2" stroke="currentColor"/>
  <rect x="470" y="36" width="90" height="40" class="f-fill2" stroke="currentColor"/>
  <rect x="560" y="36" width="90" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="60" font-size="11" class="b">s0</text>
  <text x="120" y="60" font-size="11" class="b">s1</text>
  <text x="210" y="60" font-size="11" class="b">s2</text>
  <text x="300" y="60" font-size="11" class="b">s3</text>
  <text x="390" y="60" font-size="11">scratch</text>
  <text x="480" y="60" font-size="11">discard</text>
  <text x="570" y="60" font-size="11">argv[0]</text>
  <text x="30" y="98" font-size="11" class="it">amount</text>
  <text x="120" y="98" font-size="11" class="it">balance7</text>
  <text x="120" y="114" font-size="11" class="it">log11</text>
  <text x="210" y="98" font-size="11" class="it">c_balance</text>
  <text x="300" y="98" font-size="11" class="it">c_log</text>
  <text x="300" y="114" font-size="11" class="it">log12</text>
  <text x="300" y="130" font-size="11" class="it">length13</text>
  <line x1="20" y1="150" x2="380" y2="150" stroke="currentColor" class="ink"/>
  <text x="20" y="168" font-size="10" class="lbl">root slots: seen and updated by the collector</text>
  <line x1="380" y1="150" x2="560" y2="150" stroke="currentColor" class="mut"/>
  <text x="390" y="168" font-size="10" class="lbl">fixed</text>
  <line x1="560" y1="150" x2="650" y2="150" stroke="currentColor" class="mut"/>
  <text x="570" y="168" font-size="10" class="lbl">arguments</text>
  <text x="20" y="200" font-size="11" class="mut">values sharing a slot are never needed at the same safepoint</text>
</svg>
```

**Figure 13.2.** The frame of `deposit` under the default strategy, from `program.plan('deposit')`: seven values in four root slots, then the two fixed slots and one outgoing argument.

## 13.3 What a plan must root

At each safepoint, which values need a slot? Two kinds. A value is **live across** the safepoint if the code reads it after the call returns ([Chapter 9](lab:book?ch=9) computes these sets). And a value is **borrowed** by the safepoint if it is one of the call's own operands: the helper reads its operands, may collect while it runs, and reads them again, so they must be in slots the collector updates for the duration of the call. Of these values only managed ones count, the kinds that live in the heap.

```js
// core.js
const ROOT_KINDS = KBIT.object | KBIT.function | KBIT.cell | KBIT.completion | KBIT.string;
const needsRoot = ty => (ty.bits & ROOT_KINDS) !== 0;
// …
function requiredRoots(fn, live, types, site) {
  const across = live.across[site.id] || [];
  const borrowed = site.op.args.filter(a => !isLit(a));
  const need = new Set();
  for (const v of [...across, ...borrowed]) if (needsRoot(types.typeOf(v))) need.add(v);
  return [...need].sort();
}
```

`ROOT_KINDS` is the set of kinds stored as heap pointers; strings are among them because in Hermes a string is a heap object. `needsRoot` asks whether a type contains any of them, so a value of type `any` needs a root and a value of type `number` does not. `requiredRoots` takes the live-across set of the site, adds the site's non-literal operands, and keeps the managed ones. At `total/body2/2`, the `js.add(sum2_1, v11)` of the ledger's loop, the live-across set is `c_log, i3_1`: the cell is needed on the next turn, and so is the counter. The required set is `c_log, sum2_1, v11`: the counter drops out because its type is `number`, and the two operands come in as borrowed even though neither is live after the add.

## 13.4 Three strategies and the native frame limit

Which slot each required value gets is a **root strategy**, one of the four-way slots of the pipeline ([Chapter 11](lab:book?ch=11)).

- `distinct` gives every managed value its own slot, which is what the Hermes LLVM backend does today. It is simple and its safety is easy to see, and it wastes slots: a value used once near the top of a function keeps its slot to the end.
- `stackReuse`, the default, lets two values share a slot when no safepoint requires both. That is a graph colouring problem: values are nodes, two values required at the same safepoint are joined by an edge, and slots are colours.
- `arena` takes `distinct`'s slots but puts them in chunks of memory the runtime owns instead of on the native stack, so the native frame stays small however many roots a function has.

The colouring is greedy, in the order values are first required:

```js
// core.js
  stackReuse(fn, ctx) {                            // colour the values rooted at the same points
    const slotOf = {}, order = [], seen = new Set(), sitesOf = new Map();
    const needs = ctx.sites.map(s => ctx.required(s));
    needs.forEach((need, k) => { for (const a of need) { if (!seen.has(a)) { seen.add(a); order.push(a); sitesOf.set(a, []); } sitesOf.get(a).push(k); } });
    const words = Math.ceil((order.length + 1) / 32) + 1;
    const used = needs.map(() => new Uint32Array(words));
    let n = 0;
    const taken = new Uint32Array(words);
    for (const v of order) {
      taken.fill(0);
      for (const k of sitesOf.get(v)) { const u = used[k]; for (let w = 0; w < words; w++) taken[w] |= u[w]; }
      let slot = 0; while (taken[slot >>> 5] & (1 << (slot & 31))) slot++;
      slotOf[v] = slot; n = Math.max(n, slot + 1);
      for (const k of sitesOf.get(v)) used[k][slot >>> 5] |= 1 << (slot & 31);
    }
    return { slotOf, rootSlots: n, storage: 'native stack' };
  },
```

The first two lines collect, for every safepoint, its required set (`needs`), and for every value the safepoints that require it (`sitesOf`), in `order`, the order in which values are first required. The graph is never built as a list of edges. Instead each safepoint keeps a bitmap, `used`, of the slots already given to values it requires. To colour `v`, the loop ORs together the bitmaps of `v`'s safepoints: the bits set in `taken` are exactly the slots of `v`'s neighbours that already have a colour, because two values are neighbours precisely when some safepoint requires both. `v` takes the lowest clear bit, and that slot is marked in each of its safepoints' bitmaps. The colouring is the same as with explicit edges; the cost is the number of (value, safepoint) pairs times the bitmap's width, not the square of the number of values at each safepoint, which keeps the planning of a function with a thousand live objects (the scratch function at the end of section 13.4) to under a second (0.78 s in Node). Greedy colouring is not optimal in general, but the conflict graphs of straight-line code with short-lived temporaries are close to interval graphs, where colouring in order of first appearance does well. Figure 13.3 shows the graph for `total`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 250">
  <line x1="318" y1="52" x2="158" y2="122" stroke="currentColor" class="ink"/>
  <line x1="326" y1="61" x2="261" y2="169" stroke="currentColor" class="ink"/>
  <line x1="343" y1="65" x2="358" y2="180" stroke="currentColor" class="ink"/>
  <line x1="357" y1="59" x2="457" y2="175" stroke="currentColor" class="ink"/>
  <line x1="364" y1="49" x2="561" y2="123" stroke="currentColor" class="ink"/>
  <line x1="151" y1="57" x2="315" y2="42" stroke="currentColor" class="ink"/>
  <line x1="126" y1="90" x2="136" y2="110" stroke="currentColor" class="mut"/>
  <line x1="140" y1="84" x2="234" y2="174" stroke="currentColor" class="mut"/>
  <line x1="146" y1="78" x2="342" y2="190" stroke="currentColor" class="mut"/>
  <line x1="150" y1="70" x2="451" y2="184" stroke="currentColor" class="mut"/>
  <circle cx="340" cy="40" r="25" class="f-fill2" stroke="currentColor"/>
  <text x="321" y="44" font-size="11" class="b">c_log</text>
  <circle cx="120" cy="60" r="31" class="f-sel" stroke="currentColor"/>
  <text x="99" y="64" font-size="11" class="b">sum2_1</text>
  <circle cx="140" cy="130" r="20" class="f-paper" stroke="currentColor"/>
  <text x="125" y="134" font-size="11">log5</text>
  <circle cx="250" cy="190" r="22" class="f-paper" stroke="currentColor"/>
  <text x="227" y="194" font-size="11">length6</text>
  <circle cx="360" cy="200" r="20" class="f-paper" stroke="currentColor"/>
  <text x="345" y="204" font-size="11">log9</text>
  <circle cx="470" cy="190" r="20" class="f-paper" stroke="currentColor"/>
  <text x="456" y="194" font-size="11">v11</text>
  <circle cx="580" cy="130" r="20" class="f-paper" stroke="currentColor"/>
  <text x="566" y="134" font-size="11">v12</text>
  <text x="380" y="30" font-size="10" class="lbl">s0</text>
  <text x="62" y="30" font-size="10" class="lbl">s2</text>
  <text x="560" y="100" font-size="10" class="lbl">s1</text>
  <text x="440" y="226" font-size="10" class="lbl">s1</text>
  <text x="20" y="240" font-size="11" class="mut">log5, length6, log9, v11 and v12 are never required together, so all five share s1</text>
</svg>
```

**Figure 13.3.** The conflict graph of `total`, from the required sets of its six safepoints in FACTS.md. `c_log` conflicts with everything, `sum2_1` with the four temporaries of the loop header and body; the five temporaries share slot s1. Three colours, three root slots.

Measured on the ledger, per function, as root slots / frame slots / frame bytes:

| function | distinct | stackReuse | arena |
|---|---|---|---|
| main | 20 / 24 / 192 B | 3 / 7 / 56 B | 20 / 20 / 192 B |
| makeLedger | 8 / 12 / 96 B | 4 / 8 / 64 B | 8 / 8 / 96 B |
| deposit | 11 / 14 / 112 B | 4 / 7 / 56 B | 11 / 11 / 120 B |
| total | 7 / 10 / 80 B | 3 / 6 / 48 B | 7 / 7 / 88 B |

For the arena the bytes are the activation's storage in the runtime's chunk (a 32 B header plus 8 B per slot), not native stack.

The distinction matters because of a limit. The Hermes LLVM backend refuses a function whose frame needs more than 1,024 slots, counting roots, the two fixed slots and the arguments; the workbench copies the rule as `NATIVE_FRAME_LIMIT`. The limit was met in practice: in the Hermes backend work this workbench was built to study, the unoptimised factory function of the fflate compression library requested 1,084 root slots and three argument slots, and was refused. That measurement says the emitter's storage ran out, not that 1,084 values are ever live at once. The workbench shows both quantities separately. A scratch function that creates 1,030 objects and adds them all at the end keeps all of them live, so even `stackReuse` needs $1{,}030 + 2 + 1 = 1{,}033$ slots, and `check-plan` refuses it with "wide exceeds the 1024-slot native frame limit"; with `arena` the same function compiles and needs 16,504 B of runtime storage (the arena keeps `distinct`'s one slot per managed value: the 1,030 objects and the 1,029 partial sums, 2,059 slots). [L-07 The 1,024-slot frame](lab:preset?id=L-07) measures this on [its function wide](lab:fn?name=wide), and [L-03 Root strategies compared](lab:preset?id=L-03) runs the three strategies on the ledger.

## 13.5 One checker for every plan

A strategy is an opinion; correctness is not. Every plan, whether from a built-in strategy, a lambda that wraps one, or a lambda written from scratch ([L-06 Your own root strategy](lab:preset?id=L-06)), goes through the same check before anything is emitted:

```js
// core.js
  for (const s of sites) {
    const need = required(s), rooted = [], miss = [], bySlot = new Map();
    for (const v of need) {
      const slot = chosen.slotOf[v];
      if (slot === undefined) { miss.push(v); continue; }
      if (bySlot.has(slot)) { miss.push(v); continue; }
      bySlot.set(slot, v); rooted.push(v);
    }
```

For every safepoint, each required value must have a slot, and no two required values may have the same slot, since a slot holds one word. A value that fails either test is **missing** at that site, and `check-plan` turns each missing value into an error naming the value, the operation, whether it was live across or borrowed, and the reason. The strategy `none` exists to show what this looks like: on the ledger it assigns nothing and the checker reports 98 missing roots. A strategy cannot opt out of the check; it can only produce a plan that passes it. That is the composability claim of [Chapter 11](lab:book?ch=11) at work: strategies can be swapped freely because the invariant they must meet is stated once and checked by code that none of them controls.

## 13.6 The simulated collector

A plan that passes the checker is correct by argument. The workbench also tests it by running it. The **L3 executor** (`program.run({ mode: 'plan' })`) runs the lowered program with a collector that really moves objects: with `gc: 'stress'` it collects at every safepoint, with `gc: 'alloc'` after every 16 allocations. Its roots are what the plan says: for each frame on the stack, the slots the plan roots at that frame's current operation, plus the globals, the builtins and the queues. Everything it copies gets a fresh address; everything else is dropped.

The other half is detection. Every read of a value from a frame goes through `value`:

```js
// core.js
  value(a, frame) {
    if (isLit(a)) return a.lit;
    if (!frame.env.has(a)) throw new StrataError(`${a} has no value in ${frame.fn.name} (at ${frame.at})`);
    const v = frame.env.get(a);
    if (this.mode === 'plan' && v && v.isRef && !this.heap.has(v.addr)) {
      const detail = { value: a, oid: v.oid, collectedAt: this.movedAt.get(v.addr) || '?', at: frame.at };
      this.event('stale', detail);
      throw new StaleUse(detail);
    }
    return v;
  }
```

A reference carries an address and a permanent object id. After a collection the heap contains only new addresses, so a reference the collector did not rewrite has an address the heap no longer has, whether its object was moved or freed. That is the poisoning: the old address of every object becomes invalid at once, and the first read of a stale copy stops the run with a `stale` event and the message the plan deserves. Helpers are treated differently, on purpose. A runtime helper such as `shllvm_get` holds its operands through handles, which the real runtime updates, so the executor lets a helper find an object moved during its own call (`deref` follows a forwarding table for the duration of one helper). Only the compiled code's registers can go stale, which is the part of the system the plan is responsible for.

## 13.7 The running example: 68 collections, no stale use

Under the default pipeline the ledger's six functions need 15 root slots in all, against 52 for `distinct`. Run in plan mode with GC stress, the program collects 68 times and moves 995 objects in total, and its output is the specification's: `rejected: amount must be a number`, `main 42 42`, `audit 42`, with `observe.equal` reporting the three observations equal. Here is the plan of `total` that made that true:

```text
; plan for total: stackReuse, native stack
; frame: 3 root slots + 2 fixed + 1 argument = 6 slots, 48 B
;   s0: c_log
;   s1: log5, length6, log9, v11, v12
;   s2: sum2_1
fn total(c_log: cell, this: any) -> any {
entry throws unwind:
  jump for1(0, 0)
for1(sum2_1: any, i3_1: any) throws unwind:
  log5 = cell.load_checked(c_log)            ; call shllvm_check_tdz
  length6 = js.get(log5, "length")           ; safepoint · rooted s0=c_log s1=log5 s2=sum2_1
  v7 = js.lt(i3_1, length6)                  ; safepoint · rooted s0=c_log s1=length6 s2=sum2_1
  branch v7, body2(), endfor4()
body2() throws unwind:
  log9 = cell.load_checked(c_log)            ; call shllvm_check_tdz
  v11 = js.get(log9, i3_1)                   ; safepoint · rooted s0=c_log s1=log9 s2=sum2_1
  v12 = js.add(sum2_1, v11)                  ; safepoint · rooted s0=c_log s2=sum2_1 s1=v11
  jump next3()
next3() throws unwind:
  n14 = js.mul(i3_1, 1)                      ; safepoint · rooted s0=c_log s1=v12
  v15 = js.add(n14, 1)                       ; safepoint · rooted s0=c_log s1=v12
  jump for1(v12, v15)
endfor4() throws unwind:
  return sum2_1
}
```

Each annotation is the checker's verdict at one safepoint. `sum2_1` holds slot s2 across the whole loop because it is required at every safepoint of the header and body; in `next3` the running sum has become `v12`, which reuses s1.

Now break it. With `g.pipeline().roots('none').checks({ gcSafety: false })` the missing roots become warnings, the program compiles, and the plan run stops at once: "stale reference: f4 (object #9) was not rooted, so the collection at main/entry/2 freed it; it was then used at main/entry/2". The closure `f4` was created by the operation before, the call at `main/entry/2` collected before reading its callee, and nothing held `f4`. Recursion multiplies the same accounting by depth. Measured with a scratch script, the doubly recursive Fibonacci `function f(n) { return n < 2 ? n : f(n - 1) + f(n - 2); }` called as `f(15)` has 3 root slots in a 7-slot frame, reaches a depth of 16 frames and a peak of 110 slots (880 B) of frames on the stack, and survives 6,907 collections under stress with the right answer, 610. [J-06 Recursion](lab:preset?id=J-06) has recursive programs of its own, including one that runs out of stack.

> **Try it.** [Load B-01](lab:preset?id=B-01), [run it in plan mode with GC stress](lab:run?mode=plan&gc=stress), [show the Plan](lab:show?view=plan) and [turn on the roots overlay](lab:overlay?name=roots&on=1). Then [load L-05 A stale reference, caught](lab:preset?id=L-05), [show pair](lab:fn?name=pair), [turn on the stale overlay](lab:overlay?name=stale&on=1) and [open the Events](lab:show?view=events) to see a plan with one root removed fail under stress; [L-04 A plan with a hole](lab:preset?id=L-04) shows the checker refusing such a plan before it runs.

## 13.8 Key points

A moving collector rewrites the references it knows, so every managed value compiled code needs after a safepoint must sit in a root slot. A safepoint requires the managed values live across it and the managed operands it borrows. Root strategies choose slots: `distinct` gives one per value, `stackReuse` colours the conflict graph of required sets, and `arena` moves the slots out of the native frame. One checker judges every plan by the same invariant, at every safepoint: each required value has a slot and no two share one. The L3 executor tests plans by moving every object at every safepoint and reporting the first read of an old address. The native frame limit of 1,024 slots, inherited from the Hermes backend, is a storage limit, and `stackReuse` and `arena` attack it in different ways.

## Exercises

1. In [B-01](lab:preset?id=B-01), read the plan of `makeLedger` and find two values that share a slot. Name a safepoint between them and explain why neither is required there.
2. Change the default strategy in [L-03](lab:preset?id=L-03) to `distinct` and rerun with GC stress. Does the number of collections change? Should it?
3. Write a lambda strategy that calls `ctx.default()` and then moves one value to a fresh slot. Check that the plan still passes, and count the new frame size.
4. Write a program in the subset where a value is borrowed by a safepoint but not live across it, and confirm in the Plan view that it is rooted only there.
5. A short project: implement a strategy that colours values in order of decreasing number of conflicts instead of first appearance, compare it with `stackReuse` on the J presets with `g.search.grid`, and report whether it ever uses fewer slots.

The next chapter follows the other obligation a helper can impose on compiled code: an exception that leaves the helper and must arrive at the right handler with the frame in a known state.
