// S-04: the temporal dead zone. A let or const binding exists from the start of its scope but
// holds no value until its declaration runs; reading it earlier throws a ReferenceError.
const program = g.compile(g.pipeline(), source('program.js'));

// Which loads must check for "not initialised yet"? The frontend decides, per read.
for (const site of program.find(op => op.op === 'cell.load_checked')) print('checked:', site.id, site.text);
for (const site of program.find(op => op.op === 'cell.load')) print('unchecked:', site.id, site.text);
return program;
