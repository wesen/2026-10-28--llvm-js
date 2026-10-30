// M-06: the design process as a value. A process is a list of steps (step, diverge, converge,
// critique, loop) with what each one produces. check({ requires }) reports a divergence that
// never converges and a required output that no step produces.
const rootsDecision = g.decision('Which root strategy should the first native build use?')
  .options(['distinct', 'stackReuse']).evidence(['L-03 and X-06 measurements'])
  .counterexampleSought('refines(stackReuse) on generated programs').choose('stackReuse')
  .overturnIf('a stale use in a native run').status('accepted');

const port = g.process('porting the ledger to a native build')
  .step('fix the specification', { week: 1, produces: ['profile js-async', 'spec runs of the ledger'] })
  .step('measure the workbench plans', { week: 1, produces: ['FACTS.md', 'root slots per function'] })
  .diverge('root strategies', { week: 2, options: ['distinct', 'stackReuse', 'arena'] })
  .converge('root strategies', { week: 2, by: 'X-06 hypotheses H1 to H3', produces: [rootsDecision] })
  .step('emit LLVM IR and build locally', { week: 3, produces: ['ledger.ll', 'a local Hermes and LLVM build'] })
  .critique('a second reader checks the plan against the helpers', { week: 3, produces: ['review notes'] })
  .loop('fix and re-measure until refines holds', { week: 4, until: 'refines(pipeline) on 200 generated programs' })
  .step('record the outcome', { week: 4, produces: ['decision log'] });

// The same plan written in a hurry: it diverges and never decides, and nothing records a decision.
const hurried = g.process('porting in a hurry')
  .step('emit LLVM IR', { produces: ['ledger.ll'] })
  .diverge('exception strategies', { options: ['setjmp', 'statusReturn'] })
  .step('ship it', { produces: ['a binary'] });

const requires = ['spec runs of the ledger', rootsDecision.question, 'decision log'];
const row = p => { const c = p.check({ requires }); return { process: p.name, steps: c.steps, ok: c.ok, issues: c.issues.join('; ') || 'none' }; };
print(strata.yaml(port.toYAML()));
return g.table([row(port), row(hurried)], { title: 'Two processes, checked against the same requirements', columns: [
  { key: 'process', label: 'process' }, { key: 'steps', label: 'steps' }, { key: 'ok', label: 'check' }, { key: 'issues', label: 'issues' }] });
