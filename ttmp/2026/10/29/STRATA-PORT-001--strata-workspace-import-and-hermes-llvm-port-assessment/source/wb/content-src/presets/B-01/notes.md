# The running example: a ledger

On the screen is a ledger written in JavaScript: `makeLedger` returns an object with a `name`, a `deposit` method that rejects anything that is not a number, a `balance` getter and a `total` method that sums the log. The program makes one ledger, deposits 10 and 32, tries to deposit `"five"` and catches the TypeError, prints the name, balance and total, and queues a job that prints an audit line. The book follows this program from source to LLVM IR, so every view here shows a part of it.

> **Try it.** [Open program.js](lab:open?file=program.js&line=7), then [select deposit on the Stage](lab:fn?name=deposit) and [run it with GC stress](lab:run?mode=plan&gc=stress). The output does not change: `rejected: amount must be a number`, `main 42 42`, `audit 42`.

## What compiled

`main.js` is three lines. `g.pipeline()` is the default pipeline and `source('program.js')` reads the file beside it:

```js
const program = g.compile(g.pipeline(), source('program.js'));
```

The program has six functions: `main` (the script itself), `makeLedger`, `deposit`, `get_balance`, `total` and `arrow` (the job). Each function from the frontend takes the variables it captures as its first parameters, so `deposit` begins `fn deposit(c_balance: cell, c_log: cell, this: any, amount: any)`: `balance` and `log` live in **cells** because two functions share them.

## Cells, then SSA

[Look at deposit before promotion](lab:level?l=L1.cells): every variable starts as a cell, even `amount`, which nothing else captures. The `promote-cells` pass turns 11 such cells in this program into plain SSA values (the [trace in Events](lab:show?view=events) says so), and only `c_balance`, `c_log` and `c_ledger` remain. [Back to L1](lab:level?l=L1) shows the result: `amount` is read directly and `balance` still goes through `cell.load_checked`, because `deposit` cannot know whether `makeLedger` has initialised it.

## Where a collection can happen

[Turn on the safepoints overlay](lab:overlay?name=safepoints&on=1). A **safepoint** is an operation that may allocate and so may run the garbage collector: `js.add` (it may call `valueOf`), `js.get` (a getter), `js.put`, `js.new_error`. In [deposit's plan](lab:show?view=plan) four values need root slots across those points, and the default strategy packs them into four slots for seven values, a 56 B frame.

> **Try it.** [Select the js.add in deposit](lab:node?id=deposit/endif2/1) and read the Inspector: its contract is `callsUser` with obligations `mayCollect, nonlocalThrow`, and every permission is refused with a reason.

## Why nothing was erased

The rewrite pass ran the canonical set and fired nothing: `erase-dead-result` was refused three times in `main`, on the calls whose results the script ignores (`ledger.deposit(10)`). A method call may print, throw or change the heap, so an unused result is not enough to delete it. [Ask why](lab:ask?q=Why%20was%20erase-dead-result%20refused%20at%20main%2Fentry%2F5%3F) and the agent will read `program.why('main/entry/5')` for you.

> **Exercise.** In `main.js`, change the pipeline to `g.pipeline().rewrites(g.rewrites.standard())` and rerun. Which operations in `total` change name, and why does the number of safepoints in `total` drop? ([T-04](lab:preset?id=T-04) explains narrowing.)

## Where next

[Chapter 1](lab:book?ch=1) reads this program view by view. [B-02](lab:preset?id=B-02) changes one default at a time, and [L-03](lab:preset?id=L-03) compares the root strategies on this same ledger.
