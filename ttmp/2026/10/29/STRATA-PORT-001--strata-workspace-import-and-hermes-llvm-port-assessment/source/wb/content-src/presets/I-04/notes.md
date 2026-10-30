# The verifier

Every pass in the workbench assumes the IR it receives is well formed, and the **verifier** is what makes that assumption safe. It runs right after the frontend, and any pass can run it again. This preset feeds it seven functions that each break one rule, shows what it says about each, and then repairs the first one.

> **Try it.** [Open broken.ir](lab:open?file=broken.ir&line=4) and [show the table](lab:show?view=experiments): six errors and one warning, each with the rule it broke. Then [show the repaired function](lab:fn?name=fixed) on the Stage.

## Findings are data

`g.verify(fn)` never throws. It returns `{ ok, diagnostics }`, and each diagnostic names its `rule`, a message, and where it is (`fn`, `block`, `op`). The pipeline's `verify` pass puts them into `program.diagnostics` and stops the compile when any is an error, which is why a broken program shows up in the header as errors and not as a crash.

| function | rule | message |
|---|---|---|
| `dominance` | dominance | `y is defined in left but used in join, which left does not dominate (path entry → join)` |
| `arity` | edge-arity | `edge entry→done passes 2 arguments; done expects 1` |
| `types` | edge-type | `edge entry→done passes "seven": string to r: number` |
| `throwing` | may-throw-without-exit | `js.get may throw but entry has no exceptional exit; …` |
| `twice` | single-definition | `y is defined twice (entry/0 and entry/1)` |
| `missing` | unknown-block | `entry jumps to unknown block nowhere` |
| `island` | unreachable (warning) | `block lost is unreachable` |

## Dominance, with a path

The first rule is the one SSA depends on. A block A **dominates** a block B when every path from the entry to B passes through A. A value may be used only where its definition dominates the use, because only then is it certain to have been computed. In `dominance`, `y` is defined in `left`, but `join` can be reached straight from `entry` when `c` is false. The verifier does not just say so: it gives the **counter-path**, `entry → join`, a way to reach the use without passing the definition.

The repair is the one block parameters exist for: `join` takes a parameter, and each edge passes the value it has.

```text
fn fixed(c: boolean, x: number) -> number {
entry:
  branch c, left(), join(x)
left():
  y = num.add(x, 1)
  jump join(y)
join(r: number):
  return r
}
```

[Select join](lab:node?id=fixed/join): two edges, each with one argument. `main` calls it both ways and prints `5 4`.

## Edges must match their target

An edge passes arguments to the target's parameters, so the verifier checks their number (`arity`) and their types (`types`). A type here is the static type: a literal's own type, or a value's declared type. The string `"seven"` is not a `number`, so the edge is refused before anything runs.

## Throws must have somewhere to go

`js.get` may run a getter, and a getter may throw. In text form a block with no `throws` clause declares no exceptional exit at all, so the verifier refuses any operation in it that may throw. The fix is one word in the header: `entry throws unwind:` lets the throw leave the function, and `entry throws to h:` sends it to a handler block `h`. The frontend always writes one or the other. [Chapter 5](lab:book?ch=5) explains why the exit is declared per block.

> **Try it.** [Open broken.ir at throwing](lab:open?file=broken.ir&find=fn%20throwing), change `entry:` to `entry throws unwind:` in that function, [rerun](lab:build) and watch its row in the table turn `ok`.

## Warnings

An unreachable block breaks nothing, so it is a warning: the program still compiles, and the canonical rewrite `remove-unreachable` deletes the block later. A warning is the verifier saying "this is legal, and probably not what you meant".

> **Exercise.** Write an eighth function in broken.ir in which a block parameter's type is `boolean` and one incoming edge passes `num.lt(x, 1)` while another passes `1`. Which edge does the verifier refuse? Then write a function whose last block has no terminator, and read the rule it breaks.

## Where next

[Chapter 3](lab:book?ch=3) lists every rule of the verifier. [I-05](lab:preset?id=I-05) computes dominators, and [I-09](lab:preset?id=I-09) writes exceptional exits by hand.
