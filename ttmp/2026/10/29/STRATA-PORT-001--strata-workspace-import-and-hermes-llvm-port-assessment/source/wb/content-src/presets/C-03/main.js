// C-03: derived permissions. Nothing declares that an operation may be erased, merged,
// moved, duplicated, hoisted or speculated: g.perm derives each answer from the behaviour,
// as true, false or a condition, with the reasons.
const program = g.compile(g.pipeline(), source());

const ops = ['num.add', 'js.strict_eq', 'cell.load', 'js.get_own_data', 'cell.store', 'obj.new',
  'cell.load_checked', 'host.print', 'js.get'];
const rows = ops.map(op => {
  const p = g.perm(op);
  return { op, behaviour: String(g.ops[op].behaviour), erase: String(p.erase), merge: String(p.merge), move: String(p.move),
    duplicate: String(p.duplicate), hoist: String(p.hoist), speculate: String(p.speculate) };
});

// One answer with its reasons, and the same question asked of a real site in the program.
print('cell.load, hoist:', JSON.stringify(g.perm.explain('cell.load', 'hoist')));
print('obj.new, erase:', JSON.stringify(g.perm.explain('obj.new', 'erase')));
return { program, results: g.table(rows, { title: 'Permissions derived from behaviour' }) };
