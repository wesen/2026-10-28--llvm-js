// X-06: a factorial study, written down before it is run.
// Factors: root strategy (3 levels) × program (4 levels) = 12 cells, each measured once
// (the engine is deterministic, so repetitions would add nothing).
// Hypotheses, with their thresholds, fixed before looking at the numbers:
//   H1  stackReuse never needs more root slots than distinct, on any program;
//   H2  no strategy changes what a program observably does (plan mode under GC stress = spec);
//   H3  over the corpus, stackReuse needs at most half the root slots of distinct.
const strategies = ['distinct', 'stackReuse', 'arena'];
const programs = ['ledger.js', 'counter.js', 'tokenizer.js', 'errors.js'];

const rows = [];
for (const file of programs) {
  for (const roots of strategies) {
    const program = g.compile(g.pipeline().roots(roots), source(file));
    const spec = program.run({ mode: 'spec' });
    const plan = program.run({ mode: 'plan', gc: 'stress' });
    const m = program.metrics();
    rows.push({ program: file, roots, rootSlots: m.rootSlots, maxFrameSlots: m.maxFrameSlots,
      collections: plan.metrics.collections, moved: plan.metrics.moved, same: g.observe.equal(spec, plan).equal === true });
  }
}

const cell = (file, roots) => rows.find(r => r.program === file && r.roots === roots);
const sum = roots => rows.filter(r => r.roots === roots).reduce((n, r) => n + r.rootSlots, 0);
const h1 = programs.filter(f => cell(f, 'stackReuse').rootSlots > cell(f, 'distinct').rootSlots);
const h2 = rows.filter(r => !r.same);
const ratio = sum('stackReuse') / sum('distinct');
const laws = g.laws([
  { name: 'H1 stackReuse ≤ distinct on every program', ok: h1.length === 0, samples: programs.length, note: h1.length ? 'refuted on ' + h1.join(', ') : 'supported' },
  { name: 'H2 no strategy changes observations', ok: h2.length === 0, samples: rows.length, note: h2.length ? 'refuted: ' + h2.map(r => r.program + '/' + r.roots).join(', ') : 'supported on all 12 cells' },
  { name: 'H3 stackReuse uses at most half of distinct', ok: ratio <= 0.5, samples: 1, note: `stackReuse ${sum('stackReuse')} slots, distinct ${sum('distinct')}: ratio ${ratio.toFixed(2)}` },
]);
const results = g.table(rows, { title: 'Root strategy × program', columns: [
  { key: 'program', label: 'program' }, { key: 'roots', label: 'roots' }, { key: 'rootSlots', label: 'root slots', unit: 'slots' },
  { key: 'maxFrameSlots', label: 'largest frame', unit: 'slots' }, { key: 'collections', label: 'collections', unit: 'count' },
  { key: 'moved', label: 'objects moved', unit: 'count' }, { key: 'same', label: 'plan = spec' }] });
return { laws, results };
