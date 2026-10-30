// A-07: monotone or not. The fixed-point theorem needs transfer functions that are monotone:
// x ⊑ y implies f(x) ⊑ f(y). g.law.monotone checks that on generated IR. Below, a "liveness
// with a register budget" that forgets everything when more than two values are live breaks it.
const program = g.compile(g.pipeline(), source());
const uses = op => op.args.filter(a => typeof a === 'string');

const honest = g.analysis('live').backward().lattice(g.lattice.powerset())
  .transfer((op, live) => { const s = new Set(live); if (op.result) s.delete(op.result); uses(op).forEach(a => s.add(a)); return s; });
const budgeted = g.analysis('live-within-2').backward().lattice(g.lattice.powerset())
  .transfer((op, live) => {
    const s = new Set(live); if (op.result) s.delete(op.result); uses(op).forEach(a => s.add(a));
    return s.size > 2 ? new Set() : s;                  // "too many: forget them all"
  });

// Solve the broken one on total with a time budget: the solver falls back if it does not finish.
const fn = program.module.fn('total');
const tries = [['live (honest)', honest], ['live-within-2', budgeted]].map(([name, a]) => {
  const f = g.solve(a, fn, { budget: { n: 300 } });
  return { analysis: name, status: f.status || 'fixed point', visits: f.iterations, 'in at for1': f.in ? f.in.for1.join(', ') : f.result };
});

return {
  program,
  laws: g.laws([g.law.monotone(g.analysis.liveness), g.law.monotone(honest), g.law.monotone(budgeted)]),
  results: g.table(tries, { title: 'Solving total with each analysis' }),
};
