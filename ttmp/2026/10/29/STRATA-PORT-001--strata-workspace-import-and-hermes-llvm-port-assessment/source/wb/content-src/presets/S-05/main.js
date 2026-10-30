// S-05: divergence and budgets. The interpreter counts steps; when a run uses up its budget the
// outcome is 'diverge'. A budget is a resource limit, not part of what the program means.
const program = g.compile(g.pipeline(), source('program.js'));

const runs = [
  ['the whole program, default budget', {}],
  ['the whole program, budget 5,000', { budget: 5000 }],
  ['collatz(27) alone, budget 500', { entry: 'collatz', args: [27], budget: 500 }],
  ['collatz(27) alone, default budget', { entry: 'collatz', args: [27] }],
];
const rows = runs.map(([what, opts]) => {
  const r = program.run(opts);
  return { what, outcome: r.outcome.kind, value: r.outcome.display || '', steps: r.steps, output: r.output.join(' / ') };
});
return { program, results: g.table(rows, { title: 'Budgets' }) };
