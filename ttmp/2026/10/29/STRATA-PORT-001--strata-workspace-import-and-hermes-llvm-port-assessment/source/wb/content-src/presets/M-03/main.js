// M-03: shrinking a counterexample. The generator's seed-1 program breaks naive DCE, but it has
// nine statements; most of them are noise. g.shrink(items, fails) deletes one item at a time
// and keeps a deletion whenever the failure survives, until no single deletion does.
const generated = g.gen.js({ seed: 1 });
const reference = g.pipeline();
const broken = g.pipeline().rewrites(g.rewrites.canonical().with(g.rewrites.naiveDce));
const runBoth = statements => {
  const src = g.gen.fromStatements(statements);
  return { before: g.compile(reference, src).run(), after: g.compile(broken, src).run() };
};

// Predicate 1: "the two runs differ". Anything that differs counts, including a program
// that now fails for a reason of its own.
let calls1 = 0;
const differs = statements => { calls1++; const { before, after } = runBoth(statements); return before.outcome.kind !== 'error' && g.observe.equal(before, after).equal !== true; };
// Predicate 2: "the reference run finishes normally and the runs differ": the same failure.
let calls2 = 0;
const sameFailure = statements => { calls2++; const { before, after } = runBoth(statements); return before.outcome.kind === 'normal' && g.observe.equal(before, after).equal !== true; };

const loose = g.shrink(generated.statements, differs);
const strict = g.shrink(generated.statements, sameFailure);

const describe = (label, statements, calls) => {
  const { before, after } = runBoth(statements);
  return { predicate: label, statements: statements.length, tried: calls, before: before.output.join(' / ') + (before.outcome.kind === 'throw' ? ' (throws ' + before.outcome.display + ')' : ''),
    after: after.output.join(' / ') + (after.outcome.kind === 'throw' ? ' (throws ' + after.outcome.display + ')' : '') };
};
const rows = [describe('none (the generated program)', generated.statements, 0), describe('runs differ', loose, calls1), describe('same failure', strict, calls2)];
print('strict result:\n' + strict.join('\n'));

// The program on the Stage is the strict counterexample, compiled with the broken rewrite.
const program = g.compile(broken, g.gen.fromStatements(strict));
return { program, results: g.table(rows, { title: 'Shrinking the naive-DCE counterexample', columns: [
  { key: 'predicate', label: 'shrunk while' }, { key: 'statements', label: 'statements' }, { key: 'tried', label: 'predicate calls' },
  { key: 'before', label: 'reference output' }, { key: 'after', label: 'with naive DCE' }] }) };
