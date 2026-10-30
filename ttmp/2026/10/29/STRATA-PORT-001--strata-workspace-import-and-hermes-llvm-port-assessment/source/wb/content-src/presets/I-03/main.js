// I-03: loops and block arguments. The frontend lowers each loop to a header block; after
// promote-cells, every variable the loop changes is a parameter of that header.
const program = g.compile(g.pipeline(), source('program.js'));

// List the blocks that have parameters: these are the loop headers (and merges).
for (const fn of ['gcd', 'triangle']) {
  for (const b of program.cfg(fn).blocks) if (b.params.length) print(`${fn}/${b.name}(${b.params.map(p => p.id).join(', ')})`);
}
return program;
