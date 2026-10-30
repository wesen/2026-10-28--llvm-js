// B-02: one default at a time. Each line below makes a new pipeline from the one before;
// nothing is changed in place, so all four can be compiled and compared.
const src = source('program.js');

// 1. Zero configuration: every slot takes its default.
const base = g.pipeline();

// 2. Partial parameters for one slot: roots, but without slot sharing.
const tweaked = base.roots({ reuse: false });

// 3. A named library strategy for another slot: the standard rewrite set adds narrowing.
const named = tweaked.rewrites(g.rewrites.standard());

// 4. A lambda that wraps the default: plan roots the default way, then report what it did.
const wrapped = named.roots((fn, ctx) => {
  const plan = ctx.default();                 // the plan the wrapped strategy would make
  print(`${fn.name}: ${plan.rootSlots} root slots`);
  return plan;
});

const steps = [['zero config', base], ['roots { reuse: false }', tweaked], ['+ rewrites.standard()', named], ['+ roots lambda', wrapped]];
const programs = steps.map(([, pipe]) => g.compile(pipe, src));
const rows = programs.map((p, i) => {
  const m = p.metrics(), s = p.summary();
  return { step: steps[i][0], roots: s.strategies.roots, rewriteSet: s.rewrites.split(', ').length, ops: m.ops,
    rootSlots: m.rootSlots, rewritesFired: m.rewritesFired, output: p.run().output.join(' / ') };
});

// The last program goes to the views; the table goes to Experiments.
return { program: programs[3], results: g.table(rows, { title: 'One default at a time' }) };
