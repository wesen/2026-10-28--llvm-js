# Content plan: presets, docs, chapters

The shared map for everyone writing content. Ids are fixed; titles may be polished. A preset or doc listed here may be linked before it exists (the final link check runs after all content is in).

## Presets

| id | title | shows | chapters | from API example |
|---|---|---|---|---|
| B-01 | The running example: a ledger | the whole pipeline on the ledger (done) | 1 | 20 |
| B-02 | One default at a time | zero config, then a tweak, a named strategy, a lambda wrapping ctx.default | 1, 11 | 20 |
| B-03 | Every level of one function | L0, L1.cells, L1, L2, L3, LLVM, WAT of one small function | 1 | |
| B-04 | Reading the Stage | blocks, edges, overlays, the inspector, on a loop with a try | 1 | |
| B-05 | Quantities and layouts | units, DimensionError, slots to bytes through a layout, g.limit | 12 | 01 |
| S-01 | The interpreter, step by step | the Machine view, records, frames, the step budget | 2 | 08 |
| S-02 | What counts as the same | observations, SameValue, -0 and NaN, object identity up to renaming | 2 | 08 |
| S-03 | Profiles | core, js-sync, js-async; a program outside a profile | 2 | 08 |
| S-04 | The temporal dead zone | let before declaration, cell.load_checked, the ReferenceError | 2, 4 | 24 |
| S-05 | Divergence and budgets | an infinite loop, outcome diverge, budgets | 2 | |
| S-06 | Coercion runs user code | valueOf and toString during js.add and js.lt | 2, 6 | 23 |
| I-01 | Core IR by hand | the g.fn builder: fib with block parameters | 3 | 06 |
| I-02 | Text, JSON and round trips | parse, print, JSON, g.law.roundTrip | 3 | |
| I-03 | Loops and block arguments | a loop's carried values as block parameters; the Stage's back edge | 3 | 06 |
| I-04 | The verifier | broken IR: dominance with a counter-path, arity, types, terminators | 3 | 06 |
| I-05 | Dominators | idom, the dominator tree, why SSA needs it | 3, 4 | |
| I-06 | Every variable a cell | L1.cells: what the frontend emits before promotion | 4 | 24 |
| I-07 | Building SSA: promote-cells | mem2reg with block parameters, dominance frontiers, dead parameters | 4 | |
| I-08 | Captured variables stay cells | closures share a cell; what promotion may not touch | 4 | 24 |
| I-09 | Exceptions as edges | throws to H(args), invoke, the handler's parameters | 5 | 07 |
| I-10 | try, catch and finally lowered | completion records, the finally join, rethrow | 5 | 07 |
| C-01 | Behaviours and their join | fx values, join as a semilattice, g.law.join | 6 | 03 |
| C-02 | Obligations | mayCollect, nonlocalThrow, what lowering must provide | 6 | 04 |
| C-03 | Derived permissions | g.perm and g.perm.explain on the standard table | 7 | 04 |
| C-04 | The throwing getter | why an unused js.get cannot be erased, end to end | 7 | 23 |
| C-05 | Your own operation | g.op builder, a step, registration, using it in IR | 6 | 05 |
| C-06 | Variants and narrowing | js.add to num.add under facts; g.law.variant; i32 overflow | 7, 12 | 02 |
| C-07 | More behaviour, fewer permissions | the antitone law and commuting operations | 7 | 04 |
| C-08 | Providers and operation sets | opsets, providers, statusReturn needs non-Hermes providers | 6, 14 | 05, 27 |
| A-01 | Lattices and their laws | powerset, flat, map, types, interval; g.law.lattice | 8 | 09 |
| A-02 | Liveness, one step at a time | the solver's steps on total; lab:analysis | 8, 9 | 09 |
| A-03 | Type facts and branch refinement | typeof and is_number refine edges | 9 | 02 |
| A-04 | Your own analysis: constants | a forward analysis with a flat map lattice | 8 | 09 |
| A-05 | Intervals and widening | an infinite lattice, thresholds | 8 | |
| A-06 | The solver on any graph | g.solve on a graph, strongly connected components | 8 | |
| A-07 | Monotone or not | g.law.monotone and a broken transfer function | 8 | 33 |
| A-08 | Safepoints and live-across | which values cross which collecting operations | 9 | 12 |
| T-01 | Folding and propagation | const-fold, copy-prop, simplify-branch, remove-unreachable | 10 | 10 |
| T-02 | Dead code that is not dead | naive DCE deletes a throwing getter; the law catches it | 10 | 10, 23 |
| T-03 | Your own rewrite | mul-one with a side condition, checked by g.law.refines | 10 | 10 |
| T-04 | Narrowing by facts | standard rewrites; js ops become num ops; fewer safepoints | 10, 12 | 02 |
| T-05 | Forwarding stores to loads | forward-store-to-load and noWritesBetween | 10 | |
| T-06 | Passes and their requirements | g.pass, insert, requires/provides, a pipeline that fails check() | 11 | 11 |
| T-07 | Pipelines as values | branching, use(), with(), set(), hash and summary | 11 | 11, 34 |
| T-08 | Idempotent canonical form | g.law.idempotent; rewrite order | 10 | |
| L-01 | Bound to helpers | L2: inline, helper and direct bindings; the Hermes helper names | 12 | 05 |
| L-02 | Representations | tagged words, f64 and i32 unboxing under facts | 12 | 02 |
| L-03 | Root strategies compared | distinct, stackReuse, arena on the ledger | 13 | 12, 21 |
| L-04 | A plan with a hole | roots none, the checker's missing roots | 13 | 12 |
| L-05 | A stale reference, caught | gcSafety off, plan mode with stress: the stale use | 13 | 12 |
| L-06 | Your own root strategy | a lambda wrapping ctx.default, and one that drops a value | 13 | 12 |
| L-07 | The 1,024-slot frame | the native frame limit; a function that needs many roots | 13 | 22 |
| L-08 | Unwinding with setjmp | the try state, catch.dispatch, what a catch restores | 14 | 07 |
| L-09 | statusReturn and compatibility | g.compat, declared pairs, why statusReturn needs other providers | 14 | 12 |
| W-01 | WebAssembly by hand | core IR fib to a Wasm binary, run in the page | 15 | 28 |
| W-02 | From JavaScript to Wasm | assume, narrow, then Wasm; what blocks the core profile | 15 | 13, 28 |
| W-03 | Reading WAT | the dispatch loop, br_table, locals for block parameters | 15 | |
| W-04 | LLVM IR in the Hermes shape | shllvm_enter, root slots, helper calls, the string table | 16 | 14 |
| W-05 | Closures and calls in LLVM | shllvm_closure, argv, shllvm_call | 16 | |
| W-06 | try/catch in LLVM | setjmp, try_state, catch.dispatch | 16 | 07 |
| W-07 | The structural checker | g.llvm.check, a broken module | 16 | 14 |
| E-01 | Microtasks and order | job order, the queue, print order | 17 | 25 |
| E-02 | Promises and then | Promise.resolve, then chains, adoption | 17 | 25 |
| E-03 | Timers in virtual time | setTimeout ordering against microtasks | 17 | 25 |
| E-04 | An engine: admit, evaluate, close | g.engine lifecycle, units, metrics | 18 | 14, 15 |
| E-05 | Admission refuses | compile errors and strategy mismatch before any code runs | 18 | 14 |
| E-06 | Lifecycles as state machines | runtime and code as LTS, the product, a violated invariant | 18 | 15 |
| E-07 | A plugin host | several units in one engine, retained code, close order | 18 | 26 |
| X-01 | A design space of pipelines | g.design, params, points, grid search | 20 | 30 |
| X-02 | Objectives that disagree | weighted against lexicographic; rank.disagreement | 20 | 31 |
| X-03 | A Pareto frontier | root slots against steps | 20 | 31, 32 |
| X-04 | Constraints and feasibility | require correct and admitted; constraint.compatible | 20 | 32 |
| X-05 | Your own metric | g.metric, a measurement of the plan | 20 | 31 |
| X-06 | A factorial study of roots | strategies by programs, measured | 20 | 40 |
| X-07 | Measuring a corpus | the J programs as a corpus, metrics per program | 20 | 42 |
| M-01 | Laws as tests | a LawReport over the engine's own laws | 19 | 33 |
| M-02 | Fuzzing a pipeline | g.gen.js, g.law.refines on generated programs | 19 | 33 |
| M-03 | Shrinking a counterexample | g.shrink on a failing program | 19 | 33 |
| M-04 | Differential testing | spec against plan against wasm | 19 | 41 |
| M-05 | Decision records | g.decision and check() | 21 | 50, 51 |
| M-06 | The process as a value | g.process: a seminar, checked | 21 | 50 |
| M-07 | The capstone | the ledger, end to end, with every check | 21 | 60 |
| J-01 | A counter with closures | shared cells, several closures | 4 | |
| J-02 | Getters and setters | accessors, this, a setter that validates | 7 | |
| J-03 | finally with return | completion records in a real function | 5 | |
| J-04 | A tokenizer | a loop over a string, objects per token | 9 | |
| J-05 | An event queue | jobs, timers and promises together | 17 | |
| J-06 | Recursion | recursive functions, deep frames, the budget | 2, 13 | |
| J-07 | Errors across calls | throws through several frames, catch far away | 14 | |
| J-08 | A generated program | the output of g.gen.js, compiled and checked | 19 | |

## Shelf docs

| id | title | group |
|---|---|---|
| workbench-tour | A tour of the workbench | Start here |
| semantics | Semantics and observations | Meaning |
| ssa | SSA with block parameters | Representation |
| dominance | Dominance and dominance frontiers | Representation |
| exceptions | Exceptional control flow | Representation |
| effects | Behaviours, obligations, permissions | Contracts |
| lattices | Lattices and the fixed-point theorem | Analysis |
| liveness | Liveness | Analysis |
| type-facts | Type facts | Analysis |
| rewriting | Rewriting with side conditions | Transformation |
| refinement | Refinement and why passes compose | Transformation |
| gc-roots | Moving collectors and root slots | Lowering |
| nan-boxing | Tagged values and NaN-boxing | Lowering |
| unwinding | setjmp, status codes and landing pads | Lowering |
| wasm | WebAssembly in one page | Backends |
| hermes-llvm | The Hermes LLVM backend | Backends |
| jobs | Jobs, promises and timers | Runtime |
| lts | Labelled transition systems | Runtime |
| property-testing | Property testing and shrinking | Method |
| design-spaces | Design spaces and objectives | Method |
