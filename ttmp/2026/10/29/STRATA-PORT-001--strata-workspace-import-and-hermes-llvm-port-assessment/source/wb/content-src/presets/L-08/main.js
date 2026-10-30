// L-08: unwinding with setjmp. The protected block of risky has an exceptional exit to
// its catch block. With the setjmp strategy (Hermes's protocol) the function saves a
// jump buffer once, records in try_state which region it is in, and a helper that throws
// long-jumps back to the dispatch, which goes to the handler for the current state.
const program = g.compile(g.pipeline(), source());

// What each strategy says a catch must restore.
const rows = ['stackReuse', 'arena'].map(roots => {
  const p = g.compile(g.pipeline().roots(roots), source());
  const u = p.plan('risky').unwind[0];
  return { roots, at: u.at, handler: u.handler, exceptions: u.strategy, restores: u.restores.join(', '),
    output: p.run({ mode: 'plan', gc: 'stress' }).output.join(' / ') };
});
return { program, results: g.table(rows, { title: 'Unwinding plans for risky' }) };
