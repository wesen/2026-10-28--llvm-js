# The throwing getter

`load` reads `settings.theme` and ignores the value. To an optimiser that only looks for unused results, the read is dead code. It is not: `theme` is a getter that prints a line and throws, and the program's output depends on both. This preset follows one operation, `js.get(settings3, "theme")`, from its contract to the decision the compiler made about it, and shows what erasing it anyway does.

> **Try it.** [Select the js.get in load](lab:node?id=load/entry/1). The Inspector shows its contract, `callsUser` with `mayCollect, nonlocalThrow`, and six refused permissions. Then [show Events](lab:show?view=events) for the decision.

## The program, compiled

[Open program.js](lab:open?file=program.js&line=9) and [look at load in L1](lab:fn?name=load):

```text
fn load(c_settings: cell, this: any) -> any {
entry throws unwind:
  settings3 = cell.load_checked(c_settings)
  theme4 = js.get(settings3, "theme")
  return "loaded"
}
```

`theme4` is defined and never used. The getter itself is the function `get_theme`, which runs `host.print("reading theme")`, builds an Error and throws it. The output in spec mode is `reading theme`, then `caught: no theme configured`.

## Why the contract refuses

`js.get` cannot know which object it will meet. A data property makes it a plain read; an accessor makes it a call to user code; a proxy (outside this subset, but inside JavaScript) could do anything. Its behaviour is therefore `callsUser`, which the engine expands to every user resource, throwing, diverging, fresh identities and the host. Erasing requires an operation that writes nothing, cannot throw or diverge and runs no user code; `js.get` fails all of these. `main.js` asks the program directly:

```js
const p = program.perm(site.id);
print(`${site.id} ${site.text}: result unused ${p.resultUnused}, erase ${p.erase}`);
```

and Events reads `load/entry/1 js.get(settings3, "theme"): result unused true, erase false`, followed by the five reasons. An unused result is necessary for erasing and never sufficient.

## The decision log

The canonical rewrite set includes `erase-dead-result`, which matches every operation whose result nobody uses and then asks `perm.erase`. At `load/entry/1` it was refused, and the program records why in `program.decisions`:

```text
erase-dead-result refused: perm.erase = false: may run user code; may throw; may diverge; ...
```

`program.why('load/entry/1')` gathers the same decision with the operation's liveness and its safepoint: the plan roots `settings3` there, because the helper borrows it while the getter runs.

> **Try it.** [Ask the agent why the read was kept](lab:ask?q=Why%20was%20the%20js.get%20in%20load%20not%20erased%3F). It will read `why('load/entry/1')` and quote the decision.

## Erasing it anyway

The table in [Experiments](lab:show?view=experiments) compiles the same source twice. With the canonical set the output is `reading theme / caught: no theme configured`. With `g.rewrites.naiveDce` added, a rewrite that erases unused results with no side condition, the output is `loaded`: the getter never runs, so nothing prints and nothing throws, and `load` returns normally. Two lines of observable output became a different line. That is a miscompilation, and it is the reason permissions exist. [T-02](lab:preset?id=T-02) catches the same bug automatically with `g.law.refines`.

> **Exercise.** Change the getter to `get theme() { return "dark"; }` and rerun. The two rows now print the same output. Is the naive rewrite correct for this program? Is it correct as a rewrite? (A rewrite is correct only if it preserves behaviour on every program, not on the one you tried.)

## What would earn the permission

The read could be erased if the compiler knew the property is a plain data property of an ordinary object: then the read touches nothing but the heap, and an unused read of the heap is invisible. That fact would come from analysis (shapes, in a real engine), and it would select a **variant**: an operation with a smaller contract that agrees with `js.get` when the fact holds. The standard set has one, `js.get_own_data`, with behaviour `reads(heap)` and `erase: true`. [C-06](lab:preset?id=C-06) shows how variants are chosen.

## Where next

[Chapter 7](lab:book?ch=7) tells this story with the derivation behind each permission; [C-03](lab:preset?id=C-03) has the full permission table; [J-02](lab:preset?id=J-02) uses getters and setters in a larger program.
