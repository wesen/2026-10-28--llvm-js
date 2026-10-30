// I-09: exceptions as edges. program.ir says where every throw goes, in two ways: invoke (one
// operation with a normal and a throw edge) and a block's exceptional exit (throws to H(args)).
const program = g.compile(g.pipeline(), source('program.ir'));

const run = program.run();
for (const e of run.events.filter(e => e.type === 'throw' || e.type === 'catch')) print(`step ${e.n}: ${e.type} at ${e.at}${e.handler ? ' → ' + e.handler : ''} (${e.value})`);
return { program, run };
