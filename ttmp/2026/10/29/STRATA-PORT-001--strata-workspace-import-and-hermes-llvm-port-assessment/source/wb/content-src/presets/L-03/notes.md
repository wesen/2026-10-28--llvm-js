# Root strategies compared

The ledger from [B-01](lab:preset?id=B-01) is compiled three times, once per root strategy, and each version runs in plan mode with a collection at every safepoint. The [Experiments view](lab:show?view=experiments) lists what each strategy costs; the Stage and the [Plan view](lab:show?view=plan) show the `distinct` plan of `deposit`. All three plans pass the same checker and all three runs print what the specification prints.

> **Try it.** [Show deposit at L3](lab:level?l=L3) and read the header: 11 root slots, a 14-slot frame of 112 B. Then [open main.js](lab:open?file=main.js&find=roots('distinct')), change `'distinct'` to `'stackReuse'` and [rerun](lab:build): 4 root slots, 56 B.

## What a root slot is for

A moving collector may relocate every object whenever it runs, and it runs only at a **safepoint**, an operation whose contract says `mayCollect`. A value held in a machine register at that moment would keep the old address. So every heap reference the code still needs after a safepoint, or that the safepoint's helper reads as an operand, has to sit in a **root slot**: a frame word the collector knows about and updates. The plan says which value occupies which slot at each safepoint; the checker proves that every required value has a slot of its own there.

## Three strategies

| strategy | root slots | deposit | total | frame bytes | collections | same as spec |
|---|---|---|---|---|---|---|
| distinct | 52 | 11 | 7 | 576 | 68 | true |
| stackReuse | 15 | 4 | 3 | 280 | 68 | true |
| arena | 52 | 11 | 7 | 608 | 68 | true |

**distinct** gives one slot to every managed value of a function, whether or not it is ever needed at a safepoint. That is what the Hermes LLVM backend does today, and it is easy to trust: nothing shares a slot, so nothing can be overwritten. In `deposit` it roots `v4` (the string `typeof` returns) and `err6` (the error thrown on the bad path) though neither is live across any collecting operation.

**stackReuse** roots only what the plan needs and lets values share a slot when they are never needed at the same safepoint. It builds a conflict graph (two values conflict when one safepoint requires both) and colours it greedily. In `deposit`, slot 1 holds `balance7` at the `js.add` and `log11` at the `js.get` and the `js.put`; slot 3 holds `c_log`, then `log12`, then `length13`.

> **Try it.** [Ask the agent why slot 3 is shared](lab:ask?q=Explain%20program.why('slot%3Adeposit%2F3')%20for%20the%20stackReuse%20plan) after switching main.js to `stackReuse`.

**arena** uses the slots of `distinct` but takes them from a growable arena owned by the runtime instead of the native stack. The frame bytes count the arena's 32 B header per activation, so it costs a little more here; what it buys is freedom from the native frame limit ([L-07](lab:preset?id=L-07)) and an arena mark that every catch must restore ([L-08](lab:preset?id=L-08)).

## Why every row says true

The column `same as spec` compares each plan-mode run with the specification's output, outcome and object identities, using `g.observe.equal`. Under stress the collector moves every live object 68 times in this program; a plan that missed one value would leave a stale address and the run would stop. All three plans are correct, and they differ only in cost. That is the point of separating the strategy from the checker: a cheaper strategy can be tried without trusting it.

> **Exercise.** Add `'none'` to the list of strategies in [main.js](lab:open?file=main.js&line=5) and rerun. The row reports 0 root slots, and `sameAsSpec` is no longer `true`: what does it say, and what does `p.metrics().errors` count? ([L-04](lab:preset?id=L-04) and [L-05](lab:preset?id=L-05) take the broken plan apart.)

## Where next

[Chapter 13](lab:book?ch=13) develops root plans from the beginning, and the shelf doc on [moving collectors and root slots](lab:doc?id=gc-roots) covers the collector side. [L-06](lab:preset?id=L-06) writes a strategy of your own.
