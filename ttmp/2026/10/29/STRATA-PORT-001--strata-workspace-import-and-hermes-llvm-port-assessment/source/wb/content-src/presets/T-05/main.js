// T-05: forwarding stores to loads. forward-store-to-load replaces a cell.load with the value
// last stored to the same cell in the same block, if nothing in between may write cells.
// Its side condition reads the behaviour of each operation between the store and the load.
const canonical = g.compile(g.pipeline(), source());
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source());
const mine = program.decisions.filter(d => d.by === 'forward-store-to-load' && d.at.startsWith('makeCounter/'));

// Every load that was forwarded, then every load still in makeCounter with the last reason given.
const rows = mine.filter(d => d.fired).map(d => ({ load: d.at, result: 'forwarded', because: d.because }));
for (const block of program.cfg('makeCounter').blocks) for (const op of block.ops.filter(o => o.op === 'cell.load')) {
  const last = mine.filter(d => d.at === op.id).pop();
  rows.push({ load: `${op.id} ${op.text}`, result: 'kept', because: last ? last.because : '' });
}
print('canonical: ' + canonical.run().output.join(' / '));
print('standard:  ' + program.run().output.join(' / '));
return { program, results: g.table(rows, { title: 'forward-store-to-load in makeCounter' }) };
