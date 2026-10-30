# Exceptions as edges

In JavaScript almost any operation can throw: reading a property of `undefined`, a getter, a `valueOf` call inside an addition, a `let` read in its temporal dead zone. Each of these is a branch the programmer never wrote, from the middle of a computation to the nearest handler. This chapter shows how core IR makes those branches explicit edges, so that every analysis and every pass sees them like any other control flow. You will learn the two forms the workbench offers, a block-level exceptional exit and the `invoke` terminator; how the frontend lowers `try`, `catch` and `finally`, including the completion records that let `finally` run on every way out; and why a handler sees values as they were at the head of its protected block, which puts one more condition on the promotion of cells from [Chapter 4](lab:book?ch=4).

## 5.1 Exceptions are control flow

A compiler that treats a throwing operation as an ordinary instruction gets two things wrong. The first is liveness: a value used only in a `catch` block is still needed when the protected code runs, because control may jump to the handler from any operation that throws. An analysis that cannot see that jump would decide the value is dead and let its register be reused. The second is optimisation: moving an operation past one that may throw changes what the handler observes. Both errors disappear if the jump is an edge of the control-flow graph, because then the analyses of [Chapter 9](lab:book?ch=9) and the rewrites of [Chapter 10](lab:book?ch=10) handle it with the same rules as every other edge.

There are three common ways to draw that edge. One gives every throwing operation its own terminator with two successors, normal and exceptional; LLVM's `invoke` instruction does this. Another attaches one exceptional successor to each block, so every throwing operation in the block shares it. A third keeps the edges out of the graph in a side table of protected ranges, as many bytecode formats do, and leaves each analysis to consult the table. Core IR offers the first two and rejects the third, because a side table is exactly the implicit edge the analyses would have to remember to look for. A block that has an exceptional successor is a **protected block**, its successor is its **handler**, and the edge between them is an **exceptional edge**.

## 5.2 Block-level exits: throws to H(args)

A block header may end with an exceptional exit. `throws unwind`, the frontend's default outside any `try`, means an exception propagates to the caller. `throws to H(args)` means an exception thrown by any operation of the block goes to block `H`. The handler receives the thrown value as an implicit first parameter, followed by the values of `args`:

```text
fn guarded(o: any) -> any {
entry:
  jump body(0)
body(k: number) throws to handler(k):
  v1 = js.get(o, "x")
  v2 = js.get(v1, "y")
  return v2
handler(e: any, k1: number):
  host.print(k1)
  return undefined
}
```

Run with `o` undefined, the first `js.get` throws a TypeError, control moves to `handler` with `e` the error and `k1` the value of `k`, and the function prints `0`. The Events view records it as a `catch` event at `guarded/body/0` with the handler's name.

The arguments of a block-level exit are evaluated at the **head** of the block, before its first operation, because the edge is shared by every operation in the block and must carry the same values whichever one throws. So `throws to handler(v1)` in the function above is rejected by the verifier: `v1 is used in body before it is defined`. This is why the dominance computation of [Chapter 3](lab:book?ch=3) splits each block into a head node and a body node, with the exceptional edge leaving from the head: a value the handler receives must dominate the head.

In the interpreter the rule is a few lines around each operation:

```js
// core.js
          try { v = this.exec(o, frame); }
          catch (e) {
            if (!(e instanceof JSThrow) || !block.onThrow || block.onThrow === 'unwind') throw e;
            this.event('catch', { at: frame.at, handler: block.onThrow, value: this.display(e.value) });
            next = { block: fn.block(block.onThrow), incoming: [e.value, ...(block.throwArgs || []).map(x => this.value(x, frame))] };
            break;
          }
```

A JavaScript exception from an operation's step (the engine's own errors are a different class and always propagate) is caught here. If the block has no handler, it is rethrown to the caller's frame. Otherwise the catch is recorded, the next block becomes the handler, and its incoming values are the thrown value followed by the exit's arguments. The rest of the block is skipped.

> **Try it.** [Load I-09](lab:preset?id=I-09) for both forms of exceptional edge, written in core IR by hand and run with arguments that throw.

## 5.3 invoke: one operation, two successors

The other form puts one throwing operation in a terminator of its own:

```text
fn safeGet(o: any, d: any) -> any {
entry:
  invoke js.get(o, "x") normal ok(d) throw failed(d)
ok(v: any, d1: any):
  return v
failed(e: any, d2: any):
  return d2
}
```

`invoke` runs the operation and goes to `ok` if it completes, passing its result as the implicit first parameter `v`, or to `failed` if it throws, passing the thrown value as `e`. Each edge also carries its own explicit arguments, here the default `d`.

The two forms trade precision against size. With `invoke`, the exceptional edge leaves from one operation, so the handler can receive values computed just before it, and an analysis knows exactly which operation can reach the handler. The price is one block per throwing operation: in JavaScript, where most operations may throw, a straight-line function of twenty property reads becomes twenty blocks. A block-level exit keeps the block whole and gives up the per-operation view: the handler sees the block's head. The frontend uses block-level exits for `try`; `invoke` is available to hand-written IR and to passes that need the precision. Figure 5.1 draws both.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 270" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="20" y="40" width="240" height="90" class="ink"/>
    <line x1="20" y1="60" x2="260" y2="60" class="hair"/>
    <rect x="20" y="40" width="240" height="20" class="f-fill2"/>
    <rect x="40" y="190" width="200" height="44" class="ink"/>
    <path d="M30 60 V160 H140 V188" class="ink dash" marker-end="url(#arrow)"/>
    <rect x="400" y="40" width="270" height="40" class="ink"/>
    <rect x="390" y="150" width="130" height="44" class="ink"/>
    <rect x="550" y="150" width="130" height="44" class="ink"/>
    <line x1="470" y1="80" x2="455" y2="148" class="ink" marker-end="url(#arrow)"/>
    <line x1="600" y1="80" x2="615" y2="148" class="ink dash" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="28" y="54" class="b">body(k) throws to handler(k)</text>
    <text x="40" y="80">v1 = js.get(o, "x")</text>
    <text x="40" y="98">v2 = js.get(v1, "y")</text>
    <text x="40" y="116">return v2</text>
    <text x="48" y="208" class="b">handler(e, k1)</text>
    <text x="48" y="224" font-size="10">e: thrown value · k1: k at the head</text>
    <text x="408" y="64">invoke js.get(o, "x")</text>
    <text x="398" y="168" class="b">ok(v, d1)</text>
    <text x="398" y="184" font-size="10">v: the result</text>
    <text x="558" y="168" class="b">failed(e, d2)</text>
    <text x="558" y="184" font-size="10">e: the thrown value</text>
  </g>
  <g class="mut" font-size="10">
    <text x="20" y="28" class="lbl">block-level exit</text>
    <text x="400" y="28" class="lbl">invoke</text>
    <text x="150" y="156">from the head</text>
    <text x="412" y="122">normal</text>
    <text x="616" y="122">throw</text>
    <text x="20" y="258">either operation in body may throw; the edge, and its arguments, are shared</text>
  </g>
</svg>
```

**Figure 5.1.** The two exceptional edges of core IR, dashed. Left, a block-level exit: one edge from the head of the protected block (shaded) serves every operation in it, so its arguments are evaluated at the head. Right, `invoke`: one operation with a normal and an exceptional successor, each receiving an implicit first parameter.

## 5.4 try and catch

The frontend keeps a stack of active handlers. When it lowers `try { … } catch (e) { … }`, it first creates the catch block with one parameter for the thrown value and an `endtry` block for the join, pushes the catch block onto the stack, and lowers the protected statements:

```js
// frontend.js
  tryCatch(block, handler) {
    const catchB = this.newBlock('catch', [this.value('e')]);
    const join = this.newBlock('endtry');
    this.handlers.push({ kind: 'catch', block: catchB.name });
    const body = this.newBlock('try');
    this.jump(body); this.cur = body;
    this.stmt(block);
    if (!this.done()) this.jump(join);
    this.handlers.pop();
    this.cur = catchB;
    const s = this.scopeOf(handler);
    if (handler.param) { const d = s.decls.get(handler.param.name); this.cellOf.set(d.id, this.emit('cell.new', catchB.params[0].id, { hint: 'c_' + d.name })); }
    this.stmt(handler.body);
    if (!this.done()) this.jump(join);
    this.cur = join;
  }
```

The handler stack does the rest. Every block the frontend creates takes its exceptional exit from the top of the stack, so every block made while lowering the protected statements, including the blocks of loops and `if`s inside the `try`, throws to the catch block; blocks made before the push or after the pop do not. The catch parameter becomes a cell like any other variable, holding the thrown value. A `throw` statement inside a protected block becomes a `throw` terminator, which the interpreter also sends to the block's handler.

Nested `try` statements need nothing more: the inner handler is on top of the stack while the inner protected code is lowered, and the catch block itself was created before its own handler was pushed, so an exception in a `catch` goes to the next handler out.

## 5.5 try and finally: completion records

`finally` is harder, because its body must run however the protected region ends: normally, by a `return`, or by an exception, and afterwards the region must end the same way. The frontend models each way out as a **completion record**, an object made by `completion.normal()`, `completion.return(v)` or `completion.throw(e)`, and routes every exit to one block that runs the `finally` body and then dispatches on the record:

```js
// frontend.js
  tryFinally(st) {
    // Every way out of the protected region becomes a completion record: normal, return
    // or throw. The finally body runs once, then the record says where to continue.
    const join = this.newBlock('finally', [this.value('c')]);
    join.params[0].type = t.completion;            // the record of how the protected region ended
    const thrown = this.newBlock('finthrow', [this.value('e')]);
    const after = this.newBlock('endfinally');
    this.handlers.push({ kind: 'finally', block: thrown.name, join });
// …
    if (!this.done()) this.jump(join, [this.emit('completion.normal', { hint: 'c' })]);
    this.handlers.pop();
    this.cur = thrown; this.jump(join, [this.emit('completion.throw', thrown.params[0].id, { hint: 'c' })]);
    this.cur = join;
    const c = join.params[0].id;
    this.stmt(st.finalizer);
// …
    this.branch(this.emit('completion.is', c, { kind: 'return', hint: 'isret' }), isRet, notRet);
```

Three paths reach the `finally` block. Falling off the end of the protected statements passes a normal record. An exception goes first to the `finthrow` block, the handler of the protected region, which wraps the thrown value in a throw record. And a `return` inside the region, which the frontend's `ret` turns into a jump to the innermost `finally` with a return record, passes the value. After the `finally` body the record is tested: a return record returns its value, a throw record rethrows, and a normal record continues after the statement. For

```text
function f() {
  try {
    return 1;
  } finally {
    print("finally");
  }
}
print(f());
```

the frontend produces the following, and the program prints `finally` and then `1`:

```text
fn f(this: any) -> any {
entry throws unwind:
  jump try4()
finally1(c2: completion) throws unwind:
  host.print("finally")
  isret6 = completion.is[return](c2)
  branch isret6, fin_return5(), fin_rest6()
finthrow2(e3: any) throws unwind:
  c5 = completion.throw(e3)
  jump finally1(c5)
endfinally3() throws unwind:
  return undefined
try4() throws to finthrow2:
  c4 = completion.return(1)
  jump finally1(c4)
fin_return5() throws unwind:
  r7 = completion.value(c2)
  return r7
fin_rest6() throws unwind:
  isthrow8 = completion.is[throw](c2)
  branch isthrow8, fin_throw7(), endfinally3()
fin_throw7() throws unwind:
  e9 = completion.value(c2)
  throw e9
}
```

Figure 5.2 draws its graph. The parameter `c2` has type `completion`, a kind of value separate from every JavaScript value, so a completion record can never leak into JavaScript code and the verifier would reject an edge that passed one to an ordinary parameter. The frontend does not support `break` or `continue` out of a `finally` region; adding them would mean two more kinds of record, one per target, and the dispatch would grow a branch for each.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 310" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="40" y="20" width="200" height="40" class="ink f-fill2"/>
    <rect x="300" y="20" width="200" height="40" class="ink"/>
    <rect x="170" y="110" width="220" height="44" class="ink f-fill"/>
    <rect x="20" y="210" width="150" height="40" class="ink"/>
    <rect x="210" y="210" width="150" height="40" class="ink"/>
    <rect x="400" y="210" width="150" height="40" class="ink"/>
    <rect x="530" y="130" width="150" height="40" class="ink"/>
    <path d="M140 60 V85 H230 V108" class="ink" marker-end="url(#arrow)"/>
    <path d="M240 40 H298" class="ink dash" marker-end="url(#arrow)"/>
    <path d="M400 60 V85 H330 V108" class="ink" marker-end="url(#arrow)"/>
    <path d="M220 154 V180 H95 V208" class="ink" marker-end="url(#arrow)"/>
    <path d="M320 154 V180 H285 V208" class="ink" marker-end="url(#arrow)"/>
    <path d="M360 230 H398" class="ink" marker-end="url(#arrow)"/>
    <path d="M285 250 V275 H605 V172" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="48" y="36" class="b">try4 throws to finthrow2</text>
    <text x="48" y="52" font-size="10">c4 = completion.return(1)</text>
    <text x="308" y="36" class="b">finthrow2(e3)</text>
    <text x="308" y="52" font-size="10">c5 = completion.throw(e3)</text>
    <text x="178" y="128" class="b">finally1(c2: completion)</text>
    <text x="178" y="146" font-size="10">print("finally"); is c2 a return?</text>
    <text x="28" y="228" class="b">fin_return5</text><text x="28" y="243" font-size="10">return value(c2)</text>
    <text x="218" y="228" class="b">fin_rest6</text><text x="218" y="243" font-size="10">is c2 a throw?</text>
    <text x="408" y="228" class="b">fin_throw7</text><text x="408" y="243" font-size="10">throw value(c2)</text>
    <text x="538" y="148" class="b">endfinally3</text><text x="538" y="163" font-size="10">continue after</text>
  </g>
  <g class="mut" font-size="10">
    <text x="150" y="80">return record</text>
    <text x="246" y="34">exception</text>
    <text x="404" y="80">throw record</text>
    <text x="104" y="176">yes</text><text x="294" y="176">no</text>
    <text x="364" y="224">yes</text><text x="440" y="272">no: a normal record</text>
  </g>
</svg>
```

**Figure 5.2.** `try { return 1; } finally { … }` lowered. Every way out of the protected block (shaded) reaches `finally1` with a completion record; after the `finally` body, the record decides whether to return, rethrow or continue. The dashed edge is the protected block's exceptional exit.

> **Try it.** [Load I-10](lab:preset?id=I-10) for `try`, `catch` and `finally` together. Then [load J-03](lab:preset?id=J-03), a function that returns from inside a `try` with a `finally` that cleans up, [show withResource](lab:fn?name=withResource) and [turn on the exceptional overlay](lab:overlay?name=exceptional&on=1).

## 5.6 What a handler can see

A block-level exit evaluates its arguments at the head of the block. That is enough for every value defined before the block, but not for a variable the block changes. Consider:

```text
let s = 0;
try {
  s = 1;
  throw new Error("x");
} catch (e) {
  print(s);
}
print(s);
```

The handler must print `1`, the value of `s` when the `throw` ran, not `0`, its value at the head of the protected block. If `s` were promoted to SSA values, its value after the store would be a value defined inside the block, and the exit's arguments cannot name it. With `s` in a cell there is no problem: the store writes the cell, and the handler's load reads whatever the cell holds when the exception arrives. So the promotion rule of [Chapter 4](lab:book?ch=4) has a clause for protected blocks:

```js
// core.js
  const protectedBy = b => (b.onThrow && b.onThrow !== 'unwind' ? b.onThrow : null);
  for (const b of fn.blocks) for (const o of b.ops) {
    if (o.op !== 'cell.new' || !o.result) continue;
    const us = uses.get(o.result) || [];
    if (!us.every(u => !u.edge && !u.term && u.op && u.slot === 0 && (u.op.op === 'cell.load' || u.op.op === 'cell.store'))) continue;
    const handlers = new Set([protectedBy(b), ...us.filter(u => u.op.op === 'cell.store').map(u => protectedBy(u.block))].filter(Boolean));
    const loads = us.filter(u => u.op.op === 'cell.load').map(u => u.block.name);
    if ([...handlers].some(h => loads.some(l => reachable(h).has(l)))) continue;
    out.push(o.result);
  }
```

For each cell, `handlers` collects the handlers of the blocks where the cell is created or stored. If any load of the cell is in a block reachable from one of those handlers, the cell stays. For the program above, `s` is stored in the protected block `try3`, its handler `catch1` reaches both loads, and `c_s2` is not promoted; the decision log lists only the cells for `this` and `e`. A variable declared and used only inside the `try`, such as `const y = 1; print(y);`, is promoted, because no load of it can run after the handler.

The rule gives up some precision. A compiler using `invoke` for every throwing operation could pass the current value of `s` on each exceptional edge and promote it after all. The workbench keeps the cell because the frontend's form is block-level and the cost is small: one cell for each variable that is both changed inside a `try` and read after its handler.

## 5.7 The running example: deposit("five")

The ledger's exception crosses a function boundary. `deposit` has no `try`, so its blocks are `throws unwind`, and its `then1` block ends `throw err6`. That throw leaves `deposit` and arrives in `main` at the operation that called it, `main/try3/1`:

```text
try3() throws to catch1:
  ledger12 = cell.load(c_ledger3)
  r13 = js.call_method(ledger12, "deposit", "five")
  jump endtry2()
```

`try3` is the protected block the frontend made for the `try` statement, and its exit sends the exception to `catch1(e11)`. The run's events show the hand-off at step 53: a throw at `deposit/then1/term` with the value `TypeError: amount must be a number`, and in the same step a catch at `main/try3/1` with handler `catch1`. In the next three steps `catch1` reads `e11.message`, builds the string with `js.add` and prints `rejected: amount must be a number`. The `deposit` frame is gone: unwinding it was the interpreter's job here, and in compiled code it is the job of the strategy [Chapter 14](lab:book?ch=14) chooses, which in the Hermes shape is a `setjmp` buffer and a switch on a try state.

The cell rule does not touch the ledger. `c_ledger3` is created and stored in `main`'s entry, not in `try3`, so no handler is involved, and it stays a cell for a different reason: the audit job captures it. The catch parameter's cell, `c_e14`, is created in `catch1`, which is not protected, and is promoted.

> **Try it.** [Load B-01](lab:preset?id=B-01), [show main on the Stage](lab:fn?name=main), [turn on the exceptional overlay](lab:overlay?name=exceptional&on=1) to see the dashed edge from `try3` to `catch1`, then [select the protected call](lab:node?id=main/try3/1) and [step to 53](lab:step?n=53) in the Machine view.

## 5.8 Key points

- Throwing operations are branches; core IR makes them edges of the control-flow graph so every analysis and pass sees them.
- A block-level exit `throws to H(args)` serves every operation of a protected block; the handler receives the thrown value first and then `args`, evaluated at the block's head.
- `invoke` gives one operation a normal and an exceptional successor, at the cost of one block per throwing operation.
- The frontend lowers `try`/`catch` with a handler stack: every block created inside the protected statements throws to the catch block.
- `finally` is lowered with completion records (normal, return, throw) routed to one block that runs the `finally` body and dispatches on the record.
- A cell created or stored in a protected block stays a cell if any of its loads can run after the handler, because the handler sees the head of the block.

## Exercises

1. Rewrite `guarded` with `invoke` for both property reads, so the handler can tell which read failed. How many blocks does it have now?
2. In the `finally` example, change `return 1` to `throw new Error("late")` inside a `try`/`catch` around the call, and predict the output and the path through Figure 5.2. Check it in the Machine view.
3. Put the `try`/`catch` of Section 5.6 inside a loop that runs three times, assigning `s = s + 1` before the throw. Which cells are promoted, and what does it print?
4. Write a nested `try` where the inner `catch` rethrows. Read the IR and name each block's exceptional exit.
5. A short project: write a pass with `g.pass` that counts, for each function, the protected blocks and the operations in them that may throw, and insert it after `verify`. Run it on J-03 and on the ledger.
