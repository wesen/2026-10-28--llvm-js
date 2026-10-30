// T-06: passes and their requirements. A pass declares what it requires and provides; the
// pipeline's check() verifies the chain before anything runs. We insert a pass of our own,
// and build two pipelines that check() refuses.
const countOps = g.pass('count-ops').from('L1').to('L1').requires('verified')
  .run(st => {
    let n = 0;
    for (const fn of st.module.functions.values()) for (const b of fn.blocks) n += b.ops.length;
    return `${n} operations after rewriting`;
  });
const pipe = g.pipeline().insert(countOps, { after: 'rewrite' });
const program = g.compile(pipe, source());

// A pass value keeps its levels in src and dst, its requirements in needs, gives and kills.
const rows = pipe.passList().map(p => {
  const t = program.trace.find(x => x.pass === p.name);
  return { pass: p.name, levels: `${p.src || ''}${p.dst && p.dst !== p.src ? ' → ' + p.dst : ''}`,
    requires: p.needs.join(', '), provides: p.gives.join(', '), invalidates: p.kills.join(', '), note: t ? t.note : '' };
});

// Two pipelines that are refused before compiling: a missing analysis, and our pass too early.
const P = g.pass;
const noAnalysis = g.pipeline().passes([P.frontend, P.promoteCells, P.verify, P.rewrite, P.lowerRuntime, P.planRoots, P.checkPlan, P.emitLLVM]);
const tooEarly = g.pipeline().insert(countOps, { before: 'verify' });
for (const [name, p] of [['without analyze', noAnalysis], ['count-ops before verify', tooEarly]])
  print(`${name}: ${p.check().diagnostics.map(d => d.message).join('; ')}`);
print('stopAfter L1: ' + g.compile(g.pipeline().stopAfter('L1'), source()).trace.map(t => t.pass).join(', '));

return { program, results: g.table(rows, { title: 'The pass list, with requirements and what each pass reported' }) };
