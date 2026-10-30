// E-01: microtasks and order. The script runs to completion; then the engine takes jobs
// from the microtask queue one at a time, in the order they were queued, until it is empty.
// A job can queue more jobs (they go to the back) and a job that throws does not stop the rest.
const program = g.compile(g.pipeline(), source());
const run = program.run();
for (const e of run.events.filter(e => e.type === 'job' || e.type === 'print' || e.type === 'throw'))
  print(`step ${e.n}: ${e.type} ${e.line || e.what || ''}${e.queue !== undefined ? ' (queue length ' + e.queue + ')' : ''}${e.value ? ' ' + e.value : ''}`);
return program;
