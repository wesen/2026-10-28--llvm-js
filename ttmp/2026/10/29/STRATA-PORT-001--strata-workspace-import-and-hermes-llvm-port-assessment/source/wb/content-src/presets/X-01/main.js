// X-01: a design space of pipelines, searched on the ledger.
// A design maps a point (one value per parameter) to a pipeline. The space is the product of
// the parameters: 3 root strategies × 2 rewrite sets × 2 frontend settings = 12 points.
const design = g.design({
  roots: g.param.choice(['distinct', 'stackReuse', 'arena'], { default: 'stackReuse' }),
  rewrites: g.param.choice(['canonical', 'standard'], { default: 'canonical' }),
  promote: g.param.choice([true, false], { default: true }),
}, p => g.pipeline()
  .roots(p.roots)
  .rewrites(g.rewrites[p.rewrites]())
  .frontend({ promote: p.promote }));

print('size', JSON.stringify(design.size()), 'defaults', JSON.stringify(design.defaults()));

// Grid search compiles every point on every corpus item, runs it in plan mode under GC
// stress and in the specification, and fills one row per point.
const results = g.search.grid(design, {
  corpus: [source('program.js')],
  objective: g.objective.minimize('rootSlots'),
});

// The default point, compiled on its own, is the Program the other views show.
const program = g.compile(design.at({}), source('program.js'));
return { program, results };
