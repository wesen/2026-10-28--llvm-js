# Profiles

A **profile** says two things: which operation sets a program may use, and which observations a claim about the program must preserve. "This rewrite is correct" means nothing until it says for which programs and for which observations. This preset runs the same three programs under the three built-in profiles and shows where each one stops.

> **Try it.** [Show the table](lab:show?view=experiments). The numeric IR runs everywhere; the object program needs `js-sync`; the program with a job needs `js-async`. Each refusal names the first operation outside the profile.

## The three built-in profiles

| profile | operation sets | observations |
|---|---|---|
| `core` | `core` | output, outcome |
| `js-sync` | `core`, `js.value`, `js.object`, `js.function` | output, outcome, thrown value, object identity, heap mutation seen later |
| `js-async` (`js`) | all five | the above, and job order |

The `core` set is numbers, booleans, direct calls and `host.print`. Its operations cannot run user code, allocate or throw, which is why a WebAssembly backend can take it whole ([W-01](lab:preset?id=W-01)). `js.value` adds the JavaScript operators that may call `valueOf`, `js.object` adds objects, arrays and property access, `js.function` adds closures, calls and cells, and `js.control` adds jobs, timers, promises and the completion records that `finally` uses.

## Checking a program against a profile

`g.semantics().profile(name).run(target)` first checks that every operation of the module is admitted, then runs it. The check is a scan of the IR, so it is decided before a single step runs:

```js
g.profile('core').check(module)   // ['obj.new in main/entry', 'js.define in main/entry', …]
```

[Open numeric.ir](lab:open?file=numeric.ir&line=2): `sumTo` uses only `num.le`, `num.add` and `host.print`, so all three profiles accept it and it prints 55 for `n = 10`. [Open sync.js](lab:open?file=sync.js&line=2): its first operation is `obj.new`, outside `core`.

## The program on the Stage

This preset's `program.js` queues a job, then fills an array, then prints. [Select job.enqueue](lab:node?id=main/entry/4): it belongs to `js.control`, so `js-sync` refuses the program. Under `js-async` it prints `sync done` and then `job sees 2 entries`: the job runs after the script has finished, and it sees both writes.

> **Try it.** [Show the Machine view](lab:show?view=machine) and find the step where the job starts: it is after `return undefined` of `main`.

That ordering is an observation of `js-async` and not of `js-sync`. A compiler for a synchronous profile may not reorder `job.enqueue` because it is not even allowed to see one; a compiler for `js-async` must keep the job after every synchronous step of the script.

## Profiles order claims

Profiles are ordered by inclusion: `numbers-and-objects`, defined in main.js, admits `core` and `js.object` and is below `js-sync` (`mine.le(g.profile('js-sync'))` is true). A claim proved for a larger profile holds for a smaller one only if the smaller one observes no more, so the profile records its observations too. The workbench's laws run against `js` unless told otherwise.

> **Exercise.** Add `try { print(1); } finally { print(2); }` to sync.js and rerun. Which profile refuses it now, and which operation does it name? Is that the right set for `finally`, given that nothing in it is asynchronous? Write down what you would change.

## Where next

[Chapter 2](lab:book?ch=2) places profiles in the definition of correctness. [S-02](lab:preset?id=S-02) defines the observations themselves, and [E-01](lab:preset?id=E-01) looks closely at job order.
