// 25 · Ordered jobs, await and deferred continuations
//
// Model: comparison example 5. Enqueueing a job writes the `jobs` ordering
// resource, so two enqueues never swap. `await` is a suspension: the values
// needed after it move into a managed continuation, the activation is
// released, and a job resumes it in a fresh activation. The engine pumps
// jobs with a budget; it never treats an empty queue as completion.
//
// Notice: the sink-enqueue rewrite is refused with a reason; the suspension
// lists exactly the values it saves; no saved value points into a released
// activation (checked).

import { g, jobs } from 'strata'

const src = g.source.text(`
const order = [];
Promise.resolve().then(() => order.push('a'));
queueMicrotask(() => order.push('b'));
(async () => { const tag = 'c'; await null; order.push(tag); })();
order.push('sync');
queueMicrotask(() => print(order.join(',')));`, { name: 'jobs.js' })

const p = g.compile(g.pipeline(), src)

// Enqueues are ordered by the resource they write. await is one of them: it enqueues the resumption.
p.find(n => ['job.enqueue', 'promise.then', 'js.await'].includes(n.op)).map(n => [n.id, n.contract.behaviour.toString()])
// → [['main/e1', 'writes(jobs), fresh'], ['main/e2', 'writes(jobs)'], ['anon/entry/await', 'writes(jobs)'], ['main/e4', 'writes(jobs)']]

// Try to sink the first enqueue below the second (a "batch the reactions" idea).
g.rewrite.tryMove(p.ir('L1'), { op: 'main/e1', after: 'main/e2' })
// → { allowed: false, because: 'both write the ordering resource jobs',
//     wouldChange: "output 'sync,a,b,c' would become 'sync,b,a,c'" }

// The async arrow: await is a terminator. Its resume edge passes exactly the values the
// continuation saves; its throw edge receives a rejection.
p.ir('L1', { fn: 'anon' })
// → entry:
//     tag = core.const("c")
//     order_b = js.env.binding(closureEnv, "order")      ; a script binding: a cell
//     await null, resume after_await(tag, order_b), throw reject
//   after_await(v: any, tag2: any, order_b2: cell):
//     arr = cell.load(order_b2)
//     invoke js.call_method(arr, "push", tag2) normal done throw reject
//   done(n: any):
//     return undefined
//   reject(e: any):
//     throw e
p.plan('anon').suspensions
// → [{ at: 'entry/await', saves: ['tag', 'order_b'], into: 'managed continuation (hermes generator object)',
//      activation: 'released at suspend; fresh at resume', pointsIntoReleasedActivation: false }]

// The specification and the engine agree on order. 'sync' is pushed before any job runs;
// then the jobs run in enqueue order: a, b, the await resumption (c), and the print.
g.semantics().profile('js-async').run(p).trace // → [output('sync,a,b,c')]

const engine = await g.engine()
await engine.evaluateScript(p)                 // synchronous part only
await engine.runJobs({ budget: jobs(2) })      // → { ran: 2, remaining: 2 }   (a, b)
await engine.runJobs({ budget: jobs(100) })    // → { ran: 2, remaining: 0 }   (resume c, print)
engine.output()                                // → ['sync,a,b,c']

// Budgets bound how many jobs start; they do not interrupt a job that never returns.
const spin = g.compile(g.pipeline(), g.source.text(`queueMicrotask(() => { for (;;) {} })`))
await engine.evaluateScript(spin)
// await engine.runJobs({ budget: jobs(1) })   // → would not return: no preemption (hard interruption is deferred)
engine.capabilities().interruption             // → 'none (requires polling points; deferred by design)'

await engine.close()
