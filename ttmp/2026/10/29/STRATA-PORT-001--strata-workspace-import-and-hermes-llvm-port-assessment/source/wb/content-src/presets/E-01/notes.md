# Microtasks and order

The script on screen prints two lines and queues four jobs; one of the jobs queues a fifth, and one throws. The output is `script start`, `script end`, `job A`, `job B`, `job D still runs`, `job E, queued by job A`. Every line of it follows from two rules: a script runs to completion before any job, and jobs run one at a time in the order they were queued. This preset makes both rules visible, because the order of output is an observation the compiler must preserve.

> **Try it.** [Open the Events view](lab:show?view=events): `main.js` prints every enqueue with the queue's length, every print and the throw, each with its step. Then [step through the Machine](lab:step?n=11) to the first job.

## Run to completion

`queueMicrotask(f)` does not call `f`. The frontend lowers it to `job.enqueue(f)`, which appends the closure to the **microtask queue** and returns:

```text
  f2 = js.closure(@arrow)
  job.enqueue(f2)
```

So the script prints `script start`, queues four closures (the queue grows to length 4 by step 8) and prints `script end`, all before any job runs. Only when `main` returns does the engine start on the queue. A JavaScript function always runs to its end (or its throw) without being interrupted by another job: that is **run to completion**, and it is why code between two awaits or two callbacks can reason about shared state without locks.

> **Try it.** [Select the first job.enqueue](lab:node?id=main/entry/2) and read its contract: `reads+writes(jobs)` and nothing else, so it may not be reordered with another `job.enqueue` or with anything else that touches the queue. It may also collect, because growing the queue may allocate.

## First in, first out

The engine takes the job at the head of the queue, runs it to completion, and repeats until the queue is empty. Job A runs first and queues job E; E goes to the back, behind B, C and D, which were already waiting (the queue is back at length 4 at step 13). So E prints last, although it was created by the first job. A job that queues more jobs does not get to run them early.

## A failing job

Job C throws. The exception propagates out of the job, the engine records it (two `throw` events at step 19: the throw itself and the fact that nothing caught it) and moves on to job D. In a browser this is a reported error; in the engine it is an event, and the program's outcome stays `normal`. The rule matters for compilers because a transformation that merged two jobs into one, for instance, would let C's exception skip D's output.

## What a compiler must keep

The specification observes output in order. Any pipeline the workbench accepts must print the same six lines in the same order, and the laws check that on generated programs with jobs ([M-02](lab:preset?id=M-02)). The contracts carry what makes this possible: `job.enqueue` reads and writes the resource `jobs`, and `callsUser` (any call into user code) reads and writes every user resource including `jobs`, so no permission derived from them lets a job-related operation move across a call. In plan mode the queue is a root as well: queued closures are moved and updated by every collection, and the output under a stress collector is the same six lines.

> **Exercise.** Make job B queue a job too, and predict the full output before rerunning. Then replace `queueMicrotask` in job A by `setTimeout(…, 0)`: where does its line move, and why ([E-03](lab:preset?id=E-03))?

## Where next

[Chapter 17](lab:book?ch=17) develops jobs, promises and timers. [E-02](lab:preset?id=E-02) adds promises, [E-03](lab:preset?id=E-03) timers, and the shelf doc on [jobs, promises and timers](lab:doc?id=jobs) summarises the queues.
