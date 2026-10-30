// C-05: your own operation. An operation is a name, operand and result types, a behaviour,
// obligations and a reference step. Registering a set makes the parser, verifier,
// interpreter and rewrites know it. Names are global for the page, hence the c05 prefix.
const square = g.op('c05.square').operands(t.number).results(t.number)
  .behaviour(g.fx.none).step((m, [x]) => x * x)
  .lower({ helper: 'c05_square' }).about('x times x').build();

// The same step with a print in it, declared twice: once honestly, once with a lie.
const printing = (m, [x]) => { m.print(['squaring', x]); return x * x; };
const lying = g.op('c05.lying_square').operands(t.number).results(t.number)
  .behaviour(g.fx.none).step(printing).about('prints, but claims to do nothing').build();
const honest = g.op('c05.honest_square').operands(t.number).results(t.number)
  .behaviour(g.fx.host('print')).obligations(g.ob.mayCollect).step(printing).about('prints, and says so').build();
g.opset('c05').ops(square, lying, honest).register();

const program = g.compile(g.pipeline(), source('program.ir'));
const unoptimised = g.compile(g.pipeline().rewrites(g.rewrites.none()), source('program.ir'));
print('without rewrites:', unoptimised.run().output.join(' / '));
print('canonical:       ', program.run().output.join(' / '));

return {
  program,
  results: g.contract.table([square, lying, honest]),
  laws: g.laws([g.law.refines(g.rewrites.eraseDead, { corpus: [source('program.ir')] })]),
};
