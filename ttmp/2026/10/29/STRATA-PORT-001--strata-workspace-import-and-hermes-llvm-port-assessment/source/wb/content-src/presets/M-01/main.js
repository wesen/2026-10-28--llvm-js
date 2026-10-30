// M-01: the engine's own laws, run as a test suite. Each law samples inputs, checks a
// property, and returns { name, ok, samples, counterexample? }. One of them fails on purpose:
// floating-point addition is commutative but not associative, and the sampler finds a case.
const laws = g.laws([
  g.law.lattice(t),                                         // the type lattice
  g.law.lattice(g.lattice.powerset({ universe: ['a', 'b', 'c', 'd'] })),
  g.law.lattice(g.lattice.interval()),
  g.law.join(),                                             // behaviours: a join-semilattice
  g.law.antitone(),                                         // more behaviour, never more permission
  g.law.monotone(g.analysis.liveness, { samples: 200 }),    // the liveness transfer function
  g.law.roundTrip({ samples: 50 }),                         // IR text and JSON parse back
  g.law.idempotent(g.rewrites.canonical(), { samples: 20 }),
  g.law.variant('num.add', 'js.add'),                       // a variant agrees with its general op
  g.law.algebra(g.ops['num.add'], 'commutative'),
  g.law.algebra(g.ops['num.add'], 'associative'),           // fails: (a + b) + c differs from a + (b + c)
  g.law.vectorSpace(slots),                                  // quantities add and scale
]);
const failing = laws.laws.filter(l => !l.ok).map(l => l.name);
print(`${laws.laws.length - failing.length} of ${laws.laws.length} laws hold; failing: ${failing.join(', ') || 'none'}`);
return laws;
