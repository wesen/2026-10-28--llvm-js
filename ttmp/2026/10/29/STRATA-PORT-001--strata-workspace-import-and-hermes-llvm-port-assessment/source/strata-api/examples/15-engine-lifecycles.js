// 15 · Execution ownership as state machines
//
// Model: the engine owns everything that exists while code runs: code,
// activations, modules, evaluations, jobs. Each is a labelled transition
// system with explicit failure transitions and its own variables. The engine
// is their product, which synchronizes on shared labels: a transition whose
// label several machines know happens in all of them at once. Invariants are
// checked on the product by bounded exploration. The engine API is the
// effectful face of the same machines: every call is awaited and owned by one
// thread.
//
// Notice: the bug "release code when an initializer fails" is found as a
// short trace that really happens; pending is never reported as completion.

import { g, jobs, mib } from 'strata'

// The machines, as values. `runtime-destroyed` is shared by code and engine, so code is
// released exactly when the engine destroys the runtime.
const code = g.machine('code')
  .vars({ closurePublished: false })
  .state('compiled').on('admit', 'admitted').on('reject', 'discarded')
  .state('admitted')
    .on('publish-closure', 'admitted', { set: { closurePublished: true } })   // a self-loop: still initializing
    .on('init-ok', 'retained').on('init-failed', 'retained')                  // retained either way
  .state('retained').on('runtime-destroyed', 'released')
  .final('released', 'discarded')

const evaluation = g.machine('evaluation')
  .vars({ reported: 'nothing' })
  .state('not-started').on('evaluate', 'evaluating')
  .state('evaluating').on('await', 'pending').on('return', 'fulfilled').on('throw', 'rejected')
  .state('pending').on('job-resumes', 'evaluating')
  .state('fulfilled').on('report', 'fulfilled', { set: { reported: 'fulfilled' } })
  .final('fulfilled', 'rejected')

const engineM = g.machine('engine')
  .state('ready').on('call', 'executing').on('close', 'closing')
  .state('executing').on('return', 'ready')
  .state('closing').on('runtime-destroyed', 'code-released')
  .final('code-released')

const model = g.machine.product(engineM, code, evaluation)       // synchronizes on shared labels
  .invariant('code outlives runtime', s => !(s.code === 'released' && s.engine !== 'code-released'))
  .invariant('callable closures have code', s =>
    !(s.closurePublished && ['released', 'discarded'].includes(s.code) && s.engine !== 'code-released'))
  .invariant('pending is not completion', s => !(s.evaluation === 'pending' && s.reported === 'fulfilled'))

g.check.machine(model, { depth: 12 })
// → { ok: true, states: 36, transitions: 88, synchronized: ['runtime-destroyed'] }

// A plausible bug: free code when its initializer fails.
const eager = code.retarget('admitted', 'init-failed', 'released')   // a new machine value; `code` is unchanged
g.check.machine(g.machine.product(engineM, eager, evaluation).invariants(model.invariants), { depth: 12 })
// → { ok: false, violated: ['code outlives runtime', 'callable closures have code'],
//     trace: ['code: compiled', 'admit', 'publish-closure (closurePublished = true)', 'init-failed',
//             'code: released while engine: ready'] }

// The same ownership, used through the engine API (all effects are awaited).
const engine = await g.engine({ budget: { activeRoots: mib(4) } })

const counter = await engine.defineModule('counter.mjs', g.source.text(`
export let count = 0;
export function increment() { count += 1; }`))

const main = await engine.defineModule('main.mjs', g.source.text(`
import {count, increment} from './counter.mjs';
increment();
await Promise.resolve();
print(count);`))

const ev = await engine.evaluateModule(main)
engine.evaluationState(ev)                     // → 'pending'   (top-level await; the queue holds a job)
await engine.runJobs({ budget: jobs(100) })    // → { ran: 2, remaining: 0 }
engine.evaluationState(ev)                     // → 'fulfilled'
engine.output()                                // → ['1']

// An empty queue does not fulfil a module that awaits forever.
const stuck = await engine.defineModule('stuck.mjs', g.source.text(`await new Promise(() => {})`))
const ev2 = await engine.evaluateModule(stuck)
await engine.runJobs({ budget: jobs(100) })    // → { ran: 0, remaining: 0 }
engine.evaluationState(ev2)                    // → 'pending'   (never 'fulfilled', never an error)

// Wrong-thread use and use-after-close are refused.
engine.snapshot().owner                        // → 'thread#1'
await engine.close()
await engine.runJobs({ budget: jobs(1) }).catch(e => e.name)   // → 'EngineClosed'
