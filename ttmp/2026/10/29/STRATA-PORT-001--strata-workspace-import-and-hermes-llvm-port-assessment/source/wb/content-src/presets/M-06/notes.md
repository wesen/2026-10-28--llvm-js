# The process as a value

On the screen are two plans for the same job, porting the ledger from the workbench to a native build, written as **processes** and checked against the same three requirements. A process is a list of steps of five kinds: `step`, `diverge` (open alternatives), `converge` (choose among them, by stated criteria), `critique` (a second reader), and `loop` (repeat until a condition holds). Each step says what it produces. `check({ requires })` reports a required output that no step produces and a divergence that never converges.

> **Try it.** [Run main.js](lab:build) and [open Experiments](lab:show?view=experiments). The careful plan passes; the hurried one fails with four issues. [Events](lab:show?view=events) prints the careful plan's steps as YAML.

## Writing a process

```js
const port = g.process('porting the ledger to a native build')
  .step('fix the specification', { week: 1, produces: ['profile js-async', 'spec runs of the ledger'] })
  .step('measure the workbench plans', { week: 1, produces: ['FACTS.md', 'root slots per function'] })
  .diverge('root strategies', { week: 2, options: ['distinct', 'stackReuse', 'arena'] })
  .converge('root strategies', { week: 2, by: 'X-06 hypotheses H1 to H3', produces: [rootsDecision] })
  .step('emit LLVM IR and build locally', { week: 3, produces: ['ledger.ll', 'a local Hermes and LLVM build'] })
  .critique('a second reader checks the plan against the helpers', { week: 3, produces: ['review notes'] })
  .loop('fix and re-measure until refines holds', { week: 4, until: 'refines(pipeline) on 200 generated programs' })
  .step('record the outcome', { week: 4, produces: ['decision log'] });
```

Like every other value in the workbench, a process is immutable: each call returns a new process, so a variant of a plan is a branch, not an edit. A `produces` entry may be a string or a value; here the convergence produces a decision record ([M-05](lab:preset?id=M-05)), and the check matches it by its question.

## What the check finds

The requirements are three outputs: `spec runs of the ledger`, the root-strategy decision, and `decision log`. The careful plan produces all three and every divergence has a convergence of the same name. The hurried plan:

```js
const hurried = g.process('porting in a hurry')
  .step('emit LLVM IR', { produces: ['ledger.ll'] })
  .diverge('exception strategies', { options: ['setjmp', 'statusReturn'] })
  .step('ship it', { produces: ['a binary'] });
```

fails four ways: no specification runs, so there is nothing to compare the binary with; no decision about roots; no decision log; and a divergence over exception strategies that is never resolved, so the binary embodies a choice nobody made.

## Why make a process a value

Writing the plan as data does not make it good, but it makes some ways of being bad visible to a program. The two checks here are structural: required outputs and unresolved alternatives. They are cheap, and they catch the plans that skip the specification or ship before deciding. Because the plan is a value, it can be compared with the next one, stored next to the decisions it produced, and checked again after it changes.

The order of the careful plan is also the order of this book: meaning first, then measurement, then alternatives and a decision, then the native build, a review, and a loop that only ends when refinement holds on generated programs.

> **Try it.** Remove the `converge` step from the careful plan and rerun: the check reports `"root strategies" diverges and never converges` and the missing decision.

> **Exercise.** Add a requirement, `'review notes'`, and make the hurried plan pass all four requirements with as few steps as you can. Then write a third process for adding a new operation to the core set, with a `critique` step whose `produces` is a LawReport name from [M-01](lab:preset?id=M-01).

## Where next

[Chapter 21](lab:book?ch=21) follows this process from the workbench to a native compiler. The doc on [design spaces](lab:doc?id=design-spaces) covers the alternatives a `diverge` step opens, and [M-07](lab:preset?id=M-07) runs every check the process ends with.
