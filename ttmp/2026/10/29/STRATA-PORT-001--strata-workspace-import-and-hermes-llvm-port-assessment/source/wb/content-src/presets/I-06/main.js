// I-06: every variable a cell. The frontend gives each variable (and each parameter) a cell;
// promote-cells later turns the ones no other function can see into SSA values.
const program = g.compile(g.pipeline(), source('program.js'));
const before = g.compile(g.pipeline().frontend({ promote: false }), source('program.js'));

const cellsOf = p => Object.fromEntries(p.functions().map(f => [f, p.find(op => op.op === 'cell.new').filter(s => s.fn === f).map(s => s.result)]));
const b = cellsOf(before), a = cellsOf(program);
const rows = program.functions().map(f => ({ fn: f, before: b[f].length, after: a[f].length, kept: a[f].join(', ') }));

print(`cells made by the frontend: ${rows.reduce((n, r) => n + r.before, 0)}; left after promotion: ${rows.reduce((n, r) => n + r.after, 0)}`);
return { program, results: g.table(rows, { title: 'Cells before and after promotion' }) };
