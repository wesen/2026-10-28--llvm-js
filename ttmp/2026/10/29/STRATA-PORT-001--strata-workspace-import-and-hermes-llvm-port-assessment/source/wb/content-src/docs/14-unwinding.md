---
id: unwinding
title: setjmp, status codes and landing pads
group: Lowering
about: Three ways to get an exception from a throwing helper to a handler in compiled code, what each costs, and what a catch must restore.
order: 14
---
# setjmp, status codes and landing pads

In core IR an exception is an edge: an operation in a block that `throws to H` continues at `H` when it throws ([Exceptional control flow](lab:doc?id=exceptions)). In machine code there is no such edge. The throw happens deep inside a runtime helper, perhaps inside a getter compiled as its own function, several native frames below the function that catches. **Unwinding** is the mechanism that gets control from there back to the handler, and it is a lowering decision with three well-known answers. This doc compares them as the workbench's exception strategies (`g.exceptions.setjmp`, `statusReturn`, `landingPads`), says what any of them must repair, and why the choice is tied to the root strategy. [L-08](lab:preset?id=L-08), [L-09](lab:preset?id=L-09) and [W-06](lab:preset?id=W-06) show them; [Chapter 14](lab:book?ch=14) goes deeper.

## setjmp and longjmp

C's `setjmp` saves the current registers and stack pointer in a buffer and returns 0; `longjmp(buffer, n)` restores them, so that `setjmp` appears to return again, with `n`. A function that catches calls `setjmp` once in its prologue; a helper that throws records the exception in the runtime and long-jumps to the most recent buffer. The Hermes runtime reports exceptions this way, and the workbench's LLVM text follows its shape: a jump buffer per function, a `try_state` variable naming the current protected region, and a `catch.dispatch` that switches on it.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="20" width="170" height="44" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="38" font-size="11" class="b">prologue</text>
  <text x="30" y="54" font-size="10" class="it">try_state = 0; setjmp</text>
  <rect x="240" y="20" width="170" height="44" fill="none" stroke="currentColor" class="ink"/>
  <text x="250" y="38" font-size="11" class="b">b.try3</text>
  <text x="250" y="54" font-size="10" class="it">try_state = 1; call helper</text>
  <rect x="460" y="20" width="160" height="44" fill="none" stroke="currentColor" class="ink"/>
  <text x="470" y="38" font-size="11" class="b">helper → getter</text>
  <text x="470" y="54" font-size="10" class="it">throws: longjmp</text>
  <rect x="240" y="150" width="170" height="44" class="f-fill" stroke="currentColor"/>
  <text x="250" y="168" font-size="11" class="b">catch.dispatch</text>
  <text x="250" y="184" font-size="10" class="it">switch try_state</text>
  <rect x="460" y="150" width="160" height="44" fill="none" stroke="currentColor" class="acc"/>
  <text x="470" y="168" font-size="11" class="b">h.catch1 → catch1</text>
  <text x="470" y="184" font-size="10" class="it">fetch the exception</text>
  <rect x="20" y="150" width="170" height="44" fill="none" stroke="currentColor" class="mut"/>
  <text x="30" y="168" font-size="11" class="b">catch.rethrow</text>
  <text x="30" y="184" font-size="10" class="it">state 0: to the caller</text>
  <line x1="190" y1="42" x2="238" y2="42" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="410" y1="42" x2="458" y2="42" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M540,64 L540,110 L105,110 L105,72" fill="none" stroke="currentColor" class="acc dash" stroke-dasharray="5 4" marker-end="url(#arrow)"/>
  <text x="330" y="104" font-size="10" text-anchor="middle" class="it">longjmp: setjmp returns again, status ≠ 0</text>
  <text x="168" y="142" font-size="10" class="it">status ≠ 0</text>
  <path d="M160,64 L160,128 L325,128 L325,148" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="410" y1="172" x2="458" y2="172" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="240" y1="172" x2="192" y2="172" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <text x="434" y="164" font-size="10" text-anchor="middle">1</text>
  <text x="216" y="164" font-size="10" text-anchor="middle">0</text>
  <text x="20" y="230" font-size="10" class="mut">Every value the handler reads must be in memory: try_state is volatile, the rest live in root slots.</text>
</svg>
```

**Figure 14.1.** The setjmp protocol in `risky` ([L-08](lab:preset?id=L-08)). A throw anywhere below the protected block long-jumps to the prologue's buffer; the dispatch sends state 1 to its handler and state 0 to the caller. Schematic.

Its costs are at the edges. Entering a function with a protected region costs a `setjmp` (saving a dozen registers) even if nothing throws. A throw costs a `longjmp`, which is cheap, plus a dispatch. And because `longjmp` restores the registers saved at `setjmp`, not the ones in use when the throw happened, every value the handler needs must be in memory: the workbench's plans put them in root slots, and `try_state` is a `volatile` stack variable so that LLVM neither caches it nor deletes the store before the throwing call.

## Status returns

With **status returns**, every helper that may throw returns a status, and the compiled code tests it after each call: `%st = call i32 @helper(...)` followed by `br i1 %failed, label %handler, label %next`. Nothing jumps, so nothing is skipped, no registers are lost and the handler sees the frame exactly as the failing call left it. The cost moves to the normal path: one test and one branch after every call that may throw, which in JavaScript is most calls. It also requires helpers written that way. The workbench's pipeline check refuses `statusReturn` while Hermes provides the JavaScript operation sets, because Hermes's helpers long-jump; with the reference provider for all four sets it is accepted. The plan then records the strategy; the LLVM printer, as [L-09](lab:preset?id=L-09) notes, still writes only the setjmp protocol.

## Landing pads

The C++ approach is **table-driven unwinding**: the compiler emits, beside the code, tables that describe each function's frame and the address of each handler (a **landing pad**). A throw calls the system unwinder, which walks the native stack using the tables, first to find a handler and then to unwind to it, running cleanups on the way. The normal path costs nothing at all, which is why it is called zero-cost exception handling; a throw is expensive (microseconds), and the compiler and runtime must agree on the table format. For an engine whose code throws often (JavaScript code uses exceptions for control flow more than C++ does), the cost of a throw matters, and the workbench has no declared pair for `landingPads`: nobody has traced one through its collector and suspension rules.

| strategy | normal path | a throw | needs |
|---|---|---|---|
| setjmp | a setjmp per function with a protected region | longjmp and a dispatch | volatile state, handler values in memory |
| statusReturn | a test after every throwing call | a branch | helpers that return a status |
| landingPads | nothing | a table-driven stack walk | unwind tables, an unwinder |

## What a catch must restore

Whatever the mechanism, frames between the throw and the handler are abandoned, and the runtime knew about them. The workbench's plan lists, per protected region, what the catch restores:

```text
; unwind risky/try3 → catch1: setjmp, restores root chain, managed frame
```

The **root chain** is the runtime's list of active frames whose slots the collector scans; abandoned frames must be unlinked, or the next collection reads dead stack memory. The **managed frame** is the function's register frame in the runtime, which must be the current one again. Under the `arena` root strategy there is a third item, the **arena mark**: abandoned frames took root slots from the arena, and the catch resets the arena to the mark saved at the checkpoint.

## Why roots and exceptions must agree

The third item is the reason `g.compat(roots, exceptions)` exists. A root strategy decides where managed values live; an exception strategy decides which frames get skipped; together they decide what a catch must repair. `arena` with `setjmp` is declared with the requirement "the arena mark saved in every catch checkpoint". `arena` with `statusReturn` is probably fine, since nothing is skipped, but it has not been traced, so the pipeline refuses it and names `g.compat.declare`. The workbench prefers a refusal that explains itself to a combination it has not checked.

## The handler's view in core IR

One consequence reaches back to the IR. A block's exceptional exit passes the thrown value and, optionally, arguments evaluated at the head of the block. A handler therefore cannot see a value that changes in the middle of the protected block, and the promote-cells pass keeps such variables as cells ([L-08](lab:preset?id=L-08)'s exercise, `step`). That is exactly what the setjmp protocol needs anyway: a cell is memory, so it survives the jump with its latest value.

## What this model leaves out

The plan mode and the specification execute the IR, not the LLVM text, so none of the three mechanisms actually runs in the page; their differences appear as plan annotations and as text. Real engines also unwind through native frames of host code (a C++ embedder's callback), interleave unwinding with finally blocks and generators, and must keep the collector correct while an exception is in flight (the exception value itself is a root). The setjmp text also has a rule of its own that the other two mechanisms do not need: every block outside a protected region, handlers included, stores `0` into `try_state`, or a throw after the region (or inside its handler) would dispatch back into the handler. [W-06](lab:preset?id=W-06) reads those stores, and [W-07](lab:preset?id=W-07) deletes one to show that a structural check cannot tell.
