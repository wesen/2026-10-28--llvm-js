// T-04: narrowing by facts. The standard rewrites add narrow-by-facts (and store-to-load
// forwarding) to the canonical set: wherever the type facts prove a variant's condition,
// a general js.* operation becomes its num.* or str.* variant. Measured on the ledger.
const canonical = g.compile(g.pipeline(), source());
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source());

const safepoints = (p, f) => Object.keys(p.plan(f).safepoints).length;
const rows = program.functions().map(f => ({
  function: f,
  'safepoints (canonical)': safepoints(canonical, f), 'safepoints (standard)': safepoints(program, f),
  'root slots (canonical)': canonical.plan(f).rootSlots, 'root slots (standard)': program.plan(f).rootSlots,
  narrowed: program.decisions.filter(d => d.by === 'narrow-by-facts' && d.fired && d.at.startsWith(f + '/')).map(d => d.because).join('; '),
}));
print('canonical: ' + canonical.run().output.join(' / '));
print('standard:  ' + program.run({ mode: 'plan', gc: 'stress' }).output.join(' / '));
return { program, results: g.table(rows, { title: 'The ledger with canonical and standard rewrites' }) };
