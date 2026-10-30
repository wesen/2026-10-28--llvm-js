// I-05: dominators. Block A dominates block B when every path from entry to B passes through A;
// the immediate dominator (idom) of B is its closest strict dominator. They form a tree.
const program = g.compile(g.pipeline(), source('program.ir'));
const fn = program.module.fn('parity');
const dom = g.dominators(fn);

// Predecessors from the control-flow graph.
const cfg = program.cfg('parity'), preds = {};
for (const b of cfg.blocks) for (const e of b.term.edges) (preds[e.to] = preds[e.to] || []).push(b.name);

// Dominance frontier (Cytron et al. 1991): for each block with two or more predecessors,
// walk up the dominator tree from each predecessor until reaching the block's idom.
const frontier = Object.fromEntries(cfg.blocks.map(b => [b.name, new Set()]));
for (const b of cfg.blocks) {
  if ((preds[b.name] || []).length < 2) continue;
  for (const p of preds[b.name]) for (let r = p; r && r !== dom.idom[b.name]; r = dom.idom[r]) frontier[r].add(b.name);
}

const rows = cfg.blocks.map(b => ({
  block: b.name,
  idom: dom.idom[b.name] || '(entry)',
  children: cfg.blocks.filter(c => dom.idom[c.name] === b.name).map(c => c.name).join(', '),
  predecessors: (preds[b.name] || []).join(', '),
  frontier: [...frontier[b.name]].join(', '),
}));
print('head dominates merge:', dom.dominates('head', 'merge'), '· yes dominates merge:', dom.dominates('yes', 'merge'));
return { program, results: g.table(rows, { title: 'Dominators of parity' }) };
