// T-03: your own rewrite. A rewrite is match, side condition, action. mul-one removes x * 1
// when the type facts prove x is a number; mul-one-naive forgets the condition. g.law.refines
// checks both against the specification, on program.js and on generated programs.
const isMulByOne = (m, s) => (s.op.op === 'num.mul' || s.op.op === 'js.mul') && s.op.args[1] && s.op.args[1].lit === 1;

const mulOne = g.rewrite('mul-one')
  .match(isMulByOne)
  .when((s, ctx) => {
    const ty = ctx.typeAt(s, s.op.args[0]);
    return { ok: ty.le(t.number), because: `the operand is ${ty}${ty.le(t.number) ? '' : ', and x * 1 converts it'}` };
  })
  .to(s => g.act.replaceWith(s.op.args[0]));

const mulOneNaive = g.rewrite('mul-one-naive').match(isMulByOne).to(s => g.act.replaceWith(s.op.args[0]));

const program = g.compile(g.pipeline().rewrites(g.rewrites.canonical().with(mulOne)), source());
const naive = g.compile(g.pipeline().rewrites(g.rewrites.canonical().with(mulOneNaive)), source());
print('mul-one:       ' + program.run().output.join(' / '));
print('mul-one-naive: ' + naive.run().output.join(' / '));

return {
  program,
  laws: g.laws([
    g.law.refines(mulOne, { corpus: [source()], samples: 30 }),
    g.law.refines(mulOneNaive, { corpus: [source()], samples: 30 }),
  ]),
};
