// A-01: lattices and their laws. Every analysis in the engine runs over a lattice: a set of
// facts with an order ⊑ and a join ⊔ (least upper bound). g.law.lattice samples elements and
// checks the join laws. The last lattice is broken on purpose.
const L = g.lattice;
const sets = L.powerset({ universe: ['a', 'b', 'c', 'd'] });
const consts = L.flat([1, 2, 3]);
const ranges = L.interval();

// A few joins, shown in Events with each lattice's own printer.
print('types:    number ⊔ string =', String(t.number.join(t.string)), '·  int32 ⊑ number:', t.int32.le(t.number));
print('powerset: {a} ⊔ {b, c} =', sets.show(sets.join(new Set(['a']), new Set(['b', 'c']))));
print('flat:     1 ⊔ 1 =', consts.show(consts.join(1, 1)), '·  1 ⊔ 2 =', consts.show(consts.join(1, 2)), '·  ⊥ ⊔ 3 =', consts.show(consts.join(consts.bottom(), 3)));
print('interval: [0, 2] ⊔ [5, 9] =', ranges.show(ranges.join([0, 2], [5, 9])));

// Not a lattice: adding is commutative and associative but not idempotent (3 ⊔ 3 would be 6).
const broken = { name: 'sum', bottom: () => 0, join: (a, b) => a + b, le: (a, b) => a <= b, eq: (a, b) => a === b,
  show: String, sample: r => r.int(0, 5) };

return g.laws([
  g.law.lattice(t),
  g.law.lattice(sets),
  g.law.lattice(consts),
  g.law.lattice(ranges),
  g.law.lattice(broken),
]);
