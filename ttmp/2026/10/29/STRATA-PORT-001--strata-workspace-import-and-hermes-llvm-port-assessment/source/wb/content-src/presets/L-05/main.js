// L-05: a stale reference, caught at run time. The root strategy below is the default
// with one value removed: pair's parameter b gets no slot. The checker would refuse the
// plan, so gcSafety is turned off (missing roots become warnings) and the plan runs.
const holed = g.pipeline().roots((fn, ctx) => {
  const plan = ctx.default();               // the stackReuse plan for this function
  if (fn.name === 'pair') delete plan.slotOf.b;
  return plan;
});
const program = g.compile(holed.checks({ gcSafety: false }), source());

// The same broken plan under the three collectors of plan mode.
const rows = ['off', 'alloc', 'stress'].map(gc => {
  const r = program.run({ mode: 'plan', gc });
  const stale = r.events.find(e => e.type === 'stale');
  return { gc, outcome: r.outcome.kind, output: r.output.join(' ') || '(nothing)', collections: r.metrics.collections,
    staleAtStep: stale ? stale.n : '', movedAt: stale ? stale.collectedAt : '', usedAt: stale ? stale.at : '' };
});
return { program, results: g.table(rows, { title: 'One missing root under three collectors' }) };
