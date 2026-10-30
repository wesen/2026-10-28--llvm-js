# A stale reference, caught

This preset runs a plan that is wrong on purpose and shows how the workbench catches it while running. The program pairs two boxes twenty times and prints `210`. The root strategy in `main.js` is the default with one value taken out: `pair`'s parameter `b` gets no root slot. The plan checker would refuse that plan, so `main.js` turns the check off (`checks({ gcSafety: false })` makes missing roots warnings) and the header runs the program in plan mode with a collection at every safepoint. The outcome pill reads `error`.

> **Try it.** [Run with GC stress](lab:run?mode=plan&gc=stress), [turn on the stale overlay](lab:overlay?name=stale&on=1) and [open the Events view](lab:show?view=events): one `stale` event names `b`, the collection that moved it and the use that read it.

## What plan mode simulates

In plan mode the workbench executes the lowered program against its root plan, with a **simulated moving collector**. When it collects, it copies every object reachable from the plan's rooted slots, the globals and the job queues to new addresses, and frees the rest. Values the plan rooted are updated in their slots. A value the plan did not root keeps its old address in its register, and the next read of that register finds either a freed object or an object that now lives elsewhere. Either way the run stops with a stale use:

```text
stale reference: b (object #10) was not rooted, so the collection at pair/entry/0 moved it; it was then used at pair/entry/2
```

`b` was moved rather than freed, because `main` still holds the same box in one of its own rooted slots. That is the dangerous case on real hardware: the old address may still hold a plausible object for a while.

## One bug, three collectors

The [Experiments view](lab:show?view=experiments) runs the same plan with the three settings of plan mode:

| gc | outcome | output | collections | stale at step |
|---|---|---|---|---|
| off | normal | 210 | 0 | |
| alloc | error | (nothing) | 2 | 157 |
| stress | error | (nothing) | 10 | 10 |

With no collections the broken plan prints the right answer: nothing ever moves. With a collection every 16 allocations, the bug shows up on step 157, in the third call of `pair`. With a collection at every safepoint it shows up on step 10, the first time `pair` runs. This is why the workbench's laws and searches run plan mode with stress: a collector that runs rarely can hide a missing root for a long time, and the step at which the failure appears depends on allocation counts that have nothing to do with the bug.

> **Try it.** [Select pair's js.put](lab:node?id=pair/entry/2) on the Stage, the operation that read the stale `b`, and compare its rooted set in the Inspector with [the obj.new before it](lab:node?id=pair/entry/0).

## The static check and the dynamic check

The two checks see the same hole from two sides. The plan checker reports it before anything runs, as three warnings here:

```text
b is live across obj.new at pair/entry/0 but no root assigned
b is live across js.define at pair/entry/1 but no root assigned
b is borrowed by js.put at pair/entry/2 but no root assigned
```

The stress run confirms that the hole matters: a real collection at one of those points breaks a real read. The checker is what admits a plan; the stress run is how a strategy author tests that the checker and the executor agree.

> **Exercise.** In [main.js](lab:open?file=main.js&find=delete), remove `a` instead of `b`. Predict the step at which the stress run stops, then rerun and check. Why does removing `o5` instead give a different message (freed rather than moved)?

## Where next

[Chapter 13](lab:book?ch=13) explains the collector this simulates. [L-04](lab:preset?id=L-04) shows the checker's side alone, [L-06](lab:preset?id=L-06) writes strategies as lambdas, and the shelf doc on [moving collectors and root slots](lab:doc?id=gc-roots) describes how real collectors find roots.
