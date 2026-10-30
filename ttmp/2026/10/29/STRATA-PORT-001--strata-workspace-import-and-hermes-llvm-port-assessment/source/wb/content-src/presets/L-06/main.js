// L-06: your own root strategy. A strategy is a function (fn, ctx) => plan or strategy.
// ctx.default() is the plan of the strategy being wrapped (stackReuse), ctx.run(name)
// runs a named one, ctx.sites lists the safepoints and ctx.required(site) what each needs.
// Whatever comes back goes through the same plan checker as the built-in strategies.

// 1. Choose per function: one slot per value (distinct, easy to debug) when that needs at
//    most four slots, the packed default otherwise.
const chooser = (fn, ctx) => {
  const plain = ctx.run('distinct');
  return plain.rootSlots <= 4 ? plain : ctx.default();
};
const program = g.compile(g.pipeline().roots(chooser), source());

// 2. A strategy that forgets one value: the checker refuses it.
const forgetful = (fn, ctx) => {
  const plan = ctx.default();
  if (fn.name === 'total') delete plan.slotOf.sum2_1;
  return plan;
};
const refused = g.compile(g.pipeline().roots(forgetful), source());
for (const d of refused.diagnostics.filter(d => d.severity === 'error')) print('forgetful: ' + d.message);

const rows = program.functions().map(fn => ({
  fn, chosen: program.plan(fn).strategy, rootSlots: program.plan(fn).rootSlots,
  stackReuse: g.compile(g.pipeline(), source()).plan(fn).rootSlots,
  distinct: g.compile(g.pipeline().roots('distinct'), source()).plan(fn).rootSlots,
}));
return { program, results: g.table(rows, { title: 'A strategy that chooses per function' }) };
