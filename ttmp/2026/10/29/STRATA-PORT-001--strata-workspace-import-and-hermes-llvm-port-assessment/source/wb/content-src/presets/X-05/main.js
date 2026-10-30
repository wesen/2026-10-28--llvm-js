// X-05: your own metrics. A metric is a name, a function of { program, run } and a direction.
// Search adds it to every row (summed over the corpus), and objectives can use it like the
// built-in ones.
const fnNames = program => program.functions();

// Collecting points in the compiled code: every one is a call into the runtime that may move
// objects, and every one constrains the root plan.
g.metric('safepoints', ({ program }) =>
  fnNames(program).reduce((n, f) => n + Object.keys(program.plan(f).safepoints).length, 0),
  { dir: 'min', unit: 'count', about: 'operations that may collect, over all functions' });

// What the plan reserves per call, in bytes: on the native stack the root slots, two fixed
// slots and the argument area; for the arena strategy a 32 B record header plus 8 B per slot.
g.metric('frameBytes', ({ program }) =>
  fnNames(program).reduce((n, f) => n + program.plan(f).frameBytes, 0),
  { dir: 'min', unit: 'B', about: 'sum of frame sizes over all functions' });

const design = g.design({
  roots: g.param.choice(['distinct', 'stackReuse', 'arena']),
  rewrites: g.param.choice(['canonical', 'standard']),
}, p => g.pipeline().roots(p.roots).rewrites(g.rewrites[p.rewrites]()));

const results = g.search.grid(design, {
  corpus: [source('program.js')],
  objective: g.objective.lexicographic(['safepoints', 'frameBytes']),
});
results.columns.push({ key: 'safepoints', label: 'safepoints', unit: 'count' }, { key: 'frameBytes', label: 'frame bytes', unit: 'B' });
print(g.metrics.list().filter(m => /safepoints|frameBytes/.test(m)).join('; '));

const program = g.compile(design.at({ roots: 'stackReuse', rewrites: 'standard' }), source('program.js'));
return { program, results };
