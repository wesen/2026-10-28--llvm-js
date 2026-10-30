// X-02: two objectives over the same table pick different winners.
// The design trades speculation for speed: assuming parameter types (what a JIT would guess
// from a profile) lets narrowing turn js.* operations into num.* ones, which do not collect.
// An assumption is unchecked, so it is a cost too. The metric below counts them.
g.metric('assumptions', ({ program }) => program.summary().assume.length, { dir: 'min', unit: 'count', about: 'unchecked parameter-type assumptions' });

const ASSUME = { none: {}, scale: { scale: { k: 'number', n: 'number' } }, both: { scale: { k: 'number', n: 'number' }, mean: { n: 'number' } } };
const design = g.design({
  rewrites: g.param.choice(['canonical', 'standard']),
  assume: g.param.choice(['none', 'scale', 'both']),
}, p => g.pipeline().rewrites(g.rewrites[p.rewrites]()).assume(ASSUME[p.assume]));

const weighted = g.objective.weighted({ collections: 1, assumptions: 10 });   // one assumption is worth 10 collections
const lexico = g.objective.lexicographic(['assumptions', 'collections']);     // never assume if avoidable

const results = g.search.grid(design, { corpus: [source('program.js')], objective: weighted });
results.columns.push({ key: 'assumptions', label: 'assumptions', unit: 'count' });
const split = g.rank.disagreement(results, weighted, lexico);
print('weighted picks', split.winners.first, '; lexicographic picks', split.winners.second);
results.note = `weighted: ${split.winners.first} · lexicographic: ${split.winners.second}`;

const program = g.compile(design.at({ rewrites: 'standard', assume: 'none' }), source('program.js'));
return { program, results };
