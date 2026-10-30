// B-03: every level of one function. poly is assumed to take a number, so the standard
// rewrites can narrow its js.* operations to num.*, and the Wasm backend accepts it.
const pipe = g.pipeline()
  .assume({ poly: { x: 'number' } })          // what a JIT would speculate; unchecked here
  .rewrites(g.rewrites.standard());
const program = g.compile(pipe, source('program.js'));

// One row per level: how much text each stage of the compiler prints for poly.
const levels = ['L0', 'L1.cells', 'L1', 'L2', 'L3', 'LLVM', 'WAT'];
const rows = levels.map(level => {
  const text = program.ir(level, { fn: 'poly' });
  return { level, lines: text.split('\n').length, first: text.split('\n').find(l => l.trim() && !l.startsWith(';')) };
});
print('wasm poly(2) =', program.run({ mode: 'wasm', entry: 'poly', args: [2] }).outcome.value);
return { program, results: g.table(rows, { title: 'poly at every level' }) };
