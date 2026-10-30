# Quantities and layouts

Every size, count and time the compiler reasons about is a **quantity** with a unit: `slots(3)`, `bytes(24)`, `kib(8)`, `jobs(10000)`, `ms(25)`. Quantities of one unit add, subtract and scale; quantities of different units never mix silently. This preset computes a handful of them, checks the ledger's largest frame against the native frame limit, and runs the law that says units form a vector space.

> **Try it.** [Show the table](lab:show?view=experiments): two rows are errors on purpose. Then [show the Laws](lab:show?view=laws): `vectorSpace(slots)` and `vectorSpace(bytes)` each pass 1,000 samples.

## One unit at a time

A quantity is a number and a unit, frozen. `add` and `sub` require the same unit; `mul` and `div` take a plain number:

```js
kib(16).mul(2)            // 32 KiB
mib(1).sub(kib(32))       // 992 KiB
slots(3).add(slots(4))    // 7 slots
```

Bytes print in the largest binary unit that divides them exactly, so `mib(1).sub(kib(32))` is `992 KiB` and not 1,015,808 B.

## Mixing is an error

```js
slots(3).add(bytes(8))    // DimensionError: cannot add B and slots; convert through a layout
slots(3).mul(slots(2))    // DimensionError: cannot multiply slots by slots
```

The second rule matters as much as the first: a slot count times a slot count is not a slot count. A **DimensionError** is raised where the mistake is made, not three functions later when a frame turns out to be eight times too large.

## Slots become bytes through a layout

How many bytes a slot takes depends on the target, so the conversion is a value of its own. `g.layout.host64` is the 64-bit host: a slot is one 8-byte word.

```js
g.layout.host64.bytes(slots(3))    // 24 B
g.layout.host64.slots(bytes(20))   // 3 slots (rounded up)
```

The plans in the workbench count slots; [the Plan view](lab:show?view=plan) converts them to bytes through this layout, which is why [deposit's frame](lab:fn?name=deposit) reads `7 slots, 56 B`.

## A limit is a check with a unit

The Hermes LLVM backend refuses a function whose frame would need more than 1,024 slots: its root slots, plus 2 fixed slots, plus the largest outgoing argument count. `g.limit` states that rule as a value:

```js
const frame = g.limit('native frame', { measure: p => slots(p.metrics().maxFrameSlots), max: slots(1024) });
frame.check(program)    // { ok: true, measured: '8 slots', max: '1024 slots', asBytes: { measured: '64 B', max: '8 KiB' } }
```

The ledger's largest frame (`makeLedger`) is 8 slots. The case that made the limit matter is fflate's factory function at `-O0`, measured in the LLVM-ENGINE-002 handoff: 1,082 root slots, 2 fixed and 3 arguments, 1,087 slots or 8,696 B, over the 8 KiB the limit allows. Written with units, that arithmetic can be read and checked line by line; [L-07](lab:preset?id=L-07) builds a function that crosses the limit in the workbench.

> **Try it.** [Open main.js at the limit](lab:open?file=main.js&find=g.limit) and change `max: slots(1024)` to `max: slots(6)`. Rerun: the ledger's 8-slot frame no longer fits, and the table says `ok false`.

## Units are a vector space

The laws check that, within one unit, addition is associative and commutative and that scaling distributes over addition, on 1,000 random samples each. These are the properties that let a planner add up frame sizes in any order and scale a per-call cost by a call count. A law that failed would come back with the three quantities and the scale that broke it.

> **Exercise.** Add a row that computes the bytes of the ledger's whole root plan: `g.layout.host64.bytes(slots(program.metrics().rootSlots))`. Then try to compare it with `kib(1)` without the layout, and read the error.

## Where next

[Chapter 12](lab:book?ch=12) uses quantities for frames and representations. [L-07](lab:preset?id=L-07) is the frame limit in action, and [B-01](lab:preset?id=B-01) is the ledger these numbers come from.
