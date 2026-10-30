// E-05: admission refuses before any code runs. Each case gives an engine something it
// must not run; each refusal is an AdmissionError with a reason and ranCode: false, and
// the engine's output stays empty. The last case is admitted and run, for contrast.
const engine = g.engine({ strategies: { roots: 'distinct' } });   // this engine requires distinct roots
const cases = [
  ['not a program', () => ({ kind: 'source', text: 'print(1)' })],
  ['does not compile (verifier)', () => g.compile(g.pipeline(), source('broken.ir'))],
  ['does not compile (missing roots)', () => g.compile(g.pipeline().roots('none'), source())],
  ['strategy mismatch (stackReuse)', () => g.compile(g.pipeline(), source())],
  ['admitted (distinct)', () => g.compile(g.pipeline().roots('distinct'), source())],
];
const rows = cases.map(([name, make]) => {
  try {
    const code = engine.admit(make());
    const ev = engine.evaluateScript(code);
    return { case: name, admitted: true, reason: '', ranCode: true, state: ev.state, output: engine.output().join(' | ') };
  } catch (e) {
    return { case: name, admitted: false, reason: `${e.name}: ${e.reason || ''}`, detail: e.message, ranCode: e.ranCode === undefined ? 'not reported' : e.ranCode, output: engine.output().join(' | ') || '(empty)' };
  }
});
const program = g.compile(g.pipeline().roots('distinct'), source());
return { program, results: g.table(rows, { title: 'What admission refuses' }) };
