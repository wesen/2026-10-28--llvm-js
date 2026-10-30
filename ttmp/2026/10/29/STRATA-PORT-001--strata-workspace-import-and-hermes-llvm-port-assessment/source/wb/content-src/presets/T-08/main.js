// T-08: idempotent canonical form. A rewrite set run to its fixed point should give a form that
// running it again does not change (idempotence), and ideally the same form whatever the order
// of its rules. g.law.idempotent checks the first; comparing hashes checks the second here.
const R = g.rewrites;
const orders = {
  canonical: R.canonical(),
  reversed: R(R.eraseDead, 'remove-unreachable', 'simplify-branch', R.constFold, R.copyProp),
  'fold last': R(R.copyProp, 'simplify-branch', 'remove-unreachable', R.eraseDead, R.constFold),
};
const rows = Object.entries(orders).map(([name, set]) => {
  const p = g.compile(g.pipeline().rewrites(set), source());
  return { set: name, rules: set.names.join(', '), 'size after': p.module.fn('size').hash().slice(0, 8),
    ops: p.metrics().ops, fired: p.metrics().rewritesFired, output: p.run().output.join(' / ') };
});

// Two rules that undo each other: x * 2 → x + x and x + x → x * 2. No fixed point exists.
const toAdd = g.rewrite('double-as-add').match((m, s) => s.op.op === 'num.mul' && s.op.args[1] && s.op.args[1].lit === 2)
  .to(s => g.act.replaceOp('num.add', [s.op.args[0], s.op.args[0]]));
const toMul = g.rewrite('add-as-double').match((m, s) => s.op.op === 'num.add' && s.op.args[0] === s.op.args[1])
  .to(s => g.act.replaceOp('num.mul', [s.op.args[0], g.lit(2)]));

// A fixed point means rewriting the result fires nothing. Compile, print L1, compile that again.
function settles(name, set, src) {
  const once = g.compile(g.pipeline().rewrites(set), src);
  const again = g.compile(g.pipeline().rewrites(set), g.source.ir(once.ir('L1')));
  const fired = again.decisions.filter(d => d.fired && d.by !== 'promote-cells');
  return { name: `settles(${name})`, ok: fired.length === 0, samples: 1,
    counterexample: fired.length ? { 'fired on the second run': fired.length, first: `${fired[0].by} at ${fired[0].at}` } : undefined };
}

return {
  program: g.compile(g.pipeline(), source()),
  results: g.table(rows, { title: 'One program, three orders of the canonical rules' }),
  laws: g.laws([
    g.law.idempotent(R.canonical(), { samples: 60 }),
    g.law.idempotent(R.standard(), { corpus: [source()] }),
    g.law.idempotent(R(toAdd, toMul), { corpus: [source('double.ir')] }),
    settles('canonical', R.canonical(), source()),
    settles('double-as-add, add-as-double', R(toAdd, toMul), source('double.ir')),
  ]),
};
