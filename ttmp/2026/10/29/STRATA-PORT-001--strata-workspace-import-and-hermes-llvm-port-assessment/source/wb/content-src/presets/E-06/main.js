// E-06: lifecycles as labelled transition systems. A runtime and the code it runs are two
// machines that synchronise on the labels they share. The product of the machines is
// searched breadth-first for a state that breaks an invariant.
const runtime = g.machine('runtime')
  .state('alive').on('call', 'alive').on('destroy', 'dead');
const code = g.machine('code')
  .state('loaded').on('call', 'loaded').on('release', 'freed')
  .state('freed').on('call', 'crash');

// 1. Nothing orders release and destroy: search finds a call into freed code.
const unordered = g.machine.product(runtime, code)
  .invariant('no call after free', s => s.code !== 'crash');

// 2. A host that tears down in order: destroy the runtime first, then release the code.
const host = g.machine('host')
  .state('running').on('destroy', 'stopping')
  .state('stopping').on('release', 'done');
const ordered = g.machine.product(runtime, code, host)
  .invariant('no call after free', s => s.code !== 'crash');

// 3. A host that tears down in the other order.
const backwards = g.machine('host')
  .state('running').on('release', 'released')
  .state('released').on('destroy', 'done');
const reversed = g.machine.product(runtime, code, backwards)
  .invariant('no call after free', s => s.code !== 'crash');

const asLaw = (name, r) => ({ name, ok: r.ok, samples: r.states,
  counterexample: r.ok ? undefined : r.trace.join('; '), note: r.ok ? `${r.states} states, ${r.transitions} transitions searched` : `violated in state ${JSON.stringify(r.state)}` });
const laws = g.laws([
  asLaw('unordered teardown keeps code alive', g.check.machine(unordered, { depth: 6 })),
  asLaw('ordered teardown keeps code alive', g.check.machine(ordered, { depth: 6 })),
  asLaw('release before destroy keeps code alive', g.check.machine(reversed, { depth: 6 })),
]);

const program = g.compile(g.pipeline(), source());
return { program, laws };
