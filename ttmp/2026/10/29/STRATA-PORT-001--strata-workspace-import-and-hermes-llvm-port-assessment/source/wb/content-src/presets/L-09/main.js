// L-09: exception strategies and compatibility. A root strategy and an exception strategy
// must agree on what a catch restores, so the pipeline only accepts declared pairs.
// statusReturn also needs helpers that return an error status instead of long-jumping,
// which Hermes's helpers do not do: it is refused while Hermes provides the JS sets.
const rows = [];
for (const r of ['distinct', 'stackReuse', 'arena']) {
  for (const e of ['setjmp', 'statusReturn', 'landingPads']) {
    const c = g.compat(g.roots[r](), g.exceptions[e]());
    rows.push({ roots: r, exceptions: e, declared: c.ok === true ? 'yes' : 'no', requires: c.requires || '', evidence: c.evidence || c.reason || '' });
  }
}

// The same request with two sets of providers.
const ours = { 'js.value': 'reference', 'js.object': 'reference', 'js.function': 'reference', 'js.control': 'reference' };
const withHermes = g.pipeline().exceptions('statusReturn').check();
const withOurs = g.pipeline().exceptions('statusReturn').provide(ours).check();
print('statusReturn with Hermes helpers: ' + (withHermes.ok ? 'ok' : withHermes.diagnostics[0].message));
print('statusReturn with reference helpers: ' + (withOurs.ok ? 'ok' : withOurs.diagnostics[0].message));

const program = g.compile(g.pipeline().exceptions('statusReturn').provide(ours), source());
return { program, results: g.table(rows, { title: 'Declared pairs of root and exception strategies' }) };
