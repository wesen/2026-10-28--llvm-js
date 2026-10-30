// A-03: type facts and branch refinement. Type facts are a forward analysis over the type
// lattice. A branch on typeof (or core.is_number) refines the tested value on each edge, so
// the same x has different types in different blocks. The standard rewrites use the facts.
const program = g.compile(g.pipeline().rewrites(g.rewrites.standard()), source());
const fn = program.module.fn('label');
const facts = g.solve(g.analysis.typeFacts, fn);

// The type of x on entry to each block, and of the block's parameters.
const rows = fn.blocks.map(b => ({
  block: b.name, x: String(facts.inBlock(b.name, 'x')),
  parameters: b.params.map(p => `${p.id}: ${facts.inBlock(b.name, p.id)}`).join(', ') || '',
}));
print(`types solved in ${facts.iterations} block visits`);
return { program, results: g.table(rows, { title: 'What the facts know about x, block by block' }) };
