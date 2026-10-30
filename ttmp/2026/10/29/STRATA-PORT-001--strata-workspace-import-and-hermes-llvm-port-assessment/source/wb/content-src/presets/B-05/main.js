// B-05: quantities with units. Sizes, counts and times in the compiler carry a unit, units of one
// kind add and scale, and slots become bytes only through a layout.
const rows = [];
const show = (what, f) => {
  try { rows.push({ what, result: String(f()) }); }
  catch (e) { rows.push({ what, result: `${e.name}: ${e.message}` }); }
};

show('kib(16).mul(2)', () => kib(16).mul(2));
show('mib(1).sub(kib(32))', () => mib(1).sub(kib(32)));
show('slots(3).add(slots(4))', () => slots(3).add(slots(4)));
show('slots(3).add(bytes(8))', () => slots(3).add(bytes(8)));        // a DimensionError, never a coercion
show('slots(3).mul(slots(2))', () => slots(3).mul(slots(2)));
show('g.layout.host64.bytes(slots(3))', () => g.layout.host64.bytes(slots(3)));
show('g.layout.host64.slots(bytes(20))', () => g.layout.host64.slots(bytes(20)));
show('jobs(10000).lt(jobs(5))', () => jobs(10000).lt(jobs(5)));

// A limit is a check with a unit: the native frame of the Hermes LLVM backend holds 1,024 slots.
const program = g.compile(g.pipeline(), source('program.js'));
const frame = g.limit('native frame', { measure: p => slots(p.metrics().maxFrameSlots), max: slots(1024) });
const verdict = frame.check(program);
show('largest frame of the ledger', () => `${verdict.measured} (${verdict.asBytes.measured}) of ${verdict.max} (${verdict.asBytes.max}): ok ${verdict.ok}`);

// The case from the LLVM-ENGINE-002 handoff: fflate's factory at -O0 has 1,082 root slots,
// plus the 2 fixed slots, plus 3 argument slots.
const fflate = slots(1082).add(slots(2)).add(slots(3));
show('fflate factory frame', () => `${fflate} (${g.layout.host64.bytes(fflate)}): over the limit ${fflate.gt(slots(1024))}`);

// Units are a vector space: the law samples sums and scalings.
const laws = g.laws([g.law.vectorSpace(slots), g.law.vectorSpace(bytes)]);
return { program, results: g.table(rows, { title: 'Quantities' }), laws };
