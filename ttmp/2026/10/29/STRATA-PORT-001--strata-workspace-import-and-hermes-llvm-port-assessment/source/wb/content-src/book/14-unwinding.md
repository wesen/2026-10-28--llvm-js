# Unwinding

[Chapter 5](lab:book?ch=5) made exceptions part of the IR: a block that may throw names its handler, and an exceptional edge carries the thrown value to it. That is the meaning. This chapter is about the mechanism: how a `TypeError` created inside a runtime helper, several native frames below the compiled code that will catch it, actually gets there, and what must be true of the frame when it arrives. It covers the protocol the Hermes LLVM backend uses (a `setjmp` jump buffer and a try state), the two common alternatives (status returns and landing pads), what a catch must restore, and why the workbench treats the pairing of a root strategy with an exception strategy as a relation that has to be declared and justified rather than assumed.

## 14.1 From a helper to a handler

Follow the ledger's rejected deposit. `main` calls `ledger.deposit("five")` inside a `try`. In the IR that call is `r13 = js.call_method(ledger12, "deposit", "five")` in block `try3`, whose header says `throws to catch1`. Inside `deposit`, the type check fails, block `then1` creates the error with `js.new_error[TypeError]` and ends in `throw err6`. Every block of `deposit` is `throws unwind`, so the exception leaves `deposit`'s frame and arrives at the call in `main`, where the protected block sends it to `catch1`, whose parameter `e11` receives it. The reference interpreter records the whole trip as two events at step 53: a `throw` at `deposit/then1/term` and a `catch` at `main/try3/1` with handler `catch1`.

The interpreter can do this by walking its own frames. Compiled code cannot. Between `main`'s call and `deposit`'s throw lie native frames: `shllvm_call`, the runtime's call machinery, the compiled `deposit`, the helper that allocates the error. None of them knows where `main`'s handler is. The mechanism that crosses them is called **unwinding**, and it has three jobs: transfer control to the handler, deliver the thrown value, and leave the catching frame in a state the handler can run in, which for a garbage-collected runtime includes the collector's view of which frames and roots exist.

## 14.2 setjmp and the try state

The Hermes LLVM backend uses the C library's `setjmp` and `longjmp`. `setjmp(buffer)` saves the machine's registers and stack pointer into a buffer and returns 0; a later `longjmp(buffer, 1)` from any depth restores them, so `setjmp` returns a second time, now with 1. The runtime keeps a chain of such buffers; when a helper throws, it unwinds its own bookkeeping and jumps to the innermost one. The workbench prints this protocol into every function that has a protected block:

```js
// core.js
  const hasTry = fn.blocks.some(b => (b.onThrow && b.onThrow !== 'unwind') || (b.term && b.term.kind === 'invoke'));
  if (hasTry) {
    declare('shllvm_try_size', { ret: 'i64', args: [] }); declare('shllvm_try_begin', { ret: 'ptr', args: ['ptr', 'ptr'] }); declare('_setjmp', { ret: 'i32', args: ['ptr'] });
    lines.push('  %trysize = call i64 @shllvm_try_size()', '  %try_storage = alloca i8, i64 %trysize, align 16', '  %try_state = alloca i32, align 4',
      '  store volatile i32 0, ptr %try_state, align 4', '  %buffer = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)',
      '  %status = call i32 @_setjmp(ptr %buffer) returns_twice', '  %exceptional = icmp ne i32 %status, 0',
      `  br i1 %exceptional, label %catch.dispatch, label %b.${safeName(fn.entry)}`);
  } else lines.push(`  br label %b.${safeName(fn.entry)}`);
```

A function with a `throws to` block or an `invoke` gets, in its prologue, storage for one try record (sized by the runtime with `shllvm_try_size`), a 32-bit **try state** initialised to 0, a call to `shllvm_try_begin` that links the record into the runtime's chain and returns its jump buffer, and the `setjmp` itself. The first return goes on to the function's entry block. A return caused by a throw goes to `catch.dispatch`.

One buffer serves the whole function, so the code must say which handler is current. That is the try state. Each block of a protected region stores the region's number on entry: in `main`, block `try3` begins with `store volatile i32 1, ptr %try_state, align 4    ; protected: a throw goes to catch1`, and every block outside a region, the handler `catch1` and the block `endtry2` after it included, begins by storing 0 (`; not protected: a throw unwinds to the caller`). The dispatch block reads the state and switches on it:

```llvm
catch.dispatch:
  %state = load volatile i32, ptr %try_state, align 4
  switch i32 %state, label %catch.rethrow [
    i32 1, label %h.catch1
  ]
catch.rethrow:
  call void @shllvm_rethrow(ptr %shr)
  unreachable
h.catch1:
  call void @shllvm_catch_value(ptr %s1, ptr %shr)
  br label %b.catch1
```

State 1 goes to `h.catch1`, which asks the runtime for the thrown value, writes it into root slot `s1` (the slot the plan gave the handler's parameter `e11`) and continues in the handler. Any other state means the throw happened outside every region of this function, so `catch.rethrow` passes it on to the caller's buffer. Figure 14.1 traces both paths.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 300">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="20" width="200" height="54" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="40" font-size="11" class="b">prologue</text>
  <text x="30" y="58" font-size="11">try_state = 0 · %status = _setjmp</text>
  <rect x="20" y="110" width="200" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="134" font-size="11">b.entry · state 0</text>
  <rect x="20" y="180" width="200" height="54" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="200" font-size="11" class="b">b.try3 · state = 1</text>
  <text x="30" y="218" font-size="11">shllvm_call(deposit, "five")</text>
  <rect x="270" y="180" width="170" height="54" class="f-fill" stroke="currentColor"/>
  <text x="280" y="200" font-size="11">deposit · then1</text>
  <text x="280" y="218" font-size="11">throw TypeError</text>
  <rect x="270" y="20" width="170" height="54" fill="none" stroke="currentColor" class="acc"/>
  <text x="280" y="40" font-size="11" class="b">catch.dispatch</text>
  <text x="280" y="58" font-size="11">switch on try_state</text>
  <rect x="490" y="20" width="190" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="500" y="44" font-size="11">h.catch1 → b.catch1 (e11 in s1)</text>
  <rect x="490" y="90" width="190" height="40" fill="none" stroke="currentColor" class="mut"/>
  <text x="500" y="114" font-size="11" class="mut">catch.rethrow → caller</text>
  <line x1="120" y1="74" x2="120" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="128" y="96" font-size="10" class="lbl">status 0</text>
  <line x1="120" y1="150" x2="120" y2="178" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="220" y1="207" x2="268" y2="207" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M 355 180 L 355 76" fill="none" stroke="currentColor" class="acc dash" marker-end="url(#arrow)"/>
  <text x="362" y="140" font-size="10" class="lbl">longjmp: setjmp returns 1</text>
  <line x1="440" y1="40" x2="488" y2="40" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="446" y="34" font-size="10" class="lbl">1</text>
  <path d="M 440 60 L 470 60 L 470 110 L 488 110" fill="none" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <text x="446" y="88" font-size="10" class="lbl">other</text>
  <text x="20" y="270" font-size="11" class="mut">every frame between the call and the throw is skipped; only memory survives the jump</text>
</svg>
```

**Figure 14.1.** The setjmp protocol in `main` of the ledger. The first return of `setjmp` starts the function; the second, caused by the throw in `deposit`, lands in `catch.dispatch`, which picks the handler from the try state. Block names are from the printed LLVM of B-01.

Two details carry the correctness of the scheme. The call is marked `returns_twice`, which tells the optimiser that `setjmp` can return again after later code ran, so it may not keep values in registers across it. And the try state is read and written with `volatile`, because the second return of `setjmp` restores registers to their state at the first call: a state kept in a register would read 0 again. Everything the handler needs must therefore be in memory when the throw happens, which the workbench's lowering already guarantees: every value lives in a root slot or a stack location, never only in a register.

## 14.3 What a catch must restore

Getting control to `h.catch1` is half the job. The runtime also keeps state that the skipped frames changed and that must match the catching frame again. The workbench's plans list it per protected region:

```js
// core.js
    if (b.onThrow && b.onThrow !== 'unwind') unwind.push({ at: `${fn.name}/${b.name}`, handler: b.onThrow, strategy: exceptionStrategy.name, restores: ['root chain', 'managed frame', ...(chosen.storage === 'arena' ? ['arena mark'] : [])] });
```

The **root chain** is the runtime's list of frames whose root slots the collector scans. Each skipped frame registered itself on entry (`shllvm_enter`) and will never run its matching `shllvm_leave`, so the catch must cut the chain back to the catching frame, or the next collection will scan stack memory that now belongs to someone else. The **managed frame** is the runtime's notion of the current JavaScript frame, which call helpers update. And when the roots live in an arena ([Chapter 13](lab:book?ch=13)), the arena's allocation mark must go back to where it was when the region was entered, or the skipped frames' activations leak. The plan for `main` of the ledger records `{ at: 'main/try3', handler: 'catch1', strategy: 'setjmp', restores: ['root chain', 'managed frame'] }`, and with `roots('arena')` the list grows to include `'arena mark'`. In the Hermes backend the first two are one call in the dispatch block, `shllvm_catch_prepare`, which hands the function's root storage, frame and argument capacity to the runtime's `_sh_catch_no_pop`. The workbench records the obligation in the plan and its printer leaves the call out ([Chapter 16](lab:book?ch=16) lists what a real build must add).

Values are the other half. A handler may read variables that the protected code changed, and it must see their values at the operation that threw. [Chapter 5](lab:book?ch=5) showed the IR's side of this: a block-level exceptional exit passes its arguments as they were at the head of the block, so a variable stored inside a protected block and read after its handler stays a cell rather than becoming an SSA value. Here is the program `try { hits = 1; o.x; hits = 2; } catch (e) { print("caught " + e.message + " " + hits); }` with a getter `x` that throws, after promotion:

```text
try3() throws to catch1:
  cell.store(c_hits3, 1)
  x8 = js.get(o4, "x")
  cell.store(c_hits3, 2)
  jump endtry2()
```

`hits` is still the cell `c_hits3`, the handler reads it with `cell.load`, and the program prints `caught boom 1`. The cell is memory, so it survives the jump. The IR rule and the setjmp rule are the same rule seen from two levels: whatever the handler needs must be somewhere the jump does not erase.

## 14.4 Status returns and landing pads

`setjmp` is not the only design, and the workbench names two others as exception strategies.

With **status returns** (`g.exceptions.statusReturn()`), every helper that can throw returns a status, and the compiled code tests it after every call and branches to the handler or returns its own failure status. Nothing is skipped: each frame runs its own exit code, so the root chain and the managed frame are restored by the ordinary `shllvm_leave` path. The price is a test and a branch after every throwing call on the normal path, and helpers written to return a status instead of jumping.

With **landing pads** (`g.exceptions.landingPads()`), the approach C++ compilers take with LLVM's `invoke` instruction, the normal path has no cost at all: each throwing call names an unwind destination, and the compiler emits tables that a runtime unwinder reads to find it. The price is the unwinder, the tables, and helpers that throw through the platform's unwinding ABI.

| strategy | cost when nothing throws | who restores runtime state | helpers must |
|---|---|---|---|
| `setjmp` | one `setjmp` per function with a try, a store per protected block | the catch (runtime cuts the chains) | throw with `longjmp` (Hermes's do) |
| `statusReturn` | a test and branch after every throwing call | each frame's normal exit | return a status |
| `landingPads` | none | the unwinder, from tables | throw through the platform ABI |

In the workbench the exception strategy is recorded in each plan and constrained by the pipeline's checks, but both executors unwind the same way for every strategy, by following the IR's exceptional edges, and the LLVM printer knows only the setjmp protocol. So the workbench tests the exception structure of the IR under each strategy, not the machine code of the alternatives. Figure 14.2 contrasts the three on one throwing call, and the shelf doc [setjmp, status codes and landing pads](lab:doc?id=unwinding) compares them further.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="30" font-size="10" class="lbl">setjmp</text>
  <rect x="120" y="14" width="130" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="128" y="32" font-size="11">call helper</text>
  <rect x="300" y="14" width="120" height="28" class="f-fill" stroke="currentColor"/>
  <text x="308" y="32" font-size="11">frames…throw</text>
  <rect x="520" y="14" width="160" height="28" fill="none" stroke="currentColor" class="acc"/>
  <text x="528" y="32" font-size="11">setjmp returns 1</text>
  <line x1="250" y1="28" x2="298" y2="28" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M 420 28 L 518 28" fill="none" stroke="currentColor" class="acc dash" marker-end="url(#arrow)"/>
  <text x="430" y="20" font-size="10" class="lbl">longjmp</text>
  <text x="20" y="110" font-size="10" class="lbl">statusReturn</text>
  <rect x="120" y="94" width="130" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="128" y="112" font-size="11">call helper</text>
  <rect x="300" y="94" width="120" height="28" class="f-fill" stroke="currentColor"/>
  <text x="308" y="112" font-size="11">frames return 1</text>
  <rect x="520" y="94" width="160" height="28" fill="none" stroke="currentColor" class="acc"/>
  <text x="528" y="112" font-size="11">test status · branch</text>
  <line x1="250" y1="108" x2="298" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="420" y1="108" x2="518" y2="108" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="430" y="100" font-size="10" class="lbl">each frame</text>
  <text x="20" y="190" font-size="10" class="lbl">landingPads</text>
  <rect x="120" y="174" width="130" height="28" fill="none" stroke="currentColor" class="ink"/>
  <text x="128" y="192" font-size="11">invoke helper</text>
  <rect x="300" y="174" width="120" height="28" class="f-fill" stroke="currentColor"/>
  <text x="308" y="192" font-size="11">frames…throw</text>
  <rect x="520" y="174" width="160" height="28" fill="none" stroke="currentColor" class="acc"/>
  <text x="528" y="192" font-size="11">landing pad</text>
  <line x1="250" y1="188" x2="298" y2="188" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M 420 188 L 518 188" fill="none" stroke="currentColor" class="acc dot" marker-end="url(#arrow)"/>
  <text x="430" y="180" font-size="10" class="lbl">unwinder</text>
  <text x="20" y="236" font-size="11" class="mut">schematic: how control gets from a throw in a helper to the handler in the compiled caller</text>
</svg>
```

**Figure 14.2.** Three ways to unwind. The setjmp protocol jumps over the frames, status returns walk back through them, and landing pads let an unwinder find the handler from tables. Schematic.

## 14.5 Compatibility as a declared relation

A root strategy and an exception strategy interact. The arena strategy is safe with setjmp only if every catch also restores the arena's mark; a strategy that keeps roots in a side structure is safe with landing pads only if the unwinder knows to pop it. Such interactions are found by tracing what happens at throw, catch, collection and suspension together, not by looking at either strategy alone. So the workbench does not assume that any two strategies combine. It keeps a table of pairs that have been declared compatible, with the evidence and the requirements each relies on:

```js
// core.js
const DECLARED_PAIRS = new Map([
  ['distinct|setjmp', { evidence: 'the current Hermes protocol: _sh_catch_no_pop restores locals and the frame together' }],
  ['stackReuse|setjmp', { evidence: 'same protocol; slots are plain frame storage' }],
  ['arena|setjmp', { requires: 'the arena mark saved in every catch checkpoint', evidence: 'declared, traced in the workbench (L-presets)' }],
  ['none|setjmp', { evidence: 'a demonstration: nothing is rooted, so the plan checker reports every missing root' }],
  ['distinct|statusReturn', { requires: 'helpers that return a status', evidence: 'declared' }],
  ['stackReuse|statusReturn', { requires: 'helpers that return a status', evidence: 'declared' }],
]);
```

`g.compat(roots, exceptions)` looks the pair up. `g.compat(g.roots.arena(), g.exceptions.setjmp())` returns `ok: true` with its requirement; `g.compat(g.roots.arena(), g.exceptions.statusReturn())` returns `ok: 'unknown'` and a reason that says to declare the pair with `g.compat.declare` after tracing it. A pipeline's `check()` turns `'unknown'` into an error, so `g.pipeline().exceptions('landingPads')` is refused before anything compiles: stackReuse with landing pads has not been declared. A lambda root strategy inherits the declaration of the strategy it wraps ([Chapter 13](lab:book?ch=13)), because the checker verifies whatever plan it returns. The table is small on purpose. A compatibility relation that is declared and cited can be reviewed, and a pair that someone traces and declares becomes evidence other people can rely on. [L-09 statusReturn and compatibility](lab:preset?id=L-09) tabulates every pair with its requirements and evidence.

## 14.6 Why statusReturn needs other providers

The strategies also constrain who implements the operations. A Hermes helper that throws calls `longjmp`; it does not return. Under `statusReturn` the compiled code would wait for a status that never comes, and the jump would skip the very frames whose normal exits are supposed to restore the runtime's state. The pipeline checks this:

```js
// core.js
    if (r.exceptions.name !== 'setjmp') {
      const hermesSets = ['js.value', 'js.object', 'js.function', 'js.control'].filter(s => !r.providers[s] || r.providers[s] === 'hermes');
      if (hermesSets.length) diags.push({ severity: 'error', kind: 'strategy', message: `exceptions: ${r.exceptions.name} needs helpers that report errors without longjmp, but ${hermesSets.join(', ')} ${hermesSets.length > 1 ? 'are' : 'is'} provided by Hermes, whose helpers throw nonlocally; keep setjmp or provide those sets yourself` });
    }
```

Any exception strategy other than setjmp is refused while any of the four JavaScript operation sets is provided by Hermes. Providing all four with the reference provider (`.provide({ 'js.value': 'reference', 'js.object': 'reference', 'js.function': 'reference', 'js.control': 'reference' })`) makes `check()` pass, and the ledger then compiles with `statusReturn` recorded in every unwind entry. The obligation `nonlocalThrow` in an operation's contract ([Chapter 6](lab:book?ch=6)) is what makes this a rule rather than a convention: it records, for each operation, that its implementation may leave by a jump. [C-08 Providers and operation sets](lab:preset?id=C-08) shows the provider table, and [L-08 Unwinding with setjmp](lab:preset?id=L-08) the protocol on a smaller function.

> **Try it.** [Load L-08](lab:preset?id=L-08), [show risky](lab:fn?name=risky) with [the exceptional overlay](lab:overlay?name=exceptional&on=1), then [switch to LLVM](lab:level?l=LLVM) and find the store to `%try_state` in the protected block.

## 14.7 The running example: the rejected deposit

Put together, the rejected deposit is unwound like this under the default pipeline. `main` has one protected region, `try3`, numbered 1. When its call reaches `deposit`, the helper that creates the `TypeError` allocates (so it is a safepoint, and the plan roots what `main` and `deposit` need there), and the `throw` makes the runtime cut its chains back to `main`'s try record and jump. `setjmp` in `main`'s prologue returns 1, `catch.dispatch` reads try state 1 and goes to `h.catch1`, `shllvm_catch_value` writes the error into slot `s1`, and `b.catch1` reads `e11.message` from there. The ledger's slot `s1` in `main` holds fifteen values over the function's life, `f4`, `ledger7`, `e11` among them; at the catch it holds the error and nothing else, because the plan never requires two of them at once.

The reference interpreter and the L3 executor agree with this account: both print `rejected: amount must be a number` first, and under GC stress the plan run makes its 68 collections without a stale use, including the one at the handler's first operation, `js.get(e11, "message")`, where the plan roots the error in slot `s1`. What the workbench does not do is execute the setjmp text: the LLVM shown here is printed and checked, not run ([Chapter 16](lab:book?ch=16)).

> **Try it.** [Load B-01](lab:preset?id=B-01), [select the call in try3](lab:node?id=main/try3/1) and [turn on the exceptional overlay](lab:overlay?name=exceptional&on=1); the dashed edge goes to `catch1`. Then [switch to LLVM](lab:level?l=LLVM), pick `main`, and find `catch.dispatch`. [J-07 Errors across calls](lab:preset?id=J-07) throws through several frames.

## 14.8 Key points

Unwinding transfers control from a throw deep in the runtime to a handler in compiled code, delivers the thrown value, and restores the runtime's state for the catching frame. The Hermes protocol, which the workbench prints, uses one `setjmp` per function with a try, a volatile try state that names the current region, and a dispatch block that switches on it; everything a handler needs must be in memory, never only in a register. A catch must restore the root chain, the managed frame and, for arenas, the arena mark. Status returns and landing pads trade normal-path cost against runtime machinery in opposite directions. Root and exception strategies combine only as declared pairs with cited evidence, and a non-setjmp strategy requires providers whose helpers report errors without jumping.

## Exercises

1. In [B-01](lab:preset?id=B-01), read `program.plan('main').unwind`. Then compile with `roots('arena')` and read it again: what was added, and why does `stackReuse` not need it?
2. Find the blocks of `main` at the LLVM level that lie outside every protected region and the store each begins with. Delete the store at the start of `endtry2` from a copy of the text: what would a throw in `endtry2` then do, and would `g.llvm.check` notice?
3. Write a program with two separate `try` blocks in one function and predict the `switch` in `catch.dispatch` before you look.
4. Make `g.pipeline().exceptions('statusReturn')` pass `check()` with the fewest provider changes the rule allows, and explain why fewer are not enough.
5. A short project: declare `arena|statusReturn` with `g.compat.declare`, then write down, as a list of events (throw, frame exit, collection, catch), the trace you would need to observe in a real runtime before the declaration's `evidence` could say anything but "declared".

The next part leaves lowering and takes the plans to two backends: a WebAssembly encoder built by hand, and LLVM IR text in the shape of the Hermes backend.
