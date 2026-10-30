// T-07: pipelines as values. Every method returns a new pipeline and leaves the old one alone,
// so a variant is a branch, not an edit. A preset is a function pipeline → pipeline, applied
// with use(). Hashes identify configurations; summary() shows every resolved default.
const base = g.pipeline();
const before = base.hash();

const optimised = p => p.rewrites(g.rewrites.standard());          // presets are plain functions
const lean = p => p.roots('stackReuse');
const spacious = p => p.roots('distinct');

const variants = {
  base,
  'base.roots(distinct)': base.roots('distinct'),
  'use(optimised)': base.use(optimised),
  'use(optimised, spacious)': base.use(optimised, spacious),
  'use(optimised, lean)': base.use(optimised, lean),
  'with(p => p.roots(arena))': base.with(p => p.roots('arena')),
  "set('note', 'x')": base.set('note', 'x'),
};

const rows = Object.entries(variants).map(([name, p]) => {
  const s = p.summary(), prog = g.compile(p, source());
  return { pipeline: name, hash: p.hash().slice(0, 8), roots: s.strategies.roots, rewrites: s.rewrites.split(', ').length + ' rules',
    'root slots': prog.metrics().rootSlots, ops: prog.metrics().ops, output: prog.run().output.join(' / ') };
});
print(`base.hash() before and after making the variants: ${before.slice(0, 8)} ${base.hash().slice(0, 8)}`);
print(`lean is the default, so use(optimised, lean) hashes like use(optimised): ${base.use(optimised, lean).hash() === base.use(optimised).hash()}`);
return { program: g.compile(base.use(optimised), source()), results: g.table(rows, { title: 'Seven pipelines, one source' }) };
