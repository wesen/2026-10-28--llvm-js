// I-08: captured variables stay cells. A cell handed to js.closure belongs to two functions, so
// neither may turn it into a value, and a load after any call must read it again.
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source('program.js'));

// Every cell that survived promotion, and the closures that capture it.
const rows = program.find(op => op.op === 'cell.new').map(site => {
  const uses = new RegExp(`[(, ]${site.result}[,)]`);
  const by = program.find(s => s.op === 'js.closure' && uses.test(s.text)).map(c => c.text.match(/@\w+/)[0]);
  return { cell: site.result, in: site.id, capturedBy: by.join(', ') };
});

// The standard rewrites try to forward each store to the next load; calls block them.
for (const d of program.decisions.filter(d => d.by === 'forward-store-to-load' && d.at.startsWith('makeCounter'))) print(d.at, d.fired ? 'forwarded' : 'kept:', d.because);
return { program, results: g.table(rows, { title: 'Cells that stay cells' }) };
