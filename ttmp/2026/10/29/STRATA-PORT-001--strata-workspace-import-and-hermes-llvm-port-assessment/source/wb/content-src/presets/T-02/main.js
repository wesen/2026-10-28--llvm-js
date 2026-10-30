// T-02: dead code that is not dead. naive-dce erases every operation whose result is unused,
// with no side condition. It deletes the getter call below, and the output changes. The law
// g.law.refines compares each program against the specification and finds the bug twice:
// on program.js, and on generated programs with no help from us.
const naive = g.pipeline().rewrites(g.rewrites.canonical().with(g.rewrites.naiveDce));
const program = g.compile(naive, source());
const honest = g.compile(g.pipeline(), source());
print('canonical:          ' + honest.run().output.join(' / '));
print('canonical + naive:  ' + program.run().output.join(' / '));

return {
  program,
  laws: g.laws([
    g.law.refines(g.rewrites.naiveDce, { corpus: [source()] }),
    g.law.refines(g.rewrites.naiveDce, { samples: 40, seed: 1 }),     // generated programs, shrunk
    g.law.refines(g.rewrites.eraseDead, { corpus: [source()], samples: 40, seed: 1 }),
  ]),
};
