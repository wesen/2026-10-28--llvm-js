// M-05: decision records. A decision is a value: the question, the options compared, the
// evidence (measured here, not typed in), the counterexample that was looked for, the choice,
// and what would overturn it. check() lists what a reviewer would send back.
const measure = roots => ['program.js', 'tokenizer.js'].map(file => {
  const p = g.compile(g.pipeline().roots(roots), source(file));
  const same = g.observe.equal(p.run({ mode: 'spec' }), p.run({ mode: 'plan', gc: 'stress' })).equal === true;
  return `${file}: ${p.metrics().rootSlots} root slots, largest frame ${p.metrics().maxFrameSlots} slots, plan = spec under stress: ${same}`;
});
const evidence = ['distinct', 'stackReuse', 'arena'].flatMap(r => measure(r).map(line => `${r} · ${line}`));
const fuzz = g.law.refines(g.roots.stackReuse(), { samples: 15, seed: 3 });

const roots = g.decision('Which root strategy should the pipeline use by default?')
  .context('Every safepoint needs the managed values live across it in root slots; the plan checker verifies any strategy.')
  .options(['distinct (one slot per value, as the Hermes LLVM backend emits today)', 'stackReuse (values never needed together share a slot)', 'arena (slots in runtime-owned chunks)'])
  .evidence([...evidence, `${fuzz.name} on ${fuzz.samples} generated programs: ${fuzz.ok ? 'no counterexample' : 'counterexample found'}`])
  .counterexampleSought('a program whose plan/stress run differs from the spec under stackReuse (15 generated programs, seed 3)')
  .choose('stackReuse')
  .overturnIf('a counterexample to refines(stackReuse), or a corpus where slot sharing costs more steps than it saves frame space')
  .status('accepted');

// The same question answered in a hurry: one option, no evidence, nothing that would change it.
const hasty = g.decision('Should the frontend keep every variable a cell?')
  .options(['yes'])
  .choose('yes');

const row = (d) => { const c = d.check(); const j = d.toJSON(); return { question: j.question, status: j.status, options: j.options.length, evidence: j.evidence.length, choice: j.choice, ok: c.ok, issues: c.issues.join('; ') || 'none' }; };
print(strata.yaml(roots.toJSON()));
const program = g.compile(g.pipeline(), source('program.js'));
return { program, results: g.table([row(roots), row(hasty)], { title: 'Decision records and their checks', columns: [
  { key: 'question', label: 'question' }, { key: 'status', label: 'status' }, { key: 'options', label: 'options' }, { key: 'evidence', label: 'evidence' },
  { key: 'choice', label: 'choice' }, { key: 'ok', label: 'check' }, { key: 'issues', label: 'what is missing' }] }) };
