// 41 · The deciding experiment: custom core vs MLIR vs Hermes IR
//
// Model: the infrastructure choice from the note, set up as a comparison on
// identical inputs. Each candidate encodes the same five comparison examples
// from doc 03; the encodings are measured on criteria fixed in advance: new
// constructs, verifier rules, glue code, opaque escapes, examples expressible
// without escapes, and integration facts pinned to exact revisions. The
// cheapest candidate that expresses all five without escapes wins; ties go to
// the one with less infrastructure we maintain.
//
// Notice: a candidate is pinned to a revision, and its API facts are checked
// against that revision, not current online documentation; MLIR's known gaps
// (non-local control flow, GC) are criteria, not footnotes.

import { g } from 'strata'

const five = g.corpus.five()
// → ['scalar branch and merge', 'loop with block arguments', 'captured cell shared with dynamic closure',
//    'throwing getter with collection obligations', 'ordered job enqueue with deferred continuation']

const candidates = {
  custom: g.candidate('custom-core', {
    infrastructure: 'ours: graph, verifier, parser, printer, rewrite driver, pass order',
    encode: ex => g.encode.core(ex),           // this library's core IR (examples 06, 07)
  }),
  mlir: g.candidate('mlir-dialect', {
    revision: 'llvm-project@llvmorg-18.1.3',   // pinned; APIs checked against this tag
    dialects: ['strata.core', 'strata.js', 'cf', 'func'],
    encode: ex => g.encode.mlir(ex, { effects: 'MemoryEffectOpInterface', exceptions: 'explicit successor ops' }),
  }),
  hermes: g.candidate('hermes-ir-plus-contracts', {
    revision: 'hermes@f837b9d (static_h)',
    encode: ex => g.encode.hermesIR(ex, { contracts: 'side table per instruction kind' }),
  }),
}

const criteria = g.criteria([
  ['expressesAllFive', { require: true, without: 'opaque escapes' }],
  ['newConstructs', { dir: 'min', unit: 'count' }],
  ['verifierRules', { dir: 'min', unit: 'count' }],
  ['glueLines', { dir: 'min', unit: 'count', note: 'code outside the candidate needed to express contracts' }],
  ['maintainedInfrastructure', { dir: 'min', unit: 'components' }],
  ['integration', { checks: ['links with Hermes llvh build', 'LLVM version alignment', 'license'] }],
  ['gaps', { checks: ['non-local control flow', 'GC root protocol', 'finally completion'] }],
])

const comparison = g.compare(candidates, five, criteria)

comparison.encoding('mlir', 'throwing getter with collection obligations')
// → %r = strata.js.get %recv, "x" : (!js.value, !js.key) -> !js.value  ^normal, ^caught
//   (custom terminator op with two successors; collection obligation as an op attribute;
//    root plan outside MLIR: no GC interface in this revision)

comparison.table()
// → criterion                 custom-core     mlir-dialect              hermes-ir+contracts
//   expressesAllFive          yes             yes                       yes (strict direct eval already shares native cells)
//   newConstructs             7               9 ops, 2 types            3
//   verifierRules             5               4 + MLIR's built-ins      2 + Hermes verifier
//   glueLines                 0               ~1,200 (GC, unwind)       ~600 (contract side table)
//   maintainedInfrastructure  6 components    1 (dialect)               1 (side table)
//   integration               none            llvh vs upstream: blocked without a separate build
//   gaps                      ours to design  non-local control, GC      contracts outside the IR; no use beyond JS
//   (illustrative; the seminar fills this table)

comparison.decide({ rule: 'cheapest that expresses all five; tie → less maintained infrastructure' })
// → { choice: 'undecided',
//     reason: "'cheapest' needs a cost model: custom-core has no glue but six maintained components;
//              hermes-ir has one component but ~600 lines of glue and no use beyond JavaScript;
//              mlir's integration criterion is unresolved (llvh vs upstream LLVM)",
//     nextExperiment: 'state the cost model; build MLIR 18.1.3 out of tree and link a dialect beside llvh' }

// The result becomes a decision record with every cell traceable to an encoding file.
g.decision('IR infrastructure').fromComparison(comparison).status('open')
