# Getters and setters

On the screen is a thermometer: `makeThermometer(20)` returns an object that stores Celsius in a captured variable and exposes it through accessors. `celsius` has a getter that counts reads and a setter that rejects non-numbers and values below absolute zero; `fahrenheit` converts in both directions by going through `this.celsius`. The program prints `68`, `100`, the two rejections (`RangeError: below absolute zero`, `TypeError: not a number: warm`) and `reads 2`. The point of the preset is that in JavaScript a property access can be a function call, and the compiler has to treat every `js.get` and `js.put` that way.

> **Try it.** [Open program.js](lab:open?file=program.js&line=4), [show main](lab:fn?name=main) and [select the read of t.fahrenheit](lab:node?id=main/entry/2). The Inspector says `callsUser`: this one operation runs `get_fahrenheit`, which runs `get_celsius`.

## Accessors are functions

The frontend turns each accessor into a function of its own and installs it with `js.define_getter` or `js.define_setter`. [Show makeThermometer](lab:fn?name=makeThermometer): five closures, five definitions, one object. The getter for `celsius` captures two cells, `c_reads3` and `c_celsius2`, because it counts reads and returns the value:

```text
fn get_celsius(c_reads: cell, c_celsius: cell, this: any) -> any {
entry throws unwind:
  reads2 = cell.load_checked(c_reads)
  v3 = js.add(reads2, 1)
  cell.store(c_reads, v3)
  celsius4 = cell.load(c_celsius)
  return celsius4
}
```

`reads` is a `let`, so its load is checked for the dead zone; `celsius` is a parameter, so a plain `cell.load` is enough. The accessors for `fahrenheit` capture nothing: they reach Celsius through `this`, so [get_fahrenheit](lab:fn?name=get_fahrenheit) starts with `js.get(this, "celsius")`.

## A write that throws

`t.celsius = -300` is `js.put(r6, "celsius", -300)` in the block `try3`, whose header says `throws to catch1`. [Select it](lab:node?id=main/try3/0): the put runs the setter, the setter reaches `throw err12` in its block `then3`, and the exception unwinds out of `set_celsius` into `main`, where the block's exceptional exit sends it to `catch1` with the error as the handler's parameter `e12`. The handler reads `e12.name` and `e12.message`, both `js.get` again.

> **Try it.** [Run it](lab:build) and [open the Machine view](lab:show?view=machine): step through the put on `-300` and watch the frames: `main`, then `set_celsius`, then back in `main` at `catch1`.

## Why nothing here can be erased or moved

`print(t.fahrenheit)` reads a property and prints it. If the print were removed, a compiler might be tempted to delete the read as well, since its result is unused. It may not: the read runs `get_celsius`, which increments `reads`, and the final line `reads 2` would change. The permissions in the Inspector say this mechanically: `js.get` has behaviour `callsUser`, so all six permissions (erase, merge, move, duplicate, hoist, speculate) are refused, each with the reason "may run user code". The same contract makes each `js.get` and `js.put` a safepoint, which is why [main's plan](lab:show?view=plan) keeps the thermometer `r6` in a root slot at every safepoint from the call that makes it to its last read, `t.reads`.

## Setters see this

`set_fahrenheit` computes Celsius and writes it with `js.put(this, "celsius", v6)`: that put goes through the `celsius` setter, so the range check applies to Fahrenheit writes too. `t.fahrenheit = 212` therefore stores 100, which the next line prints.

> **Exercise.** In `program.js`, set `t.fahrenheit = -1000` inside a `try`. Which function throws, how many frames does the exception cross, and which handler catches it? Then delete the `reads` counter and compare the root slots of `get_celsius` in the Plan view.

## Where next

[Chapter 7](lab:book?ch=7) derives the permissions that a getter takes away. [C-04](lab:preset?id=C-04) follows the throwing getter end to end, and [J-03](lab:preset?id=J-03) looks at `finally`.
