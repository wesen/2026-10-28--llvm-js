// A-05: intervals and widening. An interval [lo, hi] bounds a number. The interval lattice
// has infinite height ([0, 0] ⊑ [0, 1] ⊑ [0, 2] ⊑ …), so a loop can make an analysis climb
// forever. Three versions: plain, with refinement on the branch, and with widening.
const iv = g.lattice.interval();
const ALL = [-Infinity, Infinity];
// A name with no fact yet is ⊥ (null): the analysis has not reached its definition.
const range = (s, a) => (typeof a === 'string' ? (s.has(a) ? s.get(a) : null) : [a.lit, a.lit]);

function intervals({ refine, widen }) {
  let a = g.analysis('intervals').forward().lattice(g.lattice.map(iv))
    .transfer((op, s) => {
      if (!op.result) return s;
      const out = new Map(s), [x, y] = op.args.map(v => range(s, v));
      out.set(op.result, !x || (op.args.length > 1 && !y) ? null : op.op === 'num.add' ? [x[0] + y[0], x[1] + y[1]] : ALL);
      return out;
    })
    .edge((fn, from, e, s) => {
      const out = new Map(s), target = fn.block(e.block);
      let args = e.args.map(v => range(s, v));
      // On the edges of `branch c` where c = num.lt(x, K), x < K on true and x ≥ K on false.
      const test = from.ops.find(o => o.result === (from.term && from.term.cond));
      if (refine && test && test.op === 'num.lt' && test.args[1].lit !== undefined) {
        const K = test.args[1].lit;
        args = e.args.map((v, i) => (v === test.args[0] && args[i] ? (e.kind === 'true' ? [args[i][0], Math.min(args[i][1], K)] : [Math.max(args[i][0], K), args[i][1]]) : args[i]));
      }
      target.params.forEach((p, i) => out.set(p.id, args[i]));
      return out;
    });
  if (widen) {
    const w = g.widen.thresholds([0, 100, 1000]);
    a = a.widen((prev, next) => new Map([...next].map(([k, v]) => [k, w(prev && prev.get(k), v)])));
  }
  return a;
}

const fn = g.ir.parse(files['program.ir']);
const rows = [];
for (const [name, opts] of [['plain', {}], ['refined', { refine: true }], ['refined + widened', { refine: true, widen: true }]]) {
  try {
    const f = g.solve(intervals(opts), fn);
    rows.push({ version: name, converged: true, 'block visits': f.iterations, 'i at loop': f.out.loop.i, 'r at exit': f.out.exit.r });
  } catch (e) {
    rows.push({ version: name, converged: false, 'block visits': '100,000 (gave up)', 'i at loop': '', 'r at exit': e.message });
  }
}
const program = g.compile(g.pipeline(), source('program.ir'));
return { program, results: g.table(rows, { title: 'The loop counter as an interval' }) };
