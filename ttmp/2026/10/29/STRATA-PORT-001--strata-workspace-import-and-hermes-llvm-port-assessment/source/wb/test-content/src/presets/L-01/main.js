// Test fixture: a plan without roots, plus a law report and a results table written as literals
// (so the fixture runs on the stub and on the real engine alike).
const program = g.compile(g.pipeline({ roots: 'none' }), source());
const laws = { kind: 'laws', laws: [
  { name: 'promote-cells refines the cell program', ok: true, samples: 200, note: 'generated core IR, depth 4' },
  { name: 'the plan roots every object live across a safepoint', ok: false, samples: 37,
    counterexample: 'fn f() {\n  entry():\n    v1 = box.alloc 1\n    v2 = box.alloc 2\n    v3 = box.get v1\n    return v3\n}',
    minimized: 'v1 live across box.alloc 2 without a root', note: 'strategy none' },
] };
const results = { kind: 'results', title: 'Root strategies on total(4)', columns: [{ key: 'strategy', label: 'strategy' }, { key: 'slots', label: 'root slots', unit: 'slots' }, { key: 'bytes', label: 'frame', unit: 'bytes' }, { key: 'stale', label: 'stale uses', unit: 'count' }],
  rows: [{ strategy: 'distinct', slots: 2, bytes: 32, stale: 0 }, { strategy: 'stackReuse', slots: 1, bytes: 24, stale: 0 }, { strategy: 'none', slots: 0, bytes: 16, stale: 4 }], best: 1, note: 'fixture numbers, not measured' };
return { program, laws, results };
