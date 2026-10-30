# A plugin host

This preset builds the situation that makes engine lifecycles hard: one engine running code from several sources that call each other. Three plugins register hooks in a shared global list; the host's dispatcher (`program.js`) calls every hook for each event and keeps going when one fails. `main.js` admits the units one by one into a single engine, evaluates each, runs the jobs and closes the engine. The [Experiments view](lab:show?view=experiments) shows what each unit did.

> **Try it.** [Open the Experiments view](lab:show?view=experiments), then [open plugin-a.js](lab:open?file=plugin-a.js&line=2) and [plugin-b.js](lab:open?file=plugin-b.js&line=2) to see how they share `hooks`.

## Four units, one domain

| unit | admitted | state | printed |
|---|---|---|---|
| plugin-a.js | code #1 | fulfilled | plugin A loaded |
| plugin-b.js | code #2 | fulfilled | plugin B loaded |
| plugin-c.js | refused | compile errors | plugin-c.js did not compile: classes are outside this subset |
| program.js | code #3 | fulfilled | A saw open (1) \| B saw open \| A saw save (2) \| a hook failed: B cannot save |
| (jobs) | | ran 1 | A saw close (3) \| B saw close |

Plugin A assigns `hooks = []` without declaring it, which creates a **global**: a property of the engine's global object, visible to every unit (`js.global_put("hooks", …)` at L1). Its `let count` is different: a top-level `let` belongs to its unit's `main`, and A's hook captures it in a cell. So the hook keeps counting across events (1, 2, 3), and no other unit can see `count`. Plugin B appends its hook to the same list. Plugin C uses a class, which the frontend does not accept, so admission refuses it ([E-05](lab:preset?id=E-05)) and the other units never notice.

## Calls across units

The dispatcher reads the global, loops over it and calls each hook inside a `try`:

```text
try7() throws to catch5:
  r14 = js.call(item10, undefined, event)
```

`item10` is a closure that unit 1 or unit 2 created. The call runs their code with their captured cells, from unit 3's frame. When B's hook throws on `save`, the exception travels out of B's code into the dispatcher's handler, which prints `a hook failed: B cannot save` and moves on to the next hook. The `close` event comes from a job the dispatcher queued: it runs after the dispatcher's `main` has returned, and still calls into units 1 and 2.

> **Try it.** [Select the call](lab:node?id=dispatch/try7/0) on the Stage and [turn on exceptional edges](lab:overlay?name=exceptional&on=1): its block's dashed edge goes to `catch5`.

## Why every unit stays retained

The snapshot before close lists three units, all `retained: true`. The engine cannot release plugin A's code when A's `main` finishes: A's hook is still in `hooks`, and any later event will call it. In general an engine cannot know when code becomes unreachable without tracing the heap for closures that point at it, so this engine keeps every admitted unit until `close()`, which destroys the runtime (and with it every closure) before releasing any code. [E-06](lab:preset?id=E-06) checks that order as a state machine.

## Running the dispatcher alone

The header runs `program.js` on its own, outside the host, and the outcome pill reads `throw`: `ReferenceError: hooks is not defined`. In a fresh domain no plugin has created the global. The same code is correct in one engine and wrong in another, which is why admission alone cannot vouch for a unit: what it may call depends on what else is loaded.

> **Exercise.** Add a plugin that removes plugin A's hook (`hooks[0] = () => {}`) and admit it between B and the dispatcher. What does the output show, and is plugin A's code now unreachable? What would an engine need in order to release it safely before `close()`?

## Where next

[Chapter 18](lab:book?ch=18) covers engines with several units; [E-04](lab:preset?id=E-04) is the single-unit lifecycle and [E-06](lab:preset?id=E-06) the teardown order as a machine. The shelf doc on [labelled transition systems](lab:doc?id=lts) has the formalism.
