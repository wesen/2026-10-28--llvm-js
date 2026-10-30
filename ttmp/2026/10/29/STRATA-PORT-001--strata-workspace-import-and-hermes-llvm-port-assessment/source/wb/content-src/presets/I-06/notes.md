# Every variable a cell

The JavaScript frontend does the simplest correct thing with variables: it gives every one of them a **cell**, a small heap box with `cell.new`, `cell.load` and `cell.store`, and it passes a function the cells of the variables it captures. This is correct for every program, because a cell has the semantics of a JavaScript binding: closures that share a variable share its cell. It is also slow, which is what [promote-cells](lab:preset?id=I-07) is for. This preset shows the frontend's output before promotion and counts what promotion leaves.

> **Try it.** [Look at L1.cells](lab:level?l=L1.cells) for [account](lab:fn?name=account), then [switch to L1](lab:level?l=L1). Ten cells become four, and the table in [Experiments](lab:show?view=experiments) says which.

## One cell per binding

In `account` the frontend makes six cells, one for each binding of its scope:

```text
fn account(this: any, owner: any) -> any {
entry throws unwind:
  c_owner2 = cell.new(owner)
  c_opened3 = cell.new(undefined)
  c_balance4 = cell.new()
  c_limit5 = cell.new()
  c_canPay6 = cell.new(undefined)
  c_pay7 = cell.new()
  f8 = js.closure(@canPay, c_balance4, c_limit5)
  cell.store(c_canPay6, f8)
```

How each cell starts tells you what kind of binding it is:

| binding | starts as | why |
|---|---|---|
| parameter `owner` | `cell.new(owner)` | the argument's value |
| `var opened` | `cell.new(undefined)` | `var` is hoisted and starts undefined |
| `let balance`, `const limit`, `const pay` | `cell.new()` (empty) | the temporal dead zone ([S-04](lab:preset?id=S-04)) |
| `function canPay` | `cell.new(undefined)`, then the closure | function declarations are hoisted and stored first |

The declarations then run in source order as plain `cell.store`s: `true`, `0`, `100`, the arrow function.

## Closures receive cells

`canPay` reads `balance` and `limit`, so `js.closure(@canPay, c_balance4, c_limit5)` hands it those two cells, and its IR function takes them as its first parameters: `fn canPay(c_balance: cell, c_limit: cell, this: any, x: any)`. The arrow `pay` captures three: `c_canPay6`, `c_owner2` and `c_balance4`. Because `canPay` and `pay` hold the same `c_balance4`, a payment made through `pay` is seen by the next `canPay`. That is the whole point of the cell: it is shared by reference.

[Select the closure for pay](lab:node?id=account/entry/8) on the Stage at L1: its operands are the three cells.

## What promotion keeps

| function | cells before | after | kept |
|---|---|---|---|
| `main` | 2 | 0 | |
| `account` | 6 | 4 | `c_owner2`, `c_balance4`, `c_limit5`, `c_canPay6` |
| `canPay` | 1 | 0 | |
| `pay` | 1 | 0 | |

The cells of parameters `x` in `canPay` and `pay` go: nothing else sees them. In `account`, `opened` is only read by `account` itself, so its cell becomes the constant `true` passed straight to `js.define`; `pay`'s cell becomes the closure value `f9`. The four that stay are captured by a closure, and a cell another function holds cannot become a value of this one.

> **Try it.** [Select a checked load in canPay](lab:node?id=canPay/entry/0). `canPay` reads `balance` through `cell.load_checked`: it cannot know whether `account` has run `let balance = 0` yet, so the read checks for an empty cell.

## Why start this way

A frontend that tried to decide, variable by variable, whether a cell is needed would have to understand closures, `let` scoping, loops that create a binding per iteration and the dead zone all at once, and every mistake would be a miscompiled program. Emitting cells for everything is right by construction, and moving the cleverness into one separate pass means that pass can be checked on its own. [Chapter 4](lab:book?ch=4) makes this argument in full.

> **Exercise.** Change `const limit = 100;` to a parameter `limit` of `account` (and pass it from `main`). Rerun: does `c_limit5` still survive? Then make `canPay` an arrow assigned to a `const` and compare the cells.

## Where next

[Chapter 4](lab:book?ch=4) builds SSA from these cells. [I-07](lab:preset?id=I-07) shows how promotion decides, and [I-08](lab:preset?id=I-08) shows what captured variables cost.
