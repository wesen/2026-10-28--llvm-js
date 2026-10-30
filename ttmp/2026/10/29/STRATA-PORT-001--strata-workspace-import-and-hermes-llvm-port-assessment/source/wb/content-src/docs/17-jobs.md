---
id: jobs
title: Jobs, promises and timers
group: Runtime
about: Run to completion, the microtask queue, promises and their reactions, timers on a virtual clock, and why the order of output is something a compiler must preserve.
order: 17
---
# Jobs, promises and timers

JavaScript code does not only run when it is called. A script can queue work for later (`queueMicrotask`, `Promise.prototype.then`, `setTimeout`), and that work runs after the script, in an order the language defines. The workbench's engine implements the three mechanisms with two queues and a virtual clock, and its specification observes the order of output, so every pipeline must keep it. This doc collects the rules. [E-01](lab:preset?id=E-01), [E-02](lab:preset?id=E-02), [E-03](lab:preset?id=E-03) and [J-05](lab:preset?id=J-05) show them; [Chapter 17](lab:book?ch=17) explains them in depth.

## Run to completion

A **job** is a function the engine will call later with no JavaScript on the stack. The first rule is that nothing interrupts running code: a script, and each job, runs until it returns or throws before anything else starts. Code between two points where it gives up control can therefore read and update shared state without locks; the price is that a long-running job delays everything behind it. In the engine, `main` runs first; only when it returns do the queues start.

## The microtask queue

`queueMicrotask(f)` lowers to `job.enqueue(f)`, which appends `f` to the **microtask queue** and returns at once. After `main`, the engine takes jobs from the front of the queue one at a time, runs each to completion, and stops only when the queue is empty. A job that queues another puts it at the back, behind everything already waiting. A job that throws is reported (two `throw` events: the throw and the fact that nothing caught it) and the engine moves on to the next job; the program's outcome stays `normal`. In [E-01](lab:preset?id=E-01) that produces `script start`, `script end`, `job A`, `job B`, `job D still runs`, `job E, queued by job A`.

## Promises are reactions on the same queue

A promise is pending, fulfilled or rejected. `then(f)` on a promise records a **reaction**; when the promise is (or already was) fulfilled, the reaction becomes a job on the microtask queue, and `then` returns a new promise that the reaction's result settles. Two consequences follow. A chain of `then`s takes one turn of the queue per link, so other jobs interleave with it: in [E-02](lab:preset?id=E-02), `second then: 2` prints after a plain job queued later in the script. And a reaction that returns a promise does not fulfil the derived promise with that promise; the derived promise **adopts** the returned one's state, which takes extra turns of the queue.

On adoption the workbench's engine and the standard differ. The standard spends two jobs (a job that calls the returned promise's `then`, then the reaction that settles the derived promise); the engine calls `then` directly and spends one. Node prints [E-02](lab:preset?id=E-02)'s `adopt.js` with `adopted: 20` one line later than the engine does. By the workbench's own rules that is a bug in the reference interpreter, and a reminder that laws prove a compiler agrees with its specification, not that the specification agrees with the language.

## Timers and the virtual clock

`setTimeout(f, ms)` lowers to `timer.set(f, ms)`, which records `f` with a due time. The engine's clock is **virtual**: it starts at 0 and moves only when the engine moves it. When the microtask queue is empty, the engine takes the timer with the earliest due time (ties in the order they were set), moves the clock to that time, runs the timer, and empties the microtask queue again before the next timer.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 170">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="40" width="110" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="75" y="64" font-size="11" text-anchor="middle" class="b">main</text>
  <rect x="180" y="40" width="160" height="40" class="f-fill" stroke="currentColor"/>
  <text x="260" y="58" font-size="11" text-anchor="middle" class="b">microtasks</text>
  <text x="260" y="72" font-size="10" text-anchor="middle" class="it">until the queue is empty</text>
  <rect x="400" y="40" width="200" height="40" fill="none" stroke="currentColor" class="ink"/>
  <text x="500" y="58" font-size="11" text-anchor="middle" class="b">earliest timer</text>
  <text x="500" y="72" font-size="10" text-anchor="middle" class="it">clock := its due time</text>
  <line x1="130" y1="60" x2="178" y2="60" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <line x1="340" y1="60" x2="398" y2="60" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M500,80 L500,118 L260,118 L260,82" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="380" y="134" font-size="10" text-anchor="middle" class="it">after each timer, drain microtasks again</text>
  <text x="20" y="160" font-size="10" class="mut">The run ends when both the microtask queue and the timer list are empty (or the job budget is spent).</text>
</svg>
```

**Figure 17.1.** The order in which the engine runs a program's work. Schematic.

So `setTimeout(f, 0)` means "after everything currently queued", never "now": every microtask the script queued runs first. In [E-03](lab:preset?id=E-03), a job queued by the 5 ms timer prints before a timer due at 7 ms.

Real engines fire timers late and in batches. Node runs [E-03](lab:preset?id=E-03)'s program with its last two lines swapped, because its event loop wakes a few milliseconds after start, finds the 0, 5 and 10 ms timers all expired and runs them in list order, before the 2 ms timer set during that batch is due. The language promises only that a timer never fires early and that equal delays keep their order. The virtual clock gives one order out of those the language allows, the same on every run, which is what a specification must do: with the host's real clock, the same program could pass a refinement check on one run and fail on the next.

## What the contracts say

The three operations carry behaviours that keep the order intact under optimisation:

| operation | behaviour | obligations |
|---|---|---|
| `job.enqueue` | reads and writes `jobs` | mayCollect |
| `timer.set` | reads and writes `timers` | mayCollect |
| `promise.resolve` | reads and writes `jobs`, fresh | mayCollect |

An operation that writes a resource may not move past another that reads or writes it, and a call into user code (`callsUser`) reads and writes every user resource, `jobs` and `timers` included. So no permission derived from these contracts lets a rewrite reorder two enqueues, or move one across a call. Each may also allocate, so each is a safepoint, and the queues themselves are roots: in plan mode the collector moves every waiting closure and updates the queue's entries, and the output under stress is unchanged.

## The host decides when jobs run

The engine does not run jobs on its own. `program.run()` runs `main` and then the queues (up to 10,000 jobs by default). An engine created with `g.engine()` separates the steps: `evaluateScript` runs a unit's `main`, and `runJobs` drains the queues, so a host chooses when ([E-04](lab:preset?id=E-04)). A browser runs microtasks after each script and each event; a server runtime after each callback. The engine only promises the order within a drain.

## What this model leaves out

There are no rejection handlers (`then` takes one function, so a rejected promise is reported and stays rejected), no `async` functions or `await` (outside the frontend's subset), no `finally` on promises, no promise combinators, and no host task queues besides timers (no I/O, no messages). Each of these adds rules to the same two-queue picture without changing it: `await` is a `then` on the awaited value, and an I/O completion is another kind of timer.
