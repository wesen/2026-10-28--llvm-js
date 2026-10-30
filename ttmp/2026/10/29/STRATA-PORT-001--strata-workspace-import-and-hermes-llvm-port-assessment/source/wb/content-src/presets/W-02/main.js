// W-02: from JavaScript to Wasm. The Wasm backend takes only functions whose values are
// proven numbers or booleans. JavaScript's fib gets there in two steps: an assumption
// about its parameter (what a JIT would speculate from profiling, here unchecked) and the
// standard rewrites, which narrow js.lt and js.add to num.lt and num.add under those facts.
const steps = [
  ['defaults', g.pipeline()],
  ['assume n: number', g.pipeline().assume({ fib: { n: 'number' } })],
  ['assume + standard rewrites', g.pipeline().assume({ fib: { n: 'number' } }).rewrites(g.rewrites.standard())],
];
const rows = steps.map(([name, pipe]) => {
  const p = g.compile(pipe, source());
  const w = p.wasm();
  return { pipeline: name, fibInWasm: w.ok.includes('fib') ? 'yes' : 'no', reason: w.reasons.fib || '', jsOpsInFib: p.find(o => o.op.startsWith('js.')).filter(s => s.fn === 'fib').length };
});

const program = g.compile(steps[2][1], source());
const run = program.run({ mode: 'wasm', entry: 'fib', args: [30] });
print(`fib(30) in Wasm: ${run.outcome.value}; main stays out: ${program.wasm().reasons.main}`);
return { program, run, results: g.table(rows, { title: 'Getting fib into the core profile' }) };
