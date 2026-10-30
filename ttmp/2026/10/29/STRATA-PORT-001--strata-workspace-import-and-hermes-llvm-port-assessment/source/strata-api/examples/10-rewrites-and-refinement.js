// 10 · Rewrites, side conditions and refinement
//
// Model: a rewrite matches a pattern, checks a side condition and builds a
// replacement. Side conditions read derived permissions and facts; they never
// re-declare what an operation does. A rewrite is correct when its output
// refines its input for the profile (Law 1). Laws find counterexamples; a
// counterexample is kept as a minimized fixture.
//
// Notice: dead-result elimination does not fire on the throwing getter, and
// the version without a side condition is caught by the refinement law with
// a three-line counterexample.

import { g } from 'strata'

// Erase an operation whose result is unused, when its contract permits it.
const eraseDead = g.rewrite('erase-dead-result')
  .match(m => m.op('*').resultUnused())
  .when((m, ctx) => ctx.perm(m.op).erase)
  .to(m => m.erase())

// Hoist a loop-invariant operation, when permitted and facts say it's invariant.
const hoist = g.rewrite('hoist-invariant')
  .match(m => m.op('*').inLoop())
  .when((m, ctx) => ctx.perm(m.op).hoist && ctx.facts.loopInvariant(m.op))
  .to(m => m.moveTo(m.loop.preheader))

// Narrow a general operation to a variant its facts justify.
const narrow = g.rewrite('narrow-by-facts')
  .match(m => m.op('*').hasVariants())
  .when((m, ctx) => ctx.variantFor(m.op) !== null)
  .to((m, ctx) => m.replaceOp(ctx.variantFor(m.op)))

const getterSrc = g.source.text(`
let cell = {n: 0};
const receiver = { get x() { cell.n += 1; throw cell; } };
try { receiver.x; } catch (caught) { print(caught === cell, cell.n); }`)

const base = g.pipeline().rewrites(g.rewrites(narrow, eraseDead, hoist))
const p = g.compile(base, getterSrc)
p.decisions.filter(d => d.rewrite === 'erase-dead-result')
// → [{ at: 'main/entry/js.get(receiver, "x")', fired: false,
//      because: 'perm.erase = false: behaviour includes throws, callsUser' }]

// The unsound version, without a side condition.
const naiveDce = g.rewrite('naive-dce')
  .match(m => m.op('*').resultUnused())
  .to(m => m.erase())

g.law.refines(naiveDce, { corpus: g.corpus.five(), profile: 'js-sync' })
// → { ok: false,
//     counterexample: { source: 'throwing getter (minimized)',
//       program: 'const r = { get x() { throw 1 } }; try { r.x } catch (e) { print(e) }',
//       before: [output(1)], after: [] },
//     saved: 'fixtures/naive-dce-throwing-getter.js' }

g.law.refines(eraseDead, { corpus: g.corpus.five(), profile: 'js-sync' })
// → { ok: true, programs: 5, generated: 2000, method: 'interpreter before/after' }

// Canonicalization: a rewrite set run to a fixed point. It must be idempotent.
const canon = g.rewrites.canonical()           // constant folding (exact semantics), block merging, dead blocks
g.law.idempotent(canon)                        // → { ok: true, samples: 1000 }
g.law.terminates(canon)                        // → { ok: true, measure: '(non-constant ops, blocks, edges) decreases lexicographically' }

// Floating point: the library refuses rewrites that need a law the operation does not have.
const reassoc = g.rewrite('reassociate-add')
  .match(m => m.op('num.add', m.op('num.add', m.any('a'), m.any('b')), m.any('c')))
  .to(m => m.build('num.add', m.a, m.build('num.add', m.b, m.c)))
reassoc.check()
// → { ok: false, reason: "num.add declares associative: false; rewrite requires associativity",
//     example: '(1e16 + -1e16) + 1 = 1, but 1e16 + (-1e16 + 1) = 0' }

// Provenance: every rewritten node knows where it came from.
const q = g.compile(base, g.source.text(`function inc(x) { if (typeof x === 'number') return x + 1 }`))
q.lineage('inc/v7')
// → ['v3 js.add (L1, from source 1:53)', 'narrowed to num.add (a variant of js.add) by narrow-by-facts',
//    "fact: x is number, origin guard typeof === 'number' at 1:23"]   (1-based line:column)
