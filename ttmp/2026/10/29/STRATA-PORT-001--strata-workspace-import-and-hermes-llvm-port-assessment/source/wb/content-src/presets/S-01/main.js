// S-01: the reference interpreter, step by step. The program is compiled with every default
// and run by the specification (mode 'spec'); the Machine view replays its step records.
const program = g.compile(g.pipeline(), source('program.js'));
const run = program.run({ mode: 'spec' });

// Each record is one finished step: { n, fn, block, op, text, value, depth }.
const deepest = run.records.reduce((d, r) => Math.max(d, r.depth), 0);
print(`${run.steps} steps, ${run.metrics.calls} calls, deepest frame ${deepest}, output ${run.output.join(' ')}`);
print('the first step at the deepest frame:', run.records.find(r => r.depth === deepest).text);

return { program, run };
