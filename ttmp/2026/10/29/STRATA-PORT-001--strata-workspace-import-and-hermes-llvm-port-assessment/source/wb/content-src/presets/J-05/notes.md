# An event queue

On the screen is a script that schedules work four ways: two timers (20 ms and 0 ms, the second queuing a microtask of its own), a promise with two `then` reactions, a plain microtask, and a last microtask that counts the notes so far. Each piece of work calls `note`, which appends to a shared `log` and prints. The output order is the point: `script start`, `script end`, `then 1`, `microtask`, `4 notes so far`, `then 2`, `timer 0`, `microtask from timer 0`, `timer 20`. A compiler that reorders any two of these lines has changed the program, so this order is an observation the engine must keep.

> **Try it.** [Open program.js](lab:open?file=program.js&line=5), [run it](lab:build) and [open Events](lab:show?view=events): each `job` event records an enqueue with the queue's length, and each `timer` event a set or a fire in virtual time.

## Run to completion, then the queues

The script runs to its end before any job: that is why `script end` comes second, although four jobs were scheduled before it. Then the engine drains the **microtask queue** in order, and only when it is empty does it fire the next **timer** in virtual time, drain the microtasks that timer queued, and so on. The workbench implements exactly this loop: main, then microtasks until none are left, then timers by time and by the order they were set.

## Promises are microtasks too

`Promise.resolve(1)` makes a fulfilled promise. `.then(f)` on a fulfilled promise queues a reaction job at once, so `then 1` is queued before `queueMicrotask(…)` adds `microtask`. The reaction returns `v + 1`, which fulfils the promise returned by the first `then`, and only then is the second reaction queued, behind `4 notes so far`. That is why `then 2` comes after it, although it was written first.

```text
p10 = promise.resolve(1)
f11 = js.closure(@arrow_4, c_note3)
r12 = js.call_method(p10, "then", f11)
f13 = js.closure(@arrow_5, c_note3)
r14 = js.call_method(r12, "then", f13)
```

[Select the first then](lab:node?id=main/entry/14). In the IR, `then` is an ordinary method call on the promise object: the order comes from the runtime's queue, not from anything the compiler arranges.

## Timers in virtual time

`setTimeout(f, 20)` and `setTimeout(f, 0)` become `timer.set` operations ([select the first](lab:node?id=main/entry/9)). Time is virtual: no clock is read, the engine keeps a counter and jumps it to the next timer. The 0 ms timer fires first, its `queueMicrotask` runs before the 20 ms timer, and the run is the same every time, which makes the order something a test can compare.

## What the compiler sees

`note` is a function declaration that seven arrow functions call, so it lives in a cell, `c_note3`, and each arrow receives that cell. `log` is shared by `note` and the last microtask, so it is a cell too, `c_log2`. Every arrow is a separate function in the module, nine in all. Every `timer.set`, `job.enqueue` and `then` call is a safepoint: the closures they receive are objects, and the queues that hold them are roots the collector updates. Under [GC stress](lab:run?mode=plan&gc=stress) the collector runs 57 times in 100 steps, moves the closures sitting in the queues, and the order of the output does not change.

> **Exercise.** Make the first reaction return a promise, `return Promise.resolve(v + 1);`. Adopting a promise costs an extra job: the run goes from 7 jobs to 8 (the Machine view's metrics count them). Does `then 2` move in the output? Add another `queueMicrotask` after the first one and find a program where adoption does change the order.

## Where next

[Chapter 17](lab:book?ch=17) explains run to completion, adoption and virtual time. [E-01](lab:preset?id=E-01) and [E-02](lab:preset?id=E-02) take the queues one at a time, and [E-03](lab:preset?id=E-03) adds timers.
