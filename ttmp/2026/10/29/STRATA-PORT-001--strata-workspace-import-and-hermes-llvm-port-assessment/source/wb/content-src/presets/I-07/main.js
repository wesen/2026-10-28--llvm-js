// I-07: building SSA with promote-cells. For each cell, block parameters go at the iterated
// dominance frontier of the blocks that store to it; then loads are renamed along the dominator
// tree and parameters nothing uses are removed.
const cells = g.compile(g.pipeline().frontend({ promote: false }).rewrites(g.rewrites.none()), source('program.js'));
const fn = cells.module.fn('classify').clone();          // classify with every variable a cell

// Where would each cell need parameters? Dominance frontiers, iterated (as in I-05).
const dom = g.dominators(fn), preds = {};
for (const b of fn.blocks) for (const e of cells.cfg('classify').blocks.find(x => x.name === b.name).term.edges) (preds[e.to] = preds[e.to] || []).push(b.name);
const df = Object.fromEntries(fn.blocks.map(b => [b.name, new Set()]));
for (const b of fn.blocks) if ((preds[b.name] || []).length > 1)
  for (const p of preds[b.name]) for (let r = p; r && r !== dom.idom[b.name]; r = dom.idom[r]) df[r].add(b.name);
const iterated = blocks => { const out = new Set(), work = [...blocks]; while (work.length) for (const y of df[work.pop()]) if (!out.has(y)) { out.add(y); work.push(y); } return [...out]; };

const rows = [];
for (const b of fn.blocks) for (const o of b.ops) if (o.op === 'cell.new') {
  const c = o.result;
  const defs = fn.blocks.filter(x => x.ops.some(y => (y.op === 'cell.store' && y.args[0] === c) || y.result === c)).map(x => x.name);
  rows.push({ cell: c, storedIn: defs.join(', '), parametersAt: iterated(defs).join(', ') || '(none)' });
}

const stats = g.promoteCells(fn);                          // the pass itself, on the clone
print(`promoted ${stats.promoted.length} cells, placed ${stats.params} parameters, removed ${stats.removedParams} dead ones`);

const program = g.compile(g.pipeline(), source('program.js'));
return { program, results: g.table(rows, { title: 'Where promote-cells places parameters' }) };
