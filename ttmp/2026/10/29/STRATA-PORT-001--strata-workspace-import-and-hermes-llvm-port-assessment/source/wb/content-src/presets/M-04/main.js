// M-04: differential testing. The same program runs on every executor the workbench has, and
// each run is compared with the specification (the reference interpreter on L1).
// A deliberately broken compiler is in the table too: a root strategy that forgets one value,
// with the GC-safety check switched off so it compiles.
const forgetOne = (fn, ctx) => {
  const plan = ctx.default();
  const victim = Object.keys(plan.slotOf)[0];   // the first rooted value of each function
  if (victim) delete plan.slotOf[victim];
  return plan;
};
const compilers = {
  default: g.pipeline(),
  'forgets a root': g.pipeline().roots(forgetOne).checks({ gcSafety: false }),
};
const runs = { 'plan, gc off': { mode: 'plan', gc: 'off' }, 'plan, gc alloc': { mode: 'plan', gc: 'alloc' }, 'plan, gc stress': { mode: 'plan', gc: 'stress' }, wasm: { mode: 'wasm' } };

const rows = [];
for (const file of ['program.ir', 'counter.js', 'thermometer.js']) {
  for (const [cname, pipe] of Object.entries(compilers)) {
    const program = g.compile(pipe, source(file));
    const spec = program.run({ mode: 'spec' });
    const row = { program: file, compiler: cname, spec: spec.output.join(' / ') };
    for (const [rname, opts] of Object.entries(runs)) {
      const r = program.run(opts);
      row[rname] = r.outcome.kind === 'error' ? (r.error.stale ? 'stale' : opts.mode === 'wasm' ? 'outside the core profile' : 'error') : g.observe.equal(spec, r).equal === true ? 'same' : 'DIFFERS';
    }
    rows.push(row);
  }
}
const program = g.compile(g.pipeline(), source('program.ir'));
return { program, results: g.table(rows, { title: 'Every executor against the specification', columns: [
  { key: 'program', label: 'program' }, { key: 'compiler', label: 'compiler' }, { key: 'spec', label: 'spec output' },
  ...Object.keys(runs).map(k => ({ key: k, label: k }))] }) };
