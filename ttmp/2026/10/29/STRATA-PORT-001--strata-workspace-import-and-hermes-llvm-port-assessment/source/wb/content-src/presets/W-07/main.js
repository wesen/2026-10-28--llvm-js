// W-07: the structural checker. g.llvm.check(text, declarations) reads LLVM IR text and
// reports labels defined twice, blocks without a terminator, locals used before they are
// defined, branches to unknown labels and calls to undeclared functions. It does not run
// the code and does not know what the code means.
const program = g.compile(g.pipeline(), source());
const module = program.ir('LLVM');
const decls = module.split('\n').filter(l => l.startsWith('declare '));
const fn = module.slice(module.indexOf('define internal i64 @readBoth'), module.indexOf('}\n', module.indexOf('define internal i64 @readBoth')) + 1);

// The store that opens the handler catch1: outside every protected region the state is 0.
const RESET_IN_CATCH1 = 'b.catch1:\n  store volatile i32 0, ptr %try_state, align 4    ; not protected: a throw unwinds to the caller\n';

// Each case breaks the text of readBoth in one way.
const cases = [
  ['as emitted', fn],
  ['rethrow without unreachable', fn.replace('  unreachable\n', '')],
  ['an undeclared helper', fn.replace('@shllvm_env_load', '@shllvm_env_peek')],
  ['a local never defined', fn.replace('ret i64 %t0', 'ret i64 %t99')],
  ['a branch to a missing label', fn.replace('br label %b.endtry5', 'br label %b.endtry7')],
  ['a value from a block that does not dominate', fn.replace('ptr %s2, ptr %r.value8)', 'ptr %s2, ptr %t0)')],
  ['catch1 without its try_state reset', fn.replace(RESET_IN_CATCH1, 'b.catch1:\n')],
];
if (!fn.includes(RESET_IN_CATCH1)) throw new Error('the emitted text no longer starts catch1 with the reset store');
const rows = cases.map(([name, text]) => {
  const r = g.llvm.check(text, decls);
  return { case: name, ok: r.ok, errors: r.errors.length, first: r.errors[0] ? r.errors[0].message : '' };
});
return { program, results: g.table(rows, { title: 'What the structural checker sees' }) };
