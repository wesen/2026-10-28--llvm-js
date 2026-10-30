// M-07: the capstone. The ledger end to end, every check in the order a team would run them.
const src = source('program.js');

// 1. Meaning first: what the specification says the ledger does.
const spec = g.semantics().run(src);

// 2. The pipeline, every slot stated even where it equals the default.
const pipe = g.pipeline().profile('js').rewrites(g.rewrites.standard())
  .roots('stackReuse').exceptions('setjmp').checks({ verify: true, gcSafety: true, llvm: true });
const program = g.compile(pipe, src);

// 3. Engine run: admit before anything runs, evaluate, drain the jobs, close.
const engine = g.engine();
const code = engine.admit(program);
const evaluation = engine.evaluateScript(code);
engine.runJobs();
const engineOutput = engine.output();
engine.close();

// 4. A small design search on the same source, feasibility first.
const design = g.design({ roots: g.param.choice(['distinct', 'stackReuse']), rewrites: g.param.choice(['canonical', 'standard']) },
  p => g.pipeline().roots(p.roots).rewrites(g.rewrites[p.rewrites]()));
const results = g.search.grid(design, { corpus: [src], objective: g.objective.require('admitted', 'correct').then(g.objective.lexicographic(['rootSlots', 'collections'])) });

// 5. The decision the search informs, checked for completeness.
const decision = g.decision('Ship the ledger with stackReuse and the standard rewrites?')
  .options(results.rows.map(r => r.point)).evidence(results.rows.map(r => `${r.point}: ${r.rootSlots} root slots, correct ${r.correct}`))
  .counterexampleSought('refines(pipeline) on the ledger and 10 generated programs').choose(results.best)
  .overturnIf('any law below failing after an engine change');

// 6. Every check as one law report.
const fact = (name, ok, note) => ({ name, ok, samples: 1, note });
const plans = program.functions().map(f => program.plan(f));
const frame = g.limit('native frame', { measure: p => slots(p.metrics().maxFrameSlots), max: slots(1024) }).check(program);
const laws = g.laws([
  fact('the pipeline is well formed', pipe.check().ok, pipe.check().diagnostics.map(d => d.message).join('; ') || 'pass requirements and strategy pair declared'),
  fact('every function verifies', program.functions().every(f => g.verify(program.module.fn(f)).ok), `${program.functions().length} functions`),
  fact('every safepoint roots what it needs', plans.every(p => p.missing.length === 0), `${plans.reduce((n, p) => n + Object.keys(p.safepoints).length, 0)} safepoints checked`),
  fact('the frame fits the native limit', frame.ok, `${frame.measured} of ${frame.max} (${frame.asBytes.measured})`),
  fact('the LLVM text is structurally sound', !program.diagnostics.some(d => d.kind === 'llvm-check'), `${program.ir('LLVM').split('\n').length} lines`),
  g.law.refines(pipe, { corpus: [src], samples: 10, seed: 2 }),
  fact('the engine agrees with the specification', JSON.stringify(engineOutput) === JSON.stringify(spec.output), engineOutput.join(' / ')),
  fact('the decision record is complete', decision.check().ok, decision.check().issues.join('; ') || 'chose ' + results.best),
  g.law.antitone(),
  g.law.monotone(g.analysis.liveness, { samples: 100 }),
]);
print(`spec: ${spec.output.join(' / ')} · engine: ${evaluation.state}, ${engineOutput.length} lines`);
return { program, laws, results };
