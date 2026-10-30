// S-03: profiles. A profile names the operation sets a program may use and the observations a
// correctness claim must preserve. The same three programs run under three profiles.
const programs = [
  ['numeric.ir', { args: [10] }],     // core IR text: numbers and a print
  ['sync.js', {}],                    // objects, a method, this
  ['program.js', {}],                 // a job queued with queueMicrotask
];
const profiles = ['core', 'js-sync', 'js-async'];

const rows = programs.map(([file, opts]) => {
  const row = { program: file };
  for (const name of profiles) {
    const run = g.semantics().profile(name).run(source(file), opts);
    row[name] = run.outcome.kind === 'error' ? run.error.message.split(';')[0] : `${run.outcome.kind}: ${run.output.join(' / ')}`;
  }
  return row;
});

// A profile of your own: numbers and objects, but no closures, calls or jobs.
const mine = g.profile.define('numbers-and-objects', { admits: ['core', 'js.object'], observes: ['output', 'outcome', 'object identity'] });
print(`${mine}: sets ${mine.sets.join(', ')}; below js-sync: ${mine.le(g.profile('js-sync'))}`);

const program = g.compile(g.pipeline(), source('program.js'));
return { program, results: g.table(rows, { title: 'Three programs under three profiles' }) };
