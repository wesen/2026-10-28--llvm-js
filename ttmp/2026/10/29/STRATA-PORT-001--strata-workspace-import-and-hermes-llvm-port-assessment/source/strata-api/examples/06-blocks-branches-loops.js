// 06 · Core IR: blocks, branches, merges and loops
//
// Model: a function is a graph of blocks. Each block has parameters, a list of
// operations and exactly one terminator. Values flow into a block only as
// arguments on an edge, so merges and loop-carried values are block
// parameters instead of phi nodes. One verifier checks dominance, edge arity
// and types, and terminators. This file covers comparison examples 1 (scalar
// branch and merge) and 2 (loop with block arguments) from doc 03.
//
// Notice: forward block references resolve when the function is finished; the
// loop's swap needs simultaneous edge transfer; invalid graphs come back as
// data that names the rule and the path.

import { g } from 'strata'

const { t } = g

// Comparison example 1: scalar branch and merge.
//   function choose(c) { return c ? 10 : 20 }
const choose = g.fn('choose', { c: t.boolean }, t.number, (f, { c }) => {
  f.entry($ => $.branch(c, f.to('left'), f.to('right')))
  f.block('left', {}, $ => $.jump(f.to('join', $.const(10))))
  f.block('right', {}, $ => $.jump(f.to('join', $.const(20))))
  f.block('join', { v: t.number }, ($, { v }) => $.ret(v))
})

g.verify(choose)                               // → { ok: true }
g.ir.text(choose)
// → fn choose(c: boolean) -> number {
//   entry:
//     branch c, left(), right()
//   left():
//     jump join(10)
//   right():
//     jump join(20)
//   join(v: number):
//     return v
//   }

// Comparison example 2: a loop whose carried values swap on every iteration.
//   function fib(n) { let a = 0, b = 1; for (let i = 0; i < n; i++) [a, b] = [b, a + b]; return a }
// The counter is a number, not an int32: num.add returns number, and the verifier checks edge types.
const fib = g.fn('fib', { n: t.number }, t.number, (f, { n }) => {
  f.entry($ => $.jump(f.to('head', $.const(0), $.const(0), $.const(1))))
  f.block('head', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.branch($.op('num.lt', i, n), f.to('body', i, a, b), f.to('exit', a)))
  f.block('body', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.jump(f.to('head', $.op('num.add', i, $.const(1)), b, $.op('num.add', a, b))))
  f.block('exit', { r: t.number }, ($, { r }) => $.ret(r))
})

g.verify(fib)                                  // → { ok: true }
g.semantics().run(fib, { args: [10] }).outcome // → normal(55)

// The edge body→head passes (i+1, b, a+b): head.a receives the *old* b.
// Any lowering that shares storage must read every incoming value before writing any.
const edge = g.lower.edges(fib, { storage: 'shared-slots' }).edge('body→head')
// → { reads: ['i+1', 'b', 'a+b'], writes: ['head.i', 'head.b', 'head.a'],
//     order: 'head.b ← a+b is computed before head.a ← b overwrites a', temporaries: 0 }
// A true swap needs one temporary: the edge (b, a) into (a, b) is a copy cycle.
g.lower.edges(g.ir.parse(`fn swap(a: number, b: number) -> number {\nentry:\n  jump loop(a, b)\nloop(x: number, y: number):\n  jump loop(y, x)\n}`))
  .edge('loop→loop')                           // → { cycle: ['x', 'y'], temporaries: 1 }
g.law.parallelTransfer(g.lower.edges)          // → { ok: true, samples: 500 } (random swaps and rotations)

// Text form parses to the same graph (useful in tests and diagnostics).
const fromText = g.ir.parse(`
fn choose(c: boolean) -> number {
entry:
  branch c, left(), right()
left():
  jump join(10)
right():
  jump join(20)
join(v: number):
  return v
}`)
fromText.hash() === choose.hash()              // → true
g.law.alphaRenaming(g.semantics())             // → { ok: true }: renaming local ids never changes behaviour

// Invalid graph 1: an edge passes the wrong number of arguments.
const arity = g.fn('arity', { c: t.boolean }, t.number, (f, { c }) => {
  f.entry($ => $.branch(c, f.to('left'), f.to('join')))
  f.block('left', {}, $ => $.jump(f.to('join', $.const(1))))
  f.block('join', { v: t.number }, ($, { v }) => $.ret(v))
})
g.verify(arity)
// → { ok: false, diagnostics: [{ rule: 'edge-arity', edge: 'entry→join', expected: 1, got: 0 }] }

// Invalid graph 2: a use that its definition does not dominate.
const notDominated = g.ir.parse(`
fn f(c: boolean) -> number {
entry:
  branch c, left(), right()
left():
  x = core.const(1)
  jump join()
right():
  jump join()
join():
  return x
}`)
g.verify(notDominated)
// → { ok: false, diagnostics: [{ rule: 'dominance', value: 'x', definedIn: 'left', usedIn: 'join',
//                               counterPath: 'entry → right → join' }] }

// Invalid graph 3: a block without a terminator.
g.verify(g.ir.parse(`fn g() -> number {\nentry:\n  x = core.const(1)\n}`))
// → { ok: false, diagnostics: [{ rule: 'terminator', block: 'entry', found: 0, expected: 1 }] }
