# Promises and then

A promise is a value that will be settled later, and `then` registers what to do with the value when it is. In the engine, as in JavaScript, the "later" is the microtask queue of [E-01](lab:preset?id=E-01): every reaction to a settled promise runs as a job. This preset's program makes one resolved promise, attaches a chain of two reactions and a separate third one, queues a plain job and prints `sync`. The output is `sync`, `first then: 1`, `another reaction on p: 1`, `plain job`, `second then: 2`, the same order Node prints for the same program.

> **Try it.** [Run it](lab:build) and [open the Events view](lab:show?view=events), then [step the Machine](lab:step?n=15) to the moment the first reaction queues the second.

## then queues, it does not call

`Promise.resolve(1)` lowers to `promise.resolve(1)`, an already fulfilled promise, and `p.then(f)` to a method call:

```text
  p3 = promise.resolve(1)
  f5 = js.closure(@arrow)
  r6 = js.call_method(p3, "then", f5)
  f7 = js.closure(@arrow_2)
  r8 = js.call_method(r6, "then", f7)
```

Because `p3` is already fulfilled, `then` does not wait: it queues a **reaction job** at once (queue length 1 at step 2) and returns a new promise `r6`, still pending. The second `then`, on `r6`, cannot queue anything yet; it records the reaction on `r6`. The third `then`, on `p3` again, queues its job (length 2), and `queueMicrotask` queues the plain job (length 3). Then `main` prints `sync` and returns.

## Settling a promise queues its reactions

The first job runs `arrow`: it prints `first then: 1` and returns `2`. Returning from a reaction fulfils the promise `then` created, `r6`, and fulfilling a promise queues every reaction recorded on it. So `arrow_2` goes to the back of the queue (length 3 again at step 15), behind the reaction on `p3` and the plain job, and `second then: 2` prints last. A chain of `then`s is therefore not one job: each link waits a turn of the queue, and anything queued in between runs first.

> **Try it.** [Select the second then](lab:node?id=main/entry/4) and read its contract in the Inspector: `callsUser`, every permission refused. A `then` on a user object could be any function, so the compiler cannot even assume it queues anything.

## Adoption, and a difference from the standard

`adopt.js` has a reaction that returns a promise instead of a value. The derived promise does not become fulfilled with a promise as its value; it **adopts** the returned promise's state, so the next reaction receives `20`. Three counting jobs measure how long adoption takes. The engine prints (in the [Events view](lab:show?view=events)):

```text
sync | returns a promise | tick 1 | tick 2 | adopted: 20 | tick 3
```

Node prints `adopted: 20` after `tick 3`. The ECMAScript standard spends two jobs on adoption (a job that calls the returned promise's `then`, then the reaction job that settles the derived promise); the workbench's engine spends one, because it calls `then` on the returned promise directly instead of queueing a job to do it. This is a difference in an observable order, so by the workbench's own rules it is a bug in the reference interpreter, and it is listed as one. It also shows why a reference interpreter needs differential tests against real engines: its laws prove that the compiler agrees with it, not that it agrees with the language.

> **Exercise.** Chain a third `then` on `r8` in [program.js](lab:open?file=program.js&line=6) that prints its value. Predict its value and its position in the output, then rerun. Which promise does that reaction wait on?

## Where next

[Chapter 17](lab:book?ch=17) covers the job queues and the order of output; [E-03](lab:preset?id=E-03) adds timers and [J-05](lab:preset?id=J-05) combines all three. The shelf doc on [jobs, promises and timers](lab:doc?id=jobs) has the rules in one place.
