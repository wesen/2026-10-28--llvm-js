# Captured variables stay cells

Promotion turns a variable into SSA values only when one function owns it. A variable that a closure captures is shared: the closure's function and the enclosing one both hold its cell, and either may write it at any call. Such a cell must stay a cell, and every read after a call must read it again. This preset shows both, with a counter and with the per-iteration `let` of a `for` loop.

> **Try it.** [Show makeCounter on the Stage](lab:fn?name=makeCounter) and [run it](lab:build): it prints `12`, then `3`. Then [select the second load of n](lab:node?id=makeCounter/entry/8) and ask the Inspector why it is there.

## One cell, two functions

```text
fn makeCounter(this: any) -> any {
entry throws unwind:
  c_n2 = cell.new()
  cell.store(c_n2, 0)
  f4 = js.closure(@inc, c_n2)
  r6 = js.call(f4, undefined)
  n7 = cell.load(c_n2)
  v8 = js.add(n7, 10)
  cell.store(c_n2, v8)
  r10 = js.call(f4, undefined)
  n11 = cell.load(c_n2)
  return n11
}
```

`js.closure(@inc, c_n2)` gives the cell to `inc`, whose IR function starts `fn inc(c_n: cell, this: any)` and does `cell.store(c_n, v2)`. From then on `makeCounter` cannot know what `n` holds after a call: `inc` runs `n = n + 1` inside the cell. The value `makeCounter` stored (`v8`, which is 10) is not the value it returns (12).

## Why the load stays

The standard rewrites include `forward-store-to-load`, which replaces a `cell.load` by the value of the last `cell.store` to the same cell in the block, when nothing in between may write cells. Here it is refused twice, and [Events](lab:show?view=events) prints the reason:

```text
makeCounter/entry/8 kept: js.call at makeCounter/entry/7 may write cells (callsUser)
makeCounter/entry/4 kept: js.call at makeCounter/entry/3 may write cells (callsUser)
```

The contract of `js.call` is `callsUser`, which includes writing cells. Forwarding `v8` into `n11` would return 10. [Chapter 10](lab:book?ch=10) shows the rewrite firing where it may: in this same program it forwards one store in `main`, where nothing runs between the store and the load.

> **Try it.** [Turn on the roots overlay](lab:overlay?name=roots&on=1): `c_n2` holds slot 0 across both calls. A cell is a heap object, and a captured one lives as long as any closure holds it.

## A new binding every turn

`for (let i = 0; i < 3; i++) fns[i] = () => i;` makes three closures that return 0, 1 and 2, so the sum printed is 3. That only works because `let i` in a `for` header is a fresh binding each turn. The frontend implements it literally: at the top of the body it copies the loop's `i` into a new cell, which the closure captures, and before the update it copies the value back.

```text
body2() throws unwind:
  c_i12 = cell.new(i8_1)
  f13 = js.closure(@arrow_2, c_i12)
  js.put(arr7, i8_1, f13)
  jump next3()
next3() throws unwind:
  i16 = cell.load(c_i12)
```

The loop's own `i` (`i8_1`) is a block parameter: no closure sees it. Each turn's copy `c_i12` is captured and stays a cell. [Select the cell.new in body2](lab:node?id=main/body2/0): it is executed three times, so three cells exist when the closures run.

## The table

[Experiments](lab:show?view=experiments) lists every cell that survived promotion and the closure that holds it: `c_n2` captured by `@inc` and `c_i12` by `@arrow_2`. Of the eight cells the frontend made, these two are the ones a closure captures.

> **Exercise.** Change `let i` to `var i` in the loop and rerun. What does the program print now, and what happened to `c_i12`? Explain the difference from the IR, not from the JavaScript rules.

## Where next

[Chapter 4](lab:book?ch=4) states the promotion rule, and [Chapter 7](lab:book?ch=7) explains why `callsUser` blocks forwarding. [J-01](lab:preset?id=J-01) builds a counter object out of several closures, and [I-06](lab:preset?id=I-06) lists every cell the frontend makes.
