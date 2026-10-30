// X-03: a Pareto frontier. No weights: a point is on the frontier when no other point is
// at least as good on every metric and strictly better on one.
g.metric('assumptions', ({ program }) => program.summary().assume.length, { dir: 'min', unit: 'count', about: 'unchecked parameter-type assumptions' });

const ASSUME = { none: {}, scale: { scale: { k: 'number', n: 'number' } }, both: { scale: { k: 'number', n: 'number' }, mean: { n: 'number' } } };
const design = g.design({
  roots: g.param.choice(['distinct', 'stackReuse']),
  rewrites: g.param.choice(['canonical', 'standard']),
  assume: g.param.choice(['none', 'scale', 'both']),
}, p => g.pipeline().roots(p.roots).rewrites(g.rewrites[p.rewrites]()).assume(ASSUME[p.assume]));

// Measure every point once (ranked by collections so the table has an order), then ask
// which points no other point dominates on collections, root slots and assumptions together.
const results = g.search.grid(design, { corpus: [source('program.js')], objective: g.objective.minimize('collections') });
const metrics = ['collections', 'rootSlots', 'assumptions'];
const frontier = g.rank(results, g.objective.pareto(metrics)).frontier;
for (const row of results.rows) row.frontier = frontier.includes(row.point);
results.columns.push({ key: 'assumptions', label: 'assumptions', unit: 'count' }, { key: 'frontier', label: 'on the frontier' });
results.title = 'Pareto frontier over ' + metrics.join(', ');
results.frontier = frontier; results.best = null;        // no single best point without weights
results.note = `${frontier.length} of ${results.rows.length} points are on the frontier`;
print('frontier:', frontier.join(' | '));

const program = g.compile(design.at({ roots: 'stackReuse', rewrites: 'standard', assume: 'both' }), source('program.js'));
return { program, results };
