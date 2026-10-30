// L-02: representations. The type facts say which values are numbers or booleans; the
// representation strategy says how those values are stored after lowering.
//   tagged           every value is one 64-bit word with a tag (the NaN-boxed word)
//   unboxWhenProven  values proven number become f64, proven boolean become bool
// hyp and isBig get number parameters by assumption, so their arithmetic is proven.
const base = g.pipeline()
  .assume({ hyp: { a: 'number', b: 'number' }, isBig: { x: 'number' } })
  .rewrites(g.rewrites.standard());

const program = g.compile(base.representation('unboxWhenProven'), source('program.js'));
const tagged = g.compile(base.representation('tagged'), source('program.js'));

// Count the representation of every value, per function, under both strategies.
const rows = [];
for (const fn of program.functions()) {
  const count = (p, rep) => Object.values(p.plan(fn).reps).filter(r => r === rep).length;
  rows.push({ fn, tagged: count(tagged, 'tagged'), unboxedF64: count(program, 'f64'), unboxedBool: count(program, 'bool'),
    stillTagged: count(program, 'tagged'), rootSlots: program.plan(fn).rootSlots });
}

// The 64-bit words the LLVM printer writes for immediate values.
const words = g.compile(g.pipeline(), 'print(10); print(0.5); print(-0); print(true); print(false); print(null); print(undefined);');
print(words.ir('LLVM').split('\n').filter(l => /store i64 0x/.test(l)).join('\n'));

return { program, results: g.table(rows, { title: 'Representations under unboxWhenProven' }) };
