// X-04: constraints and feasibility.
// Three kinds of bad point, removed at three different moments:
//  1. never generated: g.constraint.compatible() drops points whose pipeline fails check()
//     (statusReturn exceptions with Hermes providers);
//  2. generated but not admitted: roots 'none' with the GC-safety check on does not compile;
//  3. admitted but wrong: roots 'none' with the check turned off compiles, and plan mode
//     under GC stress then reads a stale reference, so its output differs from the spec.
const design = g.design({
  roots: g.param.choice(['stackReuse', 'none']),
  gcSafety: g.param.choice([true, false]),
  exceptions: g.param.choice(['setjmp', 'statusReturn']),
}, p => g.pipeline().roots(p.roots).exceptions(p.exceptions).checks({ gcSafety: p.gcSafety }));

const allowed = design.where(g.constraint.compatible());
print('raw', design.size().raw, 'points, compatible', allowed.size().points);

// require() makes correctness and admission feasibility, not score: an infeasible point
// ranks last whatever its numbers.
const objective = g.objective.require('admitted', 'correct').then(g.objective.minimize('rootSlots'));
const results = g.search.grid(allowed, { corpus: [source('program.js')], objective });
for (const row of results.rows) row.why = !row.admitted ? 'not admitted: ' + row.reason : !row.correct ? 'wrong: plan output differs from the spec' : '';
results.columns.push({ key: 'why', label: 'why infeasible' });

const program = g.compile(g.pipeline().roots('none').checks({ gcSafety: false }), source('program.js'));
return { program, results };
