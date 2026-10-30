// A-08: safepoints and live-across. A safepoint is an operation that may collect. Liveness
// says which values are live across it (needed afterwards); the helper also borrows its
// managed operands. Values of managed types in either set need a root slot there.
const program = g.compile(g.pipeline(), source());
const fn = 'describe', plan = program.plan(fn), facts = program.facts(fn);
const slotOf = Object.fromEntries(plan.slots.flatMap(s => s.values.map(v => [v, s.slot])));
const typeOf = v => String(facts.types && facts.types[v] !== undefined ? facts.types[v] : '?');

const rows = Object.entries(plan.safepoints).map(([id, sp]) => {
  const op = program.cfg(fn).blocks.flatMap(b => b.ops).find(o => o.id === id);
  const borrowed = op.args.filter(a => !/^"|^\d|^undefined$|^null$|^true$|^false$/.test(a));
  return {
    safepoint: id, op: op.text,
    'live across': sp.live.map(v => `${v}: ${typeOf(v)}`).join(', ') || '∅',
    borrowed: borrowed.join(', ') || '∅',
    rooted: sp.rooted.map(v => `${v} → s${slotOf[v]}`).join(', ') || 'nothing',
  };
});
print(`describe: ${plan.rootSlots} root slots, frame ${plan.frameSlots} slots (${plan.frameBytes} B), peak ${plan.peakLive} values needed at once`);
return { program, results: g.table(rows, { title: 'Safepoints in describe: what is live, borrowed and rooted' }) };
