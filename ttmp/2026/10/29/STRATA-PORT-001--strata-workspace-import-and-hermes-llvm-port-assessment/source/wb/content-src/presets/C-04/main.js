// C-04: the throwing getter. The js.get in load has an unused result, and still may not be
// erased: its contract is callsUser, and user code here prints and throws.
const program = g.compile(g.pipeline(), source());
const site = program.find(op => op.op === 'js.get').find(s => s.fn === 'load');

const p = program.perm(site.id);
print(`${site.id} ${site.text}: result unused ${p.resultUnused}, erase ${p.erase}`);
print('because: ' + p.because.erase.join('; '));
const refused = program.decisions.find(d => d.at === site.id);
print(`decision: ${refused.by} ${refused.fired ? 'fired' : 'refused'}: ${refused.because}`);

// What erasing it anyway would do: the same source with the unsound naive-dce added.
const naive = g.compile(g.pipeline().rewrites(g.rewrites.canonical().with(g.rewrites.naiveDce)), source());
const rows = [
  { pipeline: 'canonical (erase-dead-result asks perm.erase)', output: program.run().output.join(' / ') },
  { pipeline: 'canonical + naive-dce (no side condition)', output: naive.run().output.join(' / ') },
];
return { program, results: g.table(rows, { title: 'The getter, with and without its contract' }) };
