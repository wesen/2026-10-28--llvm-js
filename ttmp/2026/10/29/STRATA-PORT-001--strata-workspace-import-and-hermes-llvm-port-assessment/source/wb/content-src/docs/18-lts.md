---
id: lts
title: Labelled transition systems
group: Runtime
about: Lifecycles as small state machines with labelled transitions, products that synchronise on shared labels, invariants, and breadth-first search for the shortest counterexample.
order: 18
---
# Labelled transition systems

An engine's runtime, the code it has admitted, a host that tears them down: each has a lifecycle, and the bugs that matter are in how the lifecycles interleave. A call into code that has been released, a collection while a frame is half-built, a finaliser that runs after the runtime is gone. The workbench models lifecycles as **labelled transition systems** and searches their combinations mechanically. This doc defines the model, the product that combines machines, and what a search result does and does not prove. [E-06](lab:preset?id=E-06) applies it to teardown, and [Chapter 18](lab:book?ch=18) puts it in the context of engines.

## States, labels and transitions

A labelled transition system is a set of states, a start state, and transitions $s \xrightarrow{a} s'$, each with a label $a$ naming the event. A machine is in one state at a time and moves by taking a transition whose label is the event that happens. There are no variables and no time: everything the model needs to remember is in the state. `g.machine` builds one as an immutable value; the first state declared is the start:

```js
const code = g.machine('code')
  .state('loaded').on('call', 'loaded').on('release', 'freed')
  .state('freed').on('call', 'crash');
```

`code` accepts `call` while loaded, can be released once, and models a call into freed code as a move to a state named `crash`. Naming the failure as a state is the usual trick: it turns "this must never happen" into "this state must never be reached", which a search can check.

## Products synchronise on shared labels

Several machines run together as their **product**. A state of the product is a tuple, one state per machine. A label known to several machines can happen only when all of them can take it, and then they all move together; a label known to one machine moves that machine alone. This is the synchronisation rule of Hoare's Communicating Sequential Processes, and it is what lets a third machine impose an order on two others without either of them knowing.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 230">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="90" width="130" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="85" y="114" font-size="11" text-anchor="middle">alive, loaded</text>
  <rect x="250" y="20" width="130" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="315" y="44" font-size="11" text-anchor="middle">dead, loaded</text>
  <rect x="250" y="160" width="130" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="315" y="184" font-size="11" text-anchor="middle">alive, freed</text>
  <rect x="480" y="20" width="130" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="545" y="44" font-size="11" text-anchor="middle">dead, freed</text>
  <rect x="480" y="160" width="130" height="40" fill="none" stroke="currentColor" class="acc"/>
  <text x="545" y="184" font-size="11" text-anchor="middle" class="b">alive, crash</text>
  <path d="M150,100 L248,48" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="190" y="64" font-size="10" class="it">destroy</text>
  <path d="M150,120 L248,172" fill="none" stroke="currentColor" class="acc" marker-end="url(#arrow)"/>
  <text x="180" y="166" font-size="10" class="it">release</text>
  <line x1="380" y1="40" x2="478" y2="40" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="430" y="34" font-size="10" text-anchor="middle" class="it">release</text>
  <line x1="380" y1="180" x2="478" y2="180" stroke="currentColor" class="acc" marker-end="url(#arrow)"/>
  <text x="430" y="174" font-size="10" text-anchor="middle" class="it">call</text>
  <path d="M380,170 L478,52" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="440" y="118" font-size="10" class="it">destroy</text>
  <path d="M40,90 C40,60 80,60 80,88" fill="none" stroke="currentColor" class="mut" marker-end="url(#arrow)"/>
  <text x="34" y="64" font-size="10" class="it">call</text>
</svg>
```

**Figure 18.1.** The product of the runtime and code machines from [E-06](lab:preset?id=E-06). `call` is shared, so it needs both machines able to call: it loops at the start and, after `release`, leads to the crash state. `destroy` and `release` belong to one machine each. The accented path is the counterexample the search returns. Drawn from the machines' definitions.

## Invariants and search

An **invariant** is a predicate every reachable state must satisfy: `s => s.code !== 'crash'`. `g.check.machine(product, { depth })` explores the product breadth-first from the start state, checks the invariant in each state it reaches, and stops at the first violation. Breadth-first order means the trace it returns is a shortest one: for the unordered teardown it is `release → alive, freed; call → alive, crash`, two events. When nothing is violated, it reports the states and transitions it visited (3 and 3 for [E-06](lab:preset?id=E-06)'s ordered host).

Short traces matter more than they seem. A failure found after forty events is a fact; a failure found after two is an explanation, because a person can see why it happens and what would prevent it. Most lifecycle bugs have short traces, because each step usually corresponds to one decision someone forgot to order.

## Ordering by adding a machine

The fix in [E-06](lab:preset?id=E-06) adds a host that knows both `destroy` and `release`, and allows `release` only after `destroy`. Because the host shares those labels, the product cannot take `release` until the host is in its `stopping` state; and after `destroy` the runtime is `dead`, which has no `call` transition, so no call can follow. The fix changes neither the runtime nor the code machine. That is the general shape of protocol design with these models: write each component's lifecycle on its own, write the coordination as a separate machine, and let the product show whether the coordination is enough.

## What a search proves

For finite machines and a depth at least as long as the longest path, a breadth-first search visits every reachable state, so a passing check is a proof that the invariant holds. The machines in the workbench are that small. Real lifecycles are not: each additional machine multiplies the number of product states, and a model with counters or queues has infinitely many. Then the depth bounds the claim. "No counterexample within depth 6" is weaker than "correct", but it is checked, repeatable and cheap, and it catches the short traces where most bugs live. Dedicated model checkers push the same idea much further with symbolic representations and partial-order reductions; the workbench keeps to explicit states because its machines are small enough to read.

## Where lifecycles appear in an engine

The same model fits several parts of the workbench. An engine's own states (ready, executing, closed) with admission allowed only when ready and every call refused after close ([E-04](lab:preset?id=E-04)). A unit's code, retained while any closure can still call it ([E-07](lab:preset?id=E-07)). A frame on the root chain, linked by `shllvm_enter`, unlinked by `shllvm_leave` or by a catch that skips it ([Unwinding](lab:doc?id=unwinding)). A promise, pending until settled exactly once. Each is a handful of states; the interesting properties are about their products.

## What this model leaves out

`g.machine` has no variables, guards or data on labels, so a property like "the number of calls equals the number of returns" needs a state per count. It checks invariants (safety: nothing bad happens) but not liveness (something good eventually happens), so "every queued job eventually runs" cannot be stated. And the machines are written by hand from the code, not extracted from it: a model can be right about a protocol the implementation does not follow. The workbench's answer to that gap is the same as elsewhere: check the model, then test the implementation against it ([E-04](lab:preset?id=E-04) runs the real engine through the lifecycle the model describes).
