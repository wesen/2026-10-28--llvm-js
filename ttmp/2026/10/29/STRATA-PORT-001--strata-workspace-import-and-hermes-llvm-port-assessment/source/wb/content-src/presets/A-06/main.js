// A-06: the solver on any graph. g.solve runs the same worklist algorithm on a plain graph
// { kind: 'graph', nodes, edges }. Here the graph is "which function refers to which": an
// edge f → h when f captures h's variable (or, for main, loads it). A backward analysis over
// the powerset lattice computes what each function can reach; g.graph.scc finds recursion.
const program = g.compile(g.pipeline(), source());
const names = program.functions();
const edges = [];
for (const f of names) {
  const fn = program.module.fn(f);
  const refs = f === 'main'
    ? fn.blocks.flatMap(b => b.ops).filter(o => o.op === 'cell.load').map(o => names.find(h => o.args[0].startsWith('c_' + h)))
    : fn.meta.captures;
  for (const h of new Set(refs)) if (h) edges.push({ from: f, to: h });
}
const graph = { kind: 'graph', nodes: names.map(id => ({ id })), edges };

// reach(f) = {f} ∪ the reach of everything f refers to: backward, so facts flow from callees.
const reach = g.analysis('reach').backward().lattice(g.lattice.powerset())
  .transfer((node, s) => new Set([...s, node.id]));
const facts = g.solve(reach, graph);
const groups = g.graph.scc(graph);

const rows = names.map(f => ({
  function: f, 'refers to': edges.filter(e => e.from === f).map(e => e.to).join(', '),
  reaches: facts.state[f].join(', '),
  'recursive group': (groups.find(c => c.includes(f)) || []).length > 1 ? groups.find(c => c.includes(f)).join(' + ') : '',
  'reachable from main': facts.state.main.includes(f),
}));
print(`reach solved in ${facts.iterations} visits; components: ${groups.map(c => '{' + c.join(', ') + '}').join(' ')}`);
return { program, results: g.table(rows, { title: 'The reference graph, solved' }) };
