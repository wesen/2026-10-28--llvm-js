# LLVM IR and the Hermes ABI

The last stage of the default pipeline, `emit-llvm`, prints every function as LLVM IR in the shape of the Hermes LLVM backend: the same function signature, the same frame protocol, the same `shllvm_*` helper calls with the same argument order, the same setjmp try protocol. This chapter reads that text line by line. It explains how a function sets up its frame and finds its root slots, how operations become helper calls with out pointers, how constants and literals are materialised, how numbers are computed inline on tagged words, how closures and calls pass their arguments, and how a protected region looks. It ends with the structural checker and with what would change if this text were handed to a real LLVM. One thing first, because everything else depends on it: the workbench prints LLVM IR and checks its structure; it does not compile or run it. Neither LLVM nor Hermes is in the page.

## 16.1 What the text is for

The value of printing LLVM IR without compiling it is that the text is a precise statement of a contract. Each line says which runtime function is called, with which pointers, in which order, and therefore what the plan of [Chapter 13](lab:book?ch=13) and the exception strategy of [Chapter 14](lab:book?ch=14) have committed the code to. A reader can check by eye, and the workbench's checker can check mechanically, that every value a helper borrows is passed as a pointer to a root slot, that literals never sit in a slot another value still needs, and that every block ends in a terminator. When the same pipeline later runs in a local build with Hermes and LLVM, the text is what that build compiles, and any disagreement between its behaviour and the specification points at a specific line.

The text has a fixed shape for every function: a `define`, a prologue that builds the frame, one LLVM block per IR block (named `b.` plus the IR name), small edge blocks for branches (`e.` plus the source block and `t` or `f`), and, in functions with a protected region, a dispatch block. The module around the functions starts with a string table in comments and the declarations of every helper used, sorted. For the ledger the module is 436 lines with 30 declarations and six functions. The shelf doc [The Hermes LLVM backend](lab:doc?id=hermes-llvm) describes the backend this text mirrors.

## 16.2 One function, one frame

Every compiled function has the signature `define internal i64 @f(ptr %shr)`. Its single parameter is the runtime (`%shr`, the Static Hermes runtime pointer), its result is a tagged word, and its JavaScript arguments are not LLVM parameters at all: they are read from the frame the caller built. The prologue is printed by this code:

```js
// core.js
  lines.push(`define internal i64 @${safeName(fn.name)}(ptr %shr) {`, 'entry:');
  declare('_sh_check_native_stack_overflow', { ret: 'void', args: ['ptr'] });
  lines.push('  call void @_sh_check_native_stack_overflow(ptr %shr)');
  declare('shllvm_frame_size', { ret: 'i64', args: ['i32'] });
  lines.push(`  %size = call i64 @shllvm_frame_size(i32 ${plan.rootSlots + FIXED_SLOTS})`);
  lines.push('  %storage = alloca i8, i64 %size, align 16', `  %argv = alloca [${nArgs} x i64], align 8`);
  declare('shllvm_enter', { ret: 'ptr', args: ['ptr', 'ptr', 'i32', 'i32', 'i32'] });
  lines.push(`  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 ${plan.rootSlots + FIXED_SLOTS}, i32 ${nArgs}, i32 0)`);
  declare('shllvm_roots', { ret: 'ptr', args: ['ptr'] });
  lines.push('  %roots = call ptr @shllvm_roots(ptr %storage)');
  for (let i = 0; i < plan.rootSlots; i++) lines.push(`  %s${i} = getelementptr i64, ptr %roots, i32 ${i}`);
  lines.push(`  %scratch = getelementptr i64, ptr %roots, i32 ${plan.rootSlots}`, `  %discard = getelementptr i64, ptr %roots, i32 ${plan.rootSlots + 1}`);
  for (const v of regs) lines.push(`  %r.${safeName(v)} = alloca i64, align 8                 ; ${v}: not rooted`);
```

Read in order: a stack-overflow check against the runtime's native stack limit; the size of the frame's storage, asked of the runtime for the root slots plus the two fixed slots (the runtime adds its own header); the storage itself on the native stack, 16-byte aligned; an outgoing argument area `%argv` with room for the largest call; `shllvm_enter`, which links the frame into the runtime's chain of frames (so the collector will scan it) and receives the slot count, the argument capacity and the compilation unit's index (the workbench passes 0); `shllvm_roots`, which returns the address of the first root slot. Then one `getelementptr` per root slot, giving each a name `%s0`, `%s1`…, and the two fixed slots after them. Every value the plan does not root gets a plain stack location `%r.name`, with a comment saying so.

Here is the result for `deposit`, whose plan has 4 root slots and 1 argument slot:

```llvm
define internal i64 @deposit(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %size = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %size, align 16
  %argv = alloca [1 x i64], align 8
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 1, i32 0)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %scratch = getelementptr i64, ptr %roots, i32 4
  %discard = getelementptr i64, ptr %roots, i32 5
```

The 6 passed to `shllvm_enter` is $4 + 2$, and the 1 is the argument capacity; these are the three terms of the 1,024-slot limit. Then the parameters: `shllvm_param(ptr %s0, ptr %frame, i32 3)` copies the fourth parameter, `amount`, from the caller's frame into its root slot (the first three are the two captured cells and `this`). Figure 16.1 shows where each kind of storage lives.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 260">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="22" font-size="10" class="lbl">native stack frame of deposit</text>
  <rect x="20" y="32" width="420" height="92" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="50" font-size="11" class="b">%storage · shllvm_frame_size(6)</text>
  <rect x="30" y="58" width="60" height="30" class="f-fill2" stroke="currentColor"/>
  <rect x="90" y="58" width="50" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="140" y="58" width="50" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="190" y="58" width="50" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="240" y="58" width="80" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="320" y="58" width="60" height="30" class="f-fill" stroke="currentColor"/>
  <rect x="380" y="58" width="50" height="30" class="f-fill" stroke="currentColor"/>
  <text x="36" y="78" font-size="10" class="lbl">header</text>
  <text x="100" y="78" font-size="11">%s0</text>
  <text x="150" y="78" font-size="11">%s1</text>
  <text x="200" y="78" font-size="11">%s2</text>
  <text x="250" y="78" font-size="11">%s3</text>
  <text x="326" y="78" font-size="10">scratch</text>
  <text x="384" y="78" font-size="10">discard</text>
  <line x1="90" y1="98" x2="430" y2="98" stroke="currentColor" class="acc"/>
  <text x="96" y="114" font-size="10" class="lbl">from %roots: scanned and updated by the collector</text>
  <text x="20" y="146" font-size="10" class="lbl">other allocas of the same frame</text>
  <rect x="20" y="154" width="130" height="24" fill="none" stroke="currentColor" class="mut"/>
  <text x="28" y="170" font-size="11">%argv [1 x i64]</text>
  <rect x="160" y="154" width="280" height="24" fill="none" stroke="currentColor" class="mut dash"/>
  <text x="168" y="170" font-size="11">%r.v4 %r.v5 %r.err6 %r.v9 … (not rooted)</text>
  <rect x="490" y="32" width="190" height="60" fill="none" stroke="currentColor" class="ink"/>
  <text x="500" y="52" font-size="11" class="b">runtime (%shr)</text>
  <text x="500" y="70" font-size="11">chain of frames</text>
  <text x="500" y="86" font-size="11" class="mut">shllvm_enter links %frame</text>
  <line x1="440" y1="62" x2="488" y2="62" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="20" y="206" font-size="11">root slots hold managed values the plan requires at a safepoint;</text>
  <text x="20" y="224" font-size="11">%argv is read by the call helper before anything can collect;</text>
  <text x="20" y="242" font-size="11">%r.* locations hold values with no safepoint between definition and last use.</text>
</svg>
```

**Figure 16.1.** The storage of `deposit` as the printed prologue lays it out. The root area is runtime-visible; the argument area and the unrooted locations are ordinary stack memory. The header's size is the runtime's business. Schematic in proportions; the slot names and counts are from the printed text.

## 16.3 Helpers with out pointers, and constants

Almost every operation becomes one helper call with the same convention: the first argument is a pointer to where the result goes, the second is the runtime, then an operation code if the helper serves several operations, then pointers to the operands. Results are never returned in registers, because a register is invisible to the collector; operands are never passed by value, for the same reason. Here is the body of `deposit` after the type check:

```llvm
b.endif2:
  ; balance7 = cell.load_checked(c_balance)
  call void @shllvm_check_tdz(ptr %s1, ptr %shr, ptr %s2)
  ; v9 = js.add(balance7, amount)
  call void @shllvm_binary(ptr %r.v9, ptr %shr, i32 0, ptr %s1, ptr %s0)      ; may collect
  ; cell.store(c_balance, v9)
  call void @shllvm_env_store(ptr %discard, ptr %shr, ptr %s2, ptr %r.v9)
  ; log11 = cell.load_checked(c_log)
  call void @shllvm_check_tdz(ptr %s1, ptr %shr, ptr %s3)
  ; log12 = cell.load_checked(c_log)
  call void @shllvm_check_tdz(ptr %s3, ptr %shr, ptr %s3)
  ; length13 = js.get(log12, "length")
  call void @shllvm_constant(ptr %scratch, ptr %shr, i32 11)          ; "length"
  call void @shllvm_get(ptr %s3, ptr %shr, ptr %s3, ptr %scratch)      ; may collect
```

Each IR operation is a comment followed by its code, so the two levels can be read side by side. `js.add` is `shllvm_binary` with code 0 (add), borrowing `balance7` from `%s1` and `amount` from `%s0`; its result `v9` goes to the unrooted `%r.v9`, which is safe because the next operation, `cell.store`, consumes it and cannot collect. The plan's slot sharing is visible: `log12 = cell.load_checked(c_log)` reads the cell from `%s3` and writes the result into `%s3`, because `c_log` is not needed afterwards. The same happens in `shllvm_get(ptr %s3, …, ptr %s3, …)`: the out pointer may alias an operand, so every helper must read its operands before it writes its result. That rule is part of the helper contract, and the plan relies on it.

Figure 16.2 takes the last call apart.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 230">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="22" font-size="10" class="lbl">length13 = js.get(log12, "length")</text>
  <text x="20" y="52" font-size="12">call void @shllvm_get(</text>
  <rect x="174" y="36" width="76" height="24" fill="none" stroke="currentColor" class="acc"/>
  <text x="180" y="52" font-size="12">ptr %s3,</text>
  <rect x="256" y="36" width="86" height="24" fill="none" stroke="currentColor" class="mut"/>
  <text x="262" y="52" font-size="12">ptr %shr,</text>
  <rect x="348" y="36" width="76" height="24" class="f-fill" stroke="currentColor"/>
  <text x="354" y="52" font-size="12">ptr %s3,</text>
  <rect x="430" y="36" width="116" height="24" class="f-fill" stroke="currentColor"/>
  <text x="436" y="52" font-size="12">ptr %scratch)</text>
  <line x1="212" y1="62" x2="212" y2="108" stroke="currentColor" class="acc" marker-end="url(#arrow)"/>
  <text x="150" y="124" font-size="11" class="acc">out: length13</text>
  <line x1="299" y1="62" x2="299" y2="148" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <text x="262" y="164" font-size="11" class="mut">the runtime</text>
  <line x1="386" y1="62" x2="386" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="350" y="124" font-size="11">object: log12</text>
  <line x1="488" y1="62" x2="488" y2="148" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="440" y="164" font-size="11">key: string 11 "length"</text>
  <text x="20" y="200" font-size="11">The same slot %s3 is read as the operand and then written as the result: helpers read first.</text>
  <text x="20" y="218" font-size="11" class="mut">Every pointer except %shr points into the root area, so a collection inside the helper updates them.</text>
</svg>
```

**Figure 16.2.** One helper call of `deposit`, from the printed text. The result pointer comes first, then the runtime, then the operands; `%s3` holds `log12` on the way in and `length13` on the way out, as the plan's slot sharing allows.

Literals take two forms. Numbers, booleans, `null` and `undefined` are immediates: the printer stores their tagged word directly, as `store i64 0x4024000000000000, ptr %t1` for `10` ([Chapter 12](lab:book?ch=12)). Strings are heap objects, so they come from the module's **string table**: `shllvm_constant(out, shr, index)` materialises entry `index`, and the module begins with the table in comments (`"length"` is entry 11 in the ledger's module). A literal operand is written just before the helper that reads it, to `%scratch`, or to `%discard` for a second literal in the same operation; both fixed slots are free again once the helper returns. A third or later literal in one operation (`print(1, 2, 3)`) goes to a stack temporary, `%lit2`, `%lit3` and so on, allocated in the prologue; a constant needs no root, so these are plain `alloca` words.

## 16.4 Inline arithmetic on tagged words

When the facts prove the operands are numbers ([Chapter 12](lab:book?ch=12)), the operation is inline, and the printer writes LLVM's own instructions. From `fib` with the assumption and standard rewrites:

```llvm
b.body2:
  ; v12 = num.add(a3_1, b4_1)
  %t11 = load i64, ptr %r.a3_1, align 8
  %t12 = bitcast i64 %t11 to double
  %t13 = load i64, ptr %r.b4_1, align 8
  %t14 = bitcast i64 %t13 to double
  %t16 = fadd double %t12, %t14
  %t15 = bitcast double %t16 to i64
  store i64 %t15, ptr %r.v12, align 8
  br label %b.next3
```

Because of NaN-boxing, a number's tagged word is its double's bits, so unboxing is a `bitcast`, which costs no instruction at all once LLVM has the values in registers. The add is `fadd`, and boxing the result is another `bitcast`. One rule of the representation is not enforced here: a NaN that `fadd` produces must be canonicalised before it is stored as a value (x86 produces `0xFFF8000000000000` for an invalid operation such as $\infty - \infty$), and the printed text does not insert that step. A real build has to. A comparison is `fcmp olt` followed by `select i1 %t8, i64 0xFFF9000000000001, i64 0xFFF9000000000000`, choosing between the tagged words of `true` and `false`. A branch on a value calls `shllvm_truthy` and compares its `i32` result with 0.

Edges carry block arguments as stores into the target's parameter locations, and the printer loads every argument before it stores any:

```llvm
  %t29 = load i64, ptr %r.b4_1, align 8
  %t30 = load i64, ptr %r.v12, align 8
  %t31 = load i64, ptr %r.v17, align 8
  store i64 %t29, ptr %r.a3_1, align 8
  store i64 %t30, ptr %r.b4_1, align 8
  store i64 %t31, ptr %r.i5_1, align 8
  br label %b.for1
```

That is the parallel copy of [Chapter 15](lab:book?ch=15) again: `b4_1` is both read (into `a3_1`) and written (from `v12`), and loading first keeps the swap correct.

## 16.5 Closures and calls through argv

A closure needs its code and its captured cells. A call needs a callee, a `this`, and arguments. Both pass their variable-length parts through `%argv`. From `main` of the ledger:

```llvm
  ; f4 = js.closure(@makeLedger)
  call void @shllvm_closure(ptr %s1, ptr %shr, ptr %frame, i32 1, i32 0, ptr %argv)      ; @makeLedger · may collect
  ; r6 = js.call(f4, undefined, "main")
  %t0 = getelementptr i64, ptr %argv, i32 0
  call void @shllvm_constant(ptr %t0, ptr %shr, i32 0)          ; "main"
  store i64 0xFFF8800000000000, ptr %discard       ; undefined
  call void @shllvm_call(ptr %r.r6, ptr %shr, ptr %frame, ptr %s1, ptr %discard, ptr null, i32 1, ptr %argv)      ; may collect
```

`shllvm_closure` receives the function's index in the module (1: `makeLedger` is the second function), the number of captured cells (0) and the area that holds them. The call writes its one argument straight into `argv[0]`, here a string constant materialised in place, puts `undefined` in `%discard` as `this`, and calls `shllvm_call(out, shr, frame, callee, this, new_target, argc, argv)`, with `null` for `new_target` because this is not a `new` expression. A method call, `ledger.deposit(10)`, first fetches the method with `shllvm_get` into `%scratch`, then calls with the object itself as `this`. The closure for the job, `js.closure(@arrow, c_ledger3)`, stores the cell into `argv[0]` and passes a count of 1.

The argument area is ordinary stack memory, not a root slot. That is safe under one more clause of the helper contract: a call helper copies the arguments into the callee's frame before anything can collect. With that clause, values only pass through `%argv` and are never needed there across a safepoint.

## 16.6 Protected regions

[Chapter 14](lab:book?ch=14) explained the setjmp protocol; in the text it is a few lines in three places. The prologue of a function with a protected region adds the try record, the volatile `%try_state`, `shllvm_try_begin` and the `_setjmp … returns_twice` whose second return branches to `catch.dispatch`. A protected block starts by naming its region, `store volatile i32 1, ptr %try_state, align 4    ; protected: a throw goes to catch1`, and every other block of the function, handlers included, starts by storing `0` (`; not protected: a throw unwinds to the caller`), so a throw after a region has ended, or inside its handler, leaves the function instead of re-entering the handler. And the dispatch block at the end of the function switches on the state, fetches the thrown value with `shllvm_catch_value` into the handler parameter's root slot, or passes the exception on with `shllvm_rethrow`.

The Hermes backend does more at these points than the workbench prints. Its dispatch block first calls `shllvm_catch_prepare` with the function's root storage, frame and argument capacity, which restores the runtime's root and register-stack state through `_sh_catch_no_pop`; it unlinks the try record with `shllvm_try_end` before a return or a rethrow; and in functions with a try it makes its ordinary loads and stores volatile, so a value written before a throw is in memory when the handler reads it. The workbench's plans record these obligations (`restores: ['root chain', 'managed frame']`), and its printer omits the calls. A local build that compiles this text must add them.

## 16.7 The structural checker

Since no LLVM checks the text, the workbench checks what it can without one:

```js
// core.js
function checkLLVM(text, declarations = []) {
  const errors = [], lines = text.split('\n').map(l => l.replace(/;.*$/, ''));
  const callable = new Set(declarations.map(d => /@([\w.]+)\(/.exec(d)[1]));
  for (const l of lines) { const m = /^define [^@]*@([\w.]+)\(/.exec(l.trim()); if (m) callable.add(m[1]); }
  const defined = new Set(['%shr']), labels = new Set();
// …
    if (/^[\w.]+:$/.test(line)) { if (open && !/^(br|ret|unreachable|switch|\])/.test(last)) errors.push({ line: i + 1, message: `the block before ${line} does not end in a terminator` }); open = true; last = ''; return; }
    for (const m of line.matchAll(/label %([\w.]+)/g)) if (!labels.has(m[1])) errors.push({ line: i + 1, message: `branch to unknown label %${m[1]}` });
```

It strips comments, collects the callable names (every declaration and every defined function) and every name defined with `=`, and every label. Then it walks the lines: a label that begins a block must follow a terminator (`br`, `ret`, `unreachable`, a `switch`), every label a branch names must exist, every `%name` used must be defined somewhere, and every called function must be declared or defined. Deleting the `br label %b.endif2` from the edge block of `deposit` and renaming `shllvm_set` to `shllvm_put` gives two errors: "the block before b.then1: does not end in a terminator" and "@shllvm_put is called but not declared".

What it does not check is most of what LLVM's verifier does: types of operands, that each `%t` is used only where its definition dominates the use, that `select` and `fcmp` have matching widths, the attributes. The checker catches the printer's typical mistakes, a missing branch or a forgotten declaration, not every mistake. Every function of the ledger passes it.

## 16.8 The running example: the ledger meets a real LLVM

The ledger's module is 436 lines: a 13-entry string table, 30 declarations from `_setjmp` to `shllvm_unary`, and six functions, each passing the structural check. If a local build fed it to LLVM, these are the changes to expect, in order of importance.

First, the helpers. The printer uses `shllvm_` names for every helper. Most are names of the Hermes backend's helpers (`shllvm_enter`, `shllvm_roots`, `shllvm_frame_size`, `shllvm_get`, `shllvm_call`, `shllvm_closure`, `shllvm_binary`, `shllvm_env_load`, `shllvm_try_begin`), each a thin wrapper over a Static Hermes runtime function. Some argument lists differ: the backend's `shllvm_leave` also takes the storage, and its `shllvm_check_tdz` takes the runtime, a value and a mask where the printer passes an out pointer, the runtime and the cell. One helper, `shllvm_push_args` for direct calls, is the printer's own. A real build has to reconcile each of these, which is a list the text makes easy to write. Second, the try protocol additions of 16.6. Third, optimisation. LLVM's `mem2reg` and `SROA` passes will turn every `%r.*` location into an SSA register, which is safe exactly because the plan put there only values with no safepoint in their lifetime; the root slots, whose addresses escape into helper calls, stay in memory, which is what the collector needs. The `bitcast` pairs vanish, `fadd double 0.0, 1.0` folds to a constant, and the edge blocks merge into their targets.

None of this changes the plan. The slots, the safepoints, the required sets and the unwind obligations are properties of the L3 program that the workbench has already checked by argument (the plan checker) and by test (the moving collector of [Chapter 13](lab:book?ch=13)). The LLVM text is where those decisions become visible to a tool the workbench does not have.

> **Try it.** [Load B-01](lab:preset?id=B-01), [switch to the LLVM level](lab:level?l=LLVM) and [select deposit](lab:fn?name=deposit). Find the call that writes `length13` and check its pointers against [the Plan view](lab:show?view=plan). [W-04 LLVM IR in the Hermes shape](lab:preset?id=W-04), [W-05 Closures and calls in LLVM](lab:preset?id=W-05), [W-06 try/catch in LLVM](lab:preset?id=W-06) and [W-07 The structural checker](lab:preset?id=W-07) each take one part of this chapter further.

> **Try it.** [Load W-06](lab:preset?id=W-06), [show readBoth](lab:fn?name=readBoth) at [the LLVM level](lab:level?l=LLVM) and follow `%try_state` through both protected regions. Then [load W-07](lab:preset?id=W-07) and [open its main.js](lab:open?file=main.js) to see the six ways it breaks the same function.

## 16.9 Key points

The workbench prints LLVM IR in the shape of the Hermes backend and checks its structure; it does not compile or run it. A function takes only the runtime pointer, builds a frame with `shllvm_enter`, names its root slots with `getelementptr`, and keeps unrooted values in plain stack locations. Helpers take an out pointer first and operands by pointer, may write a result over an operand, and must read operands first. Immediates are stored as tagged words, strings come from the module's string table, numbers proven by facts are computed with `fadd` and `fcmp` on bitcast words, and edges copy block arguments loads first. Closures and calls pass variable parts through `%argv`, which the call helper reads before anything can collect. The setjmp protocol appears as a prologue, a store per protected block and a dispatch block, and the Hermes backend adds catch preparation, state resets and record unlinking that the printer leaves out. The structural checker catches missing terminators, labels, definitions and declarations, and a real LLVM would mostly optimise the unrooted locations away.

## Exercises

1. In [B-01](lab:preset?id=B-01), find every `shllvm_binary` call in `main` and decode its operation code with the `OPCODES` list in `core.js`.
2. Pick a value of `total` that lives in `%r.*` and prove from the plan that no safepoint lies between its definition and its last use.
3. Break the LLVM of a function in three ways the structural checker does not detect (a type error, a use that its definition does not dominate, a wrong argument count) and explain why each would be caught by LLVM's own verifier.
4. Write the lines the dispatch block of `main` would need if the printer followed the Hermes backend's protocol of 16.6, using the helper signatures given there.
5. A short project: add an option to the printer that emits `invoke` and a landing pad instead of the setjmp protocol for one protected block, and list the helper contract changes it requires (compare [Chapter 14](lab:book?ch=14)).
