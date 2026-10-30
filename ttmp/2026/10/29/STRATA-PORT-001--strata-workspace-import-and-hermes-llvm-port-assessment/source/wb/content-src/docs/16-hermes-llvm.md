---
id: hermes-llvm
title: The Hermes LLVM backend
group: Backends
about: What the workbench's LLVM text mirrors from the Hermes LLVM backend (function shape, frames, root slots, helpers, the setjmp protocol), and what it leaves out.
order: 16
---
# The Hermes LLVM backend

The last level of the workbench's pipeline is LLVM IR text in the shape of the code the Hermes LLVM backend emits. This doc says what that shape is, which parts the workbench reproduces, and which it does not. One fact first, because everything else depends on it: **neither LLVM nor Hermes is in the page.** The workbench prints the text, checks it structurally ([W-07](lab:preset?id=W-07)) and shows it beside the plan it came from. It never compiles it, links it or runs it; Spec, Plan and Wasm mode execute the IR and the Wasm binary, not this text. What the text is good for is reading: every decision of the earlier levels is visible in it, in the form a native build would consume. [W-04](lab:preset?id=W-04) to [W-06](lab:preset?id=W-06) read it closely, and [Chapter 16](lab:book?ch=16) covers it in full.

## One function, one runtime argument

Each JavaScript function becomes one LLVM function that takes the runtime and returns a tagged word:

```llvm
define internal i64 @deposit(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %size = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %size, align 16
  %argv = alloca [1 x i64], align 8
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 1, i32 0)
```

`%shr` is the runtime; the `i64` result is a NaN-boxed value ([Tagged values and NaN-boxing](lab:doc?id=nan-boxing)). JavaScript arguments are not LLVM parameters: the callee reads them from its frame with `shllvm_param`. The prologue checks for native stack overflow, allocates the frame's storage on the native stack and calls `shllvm_enter` with the number of slots (root slots plus two fixed), the number of outgoing argument slots and a unit index. `shllvm_enter` links the frame into the runtime's chain, which is how the collector finds its slots.

## Frames and root slots

```llvm
  %roots = call ptr @shllvm_roots(ptr %storage)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %scratch = getelementptr i64, ptr %roots, i32 4
  %discard = getelementptr i64, ptr %roots, i32 5
```

Root slots are addressed as `getelementptr` offsets from the frame's slot array, numbered as in the L3 plan. The two **fixed slots** follow them: `%scratch` receives a literal operand just before a helper reads it, and `%discard` receives results nobody uses (and a second literal operand of the same call); a third or later literal goes to a stack temporary, `%lit2` and on, allocated in the prologue. Values the plan does not root get a plain `alloca` word (`%r.v9`), which the collector does not see; the plan guarantees nothing needs them across a safepoint. The Hermes backend refuses a function whose frame would exceed 1,024 slots, and the workbench's plan checker applies the same limit ([L-07](lab:preset?id=L-07)). The workbench's default strategy, `stackReuse`, is the point of departure from today's backend, which gives every managed value its own slot (the workbench's `distinct`).

## Operations become helpers

An operation either lowers inline or becomes a call to a helper whose first argument is an out pointer and second the runtime. Operands are pointers to slots, never values in registers, so a moving collection inside the helper can update them:

| operations | lowering |
|---|---|
| `num.add` … `num.ge`, `num.mod` | inline `fadd`, `fsub`, `fmul`, `fdiv`, `frem`, `fcmp` on bitcast words |
| `js.add`, `js.sub`, `js.lt` and the other operators | `shllvm_binary` with an operator code |
| `js.typeof`, `js.neg` | `shllvm_unary` |
| `js.get`, `js.put` | `shllvm_get`, `shllvm_set` |
| `obj.new`, `arr.new`, `js.define` | `shllvm_object`, `shllvm_array`, `shllvm_define` |
| `js.closure`, `js.call`, `js.call_method` | `shllvm_closure`, `shllvm_call` |
| `cell.new`, `cell.load`, `cell.store`, `cell.load_checked` | `shllvm_env_create`, `shllvm_env_load`, `shllvm_env_store`, `shllvm_check_tdz` |
| `js.new_error`, `throw` | `shllvm_constructed_object`, `shllvm_throw` |
| `host.print`, `job.enqueue`, `timer.set`, `promise.resolve` | `shllvm_builtin` with a builtin code |
| `core.call` | a direct `call i64 @callee(ptr %shr)` after `shllvm_push_args` |

The helper names follow the `shllvm_` convention of the Hermes backend's runtime interface; the signatures are the workbench's own simplification. String constants come from a string table printed at the top of the module and materialised with `shllvm_constant(out, shr, index)`.

## Calls and closures

A call writes its arguments into the outgoing area `%argv` and passes the callee, `this` and `new.target` as pointers: `shllvm_call(out, shr, frame, callee, this, null, argc, argv)`. A closure is created from a function index (its position in the module) and the cells it captures, also passed through `%argv`: `shllvm_closure(out, shr, frame, index, ncaps, argv)`. [W-05](lab:preset?id=W-05) reads both.

## The setjmp protocol

Hermes's helpers report exceptions by `longjmp`, so a function with a `try` saves a jump buffer in its prologue (`shllvm_try_begin`, then `_setjmp … returns_twice`), keeps a `volatile` `try_state` naming the current protected region, and has a `catch.dispatch` block that switches on the state after a long jump and fetches the exception with `shllvm_catch_value`, or passes it on with `shllvm_rethrow`. The evidence the workbench records for this pair of strategies is that Hermes's catch path restores locals and the frame together. [W-06](lab:preset?id=W-06) and [Unwinding](lab:doc?id=unwinding) cover it.

## Where each part of the text comes from

Nothing in the text is decided by the printer. Figure 16.1 traces each part back to the level that decided it: the frame size and slot numbers to the L3 plan, the helper names and the `may collect` comments to the L2 bindings, the constants to the IR's literals, and the protocol blocks to the plan's unwind entries. That is what makes the text useful to read: a surprising line in it is a surprising decision upstream, and the inspector of the Stage leads to it.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="20" font-size="10" class="lbl">decided at</text>
  <text x="400" y="20" font-size="10" class="lbl">appears in the LLVM text as</text>
  <rect x="20" y="30" width="200" height="34" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="51" font-size="11">L3 plan: slots, frame size</text>
  <rect x="20" y="78" width="200" height="34" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="99" font-size="11">L2 bindings: helper, collects</text>
  <rect x="20" y="126" width="200" height="34" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="147" font-size="11">L1 literals</text>
  <rect x="20" y="174" width="200" height="34" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="195" font-size="11">L3 plan: unwind entries</text>
  <rect x="400" y="30" width="220" height="34" class="f-fill" stroke="currentColor"/>
  <text x="410" y="51" font-size="10">shllvm_enter(…, i32 6, i32 1, …); %s0…%s3</text>
  <rect x="400" y="78" width="220" height="34" class="f-fill" stroke="currentColor"/>
  <text x="410" y="99" font-size="10">call @shllvm_get(…) ; may collect</text>
  <rect x="400" y="126" width="220" height="34" class="f-fill" stroke="currentColor"/>
  <text x="410" y="147" font-size="10">string table; shllvm_constant(…, i32 11)</text>
  <rect x="400" y="174" width="220" height="34" class="f-fill" stroke="currentColor"/>
  <text x="410" y="195" font-size="10">_setjmp, try_state, catch.dispatch (a try)</text>
  <line x1="220" y1="47" x2="398" y2="47" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="220" y1="95" x2="398" y2="95" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="220" y1="143" x2="398" y2="143" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="220" y1="191" x2="398" y2="191" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="20" y="236" font-size="10" class="mut">The printer adds only fixed parts: the prologue, the epilogue (shllvm_leave) and the declarations.</text>
</svg>
```

**Figure 16.1.** Where the parts of `deposit`'s LLVM text are decided. Schematic; the numbers are those of `deposit` under `stackReuse`.

## What the workbench does not reproduce

The text is a faithful shape, not a drop-in replacement. Helper signatures, operator and builtin codes and the unit index are the workbench's own. There is no metadata, debug information, attribute or calling-convention annotation, and no optimisation: every value goes through memory, as at `-O0`. Representation choices recorded at L2 do not change the text (doubles cost only bitcasts anyway). The exception strategy `statusReturn` changes the plan but not the text. And one gap shows when the text is read beside the plan: the outgoing area `%argv` is a separate `alloca` although the frame size counts it, so a helper that collected before reading its arguments would see stale copies ([W-05](lab:preset?id=W-05)). The try protocol itself is stated in full for the state: every block outside a protected region stores `0` into `try_state`, so an exception inside a handler leaves the function ([W-06](lab:preset?id=W-06)); the calls Hermes adds around it (`shllvm_catch_prepare`, `shllvm_try_end`) are not printed.

## From this text to a native build

To run this text, a local build would add three things the page cannot: LLVM itself (`opt -passes=verify` first, then code generation), the Hermes runtime with real implementations of the helpers, and a linker step that puts the compiled functions where the runtime expects them. The workbench's checks are designed to survive that move. The plan checker's invariant, the 1,024-slot limit, the declared strategy pairs and the laws that compare plan mode with the specification all carry over unchanged; only the executor changes, from the simulated collector to the real one. [Chapter 21](lab:book?ch=21) lays out that port.
