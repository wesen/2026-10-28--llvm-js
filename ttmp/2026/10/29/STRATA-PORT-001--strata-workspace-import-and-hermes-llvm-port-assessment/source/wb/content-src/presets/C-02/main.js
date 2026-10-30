// C-02: obligations. A behaviour says what an operation may do; its obligations say what
// lowering must provide around it. This script lists every operation that has any, with
// what the root plan (L3) rooted there and where a throw from it goes.
const program = g.compile(g.pipeline(), source());
print('mayCollect: root slots for the managed values it borrows or that live across it');
print('nonlocalThrow: a path for an exception to leave by (a handler, or unwinding to the caller)');
print('writeBarrier: a barrier call, so a generational collector sees the new reference');

const rows = [];
for (const name of program.functions()) {
  const plan = program.plan(name), cfg = program.cfg(name);
  for (const block of cfg.blocks) for (const op of block.ops) {
    const ob = String(g.ops[op.op].obligations);
    if (ob === 'none') continue;
    const sp = plan.safepoints[op.id];
    rows.push({
      op: op.id, text: op.text, obligations: ob,
      rooted: sp ? (sp.rooted.join(', ') || 'nothing') : 'not a safepoint',
      'a throw goes to': ob.includes('nonlocalThrow') ? block.onThrow : '',
    });
  }
}
return { program, results: g.table(rows, { title: 'Obligations, and what the plan did about them' }) };
