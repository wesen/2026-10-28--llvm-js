// L-07: the 1,024-slot frame. Hermes's LLVM backend refuses a function whose frame
// (root slots + 2 fixed + outgoing arguments) exceeds 1,024 slots; the workbench's plan
// checker applies the same limit. wide(n) below makes n objects that all stay live until
// the end, so no strategy can share their slots: the frame grows by one slot per object.
const wide = n => {
  const lines = ['function wide() {'];
  for (let i = 0; i < n; i++) lines.push(`  const o${i} = { i: ${i} };`);
  lines.push('  let sum = 0;');
  for (let i = 0; i < n; i++) lines.push(`  sum = sum + o${i}.i;`);
  lines.push('  return sum;', '}', 'print(wide());');
  return lines.join('\n');
};

// Measure the frame for growing n (program.js is wide(8), written out).
const rows = [8, 32, 64, 128].map(n => {
  const t0 = Date.now();
  const p = g.compile(g.pipeline(), wide(n));
  const plan = p.plan('wide');
  return { n, rootSlots: plan.rootSlots, frameSlots: plan.frameSlots, frameBytes: plan.frameBytes,
    underLimit: plan.limit.ok, compileMs: Date.now() - t0 };
});

// The same check as a value, with a smaller maximum so that it fails here.
const small = g.limit('frame of at most 64 slots', { measure: p => slots(p.plan('wide').frameSlots), max: slots(64) });
for (const n of [32, 64]) print(`wide(${n}): ${JSON.stringify(small.check(g.compile(g.pipeline(), wide(n))))}`);

const program = g.compile(g.pipeline(), source());
return { program, results: g.table(rows, { title: 'Frame size of wide(n) under stackReuse' }) };
