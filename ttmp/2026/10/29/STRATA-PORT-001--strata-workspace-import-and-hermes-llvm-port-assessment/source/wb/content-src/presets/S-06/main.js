// S-06: coercion runs user code. js.add, js.lt and js.mul convert objects to primitives by calling
// their valueOf or toString, so each of them may run any function the program defines.
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source('program.js'));

// The contracts of the operators this program uses, next to the number variant.
const contracts = g.contract.table(['js.add', 'js.lt', 'js.mul', 'num.add']);

// The standard rewrites try to narrow every operator; none of these can be narrowed.
for (const d of program.decisions.filter(d => d.by === 'narrow-by-facts')) print(d.at, d.op, d.fired ? 'narrowed' : 'kept:', d.because);
return { program, results: g.table(contracts, { title: 'Operator contracts' }) };
