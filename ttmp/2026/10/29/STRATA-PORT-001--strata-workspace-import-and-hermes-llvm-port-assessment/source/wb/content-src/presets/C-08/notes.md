# Providers and operation sets

The standard operations are grouped into five **operation sets**: `core` (numbers, booleans, direct calls, printing), `js.value` (JavaScript arithmetic, comparison and `typeof`), `js.object` (objects, arrays, property access), `js.function` (closures, calls, cells, globals) and `js.control` (jobs, timers, promises, completion records). A **provider** implements a set: it supplies the runtime helpers that the lowered code calls. By default Hermes provides the four JavaScript sets and the workbench's reference implementation provides `core`. This preset lists the sets, then asks `pipeline.check()` about four combinations of providers and strategies.

> **Try it.** [Show Events](lab:show?view=events) for the set sizes, then [the table](lab:show?view=experiments): two of the four pipelines are refused before anything compiles, each with a reason.

## Sets and their sizes

`main.js` prints each set from `g.opsets`: `core` has 26 operations, `js.value` 16, `js.object` 9, `js.function` 10 and `js.control` 8. A set is the unit of substitution. A profile (`g.profile('core')`) admits some sets and not others, and a provider takes responsibility for a whole set: you cannot have Hermes implement `js.get` and someone else implement `js.put`, because the two must agree on how objects are laid out.

## What a provider owes

A provider must satisfy every contract in its set. If `js.get` is declared `callsUser` with `mayCollect, nonlocalThrow`, the provider's helper may run user code, may collect and may throw nonlocally, and the compiled code around it is built on exactly those assumptions: roots for borrowed operands, a landing place for the exception. A provider that did less would be correct; one that did more (collect inside an operation declared not to) would break the plan.

How a provider throws is part of that bargain. Hermes's helpers throw with `longjmp`: control leaves the helper and lands in the nearest `setjmp` checkpoint, skipping the compiled code in between. That is why the default exception strategy is `setjmp` ([L-08](lab:preset?id=L-08)).

## The checker refuses before it compiles

[Open main.js](lab:open?file=main.js&find=const%20configs) at the four configurations:

- The default pipeline (Hermes helpers, `setjmp`) checks.
- `exceptions('statusReturn')` with Hermes helpers is refused: a status-return strategy expects each helper to return a code that the caller tests, and a helper that `longjmp`s past the caller never returns one. The message names the four sets still provided by Hermes.
- The same strategy with `.provide({ 'js.value': 'reference', … })` for all four sets checks: the reference helpers report errors by returning.
- Adding `roots('arena')` is refused for a different reason: nobody has declared that arena roots and status returns work together. `g.compat` holds the declared pairs ([L-09](lab:preset?id=L-09)), and an undeclared pair is an error rather than a guess.

The program, `f`, is compiled with the third pipeline, and runs: `2 0`. The second call passes `null`, so `null.x` throws a TypeError inside the `try` and `f` returns 0. (Events also shows a warning that block `endtry2` is unreachable: both arms of the `try` return, so the join after it is never reached, and the rewrites delete it.)

> **Try it.** [Look at f in L3](lab:level?l=L3) and [the Plan view](lab:show?view=plan): the unwind record for `try3` names its handler `catch1` and the strategy `statusReturn`.

## What the workbench does and does not change

In the workbench, the exception strategy and the providers are recorded in the plan and enforced by `check()`; they do not change the emitted text. The LLVM printer only knows the Hermes `setjmp` protocol, so the LLVM text for this program is the same with either strategy. The value of the check is that a combination that cannot work is refused by name, before a real backend would produce code that crashes. [Chapter 14](lab:book?ch=14) describes what a status-return backend would emit.

> **Exercise.** Replace `'reference'` for `js.control` only with `'hermes'` and rerun. Which sets does the refusal list now? Then declare the arena pair with `g.compat.declare(g.roots.arena(), g.exceptions.statusReturn(), { requires: 'the arena mark saved at every status check', evidence: 'C-08 exercise' })` before the configurations, and rerun.

## Where next

[Chapter 6](lab:book?ch=6) introduces sets and providers with contracts; [Chapter 14](lab:book?ch=14) covers unwinding strategies. [C-05](lab:preset?id=C-05) adds a set of your own. The doc [setjmp, status codes and landing pads](lab:doc?id=unwinding) compares the strategies.
