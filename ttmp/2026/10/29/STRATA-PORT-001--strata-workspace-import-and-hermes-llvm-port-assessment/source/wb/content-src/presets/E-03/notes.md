# Timers in virtual time

`setTimeout(f, ms)` asks for `f` to run after at least `ms` milliseconds. This preset sets five timers with delays of 10, 0, 5, 0 and (from inside the 5 ms timer) 2 more milliseconds, plus one microtask, and shows the order in which they run. The engine keeps a **virtual clock**: time advances only when the engine moves it to the next due timer, so the order is the same on every run and on every machine. The output is `script`, `job`, `timer at 0 ms`, `second timer at 0 ms`, `timer at 5 ms`, `job queued by the 5 ms timer`, `timer set at 5 ms for 2 ms later`, `timer at 10 ms`.

> **Try it.** [Open the Events view](lab:show?view=events): every timer appears twice, once when it is set (with its due time) and once when it fires (with the clock's value).

## Two queues and a clock

The engine has a microtask queue ([E-01](lab:preset?id=E-01)) and a list of timers, each with a due time and a sequence number. After the script returns, it runs microtasks until there are none; then it takes the timer with the smallest due time (the smallest sequence number among equal ones), sets the clock to that time and runs it; then it empties the microtask queue again, and so on. So:

| step | event |
|---|---|
| 1 to 7 | four timers set, due at 10, 0, 5 and 0 ms |
| 14 | the clock moves to 0 ms: the first 0 ms timer fires |
| 16 | the second 0 ms timer fires (same time, set later) |
| 18 | the clock moves to 5 ms: the 5 ms timer fires, queues a job and sets a timer due at 7 ms |
| 26 | the job has run; the clock moves to 7 ms |
| 28 | the clock moves to 10 ms |

The microtask queued by the 5 ms timer prints before the 7 ms timer: microtasks always drain between timers. And the microtask queued by the script prints before every timer, even the ones with delay 0: `setTimeout(f, 0)` means "after everything currently queued", not "now".

> **Try it.** [Select the third setTimeout](lab:node?id=main/entry/5) in `main` and read its contract: `timer.set` reads and writes the resource `timers`, so it keeps its order relative to the other `timer.set`s.

## Virtual against real time

Node prints the same program with the last two lines swapped: `timer at 10 ms` before `timer set at 5 ms for 2 ms later`. Real timers fire late. Node's event loop typically wakes once some milliseconds after start, finds the 0, 5 and 10 ms timers all expired, and runs them in one batch in their list order; the 2 ms timer set during that batch is not due yet. The language promises less than the virtual clock delivers: a timer never fires before its delay, and timers with equal delays keep their order. Anything beyond that depends on the machine.

That is why the workbench uses virtual time. A specification that depended on the speed of the host could not be the judge in [refinement checks](lab:doc?id=jobs): the same program could pass on one run and fail on the next. With a virtual clock, the order of output is a function of the program alone, and a compiler that changes it is wrong.

## Where the timer lives

`setTimeout` lowers to `timer.set(f, ms)`. The closure is held by the engine's timer list until it fires, so in plan mode the list is a root: every collection moves the waiting closures and updates their entries, and the output under a stress collector is unchanged.

> **Exercise.** Change the 2 ms delay in [program.js](lab:open?file=program.js&find=2);) to 6 and predict the new order of the last two lines. Then set it to 5: which fires first, the new timer (due at 10 ms) or the old 10 ms timer, and why?

## Where next

[Chapter 17](lab:book?ch=17) explains the queues; [E-02](lab:preset?id=E-02) covers promises and [J-05](lab:preset?id=J-05) an event queue built from all three. The shelf doc on [jobs, promises and timers](lab:doc?id=jobs) summarises the rules.
