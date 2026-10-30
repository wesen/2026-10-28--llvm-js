// 24 · A mutable captured cell shared with a dynamic closure and eval
//
// Model: comparison example 3. A `let` binding captured by a closure and
// reached by direct eval is a cell, not a value. Native code reads and writes
// the cell through js.function cell operations; eval source is compiled by a
// different provider (Hermes bytecode) that must share the same cell. The
// contract of direct eval says it may write any cell its scope can name, so
// no native code may cache the binding across it.
//
// Notice: the variable `n` and the storage cell are different things in the
// IR; a load-forwarding rewrite is blocked exactly at the eval; the provider
// contract for js.dynamic names "shares binding cells" as an obligation. The
// function is strict: today's path compiles strict direct eval against the
// native cells and rejects sloppy direct string eval, and so does this one.

import { g } from 'strata'

const src = g.source.text(`
function counter() {
  'use strict';
  let n = 0;
  const inc = () => { n += 1 };
  eval('n += 10');
  inc();
  return n;
}
print(counter());`, { name: 'cells.js' })

const p = g.compile(g.pipeline(), src)

// The binding is a cell because a closure captures it and eval can name it.
p.ir('L1', { fn: 'counter' })
// → entry:
//     env = js.env.new(parent: closureEnv, slots: [n], evalVisible: true)
//     n_cell = js.env.slot(env, "n")
//     cell.store(n_cell, 0)
//     inc = js.closure(inc_body, env)
//     invoke js.eval.direct(env, "n += 10", context: {strict: true, scope: counter}) normal k1 throw failed
//   k1(r1: any):
//     invoke js.call(inc, undefined) normal k2 throw failed
//   k2(r2: any):
//     r = cell.load(n_cell)
//     return r
//   failed(e: any):
//     throw e

// Contracts of the cell operations and of direct eval.
g.contract.table(['cell.load', 'cell.store', 'js.eval.direct'].map(n => g.ops[n]))
// → op               behaviour                                  obligations
//   cell.load        reads(cells)                               none
//   cell.store       writes(cells)                              writeBarrier
//   js.eval.direct   callsUser, throws, writes(cells in scope)  mayCollect, nonlocalThrow, sharesBindingCells

// A rewrite that forwards a stored value to a later load...
const forward = g.rewrite('forward-store-to-load')
  .match(m => m.op('cell.load', m.any('c')).after(m.op('cell.store', m.same('c'), m.any('v'))))
  .when((m, ctx) => ctx.noWritesBetween('cells', m.store, m.load))
  .to(m => m.replaceWith(m.v))

// ...does not fire across eval or the closure call, and says why.
g.compile(g.pipeline().rewrites(g.rewrites(forward)), src).decisions
  .filter(d => d.rewrite === 'forward-store-to-load')
// → [{ at: 'counter/k2/cell.load(n_cell)', fired: false,
//      because: 'js.eval.direct writes(cells in scope) between store and load; js.call(inc) callsUser' }]

// The dynamic provider shares cells with native code, by contract.
g.hermes.provider('js.dynamic').contract('js.eval.direct').obligations
// → ['mayCollect', 'nonlocalThrow', 'sharesBindingCells: native env slots are the bytecode scope slots']

// The observation, under the specification and in the engine.
g.semantics().profile('js-dynamic').run(p).trace   // → [output(11)]
const engine = await g.engine()
;(await engine.run(p)).output                  // → ['11']
await engine.close()

// Restrictions stay explicit: contexts the current eval path does not support are rejected, not guessed.
g.compile(g.pipeline(), g.source.text(`function f() { let n = 0; eval('n += 10'); return n }`)).diagnostics
// → [{ level: 'error', kind: 'unsupported', feature: 'sloppy direct string eval',
//      note: "add 'use strict' to the function, or use indirect eval" }]
g.compile(g.pipeline(), g.source.text(`class A { #x = 1; m() { return eval('this.#x') } }`)).diagnostics
// → [{ level: 'error', kind: 'unsupported', feature: 'direct eval in class with private names',
//      profile: 'js-dynamic', note: 'recorded restriction; delegate or reject, never approximate' }]
