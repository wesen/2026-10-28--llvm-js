---
id: gc-roots
title: Moving collectors and root slots
group: Lowering
about: Why a moving collector needs to find every live reference, what a root slot is, what a plan must root at a safepoint, and how the workbench checks it.
order: 12
---
# Moving collectors and root slots

A JavaScript engine allocates constantly and frees nothing explicitly; a garbage collector finds the objects nothing can reach and reclaims them. A **moving** collector also relocates the objects that survive, which makes allocation fast and keeps the heap compact, and creates the problem this doc is about: every place that holds a reference to a moved object must be updated, including the compiled code's own registers. The workbench's answer is the root plan of level L3, built by a root strategy and judged by a plan checker. [L-03](lab:preset?id=L-03) to [L-07](lab:preset?id=L-07) show it at work, and [Chapter 13](lab:book?ch=13) develops it in full.

## Why collectors move objects

A collector that never moves objects must keep track of the holes it leaves and fit new objects into them. A copying collector instead evacuates the survivors of a region into fresh space, one after another, and then treats the whole old region as free. Allocation becomes a pointer bump, and the cost of a collection is proportional to what survives rather than to what was allocated. Most production JavaScript engines move at least their young objects for this reason: most objects die young, so evacuating the few survivors of a nursery is cheap. Hermes's collector does this too.

The price is that a reference is only a stable name for an object between collections. After a collection, the object at the old address is gone, and any word that still holds the old address is **stale**.

## Roots

The collector starts from the **roots**: the references it can find without looking inside objects. In an engine they are the global object, the job and timer queues, handles held by the runtime, and the slots of every active frame of compiled code. Everything reachable from the roots survives and is moved; every root is updated to the new address.

The compiled code's registers are not roots. A machine register holding a reference across a call into the runtime is invisible to the collector, so if that call collects, the register keeps the old address. The compiler's job is therefore to make sure that, at every point where a collection can happen, each reference the code still needs is in a place the collector updates. That place is a **root slot**: a 64-bit word in the function's frame, linked into the runtime's chain of frames.

## Safepoints, live-across and borrowed values

A collection happens only inside operations that may allocate or call user code: those whose contract carries the obligation `mayCollect`. Each such operation is a **safepoint**. At a safepoint, a value must be in a root slot when it may be a heap reference (its type includes objects, functions, strings, cells or completions) and either

- it is **live across** the safepoint: a later operation reads it, or
- it is **borrowed by** the safepoint: the runtime helper reads it as an operand, possibly after it has already collected.

The second condition is easy to miss. In `deposit`, `length13 = js.get(log12, "length")` borrows `log12`: if the getter lookup allocated before reading its receiver, an unrooted `log12` would be stale inside the helper itself. Liveness alone would not require `log12` there, because nothing reads it afterwards.

## The plan and its checker

A **root plan** assigns each value that ever needs a root a slot number. The checker then visits every safepoint and verifies two things: every required value has a slot, and no two values required at the same safepoint share one. It does not care how the plan was made. That separation is what lets the workbench try strategies freely: `distinct` (a slot per managed value, as the Hermes LLVM backend does), `stackReuse` (values never required together share a slot), `arena` (slots in runtime-owned memory) or a lambda of your own ([L-06](lab:preset?id=L-06)).

For the ledger's `deposit`, `stackReuse` needs four slots for seven values:

```text
; plan for deposit: stackReuse, native stack
; frame: 4 root slots + 2 fixed + 1 argument = 7 slots, 56 B
;   s0: amount
;   s1: balance7, log11
;   s2: c_balance
;   s3: c_log, log12, length13
```

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 210">
  <text x="20" y="22" font-size="11" class="lbl">frame of deposit (stackReuse), one 64-bit word per slot</text>
  <rect x="20" y="40" width="80" height="44" fill="none" stroke="currentColor" class="ink"/>
  <rect x="100" y="40" width="80" height="44" fill="none" stroke="currentColor" class="ink"/>
  <rect x="180" y="40" width="80" height="44" fill="none" stroke="currentColor" class="ink"/>
  <rect x="260" y="40" width="80" height="44" fill="none" stroke="currentColor" class="ink"/>
  <rect x="340" y="40" width="80" height="44" class="f-fill2" stroke="currentColor"/>
  <rect x="420" y="40" width="80" height="44" class="f-fill2" stroke="currentColor"/>
  <rect x="520" y="40" width="80" height="44" class="f-fill" stroke="currentColor" stroke-dasharray="4 3"/>
  <text x="60" y="58" font-size="11" text-anchor="middle" class="b">s0</text>
  <text x="140" y="58" font-size="11" text-anchor="middle" class="b">s1</text>
  <text x="220" y="58" font-size="11" text-anchor="middle" class="b">s2</text>
  <text x="300" y="58" font-size="11" text-anchor="middle" class="b">s3</text>
  <text x="380" y="58" font-size="11" text-anchor="middle" class="b">scratch</text>
  <text x="460" y="58" font-size="11" text-anchor="middle" class="b">discard</text>
  <text x="560" y="58" font-size="11" text-anchor="middle" class="b">argv[0]</text>
  <text x="60" y="76" font-size="10" text-anchor="middle" class="it">amount</text>
  <text x="140" y="76" font-size="10" text-anchor="middle" class="it">balance7</text>
  <text x="220" y="76" font-size="10" text-anchor="middle" class="it">c_balance</text>
  <text x="300" y="76" font-size="10" text-anchor="middle" class="it">c_log</text>
  <text x="380" y="76" font-size="10" text-anchor="middle" class="mut">literals</text>
  <text x="460" y="76" font-size="10" text-anchor="middle" class="mut">unused results</text>
  <text x="560" y="76" font-size="10" text-anchor="middle" class="mut">outgoing</text>
  <text x="140" y="104" font-size="10" text-anchor="middle" class="it">then log11</text>
  <text x="300" y="104" font-size="10" text-anchor="middle" class="it">then log12</text>
  <text x="300" y="118" font-size="10" text-anchor="middle" class="it">then length13</text>
  <line x1="20" y1="140" x2="340" y2="140" stroke="currentColor" class="ink"/>
  <line x1="20" y1="134" x2="20" y2="146" stroke="currentColor" class="ink"/>
  <line x1="340" y1="134" x2="340" y2="146" stroke="currentColor" class="ink"/>
  <text x="180" y="158" font-size="10" text-anchor="middle" class="lbl">root slots: scanned and updated by the collector</text>
  <line x1="340" y1="176" x2="600" y2="176" stroke="currentColor" class="mut"/>
  <line x1="340" y1="170" x2="340" y2="182" stroke="currentColor" class="mut"/>
  <line x1="600" y1="170" x2="600" y2="182" stroke="currentColor" class="mut"/>
  <text x="470" y="196" font-size="10" text-anchor="middle" class="lbl">fixed slots and outgoing arguments</text>
</svg>
```

**Figure 12.1.** The seven slots of `deposit`'s frame under `stackReuse`, 56 B. Slots 1 and 3 hold different values at different safepoints; the checker verified that no safepoint needs two of them at once. (A schematic: the outgoing area is drawn apart because the LLVM printer allocates it separately.)

## Testing a plan by moving everything

A plan that passes the checker should never let a stale reference be read, and the workbench tests that claim by execution. In plan mode the lowered program runs against its plan with a **simulated moving collector**. At every safepoint (with GC stress) or every 16 allocations (with GC alloc), it copies every object reachable from the rooted slots, the globals, the queues and the runtime's own handles to new addresses, updates those places, and frees the rest. A register the plan did not root keeps its old address, and the next read of it stops the run with a message such as:

```text
stale reference: b (object #10) was not rooted, so the collection at pair/entry/0 moved it; it was then used at pair/entry/2
```

Runtime helpers are treated as a real runtime treats them: they hold their operands through handles, so an object moved during a helper's own execution is found at its new address. Only the compiled code's registers can go stale. [L-05](lab:preset?id=L-05) shows one missing root under all three collector settings: it passes with no collections, fails at step 157 with occasional ones and at step 10 under stress. That spread is the reason the workbench's laws and searches always run plan mode with stress.

## The frame limit

A native frame holds the root slots, two fixed slots (scratch and discard) and the outgoing arguments, and the Hermes LLVM backend refuses a function whose frame would exceed 1,024 slots. The plan checker applies the same limit as an admission error. A function whose managed values are all needed at once cannot be packed below one slot per value: [L-07](lab:preset?id=L-07)'s `wide(n)` needs $n + 3$ slots. The `arena` strategy moves the slots off the native stack and replaces the frame limit by an arena budget, at the cost of an arena mark that every catch must restore ([Unwinding](lab:doc?id=unwinding)).

## What this model leaves out

The simulated collector copies the whole heap every time; real collectors are generational and incremental, scan only part of the heap, and need **write barriers** (the obligation `writeBarrier`) to track references from old objects to young ones. The model has no interior pointers (references into the middle of an object), no pinned objects, and no derived values such as a pointer plus an offset, all of which a real backend must root or rematerialise. And it assumes collections happen only at safepoints, which is true for Hermes's helper calls but not for every runtime: a collector that interrupts compiled code at arbitrary instructions needs stack maps for every instruction instead of root slots at calls.
