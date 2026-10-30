// 01 · Quantities with units
//
// Model: every size, count and time in the compiler is a quantity with a
// unit: bytes, slots, jobs, ms, count. Quantities of one unit add and scale
// like vectors, and units never mix silently. Slots become bytes only through
// a target layout, so a root budget in bytes can't be confused with an
// argument count, and a job budget can't be confused with a deadline.
//
// Notice: the DimensionError, the layout as a value, and today's fflate
// admission limit restated with units, which makes its arithmetic auditable.

import { g, bytes, kib, mib, slots, jobs, ms } from 'strata'

// Constructors and arithmetic within one unit.
const chunk = kib(16)
const twoChunks = chunk.mul(2)                 // → 32 KiB
const budget = mib(1).sub(twoChunks)           // → 992 KiB
budget.lt(mib(1))                              // → true

// Mixing units is an error, never a coercion.
try {
  slots(3).add(bytes(8))
} catch (e) {
  e.name                                       // → 'DimensionError'
  e.message                                    // → 'cannot add bytes to slots; convert through a layout'
}

// A layout is a value that knows the target's sizes.
const host = g.layout.host64                   // 8-byte tagged values, 16-byte stack alignment
host.bytes(slots(1024))                        // → 8 KiB
host.slots(kib(8))                             // → 1024 slots

// Today's admission limit, stated as a value with its reason.
// The emitter reports roots including two fixed slots, then adds argument slots.
const frameLimit = g.limit('native-frame-slots', {
  measure: f => f.rootSlots.add(f.argumentSlots),
  max: slots(1024),
  why: 'keeps the native frame under 8 KiB, below the stack-check safety gap',
})

frameLimit.check({ rootSlots: slots(1084), argumentSlots: slots(3) })
// → { ok: false, measured: 1087 slots, max: 1024 slots,
//     asBytes: { measured: '8696 B', max: '8192 B' } on host64 }

// A limit belongs to a strategy, not to the language. Example 12 shows the same
// function admitted under a strategy whose budget is stated in bytes instead.
frameLimit.ownedBy                             // → 'roots: distinct (native stack)'

// Jobs and time are different units: a job budget is not a deadline.
const pump = { budget: jobs(100), deadline: ms(5) }
// jobs(100).lt(ms(5))                         // → DimensionError

// Quantities print with their units and serialize exactly.
String(host.bytes(slots(1087)))                // → '8696 B'
JSON.stringify({ chunk, pump })                // → '{"chunk":"16 KiB","pump":{"budget":"100 jobs","deadline":"5 ms"}}'

// Law: each unit is a vector space, checked on generated samples.
g.law.vectorSpace(bytes)                       // → { ok: true, samples: 1000 }
g.law.vectorSpace(slots)                       // → { ok: true, samples: 1000 }
