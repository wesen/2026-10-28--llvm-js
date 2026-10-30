// E-07: a plugin host. One engine admits several units: three plugins and the host's own
// dispatcher. Units share the engine's globals (hooks) and its heap, so a closure made
// by one unit can be called by another, long after the unit that made it has finished.
const engine = g.engine();
const rows = [];
for (const file of ['plugin-a.js', 'plugin-b.js', 'plugin-c.js', 'program.js']) {
  const before = engine.output().length;
  const program = g.compile(g.pipeline(), source(file));
  try {
    const code = engine.admit(program);
    const ev = engine.evaluateScript(code);
    rows.push({ unit: file, admitted: `code #${code.id}`, state: ev.state, printed: engine.output().slice(before).join(' | ') });
  } catch (e) {
    rows.push({ unit: file, admitted: 'refused', state: e.reason, printed: e.message });
  }
}
const jobs = engine.runJobs();
rows.push({ unit: '(jobs)', admitted: '', state: `ran ${jobs.ran}`, printed: engine.output().slice(-2).join(' | ') });
print('snapshot: ' + JSON.stringify(engine.snapshot()));
print(engine.close());

// The dispatcher on its own, for the Stage: run alone, it finds no hooks.
const program = g.compile(g.pipeline(), source('program.js'));
return { program, results: g.table(rows, { title: 'Four units in one engine' }) };
