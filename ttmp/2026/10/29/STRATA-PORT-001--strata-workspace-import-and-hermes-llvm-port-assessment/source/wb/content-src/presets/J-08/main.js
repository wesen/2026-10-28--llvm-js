// J-08: a program written by the generator. program.js is a copy of g.gen.js({ seed: 1 }),
// kept as a file so it can be read and edited; this script regenerates it from the seed and
// says when the copy no longer matches.
const generated = g.gen.js({ seed: 1 });
print(generated.statements.length + ' statements from seed 1');
if (generated.text.trim() !== files['program.js'].trim()) print('program.js was edited: it differs from the generator output');

const program = g.compile(g.pipeline(), source('program.js'));

// Two refinement checks on this one program: the default pipeline run in plan mode under
// GC stress against the specification, and the canonical rewrites plus naive DCE.
const laws = g.laws([
  g.law.refines(g.pipeline(), { corpus: [source('program.js')] }),
  g.law.refines(g.rewrites.naiveDce, { corpus: [source('program.js')] }),
]);
return { program, laws };
