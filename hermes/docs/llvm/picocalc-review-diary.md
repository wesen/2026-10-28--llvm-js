# PicoCalc integration and independent backend review

## 2026-10-28 13:35 UTC — Read-only source review

Read the in-progress direct LLVM emitter and C runtime bridge against the
upstream SH C emitter, lowering passes, IR instruction definitions, StaticH
runtime helpers, and native register-stack layout. This review did not modify
the emitter or bridge. Their authors were actively editing them, so each
finding refers to the code observed at review time rather than a frozen final
revision.

### Confirmed implementation relationships

- Phi-edge lowering loads every incoming value before any destination store;
  this implements simultaneous assignments for loop-carried swaps.
- Every runtime-value result and constants live in SHLocals root slots.
  The separate argv array is copied into the traced register stack before a
  runtime call; the copy loop itself allocates nothing.
- The array allocator creates both capacity and logical length. LiteralEmpty
  elements remain literal through the upstream LoadConstants pass, so skipping
  their definition preserves holes. Subsequent dynamic stores remain in IR
  order.
- Function-name indexes, expected argument counts excluding this, function
  kinds, and invocation prohibitions correspond to SH.cpp's metadata table.
- Returned tagged values are loaded before the nonallocating leave helper;
  this is safe only while that helper retains its no-allocation behavior.

### Findings sent to the implementer

1. BaseAllocObjectLiteralInst includes typed nonenumerable subclasses. Emitting
   every property enumerable=true for those subclasses is semantically wrong.
   Explicit rejection was observed being added during the review.
2. A 65,536-root admission permits more than 512 KiB in a native stack alloca,
   and argv could add more. Hermes's default/minimum native stack gap is 64 KiB.
   A before/after address check alone can jump across that gap. Suggested a
   conservative combined roots+argv admission or a size-aware stack check.
3. ThrowIfInst's bad-type mask may include Uninit. Upstream represents
   LiteralUninit as undefined and checks is_undefined for that arm; a helper
   checking only is_empty does not implement all masks. Suggested preserving
   the explicit mask or rejecting unimplemented checks.

The final validation owner must record fixes/tests for these issues; this
review log does not claim that review alone proved semantic equivalence.

### Integration document

Wrote PICOCALC_INTEGRATION.md explaining the executed scalar RV32 lane and the
separate dynamic native-host Hermes lane. It explicitly covers code/root/runtime
generation ownership, serialized state migration, the gap between canceled
external effects and heap rollback, native interruption, and the fact that
removing the bridge's host64 assertion is not an RV32 runtime port. No physical
ESP32-P4 execution or dynamic-heap device support is claimed.
