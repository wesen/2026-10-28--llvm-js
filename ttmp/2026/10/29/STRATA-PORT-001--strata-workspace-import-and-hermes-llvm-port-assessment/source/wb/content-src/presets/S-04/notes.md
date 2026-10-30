# The temporal dead zone

A `let` or `const` binding exists from the start of its block, but holds no value until its declaration runs. Reading it in between throws a ReferenceError. The stretch of the program where the name exists but cannot be read is called the **temporal dead zone**. This preset calls a function that reads a `let` too early, catches the error, then calls it again after the declaration.

> **Try it.** [Open program.js](lab:open?file=program.js&line=12) and [run it](lab:build). The output is `ReferenceError: cannot access limit before initialization`, then `limit is 10`. Then [show show on the Stage](lab:fn?name=show).

## A cell with no value yet

The frontend gives every variable a cell. For `var` and function declarations the cell starts as `undefined`; for `let` and `const` it starts empty. In core IR an empty cell is `cell.new()` with no operand:

```text
fn main() -> any {
entry throws unwind:
  c_limit3 = cell.new()
  f4 = js.closure(@show, c_limit3)
  jump try3()
```

`show` captures `limit`, so `c_limit3` is passed to the closure and survives promotion. The declaration `let limit = 10` is, at the end of `main`, a plain `cell.store(c_limit3, 10)`.

## The checked load

A read that might happen before the store is a `cell.load_checked`. [Select it in show](lab:node?id=show/entry/0): its behaviour is `reads(cells), throws`, and its one obligation is `nonlocalThrow`. When its cell is still empty, its step throws a ReferenceError naming the variable; otherwise it returns the value.

The frontend picks the checked form when it cannot prove the read comes after the declaration:

- the read is in another function than the declaration (as in `show`), because the function may be called at any time; or
- the read comes earlier in the source text than the end of the declaration, in the same function.

Every other read of a `let` or `const` is a plain `cell.load`, and after promotion most of those disappear altogether. [Events](lab:show?view=events) lists every load of this program with its form: the one in `show` is checked.

## Following the first call

> **Try it.** [Show the Machine view](lab:show?view=machine) and [go to step 3](lab:step?n=3), the jump into `try3`. Step 4 is already in `catch1`. In between, the call at `main/try3/0` ran `show`, whose `cell.load_checked(c_limit)` found the cell empty and threw. An operation that throws does not finish, so it leaves no step record; [the Events view](lab:show?view=events) has the trace instead, a `catch` event at step 3 naming `main/try3/0` and the handler `catch1`.

Main's `try3` block is headed `throws to catch1`, so the thrown error arrives in `catch1` as its parameter `e5`.

`catch1` reads `name` and `message` from the error and prints them. Then `endtry2` stores 10 into the cell and calls `show` again; this time the checked load finds a value and the second line is printed. The run is `normal`: the exception never left `main`.

## Why it matters to a compiler

A checked load is not free. It throws, so it needs an exceptional exit; it reads a cell, so it cannot move past a store; and in the Hermes backend it is a call to a helper (`shllvm_check_tdz` at L2). [Look at L2](lab:level?l=L2) to see the binding. A compiler that proved the read safe could replace it with a plain load, which has no throw and can be forwarded. The workbench does not try; [I-08](lab:preset?id=I-08) shows what else keeps captured variables as cells.

> **Exercise.** Add `print(limit);` as the first line of the program (before the `function`), and rerun. Which load does the frontend emit for it, and what does the output become? Then change `let limit` to `var limit` and explain the new output.

## Where next

[Chapter 2](lab:book?ch=2) treats the dead zone as part of the specification, and [Chapter 4](lab:book?ch=4) shows how promotion handles cells that may be empty. [I-06](lab:preset?id=I-06) prints every cell the frontend makes.
