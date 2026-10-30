// 20 · Quick start: zero config, a preset, a tweak, a lambda
//
// Model: three calls compile and run a program with every default visible.
// From there each step adds one level of control: a preset (a function from
// pipeline to pipeline), a parameter tweak, a named strategy, and finally a
// lambda that wraps the default. Nothing is mutated; every line produces a new
// pipeline value that can be compared with the previous one.
//
// Notice: summary() is how you learn what the defaults are; diff() shows
// exactly what a tweak changed; `run` is explicit about pumping jobs.

import { g, jobs } from 'strata'

const src = g.source.text(`
function sum(a, b) { return a + b }
print(sum(1, 2), sum('1', 2))`)

// 1. Zero configuration.
const program = g.compile(g.pipeline(), src)
program.summary()
// → profile:      js-sync + js-async + js-modules (js-dynamic delegated to Hermes bytecode)
//   frontend:     hermes (import before lowering), optimize: false
//   providers:    core=reference, js.*=hermes
//   ordering:     ordered blocks + contracts
//   analyses:     liveness, safepoints, behaviour, type facts (product solver)
//   rewrites:     canonical
//   strategies:   representation=tagged roots=stackReuse exceptions=setjmp suspension=hermes calls=hermesNative
//   materializer: llvm.orc host64, textual IR
//   checks:       verify at every level
//   functions: 2, ops: 14, diagnostics: 0

const engine = await g.engine()
const result = await engine.run(program, { budget: jobs(100) })   // admit + evaluate + one bounded job pump
result                                         // → { state: 'fulfilled', output: ['3 12'], jobsRun: 0 }

// 2. A preset: more checks and dumps while learning.
const learning = g.pipeline().use(g.preset.debug)
g.diff(g.pipeline(), learning)
// → checks: + interpret-vs-hermes (L0→L1), + translation-validation (L1→L2), + forced-gc (tests)
//   dumps:  + every level as text

// 3. A tweak: one slot's parameters.
const distinct = learning.roots({ reuse: false })
g.diff(learning, distinct)                     // → roots: stackReuse → distinct

// 4. A named strategy from the library.
const arena = learning.roots('arena')

// 5. A lambda that wraps the default for one function only.
const custom = learning.roots((fn, ctx) => fn.name === 'sum' ? g.roots.distinct() : ctx.default)   // returns a strategy
g.compile(custom, src).plan('sum').strategy    // → 'distinct (by lambda)'

// 6. The raw escape hatch, visible in the summary like everything else.
const raw = custom.set('llvm.optLevel', 2)
raw.summary().raw                              // → { 'llvm.optLevel': 2 }

// Each pipeline is a value: it can be stored, hashed and compared.
const all = [g.pipeline(), learning, distinct, arena, custom, raw].map(p => p.hash().slice(0, 6))
// → ['9c2e41', '3a7f0b', 'd1e9c2', '77b0aa', '0f4c19', 'e2d830']

await engine.close()
