# Obligations

A behaviour says what an operation may do to the program's state. An **obligation** says what the code around the operation must provide when it is lowered to machine code. On the screen, `pair` builds an object and an array and reads a property, and `store` writes a variable that `main` reads. The table in Experiments lists every operation that has an obligation, what the root plan did at that point, and where a throw from it goes.

> **Try it.** [Show the table](lab:show?view=experiments), then [switch the Stage to L3](lab:level?l=L3) and [select the js.get in pair](lab:node?id=pair/entry/3): the Inspector shows `mayCollect, nonlocalThrow`, and the L3 line says it is a safepoint that roots `o6`.

## Three obligations

The standard operations use three of them.

**mayCollect**: the helper behind the operation may allocate, so a moving garbage collector may run inside it and relocate every object. After it returns, any reference the compiled code still holds in a register points at the old address. Lowering must therefore keep each managed value the code needs afterwards, and each managed operand the helper reads, in a root slot that the collector updates. `obj.new`, `arr.new`, `js.closure`, `js.get`, `js.call` and `host.print` all carry it.

**nonlocalThrow**: the operation may throw in a way that does not return normally to the next instruction. Hermes's helpers throw with `longjmp`, so lowering must provide a place for control to land: a handler in this function, or an unwinding path to the caller. Every operation that may run user code carries it; so does `cell.load_checked`, which throws a ReferenceError in the temporal dead zone.

**writeBarrier**: the operation stores a reference into memory the collector may already have scanned. A generational or incremental collector needs to be told, so lowering must emit a barrier call. `cell.store`, `js.define` and `js.put` carry it.

## The plan answers mayCollect

[Open the Plan view](lab:show?view=plan) for `pair`. Its frame is 3 root slots plus 2 fixed slots plus 1 argument slot, 6 slots or 48 B. At `obj.new` the plan roots `a` and `b`: neither is an operand, but both are used afterwards by the two `js.define` operations, so they are live across the allocation. At `js.get(o6, "a")` it roots only `o6`, which the helper borrows and the array still needs. At `arr.new(a10, o6)` it roots both operands. In L3 every such line reads `; safepoint · rooted s2=o6` and so on.

> **Try it.** [Run in plan mode with GC stress](lab:run?mode=plan&gc=stress). The collector now runs at every safepoint, and the output is still `1 2 true`, because the plan rooted what each point needed.

## nonlocalThrow and the throws clause

Every block in this program is `throws unwind`: no `try` encloses anything, so a throw leaves the function and the caller's handler (or the top level) receives it. The last column of the table says so for each throwing operation. In a function with `try`, the same column names the handler block instead; [I-09](lab:preset?id=I-09) and [L-08](lab:preset?id=L-08) show what lowering does with that.

## writeBarrier is not a safepoint

[Select the cell.store in store](lab:node?id=store/entry/0). It carries `writeBarrier` but not `mayCollect`: a barrier records the store, it does not allocate. The table says "not a safepoint", and the plan roots nothing there. The two obligations are independent, which is why they are separate flags rather than one "dangerous" bit.

## Obligations are not behaviour

An obligation never appears in a permission. Whether an operation may be erased or moved depends on its behaviour only ([C-03](lab:preset?id=C-03)); whether it needs roots depends on its obligations only. `cell.store` has a behaviour (`reads+writes(cells)`) that forbids erasing it and an obligation (`writeBarrier`) that costs a call, and those are two different facts about it.

> **Exercise.** Add a getter to the object in `pair`: `const p = { a, b, get both() { return this.a + this.b; } };` and read `p.both` in `main`. Which new operations appear in the table, and which values does the plan root at the new `js.get`?

## Where next

[Chapter 6](lab:book?ch=6) introduces obligations with behaviours; [Chapter 13](lab:book?ch=13) builds the root plan that answers `mayCollect`. The doc [Behaviours, obligations, permissions](lab:doc?id=effects) puts the three side by side. [A-08](lab:preset?id=A-08) shows how live-across sets decide what each safepoint roots.
