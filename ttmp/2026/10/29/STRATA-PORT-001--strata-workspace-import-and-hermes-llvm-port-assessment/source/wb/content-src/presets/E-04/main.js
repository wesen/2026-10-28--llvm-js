// E-04: an engine and its lifecycle. g.engine() owns one execution domain: a heap, the
// job queues and the code it has admitted. Admission checks a compiled program before
// any of it runs; evaluation runs its main; runJobs drains the queues; close tears down
// the runtime first and then releases the code.
const program = g.compile(g.pipeline(), source());
const engine = g.engine();
const rows = [];
const step = (call, f) => {
  let result;
  try { result = f(); } catch (e) { result = `${e.name}: ${e.message}`; }
  rows.push({ step: rows.length + 1, call, result: typeof result === 'string' ? result : JSON.stringify(result) });
};

step('admit(program)', () => { const c = engine.admit(program); return `code #${c.id} ${c.name}`; });
step('snapshot()', () => engine.snapshot());
step('evaluateScript(code 1)', () => engine.evaluateScript(1));
step('output()', () => engine.output());
step('runJobs()', () => engine.runJobs());
step('output()', () => engine.output());
step('metrics()', () => engine.metrics());
step('close()', () => engine.close());
step('admit(program) again', () => engine.admit(program));

return { program, results: g.table(rows, { title: 'One engine, from admission to close' }) };
