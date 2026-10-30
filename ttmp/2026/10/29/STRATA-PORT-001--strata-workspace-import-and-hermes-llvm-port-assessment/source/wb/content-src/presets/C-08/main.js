// C-08: providers and operation sets. Operations come in sets (core, js.value, js.object,
// js.function, js.control); a provider implements a set. By default Hermes provides the four
// JavaScript sets and the workbench's reference implementation provides core. Some strategies
// only work with some providers, and pipeline.check() says so before anything compiles.
for (const [name, set] of Object.entries(g.opsets).filter(([k]) => k.includes('.') || k === 'core'))
  print(`${name}: ${set.size} operations (${set.names().slice(0, 4).join(', ')}, …)`);

const reference = { 'js.value': 'reference', 'js.object': 'reference', 'js.function': 'reference', 'js.control': 'reference' };
const configs = {
  'default (Hermes, setjmp)': g.pipeline(),
  'statusReturn, Hermes helpers': g.pipeline().exceptions('statusReturn'),
  'statusReturn, reference helpers': g.pipeline().exceptions('statusReturn').provide(reference),
  'arena roots, statusReturn, reference': g.pipeline().roots('arena').exceptions('statusReturn').provide(reference),
};
const rows = Object.entries(configs).map(([name, p]) => {
  const c = p.check(), s = p.summary();
  return { pipeline: name, 'js.value by': s.providers['js.value'], exceptions: s.strategies.exceptions, check: c.ok ? 'ok' : 'refused',
    because: c.ok ? '' : c.diagnostics.map(d => d.message).join(' ') };
});

const program = g.compile(configs['statusReturn, reference helpers'], source());
return { program, results: g.table(rows, { title: 'Strategies, providers and pipeline.check()' }) };
