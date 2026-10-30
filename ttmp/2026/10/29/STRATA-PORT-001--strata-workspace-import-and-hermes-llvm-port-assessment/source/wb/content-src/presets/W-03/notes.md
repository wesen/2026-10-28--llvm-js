# Reading WAT

This preset is a guided reading of a WebAssembly listing. The program, in core IR, follows the Collatz rule from 27 (halve an even number, map an odd `x` to `3x + 1`) and counts the steps until it reaches 1: it prints `111 true`, the step count and whether it exceeds 100. It has more shape than a single loop: a diamond (`even` or `odd`) that joins in `next`, a remainder, and a boolean. The [WAT](lab:level?l=WAT) is the text form of the binary the page runs; the [Experiments view](lab:show?view=experiments) lists the binary's sections.

> **Try it.** [Run in Wasm mode](lab:run?mode=wasm), keep the Stage beside the WAT, and [select the diamond's test](lab:node?id=main/step/1). Find the same `f64.eq` in the listing.

## Locals first

A Wasm function declares its locals after its signature. The backend gives every IR value one local: `f64` for numbers, `i32` for booleans, and one more `i32`, `$blk`, for the dispatch:

```wasm
    (local $x f64)
    (local $steps f64)
    (local $v1 i32)
```

Block parameters are values like any other, so `x` (a parameter of `loop`) and `x1` (a parameter of `step`) are separate locals, and an edge copies one into the other. Twenty locals for one function is many by hand-written standards; Wasm engines allocate registers for them, so the count costs little at run time.

## The nesting tells the block numbers

The dispatch is a loop around seven nested blocks, one per IR block, innermost first, and a `br_table` that leaves the block numbered by `$blk`:

```wasm
                    (br_table $entry $loop $step $even $odd $next $done (local.get $blk))
```

Read it as a table: `$blk = 0` goes to the code of `entry`, `1` to `loop`, and so on, in the IR's block order. Every edge ends with `(local.set $blk (i32.const k))` and `br $dispatch`, and the number `k` is the target's position in that list: `jump loop(y, v7)` in `next` ends with `i32.const 1`.

## A branch is an if with two edges

`branch v3, even(x1, s1), odd(x1, s1)` becomes an `if … else … end` on the `i32` value `v3`, with one edge in each arm. Each arm copies the edge's arguments into the target's parameters and sets `$blk`:

```wasm
              local.get $v3
              if
                local.get $x1
                local.get $s1
                local.set $s2
                local.set $x2
                (local.set $blk (i32.const 3))
                br $dispatch
```

The join is not special. `even` and `odd` both jump to `next`, each assigning the two parameters `y` and `s4`; where an SSA textbook would put a phi function at the top of `next`, the IR has block parameters and the Wasm has two assignments to the same locals.

> **Try it.** [Select next on the Stage](lab:node?id=main/next) and count its incoming edges; then find the two places in the WAT that set `$y`.

## What has no instruction

Wasm has `f64.add`, `f64.mul`, `f64.div`, comparisons, `f64.floor`, `f64.sqrt`, but no floating-point remainder. `num.mod` therefore becomes a call to an imported function, `call $fmod`, which the page implements with JavaScript's `%`. Printing is imported the same way: `print_num`, `print_bool` and `print_end` (one call per value, then one to end the line), which is how `host.print(r, v8)` becomes three calls.

## The binary

`main.js` walks the 454-byte module: an 8-byte header, then five sections, each an id, a LEB128 length and a body. The code section, 342 bytes, holds the one function body; the import section, 61 bytes, is mostly the four names. The interpreter took 1,046 steps to get the same `111 true`; the Wasm run is one call.

| id | section | bytes |
|---|---|---|
| 1 | type | 22 |
| 2 | import | 61 |
| 3 | function | 2 |
| 7 | export | 8 |
| 10 | code | 342 |

> **Exercise.** Start from 97 instead of 27 (edit `jump loop(27, 0)` in [program.ir](lab:open?file=program.ir&find=jump%20loop(27)). Predict which section sizes change, then rerun and read the table. Why does no size change at all, when an integer constant in an `i32.const` would have grown by a byte?

## Where next

[Chapter 15](lab:book?ch=15) explains the encoding; [W-01](lab:preset?id=W-01) is the simplest module and [W-02](lab:preset?id=W-02) gets JavaScript into the profile. The shelf doc on [WebAssembly](lab:doc?id=wasm) has the section list.
