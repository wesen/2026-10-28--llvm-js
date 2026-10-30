# An engine: admit, evaluate, close

A compiler produces code; an **engine** runs it. This preset takes the ledger from [B-01](lab:preset?id=B-01), compiled with every default, and walks one engine through its whole life: admit the program, evaluate it, run its jobs, read its metrics, close it, and try to use it once more. The [Experiments view](lab:show?view=experiments) lists the nine calls and what each returned.

> **Try it.** [Open the Experiments view](lab:show?view=experiments), then [open main.js](lab:open?file=main.js&find=step('admit) and read the calls in order.

## One engine, one domain

`g.engine()` creates an **execution domain**: one heap, one microtask queue, one timer list, one set of globals, and the code admitted into it. Everything a program does at run time happens inside one domain, and nothing crosses between domains. That boundary is what makes an engine a unit you can reason about: when it closes, everything in it can go.

## Admission comes before execution

`engine.admit(program)` does not run anything. It checks the compiled program (it must have compiled without errors, and its strategies must match any the engine requires), renames its functions into the engine's namespace (`main` becomes `u1.main`) and returns a handle, `code #1`. The snapshot after admission shows one unit with six functions, retained, and the four builtin globals. Separating admission from execution means a refusal never leaves the engine half-changed: [E-05](lab:preset?id=E-05) shows two refusals, each reported with `ranCode: false`.

## Evaluation and jobs are separate steps

`evaluateScript(1)` runs the unit's `main` to completion and reports `fulfilled`. At that point the output has two lines, `rejected: amount must be a number` and `main 42 42`. The audit line is missing: it belongs to a job that `main` queued, and evaluating a script does not run jobs. `runJobs()` does, and reports `{ ran: 1, remaining: 0 }`; now the output has all three lines. A host decides when jobs run (after each script, after each event); the engine only promises to run them in order ([E-01](lab:preset?id=E-01)).

> **Try it.** Delete the `runJobs()` step in [main.js](lab:open?file=main.js&find=runJobs) and rerun: the last `output()` row loses `audit 42`, and `metrics()` reports one job pending.

## What the metrics count

After the jobs, `metrics()` reports:

```text
{"code":{"admittedUnits":1,"codeBytes":1248,"retained":1},"heap":{"objects":18,"allocations":18},"jobs":{"ran":1,"pending":0},"collections":0,"steps":134}
```

`codeBytes` is an estimate the engine keeps per admitted unit (16 bytes per operation), not a measurement of machine code. `objects` and `allocations` agree because this engine runs in spec mode, without a collector; the 134 steps are the same 134 the specification takes for the ledger, now counted inside the engine.

## Closing is ordered

`close()` destroys the runtime first and releases the code second, and says so. The order is the point. Objects in the heap can refer to code (a closure refers to its function); if the code went first, a finaliser or a pending job running during teardown could call into freed code. After `close()`, every call on the engine throws `EngineClosed`, which the last row shows. [E-06](lab:preset?id=E-06) states this rule as a state machine and finds the bad order by search.

> **Exercise.** Admit the same program twice before evaluating, and evaluate both units. What does the output show, and why do the two units not share `ledger` (hint: where does a top-level `const` live)? Compare with [E-07](lab:preset?id=E-07), where two units do share something.

## Where next

[Chapter 18](lab:book?ch=18) develops engines and lifecycles. [E-05](lab:preset?id=E-05) shows admission refusing, [E-06](lab:preset?id=E-06) the lifecycle as a machine, and the shelf doc on [labelled transition systems](lab:doc?id=lts) the formalism.
