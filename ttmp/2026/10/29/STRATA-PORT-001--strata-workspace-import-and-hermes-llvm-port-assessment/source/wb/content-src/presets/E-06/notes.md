# Lifecycles as state machines

An engine's runtime and the code it has admitted have separate lifetimes, and the rule that connects them is easy to state and easy to break: code must stay loaded as long as anything can still call it. This preset writes the two lifetimes as small state machines, combines them, and lets a search find the order of events that breaks the rule. The [Laws view](lab:show?view=laws) shows three teardown protocols: one with no order (fails), the ordered one (passes) and the reversed one (fails), each failure with its trace.

> **Try it.** [Open the Laws view](lab:show?view=laws) and read the first counterexample: `release → alive, freed; call → alive, crash`. Two events are enough.

## Machines as values

A **labelled transition system** is a set of states, a start state and transitions, each with a label. `g.machine` builds one immutably:

```js
const runtime = g.machine('runtime')
  .state('alive').on('call', 'alive').on('destroy', 'dead');
const code = g.machine('code')
  .state('loaded').on('call', 'loaded').on('release', 'freed')
  .state('freed').on('call', 'crash');
```

The runtime accepts calls while alive and can be destroyed. The code accepts calls while loaded and can be released; a call into freed code is modelled as a move to `crash`, so the failure is a state the search can find.

## The product synchronises on shared labels

`g.machine.product(runtime, code)` runs the machines together. A label both machines know (`call`) happens only when both can take it, and then both move. A label only one machine knows (`destroy`, `release`) moves that machine alone. `g.check.machine` searches the product breadth-first from the start state and checks the invariant in every state it reaches; breadth-first means the trace it returns is a shortest one.

Without any ordering, `release` can happen while the runtime is alive. The runtime still accepts `call` (it does not know the code was freed), the code moves to `crash`, and the invariant `s.code !== 'crash'` fails after 5 states. This is the bug [E-04](lab:preset?id=E-04)'s `close()` avoids by destroying the runtime first.

## A host that orders teardown

The fix is a third machine, the host, which owns the order:

```js
const host = g.machine('host')
  .state('running').on('destroy', 'stopping')
  .state('stopping').on('release', 'done');
```

Because the host knows both `destroy` and `release`, the product can take `release` only when the host allows it, which is after `destroy`. After `destroy` the runtime is `dead`, and `dead` has no `call` transition, so no call can reach the freed code. The search visits 3 states and 3 transitions and finds nothing. The reversed host (release, then destroy) fails exactly like the unordered one: `release` happens while the runtime is alive, and a call follows.

> **Try it.** [Open main.js](lab:open?file=main.js&find=const host) and add `.on('call', 'running')` to the host's running state. Rerun: does the ordered protocol still pass, and why does adding a label to the host change which calls the product allows?

## Why this program

The program in `program.js` is the situation the machines abstract. `makeGreeter` returns a closure and `main` queues it as a job, so the closure is called after `main` has returned: the code for `arrow` must still be loaded when the job runs. In an engine with several units, code can be called long after the unit that defined it finished evaluating, which is why [E-07](lab:preset?id=E-07)'s plugin host keeps every unit retained until close.

## What search can and cannot show

`check.machine` explores every interleaving up to a depth (6 here), so for these tiny machines it is a proof: there are only a handful of states. For real lifecycles (suspension, finalisers, several engines sharing a runtime) the state space grows fast and the depth bounds the claim. A passing check then says "no counterexample within depth 6", which is still worth having: most lifecycle bugs, like this one, need only two or three steps.

> **Exercise.** Add a `finaliser` machine that can `call` at any time until the runtime is destroyed (it shares `call` and `destroy` with the runtime). Does the ordered host still pass? Then let the finaliser run after `destroy` and find the trace the search reports.

## Where next

[Chapter 18](lab:book?ch=18) covers engines and lifecycles, and the shelf doc on [labelled transition systems](lab:doc?id=lts) the formalism. [E-04](lab:preset?id=E-04) shows `close()` in a real engine and [E-07](lab:preset?id=E-07) several units in one.
