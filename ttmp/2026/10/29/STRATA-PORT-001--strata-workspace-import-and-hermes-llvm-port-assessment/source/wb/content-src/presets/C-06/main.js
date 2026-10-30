// C-06: variants and narrowing. js.add has variants: num.add when both operands are numbers,
// str.concat when both are strings. The standard rewrites pick one wherever the type facts
// prove its condition. g.law.variant checks that a variant agrees with the general operation.
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source());

const { t } = g;
const pairs = [[t.number, t.number], [t.int32, t.double], [t.string, t.string], [t.number, t.string], [t.any, t.number], [t.boolean, t.number]];
const rows = pairs.flatMap(([a, b]) => ['js.add', 'js.lt', 'js.strict_eq'].map(op => ({
  op, operands: `${a}, ${b}`, variant: g.op.narrow(op, [a, b]) || '(none: stays general)',
})));

return {
  program,
  results: g.table(rows, { title: 'g.op.narrow: which variant each pair of operand types selects' }),
  laws: g.laws([
    g.law.variant('num.add', 'js.add'),          // agrees on numbers, -0 and NaN included
    g.law.variant('num.lt', 'js.lt'),
    g.law.variant('i32.add', 'num.add'),         // not a variant: int32 addition wraps
  ]),
};
