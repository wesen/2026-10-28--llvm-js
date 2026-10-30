// A-04: your own analysis, constant propagation. A forward analysis over a map from value
// names to the flat lattice (⊥, a constant, ⊤ = "not a constant"), with an edge rule that
// passes facts to block parameters. Then a rewrite of our own uses the facts.
const flat = g.lattice.flat();
const ARITH = { 'num.add': (x, y) => x + y, 'num.sub': (x, y) => x - y, 'num.mul': (x, y) => x * y, 'num.lt': (x, y) => x < y };
const valueOf = (state, a) => (typeof a === 'string' ? (state.has(a) ? state.get(a) : flat.BOT) : a.lit);   // not reached yet: ⊥

const constants = g.analysis('constants').forward().lattice(g.lattice.map(flat))
  .init(fn => new Map(fn.params.map(p => [p.id, flat.TOP])))          // parameters: unknown
  .transfer((op, state) => {
    if (!op.result) return state;
    const out = new Map(state), args = op.args.map(a => valueOf(state, a));
    if (args.includes(flat.BOT)) out.set(op.result, flat.BOT);
    else if (ARITH[op.op] && args.every(x => typeof x === 'number')) out.set(op.result, ARITH[op.op](...args));
    else out.set(op.result, flat.TOP);
    return out;
  })
  .edge((fn, from, e, state) => {                                    // arguments become parameters
    const out = new Map(state);
    fn.block(e.block).params.forEach((p, i) => out.set(p.id, valueOf(state, e.args[i])));
    return out;
  });

const calc = g.ir.parse(files['program.ir']).fn('calc');
const facts = g.solve(constants, calc);
const known = new Map();
const rows = [];
for (const b of calc.blocks) for (const v of [...b.params.map(p => p.id), ...b.ops.filter(o => o.result).map(o => o.result)]) {
  const c = facts.out[b.name][v];
  rows.push({ block: b.name, value: v, constant: c === undefined ? '?' : String(c) });
  if (typeof c === 'number') known.set(v, c);
}
print(`constants solved in ${facts.iterations} block visits: ${[...known].map(([v, c]) => `${v} = ${c}`).join(', ')}`);

// A rewrite that replaces every operation whose result is a known constant by that constant.
const fold = g.rewrite('fold-by-constants')
  .match((m, s) => s.fn.name === 'calc' && s.op.result && known.has(s.op.result))
  .to(s => g.act.replaceWith(g.lit(known.get(s.op.result))));
const program = g.compile(g.pipeline().rewrites(g.rewrites(fold, g.rewrites.eraseDead)), source('program.ir'));
return { program, results: g.table(rows, { title: 'Constants in calc, from our own analysis' }) };
