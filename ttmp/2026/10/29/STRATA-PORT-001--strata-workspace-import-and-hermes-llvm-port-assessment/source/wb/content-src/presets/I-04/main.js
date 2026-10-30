// I-04: the verifier. broken.ir holds seven functions, each breaking one rule; g.verify returns
// its findings as data: a rule, a message and where, never an exception.
const broken = g.ir.parse(files['broken.ir']);
const rows = broken.names().map(name => {
  const v = g.verify(broken.fn(name));
  const d = v.diagnostics[0] || {};
  return { fn: name, ok: v.ok, severity: d.severity || '', rule: d.rule || '', message: d.message || '' };
});

// program.ir is the first function repaired; it verifies, compiles and runs.
const program = g.compile(g.pipeline(), source('program.ir'));
return { program, results: g.table(rows, { title: 'One broken rule per function' }) };
