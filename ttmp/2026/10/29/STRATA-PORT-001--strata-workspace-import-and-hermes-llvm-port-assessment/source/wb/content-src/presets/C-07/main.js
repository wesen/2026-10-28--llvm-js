// C-07: more behaviour, fewer permissions. The engine's derivation is antitone: if a ⊑ b then
// every permission of b is at most the same permission of a. g.law.antitone() checks it. Below,
// a plausible rule of our own fails the same test, and the table asks which neighbours commute.
const program = g.compile(g.pipeline().assume({ step: { n: 'number' } }).rewrites(g.rewrites.standard()), source());
const { fx } = g;

// Our rule: "an unused result may be erased unless the operation throws; a write is harmless
// when the operation creates a fresh object". It looks reasonable for obj.new + js.define.
const myErase = b => !b.throws && !b.callsUser && b.host.size === 0 && (b.writes.size === 0 || b.fresh);
const atoms = [fx.none, fx.reads('heap'), fx.writes('heap'), fx.writes('cells'), fx.fresh, fx.throws, fx.host('print')];
let seed = 7, checked = 0, counterexample = null;
const next = () => (seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648;
const pick = () => fx.join(...atoms.filter(() => next() < 0.35));
for (let i = 0; i < 2000 && !counterexample; i++, checked++) {
  const a = pick(), b = a.join(pick());                        // a ⊑ b by construction
  if (myErase(b) && !myErase(a)) counterexample = { smaller: String(a), larger: String(b), rule: 'the larger behaviour may be erased, the smaller may not' };
}
const mine = { name: 'antitone(myErase)', ok: !counterexample, samples: checked, counterexample };

// Which neighbours in step could a scheduler swap?
const ops = program.cfg('step').blocks[0].ops;
const rows = ops.slice(1).map((op, i) => {
  const c = g.perm.commute(ops[i].op, op.op);
  return { first: ops[i].text, second: op.text, swap: c.allowed, because: c.because };
});
return { program, laws: g.laws([g.law.antitone(), mine]), results: g.table(rows, { title: 'Adjacent operations in step: may they commute?' }) };
