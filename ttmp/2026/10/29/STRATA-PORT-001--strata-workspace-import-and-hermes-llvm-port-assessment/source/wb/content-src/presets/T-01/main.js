// T-01: folding and propagation. The canonical rewrites: constant folding (an operation on
// literals becomes its result), copy propagation (a copy's uses read the original), branch
// simplification (a branch on a literal becomes a jump) and unreachable-block removal, then
// erasing results nobody uses. Compare the program with no rewrites and with the canonical set.
const none = g.compile(g.pipeline().rewrites(g.rewrites.none()), source());
const program = g.compile(g.pipeline(), source());

const count = (p, by) => p.decisions.filter(d => d.by === by && d.fired).length;
const rows = [none, program].map((p, i) => ({
  rewrites: i ? 'canonical' : 'none', blocks: p.module.fn('main').blocks.length, ops: p.metrics().ops,
  'const-fold': count(p, 'const-fold'), 'simplify-branch': count(p, 'simplify-branch'),
  'remove-unreachable': count(p, 'remove-unreachable'), steps: p.run().steps, output: p.run().output.join(' / '),
}));
return { program, results: g.table(rows, { title: 'The same program, before and after the canonical rewrites' }) };
