# Safepoints and live-across

A **safepoint** is an operation that may run the garbage collector: its obligations include `mayCollect`. A moving collector may relocate every object there, so the compiled code must keep, in root slots the collector updates, every managed value it still needs. Two sets decide which values those are: the values **live across** the safepoint (used after it), and the managed operands the safepoint's helper **borrows** while it runs. This preset lists both for every safepoint in `describe`, with the slot the root plan gave each value.

> **Try it.** [Turn on the safepoints and live overlays](lab:overlay?name=safepoints&on=1), [switch to L3](lab:level?l=L3), then [show the table](lab:show?view=experiments). Every one of `describe`'s six operations is a safepoint.

## The rule

A value needs a root at safepoint `p` when

$$v \in (\mathrm{across}(p) \cup \mathrm{borrowed}(p)) \quad\text{and}\quad \mathrm{type}(v)\ \text{may be managed}.$$

Managed types are those that hold heap references: objects, functions, cells, completion records and strings. A number does not move, so a value proved to be a number needs no root; a value of type `any` might be an object, so it does.

## Reading the table

```text
  name7 = js.get(user, "name")               ; safepoint · rooted s0=user
  arr9 = arr.new(name7, "member")            ; safepoint · rooted s0=name7
  v11 = js.add(name7, ": ")                  ; safepoint · rooted s1=arr9 s0=name7
  length13 = js.get(arr9, "length")          ; safepoint · rooted s1=arr9 s0=v11
```

- At [the first js.get](lab:node?id=describe/entry/0) nothing is live across: `user` is not used again. But the helper borrows `user` (it reads the property after it may have collected, if a getter allocates), so `user` is rooted.
- At [arr.new](lab:node?id=describe/entry/1), `name7` is both live across (the `+` uses it) and borrowed.
- At [the first js.add](lab:node?id=describe/entry/2), `arr9` is live across (it is returned) and `name7` is borrowed for the last time.
- At [the second js.get](lab:node?id=describe/entry/3), `v11` is a `string` and is rooted: strings live in the heap and move too.
- At [the second js.add](lab:node?id=describe/entry/4), `length13` is rooted although it is an array length: the facts give `js.get` the result type `any`, and the plan cannot assume a number.

## Slots are shared

The plan uses three root slots for seven rooted values. `s0` holds `user`, `name7`, `v11` and `v14` in turn: no two of them are needed at the same safepoint, so the default strategy, `stackReuse`, lets them share. `arr9` keeps `s1` from its allocation to the end, and `length13` needs `s2` only at the one point where it overlaps both others. With the frame's 2 fixed slots and 1 argument slot, `describe` needs 6 slots, 48 B. [Ask why s0 is shared](lab:ask?q=Why%20can%20user%2C%20name7%2C%20v11%20and%20v14%20share%20slot%200%3F) and the agent will read `program.why('slot:describe/0')`.

> **Try it.** [Run in plan mode with GC stress](lab:run?mode=plan&gc=stress). The collector moves every object at each of the six safepoints, and the output is still `ada: 2` and `member`.

## Why both sets

Live-across alone would miss `user` at the first `js.get`: it is dead afterwards, but the helper reads it during the call, and if the property were a getter that allocated, the collector would move the object between the helper's start and its read. Borrowed alone would miss `arr9` at the `js.add`: the addition does not touch the array, but the function returns it, so it must survive. The engine's checker (`check-plan`) verifies both sets at every safepoint, whatever strategy produced the plan.

> **Exercise.** Add `.rewrites(g.rewrites.standard())` and `.assume({ describe: { user: 'object' } })` to the pipeline, then replace `tags.length` with the literal `2`. Which safepoints disappear, which values stop needing roots, and how many slots does the plan need now?

## Where next

[Chapter 9](lab:book?ch=9) derives live-across sets from liveness; [Chapter 13](lab:book?ch=13) builds root plans from them. [A-02](lab:preset?id=A-02) shows the liveness solve, [L-03](lab:preset?id=L-03) compares root strategies, and the doc [Liveness](lab:doc?id=liveness) has the per-operation equations.
