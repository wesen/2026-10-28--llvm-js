# A compiler you can see

A **compiler** translates a program from the language a person wrote into a language a machine runs, and the translation must preserve what the program does. This chapter compiles the running example, the ledger, with every default the workbench offers, and reads the result view by view: the source, the core IR the frontend produces, the contracts that stop the optimiser from deleting work it must keep, the plan that tells a garbage collector where references live, and the LLVM IR at the end. By the end you will know what each stage of the pipeline is for, where to look for it in the workbench, and which chapter takes each one apart.

## 1.1 What a compiler has to preserve

Translating `balance = balance + amount` into machine instructions looks easy until you list what the JavaScript line can do. `amount` might be a number, in which case one floating-point addition suffices. It might be an object whose `valueOf` method prints a line, throws an exception or allocates memory, in which case the addition runs user code. The allocation might trigger the garbage collector, which in an engine with a moving collector relocates objects, so any address the compiled code still holds in a register is wrong afterwards. And `balance` is shared with two other functions, so it cannot live only in a register of this one.

A compiler copes with this by working in stages. Each stage rewrites the program into a form that makes the next decision easier to state and check, and each form is called an **intermediate representation**, or IR. The workbench names its forms by **level**: L0 is the source text, L1 is core IR (the form most of this book studies), L2 is core IR with every operation bound to an implementation, L3 adds the plan for garbage-collection roots, and LLVM is the textual LLVM IR a native backend would receive. A **pass** is one stage: a function from one level to the same or the next, which records what it did.

> **Try it.** [Load B-01](lab:preset?id=B-01). The header's status pill reads `ok · 6 functions · 15 blocks · 78 ops`, and the outcome pill reads `normal`, with 134 steps in spec mode. [Show the Events view](lab:show?view=events) to see the three lines of output and the pass trace.

## 1.2 One call, nine passes

The preset's `main.js` is one line of real work:

```js
const program = g.compile(g.pipeline(), source('program.js'));
```

`g.pipeline()` is the default pipeline, a value describing which passes run and which strategy fills each choice they make. `g.compile` runs it on the source and returns a **Program**, the object every view reads. The loop at its centre is short:

```js
// core.js
function compile(pipe, src) {
  pipe = pipe || pipeline();
  if (typeof src === 'string') src = source.text(src);
  const r = pipe.resolved();
  const st = { source: src, module: null, levels: {}, facts: {}, plans: {}, bindings: {}, reps: {}, llvm: {}, diagnostics: [], trace: [], decisions: [] };
  const chk = pipe.check();
  st.diagnostics.push(...chk.diagnostics);
  const t0 = now();
  if (chk.ok) {
    for (const p of pipe.passList()) {
// …
      try { note = p.body ? p.body(st, r) : 'no body'; }
// …
      st.trace.push({ pass: p.name, level: `${p.src || ''}${p.dst && p.dst !== p.src ? '→' + p.dst : ''}`, ms: round(now() - ts, 2), note: note || '' });
    }
  }
  return new Program(pipe, st, round(now() - t0, 2));
}
```

The state `st` is shared by the passes: the module of functions, the facts the analyses compute, the root plans, the LLVM text, and three logs. `pipe.check()` runs before any pass and refuses a pipeline whose passes need something no earlier pass provides, or whose strategies are not declared compatible ([Chapter 11](lab:book?ch=11) covers both). Then each pass runs in order, and its note goes into the **trace**. A pass that throws stops the loop and leaves a diagnostic instead of a half-built program.

For the ledger the trace has nine entries:

| pass | level | note |
|---|---|---|
| `frontend` | L0→L1 | 6 functions |
| `promote-cells` | L1 | 11 cells promoted |
| `verify` | L1 | ok |
| `rewrite` | L1 | 0 rewrites fired |
| `analyze` | L1 | liveness 20 block visits |
| `lower-runtime` | L1→L2 | bound to providers |
| `plan-roots` | L2→L3 | 15 root slots in 6 functions |
| `check-plan` | L3 | every collecting point roots what it needs |
| `emit-llvm` | L3→LLVM | textual LLVM IR, structurally checked |

Figure 1.1 draws the same pipeline. Three passes change level; the others refine L1 or check what an earlier pass produced. Two of them, `verify` and `check-plan`, transform nothing at all: they exist so that a mistake in an earlier pass is reported where it happened instead of surfacing as a wrong answer later.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 250" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="10" y="100" width="70" height="40" class="ink"/>
    <rect x="130" y="100" width="190" height="40" class="ink"/>
    <rect x="370" y="100" width="70" height="40" class="ink"/>
    <rect x="490" y="100" width="90" height="40" class="ink"/>
    <rect x="630" y="100" width="60" height="40" class="ink"/>
    <line x1="80" y1="120" x2="128" y2="120" class="ink" marker-end="url(#arrow)"/>
    <line x1="320" y1="120" x2="368" y2="120" class="ink" marker-end="url(#arrow)"/>
    <line x1="440" y1="120" x2="488" y2="120" class="ink" marker-end="url(#arrow)"/>
    <line x1="580" y1="120" x2="628" y2="120" class="ink" marker-end="url(#arrow)"/>
    <path d="M160 100 C160 70 200 70 200 98" class="ink" marker-end="url(#arrow)"/>
    <path d="M205 100 C205 70 245 70 245 98" class="mut dash" marker-end="url(#arrow)"/>
    <path d="M250 100 C250 70 290 70 290 98" class="ink" marker-end="url(#arrow)"/>
    <path d="M520 140 C520 170 560 170 560 142" class="mut dash" marker-end="url(#arrow)"/>
    <path d="M230 140 C230 170 270 170 270 142" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="45" y="124" text-anchor="middle" class="b">L0</text>
    <text x="225" y="124" text-anchor="middle" class="b">L1 core IR</text>
    <text x="405" y="124" text-anchor="middle" class="b">L2</text>
    <text x="535" y="124" text-anchor="middle" class="b">L3</text>
    <text x="660" y="124" text-anchor="middle" class="b">LLVM</text>
    <text x="104" y="112" text-anchor="middle" font-size="9">frontend</text>
    <text x="344" y="112" text-anchor="middle" font-size="9">lower-</text>
    <text x="344" y="135" text-anchor="middle" font-size="9">runtime</text>
    <text x="464" y="112" text-anchor="middle" font-size="9">plan-</text>
    <text x="464" y="135" text-anchor="middle" font-size="9">roots</text>
    <text x="604" y="112" text-anchor="middle" font-size="9">emit-</text>
    <text x="604" y="135" text-anchor="middle" font-size="9">llvm</text>
    <text x="180" y="62" text-anchor="middle" font-size="9">promote-cells</text>
    <text x="225" y="50" text-anchor="middle" font-size="9" class="mut">verify</text>
    <text x="270" y="62" text-anchor="middle" font-size="9">rewrite</text>
    <text x="250" y="186" text-anchor="middle" font-size="9">analyze</text>
    <text x="540" y="186" text-anchor="middle" font-size="9" class="mut">check-plan</text>
  </g>
  <text x="10" y="226" class="lbl mut">solid: the pass changes the program or adds to it · dashed: the pass only checks</text>
</svg>
```

**Figure 1.1.** The default pipeline. Arrows between boxes are passes that change level; loops above and below a box are passes that stay at that level. Dashed loops (`verify`, `check-plan`) only check, and a failure there stops compilation with a diagnostic.

## 1.3 From source to core IR

The frontend parses the ledger and produces six functions: `main` (the top-level script), `makeLedger`, `deposit`, `get_balance`, `total`, and `arrow` (the function passed to `queueMicrotask`). A function's body is a list of **blocks**; each block is a list of operations ending in one **terminator** that says where control goes next. [Chapter 3](lab:book?ch=3) defines the form exactly; for now, read it as assembly with named values.

Before anything else, the frontend gives every variable a **cell**: a small heap box with `cell.new`, `cell.load` and `cell.store`. Cells are how closures share variables. `makeLedger` creates cells for `balance` and `log` and hands them to the closures it builds:

```text
f8 = js.closure(@deposit, c_balance3, c_log4)
js.define(o6, "deposit", f8)
f9 = js.closure(@get_balance, c_balance3)
js.define_getter(o6, "balance", f9)
```

So `deposit` begins `fn deposit(c_balance: cell, c_log: cell, this: any, amount: any)`: the cells it captured come first, then `this`, then its JavaScript parameter. A cell nobody else captures is a wasted allocation, and the second pass, `promote-cells`, removes those. In `deposit` it removed two (for `this` and `amount`); across the program it removed 11, and three remain because two functions really do share them: `c_balance`, `c_log` and `main`'s `c_ledger`, which the audit job reads after `main` has returned. [Chapter 4](lab:book?ch=4) builds this pass. After it, `deposit` at L1 reads:

```text
fn deposit(c_balance: cell, c_log: cell, this: any, amount: any) -> any {
entry throws unwind:
  v4 = js.typeof(amount)
  v5 = js.strict_ne(v4, "number")
  branch v5, then1(), endif2()
then1() throws unwind:
  err6 = js.new_error[TypeError]("amount must be a number")
  throw err6
endif2() throws unwind:
  balance7 = cell.load_checked(c_balance)
  v9 = js.add(balance7, amount)
  cell.store(c_balance, v9)
  log11 = cell.load_checked(c_log)
  log12 = cell.load_checked(c_log)
  length13 = js.get(log12, "length")
  js.put(log11, length13, amount)
  balance14 = cell.load_checked(c_balance)
  return balance14
}
```

Each line is one operation with named operands. `throws unwind` on a block header means an exception in that block leaves the function; [Chapter 5](lab:book?ch=5) explains the alternative, `throws to` a handler, which `main` uses for its `try`.

> **Try it.** [Show deposit before promotion](lab:level?l=L1.cells) and compare it with [L1](lab:level?l=L1): `c_amount2 = cell.new(amount)` and its three loads are gone, replaced by `amount` itself.

## 1.4 Contracts and the decision log

Every operation carries a **contract**: a **behaviour** that says what it may do (read or write the heap, allocate, throw, run user code) and **obligations** that say what lowering owes it (roots for a collection it may trigger, a way to unwind an exception it may throw). The contract of `js.add` is behaviour `callsUser` with obligations `mayCollect, nonlocalThrow`, because adding two arbitrary values may call `valueOf`.

The rewrite pass is where an optimiser would delete or reorder work, and it consults contracts before it does. In the ledger it fired nothing. Its rule `erase-dead-result` erases an operation whose result nobody uses, and it found three candidates in `main`: the calls `ledger.deposit(10)`, `ledger.deposit(32)` and `ledger.deposit("five")`, whose return values the script ignores. It refused all three, and each refusal is a **decision** in the program's log with the reason:

```text
erase-dead-result at main/entry/5 (js.call_method): perm.erase = false: may run user code;
may throw; may diverge; writes heap, cells, jobs, timers, globals; talks to the host
```

The reason lists exactly what the call's contract allows and therefore what erasing it could lose. Here the loss would be everything: these calls are the program. [Chapter 7](lab:book?ch=7) derives each permission from the behaviour and follows a getter that throws to show why an unused result is not enough to delete an operation.

## 1.5 Lowering: helpers, safepoints and the root plan

`lower-runtime` binds every operation to an implementation. Pure arithmetic on known numbers becomes an inline instruction; most JavaScript operations become calls to a runtime **helper** with the names the Hermes LLVM backend uses (`shllvm_binary`, `shllvm_get`, `shllvm_check_tdz`). The L2 text annotates each operation with its binding, and marks those that **collect**: they may allocate and so may run the garbage collector. An operation that may collect is a **safepoint**.

The workbench's collector moves objects. After a collection, every reference the compiled code still needs must be found and updated, so before each safepoint those references must sit in **root slots**, frame slots the collector knows to scan. `plan-roots` decides which values need slots and which may share one; `check-plan` verifies that at every safepoint everything needed is rooted and no two needed values share a slot. In `deposit` four safepoints need seven values over the function, and the default strategy, `stackReuse`, packs them into four slots:

```text
; plan for deposit: stackReuse, native stack
; frame: 4 root slots + 2 fixed + 1 argument = 7 slots, 56 B
;   s0: amount
;   s1: balance7, log11
;   s2: c_balance
;   s3: c_log, log12, length13
```

Figure 1.2 shows `deposit`'s three blocks with the safepoints marked and the slot each value occupies. `balance7` and `log11` can share slot 1 because no safepoint needs both: `balance7` is last used by the `js.add`, and `log11` is first defined after it.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 330" font-size="10">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="200" y="10" width="300" height="56" class="ink"/>
    <line x1="200" y1="26" x2="500" y2="26" class="hair"/>
    <rect x="10" y="110" width="280" height="56" class="ink"/>
    <line x1="10" y1="126" x2="290" y2="126" class="hair"/>
    <rect x="330" y="110" width="360" height="160" class="ink"/>
    <line x1="330" y1="126" x2="690" y2="126" class="hair"/>
    <path d="M300 66 V90 H150 V108" class="ink" marker-end="url(#arrow)"/>
    <path d="M400 66 V90 H510 V108" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="208" y="22" class="b">entry</text>
    <text x="208" y="40">v4 = js.typeof(amount)</text>
    <text x="208" y="53">v5 = js.strict_ne(v4, "number")</text>
    <text x="208" y="63" class="mut" font-size="9">branch v5</text>
    <text x="250" y="86" font-size="9" class="mut">true</text>
    <text x="420" y="86" font-size="9" class="mut">false</text>
    <text x="18" y="122" class="b">then1</text>
    <text x="18" y="140" class="acc">● err6 = js.new_error[TypeError](…)</text>
    <text x="18" y="155">throw err6</text>
    <text x="338" y="122" class="b">endif2</text>
    <text x="338" y="140">balance7 = cell.load_checked(c_balance)</text>
    <text x="338" y="154" class="acc">● v9 = js.add(balance7, amount)</text>
    <text x="338" y="168">cell.store(c_balance, v9)</text>
    <text x="338" y="182">log11 = cell.load_checked(c_log)</text>
    <text x="338" y="196">log12 = cell.load_checked(c_log)</text>
    <text x="338" y="210" class="acc">● length13 = js.get(log12, "length")</text>
    <text x="338" y="224" class="acc">● js.put(log11, length13, amount)</text>
    <text x="338" y="238">balance14 = cell.load_checked(c_balance)</text>
    <text x="338" y="252">return balance14</text>
  </g>
  <g class="mut" font-size="9">
    <text x="610" y="154">s0 s1 s2 s3</text>
    <text x="610" y="210">s0 s1 s2 s3</text>
    <text x="610" y="224">s0 s1 s2 s3</text>
    <text x="210" y="140">nothing rooted</text>
  </g>
  <text x="10" y="292" class="mut" font-size="10">● safepoint (may collect). Slots: s0 amount · s1 balance7, then log11 · s2 c_balance · s3 c_log, log12, then length13</text>
  <text x="10" y="312" class="lbl mut">from the L3 plan printed by program.ir('L3', { fn: 'deposit' })</text>
</svg>
```

**Figure 1.2.** `deposit` at L3. The four safepoints are marked, with the root slots each one needs to be filled. At `js.new_error` nothing else is live, so nothing is rooted; at the `js.add` all four slots hold a value the rest of the function needs.

The plan is tested as well as checked. In plan mode the workbench runs the L3 program with a collector that moves every object at every safepoint: for the ledger that is 68 collections and 995 object moves, and the output is still the same three lines. A plan that forgot a root would read a stale address and stop with an error naming the value; [Chapter 13](lab:book?ch=13) breaks a plan on purpose to show it.

> **Try it.** In B-01, [run with GC stress](lab:run?mode=plan&gc=stress), then [show the Machine](lab:show?view=machine): the metrics report the collections and moves, and the outcome is still `normal`.

## 1.6 The running example: one function at every level

`get_balance`, the getter, is the smallest function in the ledger, small enough to read at every level. At L1 it is two lines:

```text
fn get_balance(c_balance: cell, this: any) -> any {
entry throws unwind:
  balance2 = cell.load_checked(c_balance)
  return balance2
}
```

`cell.load_checked` rather than `cell.load`, because `balance` is declared with `let` in another function, and reading a `let` before its declaration runs must throw a ReferenceError ([Chapter 2](lab:book?ch=2) shows the rule). At L2 the load is bound to the helper `shllvm_check_tdz`, which may throw but never collects. So `get_balance` has no safepoint, its plan has no root slots, and its frame is the two fixed slots (scratch and discard) plus one for outgoing arguments: 3 slots, 24 B. The LLVM text for it is the frame setup, one helper call, and the return:

```llvm
define internal i64 @get_balance(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %size = call i64 @shllvm_frame_size(i32 2)
  %storage = alloca i8, i64 %size, align 16
  %argv = alloca [1 x i64], align 8
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 2, i32 1, i32 0)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %scratch = getelementptr i64, ptr %roots, i32 0
  %discard = getelementptr i64, ptr %roots, i32 1
  %r.c_balance = alloca i64, align 8                 ; c_balance: not rooted
  %r.this = alloca i64, align 8                 ; this: not rooted
  %r.balance2 = alloca i64, align 8                 ; balance2: not rooted
  call void @shllvm_param(ptr %r.c_balance, ptr %frame, i32 0)
  call void @shllvm_param(ptr %r.this, ptr %frame, i32 1)
  br label %b.entry
b.entry:
  ; balance2 = cell.load_checked(c_balance)
  call void @shllvm_check_tdz(ptr %r.balance2, ptr %shr, ptr %r.c_balance)
  %t0 = load i64, ptr %r.balance2, align 8
  call void @shllvm_leave(ptr %shr, ptr %frame)
  ret i64 %t0
}
```

`%shr` is the runtime, `shllvm_enter` builds a frame of 2 slots, `shllvm_param` copies the arguments out of it, and every value lives in an `alloca` marked "not rooted", which is safe only because nothing here can collect. The whole module is 434 lines with 30 helper declarations, and a structural checker passes all six functions. The text is never compiled: no LLVM is in the page. [Chapter 16](lab:book?ch=16) reads `deposit`'s version, where four values do live in root slots.

> **Try it.** [Load B-03](lab:preset?id=B-03) for one numeric function printed at every level, including the WAT text of a WebAssembly module the page really runs, and [B-04](lab:preset?id=B-04) for a guided reading of the Stage.

## 1.7 The shape of the book

Every level in this chapter is a chapter later. Part II takes L1 apart: blocks and SSA ([Chapter 3](lab:book?ch=3)), how the frontend and `promote-cells` build it ([Chapter 4](lab:book?ch=4)), and exceptions ([Chapter 5](lab:book?ch=5)). Part III is the contracts that made the rewrite pass refuse; Part IV the analyses behind `analyze`; Part V the rewrites and the pipeline itself. Part VI is L2 and L3; Part VII the two backends; Part VIII the jobs and engines that run the result; Part IX the laws, fuzzing and experiments that check and measure it.

One idea holds the parts together: the program's meaning is fixed first, by an interpreter, and every other part is checked against it. The output of plan mode under stress was compared with that interpreter's output, observation by observation, and found equal. The next chapter is about that interpreter and what "equal" means.

Every default you saw here is a choice that can be changed. [B-02](lab:preset?id=B-02) changes them one at a time: partial parameters for the root strategy, a different rewrite set, and a lambda that wraps the default plan and reports what it did.

## 1.8 Key points

- A compiler works in stages; each stage is a pass from one level of intermediate representation to the same or the next, and the workbench names the levels L0, L1, L2, L3 and LLVM.
- `g.compile(pipeline, source)` runs the pipeline's passes in order and returns a Program whose trace records each pass and whose decision log records every rewrite attempted, with its reason.
- The frontend gives every variable a cell; `promote-cells` keeps only the cells that closures share, 3 of 14 in the ledger.
- Every operation has a contract, and an optimisation fires only when the contract permits it; an unused result does not make a call deletable.
- Operations that may collect are safepoints; the root plan gives every reference needed across a safepoint a slot, and a checker and a moving collector both test the plan.
- The LLVM text has the shape of the Hermes backend and is checked structurally, not compiled.

## Exercises

1. In B-01, change `main.js` to compile with `g.pipeline().rewrites(g.rewrites.standard())`. Compare the trace's rewrite line and `total` at L1 with the default. Which operations changed name?
2. Add `print(program.plan('total').rootSlots, program.plan('total').frameBytes)` to `main.js` and rerun. Explain the two numbers from the L3 text.
3. Add a second `let` to `makeLedger` that only `deposit` uses. How many cells does `promote-cells` remove now, and why does the new one survive?
4. Use `program.why('main/entry/7')` in `main.js` and read every field it returns. Which field says the call is a safepoint, and which says what had to be rooted across it?
5. A short project: write a `main.js` that prints, for each function of the ledger, its number of blocks, operations, safepoints and root slots, as a table returned with `g.table(rows)`. Which function has the most safepoints, and why?
