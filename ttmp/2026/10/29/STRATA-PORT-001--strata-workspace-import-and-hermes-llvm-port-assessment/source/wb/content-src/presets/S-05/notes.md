# Divergence and budgets

Some programs never finish. The interpreter cannot decide in general whether a program will stop (that is the halting problem), so it does the practical thing: it counts steps, and when a run has taken more steps than its **budget** it stops and reports the outcome **diverge**. This preset has one loop that ends and one that does not, and runs them with four budgets.

> **Try it.** [Run the program](lab:build): the header's outcome pill says `diverge` after 200,001 steps, but `111` was printed first. Then [show the table](lab:show?view=experiments).

## The program

`collatz(n)` halves an even number and maps an odd one to $3n + 1$ until it reaches 1, and returns how many moves that took. From 27 it takes 111 moves, a famous long walk. The script prints that number, then spins in `while (true)` forever.

## What the compiler did with while (true)

[Show main on the Stage](lab:fn?name=main). The loop is two blocks and no exit:

```text
while1(spins3_1: any) throws unwind:
  jump body2()
body2() throws unwind:
  v8 = js.add(spins3_1, 1)
  jump while1(v8)
```

The frontend lowered `while (true)` to a header that branches on `true`, and the canonical rewrites simplified the branch to a `jump` and removed the block after the loop, which nothing could reach. The function has no `return` left. [Select the js.add](lab:node?id=main/body2/0): `spins` is a parameter of the loop header, carried round the back edge.

## Budgets

| run | outcome | steps |
|---|---|---|
| whole program, default budget | diverge | 200,001 |
| whole program, budget 5,000 | diverge | 5,001 |
| `collatz(27)` alone, budget 500 | diverge | 501 |
| `collatz(27)` alone, default budget | normal, 111 | 1,044 |

The step that goes over the budget is counted, so a budget of 5,000 stops at step 5,001. The default is 200,000 steps, which the interpreter runs in a fraction of a second. `program.run({ entry: 'collatz', args: [27] })` runs one function on its own: its 111 moves take 1,044 interpreter steps, about nine per turn of the loop.

> **Try it.** [Open main.js](lab:open?file=main.js&line=7) and change the budget of the third run from 500 to 1,044, then to 1,043, and rerun. The first is enough and the second is not.

## A resource is not a meaning

The third row is the interesting one: `collatz(27)` does finish, but a budget of 500 calls it `diverge`. A budget is a limit on the machine, not a fact about the program, and the checks that compare runs treat it that way. `g.observe.equal` compares two runs that both diverged by what they observed before they stopped, and when only one side ran out of budget it answers `unknown` with the reason `one run exhausted its step budget; compare under equal budgets`, never `false`. A law that meets such a pair reports it with that reason, so a resource problem is not mistaken for a wrong compiler.

## Divergence in the other modes

The plan executor ([B-04](lab:preset?id=B-04) shows its overlays) counts the same steps. Under GC stress the same program with a budget of 5,000 diverges after the same 5,001 steps and collects 1,695 times along the way, once before every operation that may collect; the output is the same `111`.

> **Exercise.** Write a loop that diverges without `while (true)`, for example one whose counter never reaches its bound because of a floating-point step (`for (let x = 0; x !== 1; x += 0.1)`). Run it with a budget of 1,000 and explain from the Machine view why it never stops.

## Where next

[Chapter 2](lab:book?ch=2) lists diverge among the outcomes of the specification. [S-01](lab:preset?id=S-01) explains what a step is, and [J-06](lab:preset?id=J-06) runs deep recursion into the frame limit instead.
