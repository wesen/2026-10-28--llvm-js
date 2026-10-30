// L-03: three root strategies on the ledger. Each one is checked by the same plan checker,
// then run in plan mode with a collection at every safepoint and compared with the spec.
const spec = g.compile(g.pipeline(), source()).run();
const rows = [];
for (const name of ['distinct', 'stackReuse', 'arena']) {
  const p = g.compile(g.pipeline().roots(name), source());
  const run = p.run({ mode: 'plan', gc: 'stress' });
  const plans = p.functions().map(f => p.plan(f));
  rows.push({
    strategy: name,
    rootSlots: p.metrics().rootSlots,
    deposit: p.plan('deposit').rootSlots,
    total: p.plan('total').rootSlots,
    frameBytes: plans.reduce((n, pl) => n + pl.frameBytes, 0),
    collections: run.metrics.collections,
    sameAsSpec: g.observe.equal(spec, run).equal,
  });
}
// The Stage and the Plan view show this one; change the name to compare.
const program = g.compile(g.pipeline().roots('distinct'), source());
return { program, results: g.table(rows, { title: 'Root strategies on the ledger (plan mode, GC stress)' }) };
