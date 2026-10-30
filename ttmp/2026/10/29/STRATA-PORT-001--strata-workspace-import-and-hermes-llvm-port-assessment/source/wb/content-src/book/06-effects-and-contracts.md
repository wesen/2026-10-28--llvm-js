# Effects and contracts

Every optimisation a compiler performs rests on a claim about what an operation may do. Deleting an operation whose result nobody uses is correct only if the operation does nothing else; moving one past another is correct only if neither can see the other's work. This chapter gives each operation a **contract**: a **behaviour** that bounds what it may do to the program's state, and **obligations** that say what the lowering must provide when it runs. By the end you will know how behaviours combine, why they form a join-semilattice, what the 69 standard operations promise, and how to add an operation of your own that the rest of the engine understands.

The next chapter turns these contracts into permissions. This one is about the contracts themselves.

## 6.1 Why a compiler needs to know what an operation may do

Look at the start of the ledger's `main` in core IR ([B-01](lab:preset?id=B-01), level L1):

```text
fn main() -> any {
entry throws unwind:
  c_ledger3 = cell.new()
  f4 = js.closure(@makeLedger)
  r6 = js.call(f4, undefined, "main")
  cell.store(c_ledger3, r6)
  ledger7 = cell.load(c_ledger3)
  r8 = js.call_method(ledger7, "deposit", 10)
```

Nothing reads `r8`. A compiler that deleted every operation with an unused result would delete the deposit, and the program would print `main 32 32` instead of `main 42 42`. The call is there for what it does, not for what it returns. On the other hand `ledger7 = cell.load(c_ledger3)` only reads a cell; if nothing used `ledger7`, deleting the load would change nothing a program can observe.

A compiler could answer such questions case by case: a flag on each instruction saying "has side effects", another saying "may throw", a list of special cases in each pass. Hermes and LLVM both carry per-instruction side-effect descriptions of this kind. The workbench takes one step further: every operation has a single summary of what it may do, and every question a pass asks is derived from that summary. The summary is the contract's first half.

## 6.2 Behaviours

A **behaviour** is an upper bound on what an operation may do. It names the **resources** the operation may read or write (`heap`, `cells`, `jobs`, `timers`, `globals`, and `engine` for the engine's own state), and five flags: whether it may allocate a new identity (`fresh`), throw (`throws`), fail to return (`diverges`), run user code (`callsUser`), or talk to the host (`host`, with the capability's name). The engine's class is short:

```js
// core.js
class Behaviour {
  constructor({ reads = [], writes = [], fresh = false, throws = false, diverges = false, callsUser = false, host = [] } = {}) {
    this.reads = new Set(reads); this.writes = new Set(writes);
    this.fresh = fresh; this.throws = throws; this.diverges = diverges; this.callsUser = callsUser;
    this.host = new Set(host);
    if (callsUser) {                              // user code may touch every user-visible resource
      for (const r of USER_RESOURCES) { this.reads.add(r); this.writes.add(r); }
      this.fresh = this.throws = this.diverges = true; this.host.add('*');
    }
    Object.freeze(this);
  }
```

The first three lines store the fields. The `if` is the important part: an operation that may run user code inherits everything user code may do. A getter can read and write the heap, store into a captured variable, queue a job, set a timer, assign a global, allocate, throw, loop forever and print. So `callsUser` is not a separate kind of effect; it is shorthand for all of them at once, and the constructor expands it so that every later question sees the expansion. `Object.freeze` makes a behaviour a value: nothing can widen it after the fact.

The word "may" matters. A behaviour is a promise about the worst case, not a description of what happens on a particular run. `js.add(a, b)` is `callsUser` because one of its operands might be an object with a `valueOf` method; on the ledger's numbers it never runs user code, but the compiler cannot know that from the operation alone. [S-06 Coercion runs user code](lab:preset?id=S-06) shows the case where it does.

> **Try it.** [Load B-01](lab:preset?id=B-01), [select the js.add in deposit](lab:node?id=deposit/endif2/1) and read its contract in the Inspector: behaviour `callsUser`, obligations `mayCollect, nonlocalThrow`.

## 6.3 The join and its laws

Behaviours combine. A block, a loop or a whole function may do whatever any of its operations may do, so its behaviour is the **join** of theirs: the union of resources read and written, and the logical or of each flag. The engine defines it in one method:

```js
// core.js
  join(o) {
    return new Behaviour({
      reads: [...this.reads, ...o.reads], writes: [...this.writes, ...o.writes],
      fresh: this.fresh || o.fresh, throws: this.throws || o.throws, diverges: this.diverges || o.diverges,
      callsUser: this.callsUser || o.callsUser, host: [...this.host, ...o.host],
    });
  }
```

Because set union and logical or are associative, commutative and idempotent, so is the join: for behaviours $a$, $b$ and $c$,

$$a \sqcup (b \sqcup c) = (a \sqcup b) \sqcup c, \qquad a \sqcup b = b \sqcup a, \qquad a \sqcup a = a.$$

A set with an operation obeying these three laws is a **join-semilattice**, and it carries an order: $a \sqsubseteq b$ exactly when $a \sqcup b = b$, that is, when $b$ allows everything $a$ allows. `fx.none` is the least element and the unit of the join ($a \sqcup \mathit{none} = a$); `fx.unknown` is the greatest, an operation the engine knows nothing about, which may also touch the engine's own state. `callsUser` sits strictly below `unknown`: user code can do anything the program can, but it cannot corrupt the engine.

The laws are not decoration. Associativity and commutativity mean a function's behaviour does not depend on the order in which its operations are visited, so a summary computed block by block equals one computed operation by operation. Idempotence means visiting a loop body twice adds nothing. The engine checks all of it: `g.law.join()` draws 2,000 random triples of behaviours and reports `associative, commutative, idempotent; none is the unit, unknown the top` with no counterexample. [C-01 Behaviours and their join](lab:preset?id=C-01) runs that law and summarises six small functions by joining their operations' behaviours.

> **Try it.** [Load C-01](lab:preset?id=C-01), [run the join law](lab:law?name=join%28fx%29) and [show the Experiments](lab:show?view=experiments) for the table of summaries; then edit a function in [program.js](lab:open?file=program.js) and rerun to watch its row move.

Figure 6.1 draws a corner of the order with the operations that have each behaviour. Read it upwards: every line goes from a behaviour to one that allows more.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 326">
  <g class="ink" fill="none" stroke="currentColor" stroke-width="1">
    <line x1="340" y1="281" x2="130" y2="249"/><line x1="340" y1="281" x2="340" y2="249"/><line x1="340" y1="281" x2="550" y2="249"/>
    <line x1="130" y1="211" x2="130" y2="179"/><line x1="130" y1="211" x2="450" y2="179"/><line x1="550" y1="211" x2="450" y2="179"/>
    <line x1="340" y1="211" x2="340" y2="109"/><line x1="130" y1="141" x2="340" y2="109"/><line x1="450" y1="141" x2="340" y2="109"/>
    <line x1="340" y1="71" x2="340" y2="44"/>
  </g>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="250" y="281" width="180" height="38" class="f-paper"/>
    <rect x="40" y="211" width="180" height="38" class="f-paper"/>
    <rect x="250" y="211" width="180" height="38" class="f-paper"/>
    <rect x="460" y="211" width="180" height="38" class="f-paper"/>
    <rect x="40" y="141" width="180" height="38" class="f-paper"/>
    <rect x="360" y="141" width="180" height="38" class="f-paper"/>
    <rect x="250" y="71" width="180" height="38" class="f-fill"/>
    <rect x="250" y="6" width="180" height="38" class="f-fill2"/>
  </g>
  <g font-size="11" text-anchor="middle" class="f-ink">
    <text x="340" y="297" class="b">none</text><text x="340" y="311" font-size="10" class="it f-mut">num.add, js.typeof</text>
    <text x="130" y="227" class="b">reads(cells)</text><text x="130" y="241" font-size="10" class="it f-mut">cell.load</text>
    <text x="340" y="227" class="b">fresh</text><text x="340" y="241" font-size="10" class="it f-mut">obj.new, cell.new</text>
    <text x="550" y="227" class="b">throws</text><text x="550" y="241" font-size="10" class="it f-mut">(a join only)</text>
    <text x="130" y="157" class="b">reads+writes(cells)</text><text x="130" y="171" font-size="10" class="it f-mut">cell.store</text>
    <text x="450" y="157" class="b">reads(cells), throws</text><text x="450" y="171" font-size="10" class="it f-mut">cell.load_checked</text>
    <text x="340" y="87" class="b">callsUser</text><text x="340" y="101" font-size="10" class="it f-mut">js.get, js.add, js.call</text>
    <text x="340" y="22" class="b">unknown</text><text x="340" y="36" font-size="10" class="it f-mut">g.op.opaque</text>
  </g>
</svg>
```

**Figure 6.1.** Part of the order on behaviours, with the standard operations whose contract is each one. A line rises from a behaviour to one that allows more. Only a few behaviours are drawn: the join of `reads+writes(cells)` and `reads(cells), throws`, for instance, is `reads+writes(cells), throws`, which lies between them and `callsUser`. `throws` alone belongs to no standard operation; it appears only inside joins.

## 6.4 Obligations

A behaviour describes what the program can observe. It does not say what the code generated for an operation must arrange around it, and that is a separate question. `host.print` has behaviour `host(print)`: it writes a line and touches nothing else the program can read back. But printing converts its arguments to strings, a string is a heap object, and allocating may trigger the garbage collector. The program cannot observe the collection, yet the lowering must prepare for it, because a moving collector relocates objects and every reference the compiled code still holds must be somewhere the collector can update ([Chapter 13](lab:book?ch=13)).

An **obligation** is such a requirement. The engine has five, plus host capabilities:

| obligation | means for the lowering |
|---|---|
| `mayCollect` | the operation is a **safepoint**: managed values still needed after it, and its own managed operands, must be in root slots |
| `nonlocalThrow` | an exception may leave through the helper, so the code must be ready to unwind to a handler ([Chapter 14](lab:book?ch=14)) |
| `writeBarrier` | a store into a heap object or cell, which a generational collector must record |
| `protectsResult` | the result must be rooted before the next allocation |
| `sharesBindingCells` | the operation shares captured variables with other functions |
| `needsHost(cap)` | the engine must offer a host capability |

Of the 69 standard operations, 33 have no obligation at all, 16 have `mayCollect, nonlocalThrow` (all but one of the operations that may run user code, which allocate and throw at will, and `js.type_error`), 12 have `mayCollect` alone (allocations, printing, queueing a job), and the rest combine a write barrier or a throw. Obligations join by set union, as behaviours do, and [C-02 Obligations](lab:preset?id=C-02) lists them per operation.

The two halves are kept apart on purpose. Behaviour feeds the optimiser: it decides what may be erased, merged or moved. Obligations feed the lowering: they decide where safepoints are and which helpers may throw through compiled code. An operation can have a quiet behaviour and heavy obligations (`host.print`), or the reverse (`cell.load_checked` throws a ReferenceError and so has `nonlocalThrow`, yet allocates nothing). Folding the two into one flag would either make the optimiser treat printing as a heap write or hide a collection from the lowering.

## 6.5 The standard operation sets

The engine's 69 operations live in five sets: `core` (26: numbers, int32, booleans, identity tests, direct calls and `host.print`), `js.value` (16: the JavaScript operators), `js.object` (9: allocation and properties), `js.function` (10: closures, calls, cells, globals) and `js.control` (8: jobs, timers, promises and the completion records of `finally`). Each is a table entry. Three lines from the table show the range:

```js
// core.js
  { name: 'num.add', operands: [N, N], results: [N], step: (s, [a, b]) => a + b, laws: { commutative: true, associative: false }, lower: { inline: 'fadd' } },
// …
  { name: 'js.get', operands: [A, t.propertyKey], results: [A], behaviour: USER, obligations: CALLING, step: (s, [o, k]) => s.getProperty(o, k), lower: { helper: 'shllvm_get' } },
// …
  { name: 'cell.load_checked', operands: [t.cell], results: [A], behaviour: fx.reads('cells').join(fx.throws), obligations: ob.nonlocalThrow, step: (s, [c], op) => s.cellLoad(c, true, op.attrs.name), lower: { helper: 'shllvm_check_tdz' } },
```

An entry gives the operand and result types, the behaviour and obligations (absent means `none`), the **step**, which is the operation's meaning in the reference interpreter of [Chapter 2](lab:book?ch=2), and a lowering hint: `num.add` becomes an inline `fadd`, `js.get` a call to the runtime helper `shllvm_get`. `num.add` also declares algebraic laws: it is commutative and, because floating-point rounding depends on order, not associative. `USER` is `fx.callsUser` and `CALLING` is `mayCollect, nonlocalThrow`, the pair every operation that may run user code carries.

Grouped by behaviour, the table has 31 operations with behaviour `none`, 16 with `callsUser`, 8 that only allocate (`fresh`), and 14 with something narrower in between: a read of the heap (`js.get_own_data`), a write of cells (`cell.store`), a write of the job queue (`job.enqueue`). The pure group includes `js.typeof`, `js.strict_eq` and `js.truthy`: these JavaScript operators never convert their operands, so they cannot reach user code. The arithmetic and comparison operators (`js.add` to `js.ge`) can, through `valueOf` and `toString`, and so they are `callsUser`. That single difference decides most of what the optimiser may do to JavaScript code, as [Chapter 7](lab:book?ch=7) shows.

## 6.6 Your own operations and providers

An operation is a value, and the builder that makes one asks for exactly the fields of a table entry:

```js
const square = g.op('ch6.square').operands(t.number).results(t.number)
  .behaviour(g.fx.none).step((machine, [x]) => x * x)
  .lower({ inline: 'fmul' }).about('x times x').build();
g.opset('ch6').ops(square).register();
```

After `register()` the parser, the verifier and the interpreter know `ch6.square`. A function that squares its argument twice verifies, runs to `81` for the argument 3 in the specification, and `g.contract.table([square])` reports behaviour `none`, obligations `none` and every permission granted, without anyone writing those permissions down. Registration is global for the page, so names carry a prefix. Two limits are worth stating: the Wasm backend accepts only the operations it knows how to encode, so a program using `ch6.square` stays out of the Wasm core profile ([Chapter 15](lab:book?ch=15)), and the engine trusts the contract you declare: nothing checks that the step really is as quiet as its behaviour says. [C-05 Your own operation](lab:preset?id=C-05) defines a square that prints and claims behaviour `none`; `erase-dead-result` believes the claim and deletes an unused call, and the refinement law of [Chapter 10](lab:book?ch=10) catches the missing output.

A **provider** is whoever implements an operation set's runtime helpers. By default `core` is provided by the reference implementation and the four JavaScript sets by Hermes, whose helpers (the `shllvm_*` functions the LLVM text calls) may throw by `longjmp`. The workbench records the choice in `program.summary().providers` and uses it when strategies are checked: `g.pipeline().exceptions('statusReturn').check()` fails with the message that `js.value, js.object, js.function, js.control are provided by Hermes, whose helpers throw nonlocally`, and passes once `.provide()` names other providers for those sets. The choice does not change the helper names printed at L2; those come from each operation's lowering hint. [C-08 Providers and operation sets](lab:preset?id=C-08) is the preset for this section.

## 6.7 The running example: what each ledger function may do

A function's behaviour is the join of its operations' behaviours. For the ledger compiled with the default pipeline (measured with `g.fx.of` over the operations of each function in [B-01](lab:preset?id=B-01)):

| function | behaviour of its operations, joined |
|---|---|
| `main` | callsUser |
| `makeLedger` | reads+writes(cells, heap), fresh |
| `deposit` | callsUser |
| `get_balance` | reads(cells), throws |
| `total` | callsUser |
| `arrow` | callsUser |

Four of the six functions are `callsUser`, and for a plain reason: each contains a `js.add`, a `js.get` or a call, and any one of those may run a getter. `get_balance` is the exception worth reading. Its body is one operation:

```text
fn get_balance(c_balance: cell, this: any) -> any {
entry throws unwind:
  balance2 = cell.load_checked(c_balance)
  return balance2
}
```

The getter reads a cell and may throw (if `balance` were read before `makeLedger` initialised it, the temporal dead zone would raise a ReferenceError), and that is all. `makeLedger` is the other informative row. Figure 6.2 draws its thirteen operations sorted by behaviour and joined.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 230">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor" stroke-width="1" class="ink">
    <rect x="16" y="16" width="310" height="58" class="f-paper"/>
    <rect x="16" y="86" width="310" height="58" class="f-paper"/>
    <rect x="16" y="156" width="310" height="58" class="f-paper"/>
    <circle cx="400" cy="115" r="18" class="f-fill"/>
    <rect x="460" y="80" width="204" height="70" class="f-fill" stroke-width="1.6"/>
    <path d="M326,45 C360,45 370,100 383,108" marker-end="url(#arrow)"/>
    <path d="M326,115 L381,115" marker-end="url(#arrow)"/>
    <path d="M326,185 C360,185 370,130 383,122" marker-end="url(#arrow)"/>
    <path d="M418,115 L458,115" marker-end="url(#arrow)"/>
  </g>
  <g font-size="11" class="f-ink">
    <text x="28" y="36" class="b">fresh</text>
    <text x="28" y="54" font-size="10">cell.new ×2, arr.new, obj.new, js.closure ×3</text>
    <text x="28" y="68" font-size="10" class="f-mut">obligation mayCollect</text>
    <text x="28" y="106" class="b">reads+writes(cells)</text>
    <text x="28" y="124" font-size="10">cell.store ×2</text>
    <text x="28" y="138" font-size="10" class="f-mut">obligation writeBarrier</text>
    <text x="28" y="176" class="b">reads+writes(heap)</text>
    <text x="28" y="194" font-size="10">js.define ×3, js.define_getter</text>
    <text x="28" y="208" font-size="10" class="f-mut">obligations mayCollect, writeBarrier</text>
    <text x="400" y="120" text-anchor="middle" font-size="13" class="b">⊔</text>
    <text x="472" y="102" class="b">makeLedger</text>
    <text x="472" y="120" font-size="10">reads+writes(cells, heap), fresh</text>
    <text x="472" y="138" font-size="10" class="f-mut">mayCollect, writeBarrier</text>
  </g>
</svg>
```

**Figure 6.2.** The thirteen operations of `makeLedger` grouped by behaviour, and their join. The function allocates and writes cells and the heap, but it cannot throw, run user code or touch the host; its obligations say every allocation is a safepoint and every store needs a barrier.

The join already tells a compiler something useful about `makeLedger` without looking inside: a call to it can be reordered with an operation that touches neither cells nor the heap, and it never needs a handler. The engine does not yet summarise functions for their callers (a `js.call` is `callsUser` whatever it calls), and [Exercise 4](lab:book?ch=6&at=exercises) asks what that would take.

## 6.8 Key points

A contract has two halves. The behaviour bounds what an operation may do that the program can observe; the obligations say what the lowering must provide around it. Behaviours form a join-semilattice: the join is associative, commutative and idempotent, `none` is its unit and `unknown` its top, so the behaviour of any region of code is the join of its operations' behaviours in any order. `callsUser` means everything user code can do, and the constructor expands it so that no later question can forget a part. Of the 69 standard operations, 31 are pure and 16 may run user code; the JavaScript arithmetic operators are in the second group because conversion can call `valueOf`. A new operation needs only a contract and a step, and every permission follows from them. Providers name who implements a set's helpers, and strategies are checked against that choice.

## Exercises

1. In [C-01](lab:preset?id=C-01), compute `g.fx.join(g.fx.reads('cells'), g.fx.throws)` and compare it with the contract of `cell.load_checked`. Then check by hand that $a \sqsubseteq a \sqcup b$ for any two behaviours.
2. Write the contract table for every operation in `deposit` (`g.contract.table` on the names in `program.cfg('deposit')`), and join the behaviours yourself. Which single operation makes `deposit` `callsUser`, and is it the only one?
3. Build `ch6.square` as in Section 6.6, register it, and run `g.law.algebra(square, 'commutative')`. What does it report, and why is the answer meaningless for an operation with one operand? Write a check of your own that compares the step with `x * x` on 1,000 random numbers.
4. A project: give `js.call` a better behaviour when its callee is known. Find in `main` the `js.call` of `makeLedger`, and write a function that returns the join of the callee's operations (as in Section 6.7). What would a rewrite need to know to use it, and what breaks if the callee could be replaced at run time?

[Chapter 7](lab:book?ch=7) derives from these contracts the six permissions every rewrite asks for, and follows one getter that prints and throws through all of them.
