// M-02: fuzzing a pipeline. g.gen.js writes random programs from templates (a getter that
// may throw, loops, closures, try/finally, jobs). g.law.refines compiles each one twice, runs
// the reference (no rewrites, spec mode) and the target, and compares the observations.
const N = 20;          // generated programs per law; raise it and rerun to search longer
const named = (name, report) => ({ ...report, name });

const laws = g.laws([
  // The default pipeline, run in plan mode under GC stress: rewrites, lowering and root plans.
  named('default pipeline, plan mode, GC stress', g.law.refines(g.pipeline(), { samples: N, seed: 1 })),
  // The standard rewrites add narrowing and store-to-load forwarding.
  named('standard rewrites, plan mode, GC stress', g.law.refines(g.pipeline().rewrites(g.rewrites.standard()), { samples: N, seed: 1 })),
  // One root strategy on its own: a slot per value.
  named('roots distinct, plan mode, GC stress', g.law.refines(g.roots.distinct(), { samples: N, seed: 1 })),
  // A rewrite that is wrong on purpose. The fuzzer should find a program it breaks.
  named('naive DCE, spec mode', g.law.refines(g.rewrites.naiveDce, { samples: N, seed: 1 })),
]);
for (const l of laws.laws) print(l.name + ': ' + (l.ok ? 'holds on ' + l.samples + ' programs' : 'fails at program ' + l.samples));
return laws;
