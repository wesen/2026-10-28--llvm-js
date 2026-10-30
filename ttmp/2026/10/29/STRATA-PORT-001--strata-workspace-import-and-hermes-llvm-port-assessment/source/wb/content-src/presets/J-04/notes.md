# A tokenizer

On the screen is a small tokenizer: `tokenize("12 + 345 * 6")` walks the string once, skips spaces, folds runs of digits into numbers, and makes one object per token. The program prints `num:12 op:+ num:345 op:* num:6` and `5 tokens`. It is the kind of loop a compiler is expected to make fast, and the preset shows how much of it the compiler is allowed to touch when all it knows about `text` is that it is a JavaScript value.

> **Try it.** [Open program.js](lab:open?file=program.js&line=5), [show tokenize on the Stage](lab:fn?name=tokenize) and [turn on the safepoints](lab:overlay?name=safepoints&on=1). Nearly every operation in the loop is marked: reads of `text.length`, reads of `text[i]`, comparisons, additions, calls.

## Two loops, one function

`tokenize` has an outer `while` over the string and an inner `while` over a run of digits. Each loop header is a block whose parameters carry the loop's variables: `while1(i4_2)` for the outer loop and `while8(i4_1, value24_1)` for the inner one, where `value` accumulates the number. A `continue` is a jump back to `while1` with the current `i`. The condition `i < text.length && isDigit(text[i])` has no single operation for `&&`: the frontend lowers it to a branch into `rhs12`, which calls `isDigit`, and a join block `endlogic11` whose parameter is the value of the whole expression.

> **Try it.** [Select the inner loop's header](lab:node?id=tokenize/while8) and follow its two exits: the `false` edge passes `v28` straight to `endlogic11`, the `true` edge goes through the call in [rhs12](lab:node?id=tokenize/rhs12/2).

## Reading text.length again and again

The source reads `text.length` in both loop conditions, so the compiled code does too: `js.get(text, "length")` runs 19 times in this run. Moving that read out of the loop is the textbook optimisation, loop-invariant code motion, and it is not allowed here. [Select the read in while1](lab:node?id=tokenize/while1/0) and look at its permissions: `hoist` is false, because `js.get` has behaviour `callsUser`. If `text` were an object with a `length` getter, each read could return something different or print. Only the type of `text` would make the hoist safe, and nothing in this program states it.

## Functions are values here

`isDigit` and `isSpace` are function declarations in the script, and `tokenize` calls them, so `tokenize` captures them: its first two parameters are the cells `c_isSpace` and `c_isDigit`, and each call starts with a `cell.load`. The loads are unchecked, because a function declaration is initialised before any code of its scope runs. The call itself is `js.call`, which may run anything, so it is a safepoint, and so is everything after it that the call could have changed.

## Strings that become numbers

`value * 10 + (text[i] - "0")` subtracts one string from another. `js.sub` converts both operands to numbers first, so `"3" - "0"` is 3. [Select it in body9](lab:node?id=tokenize/body9/2): it is a `js.sub`, not a `num.sub`, because its operands are not known to be numbers. The type facts do know that `value24_1` is a number, since `js.mul` and `js.sub` always produce numbers and the join with the initial 0 stays a number.

## Measuring it

The run takes 411 steps; under [GC stress](lab:run?mode=plan&gc=stress) the collector runs 223 times and the output is unchanged. Each token object is created by `obj.new` and stored into the array with `js.put(arr5, length, o)`, so the array and the current token are among the values the plan keeps in root slots across those collections.

> **Exercise.** Hoist the length yourself: add `const n = text.length;` before the outer loop and use `n` in both conditions. Rerun and compare the step count (it drops to 393) and the number of `js.get(text, "length")` operations at L1. Why is your change correct when the compiler's would not have been?

## Where next

[Chapter 9](lab:book?ch=9) computes liveness and safepoints for loops like these. [T-04](lab:preset?id=T-04) shows what known types let narrowing do, and [X-07](lab:preset?id=X-07) measures how much of this corpus may run user code.
