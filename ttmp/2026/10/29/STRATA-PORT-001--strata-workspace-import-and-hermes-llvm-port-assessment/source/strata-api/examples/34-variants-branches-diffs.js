// 34 · Variants, branches and diffs
//
// Model: because pipelines and programs are immutable values, an experiment
// is a branch: `const b = a.roots('arena')`. Diffs work at every level: the
// pipeline configuration, each IR level, the execution plan, the decisions
// made, and the measured run. A diff is the first thing to look at when a
// variant behaves differently: it says which level first diverges.
//
// Notice: the configuration diff is one line while the plan diff is large;
// the semantic levels are identical; decision diffs explain the plan diff.

import { g } from 'strata'

const src = g.corpus.ladder().get('03-loop-carried-swap')        // the fib loop from example 06, as JS
const a = g.pipeline()
const b = a.roots('arena')
const c = a.representation('unboxWhenProven').rewrites(g.rewrites.standard())

// Configuration diffs.
g.diff(a, b)                                   // → roots: stackReuse → arena
g.diff(a, c)                                   // → representation: tagged → unboxWhenProven; rewrites: canonical → standard

// Program diffs, level by level.
const [pa, pb, pc] = [a, b, c].map(p => g.compile(p, src))
g.diff(pa, pb).levels                          // → { L0: 'equal', L1: 'equal', L2: 'equal', L3: 'differs', L4: 'differs' }
g.diff(pa, pc).levels                          // → { L0: 'equal', L1: 'differs', L2: 'differs', L3: 'differs', L4: 'differs' }

// The first differing level, shown as a readable IR diff. From JS source every counter starts as
// any; only the facts pipeline (c) narrows it. (Blocks from JS source declare onThrow: unwind.)
g.diff(pa, pc).at('L1', { fn: 'fib' })
// →   body(i: any, a: any, b: any):
// -     s = js.add(a, b)
// +     s = num.add(a, b)          ; narrow-by-facts: a and b are number (constants, num.add results)
// -     i2 = js.add(i, 1)
// +     i2 = num.add(i, 1)         ; i is number (constant 0, num.add)
//       jump head(i2, b, s)
//   (head still compares with js.lt(i, n): n is an unknown argument, so that call may run user code)

// Plan diffs: what moved, and why. Frame = rooted values + 2 fixed + 1 argument slot.
g.diff(pa, pb).plan('fib')
// → roots:  4 value slots (i, a, b, n) on the native stack → arena offsets 0..3
//   frame:  7 slots · 56 B native → 32 B header + 56 B payload in an arena chunk
//   unwind: checkpoint gains arenaMark
g.diff(pa, pc).plan('fib')
// → roots:  4 value slots → 1 (i, a, b unboxed to f64; n stays tagged and is rooted across js.lt, which borrows it)
//   frame:  7 slots → 4 slots
//   exit:   boxes r from f64 to tagged (exact)

// Decision diffs explain plan diffs.
g.diff(pa, pc).decisions
// → + narrow-by-facts fired at fib/body/js.add ×2 (fact number, origin: constants and num.add)
//   + representation chose f64 for head.i, head.a, head.b (fact number)
//   = erase-dead-result: 0 fired in both

// Branches can be named and stored, like commits.
const lab = g.workspace('root-experiments')
lab.save('baseline', a)
lab.save('arena', b, { note: 'doc 01 proposal' })
lab.save('facts', c, { note: 'narrowing + standard rewrites' })
lab.list()
// → [{ name: 'baseline', hash: '9c2e41' }, { name: 'arena', hash: '5b81e0', parent: 'baseline' },
//    { name: 'facts', hash: 'c08d3f', parent: 'baseline' }]

// Running both and diffing behaviour: equal output, different resources.
const runs = await g.differential({ pipelines: { a, b }, corpus: [src], observe: 'js-sync' })
runs.diff()
// → { behaviour: 'equal', resources: { activeRootBytes: '56 B → 88 B', reservedArenaBytes: '0 B → 16 KiB' } }
