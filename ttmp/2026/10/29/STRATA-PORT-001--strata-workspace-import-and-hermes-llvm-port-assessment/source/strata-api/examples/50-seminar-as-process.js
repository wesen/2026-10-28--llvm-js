// 50 · The seminar itself as a process value
//
// Model: the eight-week research assignment from doc 03 is written as a
// process: steps with inputs and outputs, divergence into alternatives,
// convergence by stated criteria, critique by a second reader, and loops
// when a critique finds a counterexample. Outputs are typed (claim ledger,
// decision record, trace, counterexample), so the process can check that
// every required deliverable exists and that every decision cites evidence.
//
// Notice: decision records are values that cite studies and comparisons by
// hash; the process flags a decision with no counterexample sought; two
// processes can be compared on rework.

import { g } from 'strata'

const seminar = g.process('LLVM-ENGINE-002 seminar', { weeks: 8 })
  .step('map the current system', {
    week: 1, reads: ['Engine.h', 'Frontend.cpp', 'Engine.cpp', 'LLVMBackend.cpp', 'StaticH.cpp', 'module-host/*'],
    produces: ['current-system map', g.ledger('claims')],
  })
  .step('semantics and observations', {
    week: 2, produces: [
      g.profile.define('edu', {                  // the same teaching profile as example 08
        admits: ['core', 'js.function.cells', 'js.object.basic', 'js.control.exceptions'],
        observes: ['output', 'outcome', 'object identity'],
      }),
      'three execution derivations'],
  })
  .step('effects and legality', {
    week: 3, produces: [g.contract.table, 'transformation-permission table', 'counterexamples'],
  })
  .diverge('IR infrastructure', {
    week: 4, alternatives: ['custom-core', 'mlir-dialect', 'hermes-ir-plus-contracts'],
    sameInputs: g.corpus.five(),
  })
  .converge('IR infrastructure', { by: 'example 41 criteria', produces: g.decision('IR infrastructure') })
  .diverge('root storage', {
    week: 5, alternatives: ['stackReuse', 'arena', 'statepoints'],
    traces: ['normal return', 'throwing call', 'nested catch', 'collection', 'reentrant native call', 'suspended generator'],
  })
  .converge('root storage', { by: 'example 40 study', produces: g.decision('root storage policy') })
  .step('reusable subsystems', { week: 6, produces: [g.subsystem('fixed-point solver'), g.subsystem('module graph SCC')] })
  .step('rewrite the architecture', { week: 7, produces: ['revised guide', 'removed abstractions', 'remaining risks'] })
  .critique('adversarial review', {
    week: 8, reviewer: 'second reader (or labelled self-review)',
    asks: ['a counterexample to one rewrite rule', 'an ownership path a state machine missed', 'a subsystem whose dependencies defeat its independence'],
  })
  .loop('critique finds a counterexample', { back: 'effects and legality' })

// doc 03 asks for six decision records; this process converges on two of them.
seminar.check()
// → { ok: false, issues: [
//      "decision 'effect/control representation' required by doc 03 has no producing step",
//      "decision 'semantic observations' required by doc 03 has no producing step",
//      "decision 'reusable subsystem boundaries' required by doc 03 has no producing step",
//      "decision 'staged dependency replacement' required by doc 03 has no producing step" ] }

// A decision record is a value with evidence by reference.
const roots = g.decision('root storage policy')
  .context('fflate O0 needs 1,084 + 3 slots under distinct slots; limit 1,024 (historical execution)')
  .options(['stackReuse', 'arena', 'statepoints'])
  .evidence([g.ref.study('root-storage-2026-11', 'H1'), g.ref.study('root-storage-2026-11', 'H3')])
  .counterexampleSought('a catch handler that reads a value rooted only on the normal edge (example 33)')
  .choose('stackReuse for the first slice; arena kept as a declared strategy')
  .overturnIf('an admitted function whose measured frame (peak live + 2 fixed + its outgoing argument slots) exceeds 1,024')

roots.status                                   // → 'proposed'
roots.check()                                  // → { ok: true, evidenceResolved: 2, counterexampleSought: true }

// The record the process produced is looked up through the process, not rebuilt.
seminar.decision('IR infrastructure').check()
// → { ok: false, issues: ['no counterexample sought', 'evidence: comparison status open (example 41)'] }

// Comparing two processes: semantics-first (this one) vs implement-first (doc 01's phases).
const implementFirst = g.process('engine-v2 phases').step('arena prototype', { week: 1 }).step('port emitter', { week: 3 })
g.process.compare([seminar, implementFirst], { metrics: ['decisions with evidence', 'reversible steps', 'expected rework'] })
// → { seminar: { decisionsWithEvidence: 6, reversibleSteps: 9, expectedRework: 'low' },
//     'engine-v2 phases': { decisionsWithEvidence: 1, reversibleSteps: 2, expectedRework: 'high if arena is wrong' } }
//   (a model of the processes, not a measurement of people)
