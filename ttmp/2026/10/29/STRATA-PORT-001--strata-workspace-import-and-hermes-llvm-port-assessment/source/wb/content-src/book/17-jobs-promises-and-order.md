# Jobs, promises and order

A JavaScript program does not end when its last statement runs. Callbacks passed to `queueMicrotask`, handlers attached with `then` and functions given to `setTimeout` run later, one at a time, in an order the language fixes. This chapter explains that order as the workbench's interpreter implements it: run to completion, the microtask queue, promises and their reactions, adoption of one promise by another, and timers in virtual time. By the end you will know why the order of output lines is an observation a compiler must preserve, which operations a compiler may still move past a `job.enqueue`, and one place where the workbench's model of promises differs from the ECMAScript standard by a single job.

## 17.1 Run to completion

The interpreter of [Chapter 2](lab:book?ch=2) runs a program's `main` function first. Everything that `main` schedules waits in a queue, and nothing in the queue runs until `main` returns. When it does, the machine takes one **job** (a function and its arguments) off a queue, calls it, and waits for it to return before taking the next. No job interrupts another. This discipline is called **run to completion**.

It has a consequence you can see in four lines:

```js
let x = 0;
queueMicrotask(() => print("job sees " + x));
x = 1; x = 2;
print("main done");
```

The output is `main done`, then `job sees 2`. The job is created while `x` is 0, but it reads `x` through the cell it shares with `main` ([Chapter 4](lab:book?ch=4)), and by the time it runs `main` has finished and stored 2. The compiled `main` shows the order plainly: `job.enqueue(f3)` comes before `cell.store(c_x2, 1)` and `cell.store(c_x2, 2)`, and the job's own function begins with `cell.load_checked(c_x)`.

Run to completion is what makes the rest of this chapter simple. A job is an ordinary call of an ordinary function, so everything earlier chapters said about calls, cells, safepoints and roots applies inside a job unchanged. What is new is only the question of which job runs next.

## 17.2 The microtask queue and the loop

`queueMicrotask(f)` compiles to `job.enqueue(f)`, an operation in the `js.control` set whose behaviour is `reads+writes(jobs)`: it changes the queue and nothing else. The queue is first in, first out. After `main`, the machine drains it with this loop:

```js
// core.js
  runJobs(limit = Infinity) {
    let ran = 0;
    while (ran < limit && (this.microtasks.length || this.timers.length)) {
      let job;
      if (this.microtasks.length) job = this.microtasks.shift();
      else {
        this.timers.sort((a, b) => a.at - b.at || a.seq - b.seq);
        const tm = this.timers.shift(); this.vtime = tm.at; job = { f: tm.f, args: [] };
        this.event('timer', { what: 'fire', at: tm.at });
      }
      ran++; this.metrics.jobs++;
      this.hostRoots.push(job);                   // the running job is the host's: it stays rooted
      try { this.execDepth++; this.callValue(job.f, undefined, job.args); }
      catch (e) {
        const out = this.outcomeOf(e);
        if (out.kind !== 'throw') return { ran, stopped: out };
      } finally { this.execDepth--; this.hostRoots.pop(); }
    }
    return { ran, remaining: this.microtasks.length + this.timers.length };
  }
```

Read it from the top. The loop runs while either queue has work, up to a limit (10,000 jobs by default, so a program that keeps scheduling itself still stops). The second line of the body is the rule that matters most: a microtask always goes before a timer. Only when the microtask queue is empty does the loop look at timers, sort them, and take the earliest. A job that throws is reported (the run's events record an uncaught throw) and the loop goes on with the next job; only an engine error, such as a stale reference in plan mode, stops it.

Two lines concern memory. `hostRoots.push(job)` keeps the running job's function and arguments reachable while the job runs, because the job has just been taken off the queue, which was its root until then. [Chapter 13](lab:book?ch=13) explained why every reference the collector cannot see goes stale; the queue and the running job are roots of the host, in the same way the plan's slots are roots of compiled code. `execDepth` tells the machine that a host helper is active, which matters for how the simulated collector forwards the helper's handles.

A microtask may enqueue another microtask. The new one goes to the back of the same queue and still runs before any timer, so a chain of microtasks can delay a timer indefinitely. The limit of 10,000 is the workbench's guard against that.

> **Try it.** [Load E-01 Microtasks and order](lab:preset?id=E-01), [open program.js](lab:open?file=program.js&line=3) and [show the Events](lab:show?view=events). The output is `script start`, `script end`, `job A`, `job B`, `job D still runs`, `job E, queued by job A`: job E waits behind the jobs queued before it, and job C's throw does not stop job D.

## 17.3 Timers in virtual time

`setTimeout(f, ms)` compiles to `timer.set(f, ms)`. The machine keeps a **virtual clock**, `vtime`, which starts at 0 and moves only when a timer fires: it jumps to that timer's time. A timer set at virtual time $v$ with delay $d$ fires at $v + \max(0, d)$; a negative or non-numeric delay counts as 0. Timers with the same time fire in the order they were set, which is what the second key of the sort, `seq`, records.

Virtual time makes runs deterministic. A delay of 5 does not mean 5 ms of the host's clock; it means "after every timer due earlier, and after the microtasks those timers schedule". Here is a program that uses all three kinds of scheduling:

```js
print("main start");
setTimeout(() => print("timer 5"), 5);
setTimeout(() => {
  print("timer 0");
  queueMicrotask(() => print("micro from timer"));
}, 0);
Promise.resolve(1).then(v => print("then " + v));
queueMicrotask(() => print("micro"));
print("main end");
```

It prints `main start`, `main end`, `then 1`, `micro`, `timer 0`, `micro from timer`, `timer 5`, the same seven lines Node prints for it. The interpreter takes 25 steps and runs 5 jobs. Figure 17.1 draws the steps on one axis: `main` takes steps 1 to 12, the two microtasks take 13 to 17, and the timers come last, with the microtask that the first timer scheduled squeezed in before the second timer.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 250">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="6" y="58" font-size="10" class="lbl">main</text>
  <text x="6" y="118" font-size="10" class="lbl">micro</text>
  <text x="6" y="178" font-size="10" class="lbl">timers</text>
  <line x1="40" y1="200" x2="640" y2="200" class="hair" stroke="currentColor" stroke-width="0.6"/>
  <rect x="40" y="40" width="288" height="30" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="50" y="59" font-size="11">main: steps 1–12</text>
  <rect x="328" y="100" width="72" height="30" class="ink f-fill2" stroke="currentColor" stroke-width="1"/>
  <text x="333" y="119" font-size="10">then 1</text>
  <rect x="400" y="100" width="48" height="30" class="ink f-fill2" stroke="currentColor" stroke-width="1"/>
  <text x="405" y="119" font-size="10">micro</text>
  <rect x="448" y="160" width="96" height="30" class="ink f-fill" stroke="currentColor" stroke-width="1"/>
  <text x="453" y="179" font-size="10">timer 0</text>
  <rect x="544" y="100" width="48" height="30" class="acc f-fill2" stroke="currentColor" stroke-width="1.6"/>
  <text x="540" y="92" font-size="10">micro from timer</text>
  <rect x="592" y="160" width="48" height="30" class="ink f-fill" stroke="currentColor" stroke-width="1"/>
  <text x="597" y="179" font-size="10">timer 5</text>
  <line x1="220" y1="70" x2="328" y2="112" class="ink dash" stroke="currentColor" stroke-width="0.8" marker-end="url(#arrow)"/>
  <line x1="268" y1="70" x2="400" y2="118" class="ink dash" stroke="currentColor" stroke-width="0.8" marker-end="url(#arrow)"/>
  <line x1="508" y1="160" x2="548" y2="130" class="ink dash" stroke="currentColor" stroke-width="0.8" marker-end="url(#arrow)"/>
  <line x1="40" y1="196" x2="40" y2="204" stroke="currentColor" class="ink"/>
  <line x1="328" y1="196" x2="328" y2="204" stroke="currentColor" class="ink"/>
  <line x1="448" y1="196" x2="448" y2="204" stroke="currentColor" class="ink"/>
  <line x1="592" y1="196" x2="592" y2="204" stroke="currentColor" class="ink"/>
  <line x1="640" y1="196" x2="640" y2="204" stroke="currentColor" class="ink"/>
  <text x="36" y="217" font-size="9" class="mut">1</text>
  <text x="320" y="217" font-size="9" class="mut">13</text>
  <text x="440" y="217" font-size="9" class="mut">18</text>
  <text x="584" y="217" font-size="9" class="mut">24</text>
  <text x="632" y="217" font-size="9" class="mut">25</text>
  <text x="40" y="236" font-size="10" class="it">virtual time 0</text>
  <line x1="120" y1="232" x2="588" y2="232" class="hair dot" stroke="currentColor" stroke-width="0.6"/>
  <text x="596" y="236" font-size="10" class="it">5</text>
  <text x="648" y="204" font-size="9" class="lbl">step</text>
</svg>
```

**Figure 17.1.** The interpreter's 25 steps for the program above, measured in spec mode: one row per kind of work. Dashed arrows run from the step that scheduled a microtask to the job. Virtual time stays at 0 until the 5 ms timer fires at step 24.

The run also shows how little the compiler sees of all this. In core IR, `main` is a straight line of eleven operations and a `return undefined`: two `timer.set`, a `promise.resolve`, a `js.call_method(p4, "then", f5)` and one `job.enqueue`, each taking a closure made by `js.closure`. The scheduling is entirely in the runtime; what the compiler must get right is the order and the arguments of those operations.

## 17.4 Promises and then

A **promise** is an object with a state (pending, fulfilled or rejected), a value once it is settled, and a list of **reactions**: handlers waiting for it to settle. `Promise.resolve(v)` compiles to `promise.resolve(v)`, which allocates a fulfilled promise (or returns `v` itself if it is already a promise: `Promise.resolve(p) === p` prints `true`). `p.then(f)` is an ordinary method call that reaches a builtin:

```js
// core.js
  promiseThen(p, onFulfilled) {
    const q = this.alloc('promise', { state: 'pending', value: undefined, reactions: [] });
    const po = this.deref(p);
    const reaction = { handler: onFulfilled, target: q };
    if (po.state === 'fulfilled') this.enqueue(this.builtin('react'), [reaction, po.value]);
    else po.reactions.push(reaction);
    return q;
  }
```

`then` always returns a new pending promise `q`, the **derived promise**. If `p` is already fulfilled, the reaction becomes a microtask at once; otherwise it waits in `p`'s list. Either way the handler never runs during the call to `then`, which is why `print("sync")` after a `then` prints first. When the reaction job runs, the builtin `react` calls the handler with the value and settles `q` with whatever the handler returned, which enqueues `q`'s own reactions. A chain `p.then(f).then(g)` therefore takes one job per link: `then 1` and `then 2` print two jobs after `sync`.

[E-02 Promises and then](lab:preset?id=E-02) shows the rule with two reactions on one promise: its program prints `sync`, `first then: 1`, `another reaction on p: 1`, `plain job`, `second then: 2`, because the second link of the chain is queued only when the first runs.

If the handler throws, `react` marks `q` rejected and records an `unhandled rejection` event. The workbench's `then` takes only a fulfilment handler, so a rejection is never handled: the next link of the chain never runs. That is a deliberate limit of the subset, and the Events view says so when it happens.

## 17.5 Adoption, and a difference of one job

A handler may return a promise. Then the derived promise does not settle with the promise object; it **adopts** it, settling when the returned promise settles and with its value. The workbench implements adoption in `fulfil`:

```js
// core.js
  fulfil(q, value) {
    const qo = this.deref(q);
    if (qo.state !== 'pending') return;
    if (value && value.isRef && this.deref(value).kind === 'promise') { this.promiseThen(value, this.builtin('adopt', q)); return; }
    qo.state = 'fulfilled'; qo.value = value;
    for (const r of qo.reactions) this.enqueue(this.builtin('react'), [r, value]);
    qo.reactions = [];
  }
```

The third line is adoption: instead of fulfilling `q` with a promise, it attaches a reaction to that promise whose handler, `adopt`, fulfils `q` later. If the returned promise is already fulfilled, that reaction is enqueued immediately.

ECMAScript takes one more step. When a handler returns a thenable, the standard first enqueues a job (it names it NewPromiseResolveThenableJob) whose only work is to call the thenable's `then`; the reaction is enqueued by that job, not by the handler. So adoption costs two jobs in the standard (the thenable job, then the reaction that settles the derived promise) and one in the workbench (the `adopt` reaction alone), and the difference is visible when another chain runs alongside. This program shows it:

```js
const inner = Promise.resolve(7);
Promise.resolve(0).then(v => inner).then(v => print("adopted " + v));
Promise.resolve(0).then(v => print("a1")).then(v => print("a2")).then(v => print("a3")).then(v => print("a4"));
```

The workbench prints `a1 a2 adopted 7 a3 a4` and runs 7 jobs; Node prints `a1 a2 a3 adopted 7 a4`. Figure 17.2 lines the two job sequences up.

> **Try it.** [Load E-02](lab:preset?id=E-02) and [open adopt.js](lab:open?file=adopt.js), which measures adoption with counting jobs: the workbench prints `adopted: 20` after `tick 2`, Node after `tick 3`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 190">
  <text x="10" y="44" font-size="10" class="lbl">workbench</text>
  <text x="10" y="134" font-size="10" class="lbl">ECMAScript</text>
  <g font-size="10">
    <rect x="100" y="26" width="64" height="28" class="ink f-fill" stroke="currentColor"/><text x="106" y="44">ret inner</text>
    <rect x="168" y="26" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="186" y="44">a1</text>
    <rect x="236" y="26" width="64" height="28" class="ink f-fill" stroke="currentColor"/><text x="244" y="44">adopt</text>
    <rect x="304" y="26" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="322" y="44">a2</text>
    <rect x="372" y="26" width="64" height="28" class="acc f-fill" stroke="currentColor" stroke-width="1.6"/><text x="378" y="44">adopted</text>
    <rect x="440" y="26" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="458" y="44">a3</text>
    <rect x="508" y="26" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="526" y="44">a4</text>
    <rect x="100" y="116" width="64" height="28" class="ink f-fill" stroke="currentColor"/><text x="106" y="134">ret inner</text>
    <rect x="168" y="116" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="186" y="134">a1</text>
    <rect x="236" y="116" width="64" height="28" class="ink f-fill" stroke="currentColor"/><text x="242" y="134">thenable</text>
    <rect x="304" y="116" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="322" y="134">a2</text>
    <rect x="372" y="116" width="64" height="28" class="ink f-fill" stroke="currentColor"/><text x="380" y="134">adopt</text>
    <rect x="440" y="116" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="458" y="134">a3</text>
    <rect x="508" y="116" width="64" height="28" class="acc f-fill" stroke="currentColor" stroke-width="1.6"/><text x="514" y="134">adopted</text>
    <rect x="576" y="116" width="64" height="28" class="ink f-fill2" stroke="currentColor"/><text x="594" y="134">a4</text>
  </g>
  <line x1="100" y1="76" x2="640" y2="76" class="hair" stroke="currentColor" stroke-width="0.6"/>
  <text x="100" y="92" font-size="9" class="mut">job 1</text>
  <text x="508" y="92" font-size="9" class="mut">job 7</text>
  <text x="100" y="168" font-size="9" class="mut">job 1</text>
  <text x="576" y="168" font-size="9" class="mut">job 8</text>
  <line x1="268" y1="148" x2="268" y2="160" class="ink" stroke="currentColor"/>
  <text x="200" y="182" font-size="10" class="it">the extra job calls inner.then</text>
</svg>
```

**Figure 17.2.** The jobs of the adoption program in order. Top: the workbench, 7 jobs, measured. Bottom: the order the ECMAScript standard prescribes, 8 jobs, matching the output of Node. Shaded boxes are the second chain's handlers; the accented box is the line that moves.

This is a defect of the workbench's model, not a choice: its specification disagrees with the language's on this program. It matters for the book in two ways. First, every check that compares a compiled program with the workbench's interpreter is a comparison with *this* model, so a compiler that preserved job order perfectly would still print `adopted 7` one line early compared with Node. The specification is only as good as its agreement with the language, which is why [Chapter 19](lab:book?ch=19) tests the interpreter itself against an independent engine. Second, the fix is local: an extra job in the third line of `fulfil`, and nothing in the compiler changes.

## 17.6 Order as an observation

The profiles of [Chapter 2](lab:book?ch=2) say what a run is compared on. The `js-sync` profile observes output, outcome, thrown values, object identity and later heap mutation; `js-async` (the default `js`) adds **job order**. Under `js-async`, two runs are the same only if their jobs print in the same order.

For a compiler, the question is which operations may move relative to the ones that schedule work. The contracts of [Chapter 6](lab:book?ch=6) answer it without any special rule for jobs, because the queues are resources like the heap. `g.perm.commute` reports:

| first | second | may swap | reason |
|---|---|---|---|
| `job.enqueue` | `job.enqueue` | no | they conflict on jobs |
| `promise.resolve` | `job.enqueue` | no | they conflict on jobs |
| `js.call` | `job.enqueue` | no | one of them may run user code |
| `cell.store` | `job.enqueue` | yes | no shared resource is written |
| `host.print` | `job.enqueue` | yes | no shared resource is written |
| `timer.set` | `job.enqueue` | yes | no shared resource is written |

The last three rows are run to completion at work. A store after `job.enqueue` may move before it because the job cannot run until `main` returns; in the four-line example of section 17.1 the store of 1 could even be deleted, since the store of 2 overwrites it before anything reads the cell. A `print` may move past an enqueue for the same reason. A `timer.set` may swap with a `job.enqueue` because the two write different queues, and every microtask runs before every timer anyway. Two enqueues may not swap, and neither may a call that could run user code, since that code could enqueue something itself.

## 17.7 The running example: the audit job

The ledger's last statement is `queueMicrotask(() => print("audit " + ledger.total()))`. In core IR it is the end of `main`: `f28 = js.closure(@arrow, c_ledger3)` followed by `job.enqueue(f28)`. The closure captures the cell holding `ledger`, so the job reads the ledger after `main` has returned. In spec mode `main` returns at step 101, the job starts at step 102, and the run ends at step 134 with `audit 42`, one job in all (FACTS.md).

> **Try it.** [Load B-01](lab:preset?id=B-01), [select the enqueue](lab:node?id=main/endtry2/12), then [run in plan mode with GC stress](lab:run?mode=plan&gc=stress) and [open Events](lab:show?view=events).

Under stress the collector runs 68 times. The enqueue itself is a safepoint, and while the job waits in the queue the closure in `f28` is reachable only through the queue: the machine moves it like any other object at the next collection. During the job, which calls `total`, there are 17 more collections; each finds the job's closure through `hostRoots` and the ledger through the closure's captured cell. The output is the same three lines, and `observe.equal` reports the spec and plan runs equal on 3 observations. The presets [E-01 Microtasks and order](lab:preset?id=E-01), [E-02 Promises and then](lab:preset?id=E-02), [E-03 Timers in virtual time](lab:preset?id=E-03) and [J-05 An event queue](lab:preset?id=J-05) take each mechanism apart separately; the shelf doc [Jobs, promises and timers](lab:doc?id=jobs) collects the rules on one page.

## 17.8 Key points

- A program runs `main` to completion, then one job at a time; a job is an ordinary call, so everything about calls, cells and roots applies inside it.
- The microtask queue is first in, first out, and every microtask runs before any timer; timers fire in virtual-time order, ties broken by the order they were set.
- `then` returns a new pending promise and never runs its handler during the call; each link of a chain takes one job.
- The workbench adopts a returned promise in one job where ECMAScript takes two, so its specification differs from the language's on programs that interleave adoption with another chain.
- Job order is an observation of the `js-async` profile; contracts decide which operations may cross a `job.enqueue`, and run to completion lets stores and prints cross it.
- The queues and the running job are roots of the host; a moving collector must update them like the plan's slots.

## Exercises

1. In the four-line example of section 17.1, swap the two `cell.store` lines by hand and predict the output. Then ask `g.perm.commute('cell.store', 'cell.store')` and explain its answer.
2. Change the 5 ms timer of Figure 17.1's program to `-3` and to `"5"`, and predict the order before you run it. Which line of the machine decides each case?
3. Write a program of three or four lines whose output in the workbench differs from Node's because of adoption, without copying the one in section 17.5. Count the jobs in each order.
4. Make a microtask that enqueues itself again. How many jobs run before the loop's limit stops it, and what does `runJobs` return? Is the program's outcome `normal`?
5. Project: in a copy of `site/js/core.js`, make `fulfil` enqueue a separate job that calls the returned promise's `then`, so adoption takes two jobs. Rerun the program of section 17.5 and the ledger, and check that everything else in this chapter still holds.

The next chapter puts the machine itself behind an interface: an engine that admits code, runs it, runs its jobs and shuts down, and the state machines that say in which order those things may happen.
