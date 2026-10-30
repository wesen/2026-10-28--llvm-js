// 28 · A small non-JavaScript language on the same core
//
// Model: the core IR, the analyses, lowering and LLVM materialization know
// nothing about JavaScript, so a different frontend can reuse them. Here a
// tiny integer "world" language (like the PicoCalc RV32 proof of concept)
// produces core IR directly, uses only `core` and its own `i32` operation set,
// needs no Hermes at all, and targets RV32. A relaxed numeric dialect may declare laws
// JavaScript numbers don't have, and that choice is visible.
//
// Notice: the profile admits `core` and `i32` only; the summary shows no Hermes provider; the
// reassociation rewrite refused in example 10 is legal here because the
// dialect's integer add declares wrapping associativity.

import { g } from 'strata'

const { t, fx } = g

// A frontend is anything that produces verified core IR plus source metadata.
const worldFrontend = g.frontend('world-lang', {
  parse: text => g.parsers.sexpr(text),        // (def tick (x) (wrap+ x 1))
  lower: (ast, f) => f.fromSexpr(ast, { ops: { 'wrap+': 'i32.add_wrap', '<': 'i32.lt_s' } }),
})

// A dialect: integer operations with wrapping semantics and the laws that come with them.
const i32 = g.opset('i32', { version: '0.1.0' }).ops(
  g.op('i32.add_wrap').operands(t.int32, t.int32).results(t.int32).behaviour(fx.none)
    .step((s, [a, b]) => (a + b) | 0)
    .laws({ commutative: true, associative: true }),   // true for wrapping two's-complement addition
  g.op('i32.lt_s').operands(t.int32, t.int32).results(t.boolean).behaviour(fx.none)
    .step((s, [a, b]) => a < b),
)
g.law.declared(i32)                            // → { ok: true }: each declared law tested on its step function

const worldProfile = g.profile.define('world', { admits: ['core', 'i32'], observes: ['output', 'outcome'] })

const world = g.pipeline()
  .profile(worldProfile)
  .frontend(worldFrontend)
  .provide('i32', g.reference.provider('i32')) // reference steps lowered to plain LLVM instructions
  .representation('unboxWhenProven')           // everything is int32: no tagged values at all
  .rewrites(g.rewrites(g.rewrites.canonical(), g.rewrites.reassociate({ when: op => op.laws.associative })))
  .materialize(g.llvm.aot({ target: g.target.riscv32, output: 'world.elf', freestanding: true }))

world.summary().providers                      // → { core: 'reference', i32: 'reference' }   (no Hermes)
world.summary().strategies.roots               // → 'none needed: no managed values in profile world'

const src = g.source.text(`(def tick (x) (wrap+ (wrap+ x 1) 2))`, { name: 'tick.world' })
const p = g.compile(world, src)
p.ir('L1', { fn: 'tick' })
// → fn tick(x: int32) -> int32 {
//   entry:
//     a = i32.add_wrap(x, 3)        reassociated and folded: allowed, the dialect declares associativity
//     return a
//   }
p.ir('L4', { format: 'llvm', fn: 'tick' })     // → define i32 @tick(i32 %x) { %a = add i32 %x, 3  ret i32 %a }

// The same specification checks it: the interpreter runs core IR without any JS provider.
g.semantics().profile(worldProfile).run(p, { fn: 'tick', args: [2147483646] }).outcome
// → normal(-2147483647)   (wrapping)

// Mixing dialects is explicit: JS numbers never pick up these laws.
g.pipeline().provide('i32', g.reference.provider('i32')).check()
// → { ok: true, note: "i32 ops appear only where a frontend emits them; js.add never narrows to i32.add_wrap" }
