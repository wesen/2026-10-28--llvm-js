// A-02: liveness, one step at a time. Liveness is a backward analysis over the powerset
// lattice: a value is live at a point if some path from there uses it before redefining it.
// The solver visits blocks from a worklist until nothing changes; program.steps records
// every visit, and the Facts view and the Stage replay them (lab:analysis?name=liveness&i=…).
const program = g.compile(g.pipeline(), source());
const steps = program.steps('total', 'liveness');
const rows = steps.map(s => ({
  step: s.i, block: s.block,
  'live out': (s.after.out || []).join(', ') || '∅', 'live in': (s.after.in || []).join(', ') || '∅',
  changed: s.changed,
}));
print(`${steps.length} block visits to the fixed point`);
return { program, results: g.table(rows, { title: 'Liveness in total, visit by visit' }) };
