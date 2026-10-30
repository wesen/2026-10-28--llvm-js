// X-07: measuring a corpus. Seven small programs (copies of J-01 to J-07), one row each.
// The question is the one a compiler team asks before investing in an optimisation:
// how much of real code is the optimiser allowed to touch?
const corpus = ['counter.js', 'thermometer.js', 'resource.js', 'tokenizer.js', 'events.js', 'recursion.js', 'errors.js'];

// Every operation's behaviour class, read from its contract (g.ops[name].behaviour).
const classOf = name => {
  const b = g.ops[name].behaviour;
  if (b.callsUser) return 'user';                 // may run user code: getters, valueOf, calls
  return String(b) === 'none' ? 'pure' : 'other';  // allocation, cells, host, jobs
};

const rows = corpus.map(file => {
  const program = g.compile(g.pipeline(), source(file));
  const spec = program.run({ mode: 'spec' }), plan = program.run({ mode: 'plan', gc: 'stress' });
  const count = { pure: 0, user: 0, other: 0 };
  let cellsKept = 0, safepoints = 0;
  for (const f of program.functions()) {
    for (const b of program.cfg(f).blocks) for (const o of b.ops) { count[classOf(o.op)]++; if (o.op === 'cell.new') cellsKept++; }
    safepoints += Object.keys(program.plan(f).safepoints).length;
  }
  const ops = count.pure + count.user + count.other;
  const m = program.metrics();
  return { program: file, functions: m.functions, ops, pure: count.pure, user: count.user, other: count.other,
    userShare: Math.round(100 * count.user / ops), cellsPromoted: m.cellsPromoted, cellsKept, safepoints,
    rootSlots: m.rootSlots, steps: spec.steps, collections: plan.metrics.collections, same: g.observe.equal(spec, plan).equal === true };
});

const total = k => rows.reduce((n, r) => n + r[k], 0);
print(`corpus: ${total('ops')} operations, ${total('user')} may run user code (${Math.round(100 * total('user') / total('ops'))} %), ${total('pure')} pure`);
return g.table(rows, { title: 'The J programs, measured with the default pipeline', columns: [
  { key: 'program', label: 'program' }, { key: 'functions', label: 'functions' }, { key: 'ops', label: 'ops', unit: 'count' },
  { key: 'pure', label: 'pure' }, { key: 'user', label: 'user code' }, { key: 'other', label: 'other' }, { key: 'userShare', label: 'user code', unit: '%' },
  { key: 'cellsPromoted', label: 'cells promoted' }, { key: 'cellsKept', label: 'cells kept' }, { key: 'safepoints', label: 'safepoints' },
  { key: 'rootSlots', label: 'root slots', unit: 'slots' }, { key: 'steps', label: 'steps' }, { key: 'collections', label: 'collections (stress)' }, { key: 'same', label: 'plan = spec' }] });
