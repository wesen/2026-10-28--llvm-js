# statusReturn and compatibility

A root strategy decides where managed values live; an exception strategy decides how control gets from a throwing helper to a handler. The two are not independent: whatever the exception mechanism skips over, the catch must repair, and what needs repairing depends on where the roots are. This preset tabulates which pairs of strategies the workbench accepts, shows why `statusReturn` is refused with Hermes's helpers and accepted with the workbench's own, and compiles [L-08](lab:preset?id=L-08)'s `risky` under `statusReturn`.

> **Try it.** [Open the Experiments view](lab:show?view=experiments) for the nine pairs, then [the Events view](lab:show?view=events) for the two `check()` results that `main.js` prints.

## Three ways to unwind

With **setjmp**, the function saves a jump buffer once and a throwing helper long-jumps to it; this is the protocol of the Hermes runtime ([L-08](lab:preset?id=L-08)). With **statusReturn**, every helper that may throw returns a status, and the compiled code tests it after each call and branches to the handler; nothing jumps, so nothing is skipped, at the price of a test after every call. With **landingPads**, the unwinder walks the native stack with tables the compiler emitted (the C++ approach); calls cost nothing until an exception happens.

## Compatibility is declared, not inferred

`g.compat(roots, exceptions)` answers from a table of declared pairs, each with what it requires and the evidence for it:

| roots | exceptions | declared | requires |
|---|---|---|---|
| distinct | setjmp | yes | |
| distinct | statusReturn | yes | helpers that return a status |
| stackReuse | setjmp | yes | |
| stackReuse | statusReturn | yes | helpers that return a status |
| arena | setjmp | yes | the arena mark saved in every catch checkpoint |
| arena | statusReturn | no | |
| any | landingPads | no | |

A pair is declared only after someone has traced throw, catch, collection and suspension through it. `arena` with `setjmp` is declared with a requirement: frames that the jump skips may have taken arena slots, so each catch checkpoint saves the arena mark and the catch resets it. `arena` with `statusReturn` would probably work (nothing is skipped), but nobody has traced it, so the pipeline refuses it with a message naming `g.compat.declare`. The workbench prefers a refusal it can explain to a combination it has not checked.

## Providers decide what helpers can do

The second check is about helpers. Every JavaScript operation set (`js.value`, `js.object`, `js.function`, `js.control`) is provided by Hermes by default, and Hermes's helpers throw by long-jumping. A strategy that expects helpers to return a status cannot work with them:

```text
exceptions: statusReturn needs helpers that report errors without longjmp, but js.value, js.object, js.function, js.control are provided by Hermes, whose helpers throw nonlocally; keep setjmp or provide those sets yourself
```

Providing all four sets with the reference provider (`.provide({ 'js.value': 'reference', … })`) satisfies the check, and `risky` compiles. Its plan records the choice:

```text
; unwind risky/try3 → catch1: statusReturn, restores root chain, managed frame
```

> **Try it.** [Show risky's plan at L3](lab:level?l=L3) and compare the last line with [L-08](lab:preset?id=L-08)'s. Then [ask what a status check would cost](lab:ask?q=How%20many%20status%20checks%20would%20risky%20need%20under%20statusReturn%2C%20and%20where%3F).

## What the workbench does not yet do

The plan and the pipeline check implement `statusReturn`; the printers do not. L2 still marks each binding `throws (setjmp)`, because the mark comes from the operation's obligations rather than the provider, and the LLVM text still contains the `_setjmp` prologue and `catch.dispatch` of [W-06](lab:preset?id=W-06). The run is unaffected (the specification and plan mode do not model the mechanism, only the plan), and it prints `2 / caught no x 1 / -1` under stress. A status-return emitter would put `%st = call i32 @helper(...)` and `br i1 %failed, label %h.catch1, ...` after every throwing call in `try3`.

> **Exercise.** In [main.js](lab:open?file=main.js&find=landingPads) add a row for `none` roots. Which pairs are declared for it, and what does the `evidence` column say? Then call `g.compat.declare(g.roots.arena(), g.exceptions.statusReturn(), { requires: 'helpers that return a status', evidence: 'my trace' })` before the loop and rerun: what changes, and why is a declaration a claim someone has to stand behind?

## Where next

[Chapter 14](lab:book?ch=14) develops the three mechanisms; the shelf doc on [unwinding](lab:doc?id=unwinding) compares their costs. [C-08](lab:preset?id=C-08) is about providers and operation sets.
