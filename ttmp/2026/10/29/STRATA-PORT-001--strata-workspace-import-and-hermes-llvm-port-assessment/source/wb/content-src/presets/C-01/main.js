// C-01: behaviours and their join.
// A behaviour is an upper bound on what an operation may do. The behaviour of a whole
// function is the join of its operations' behaviours. Change program.js and rerun to
// watch the summaries move.
const { fx } = g;
const program = g.compile(g.pipeline(), source());

const rows = program.functions().map(name => {
  const fn = program.module.fn(name);
  const defs = fn.blocks.flatMap(b => b.ops.map(o => g.ops[o.op]));
  const summary = fx.join(...defs.map(d => d.behaviour));     // fx.join() of nothing is fx.none
  return {
    fn: name, ops: defs.length, behaviour: String(summary),
    'below callsUser': summary.le(fx.callsUser),
    'erase an unused call': String(g.perm({ behaviour: summary }).erase),
  };
});
print('callsUser ⊑ unknown:', fx.callsUser.le(fx.unknown), ' unknown ⊑ callsUser:', fx.unknown.le(fx.callsUser));

return {
  program,
  results: g.table(rows, { title: 'The behaviour of each function, as a join' }),
  laws: g.laws([g.law.join()]),
};
