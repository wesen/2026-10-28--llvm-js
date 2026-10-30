// S-02: what counts as the same. Each pair below prints the same characters; observe.equal
// compares the observations themselves: printed values by SameValue, objects up to a renaming.
const pairs = [
  ['-0 against 0', 'print(0 * -1);', 'print(0);'],
  ['NaN against NaN', 'print(0 / 0);', 'print(NaN);'],
  ['one object twice against two objects', 'const a = {}; print(a, a);', 'print({}, {});'],
  ['objects made in another order', 'const x = {}; const y = {}; print(y); print(x);', 'const y = {}; const x = {}; print(y); print(x);'],
  ['a string against a number', 'print("1");', 'print(1);'],
  ['a throw against a print', 'throw new Error("stop");', 'print("Error: stop");'],
];

const rows = pairs.map(([what, left, right]) => {
  const l = g.compile(g.pipeline(), left).run(), r = g.compile(g.pipeline(), right).run();
  const eq = g.observe.equal(l, r);
  return { what, left: l.output.join(' / ') || `(${l.outcome.kind} ${l.outcome.display})`, right: r.output.join(' / ') || `(${r.outcome.kind} ${r.outcome.display})`,
    equal: eq.equal, rule: eq.rule || '' };
});

const program = g.compile(g.pipeline(), source('program.js'));
return { program, results: g.table(rows, { title: 'Same text, same behaviour?' }) };
