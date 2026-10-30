// E-03: timers in virtual time. setTimeout(f, ms) records f with a due time on a virtual
// clock that starts at 0. When the script and every microtask are done, the engine moves
// the clock to the earliest due timer (ties in the order they were set) and runs it; then
// it empties the microtask queue again before the next timer.
const program = g.compile(g.pipeline(), source());
const run = program.run();
for (const e of run.events.filter(e => e.type === 'timer')) print(`step ${e.n}: ${e.what} ${e.what === 'set' ? 'due at' : 'at'} ${e.at} ms`);
return program;
