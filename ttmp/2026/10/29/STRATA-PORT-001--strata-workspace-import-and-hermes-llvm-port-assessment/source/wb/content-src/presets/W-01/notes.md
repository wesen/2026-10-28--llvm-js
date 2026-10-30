# WebAssembly by hand

This preset compiles two functions of core IR to a real WebAssembly binary and runs it in the page. `main` computes the 30th Fibonacci number with a loop and prints `832040`; `fib(n)` is the same loop with `n` as a parameter. Both use only numbers, booleans and comparisons, which is the **core profile**: the one subset of the IR the Wasm backend accepts. Nothing here is interpreted. The header's Wasm mode hands the encoded bytes to `WebAssembly.Module`.

> **Try it.** [Run in Wasm mode](lab:run?mode=wasm), then [show the WAT](lab:level?l=WAT) and [the Events view](lab:show?view=events): the module is 484 bytes and starts `00 61 73 6d 01 00 00 00`: the four bytes `\0asm` and the version, 1.

## Why a core profile

A JavaScript value can be a number, a string, an object or a closure, and most operations on them may call user code or allocate. WebAssembly has none of that built in: it has `i32`, `i64`, `f32`, `f64`, linear memory and calls. A backend that accepts any IR would need a runtime written in Wasm (a heap, a collector, property lookup). The workbench's Wasm backend does the opposite: it accepts only functions whose every value is proven to be a number or a boolean, and gives each value one Wasm local (`f64` or `i32`). Everything else is refused with a reason, which [W-02](lab:preset?id=W-02) uses to get JavaScript into the profile.

## Blocks become a dispatch loop

WebAssembly has structured control flow (`block`, `loop`, `if`, `br` to an enclosing label) and no `goto`, while core IR has arbitrary edges between blocks. The backend bridges the two with the simplest correct construction: a loop around a `br_table` that jumps to the current block, and a local `$blk` holding the number of the next block.

```wasm
    (loop $dispatch
      (block $exit
        (block $body
          (block $head
            (block $entry
              (br_table $entry $head $body $exit (local.get $blk))
            ) ;; entry
```

Branching to the label `$entry` leaves the innermost block, so execution continues right after it, where the code of `entry` sits. That code ends by setting `$blk` and branching back to `$dispatch`. Every edge of the IR becomes `local.set $blk` plus `br $dispatch`. The construction costs one indirect jump per edge and no analysis at all; a production backend would recover loops and `if`s from the control-flow graph instead.

## Block parameters become locals

An edge's arguments are assigned to the target's parameters before the jump. The back edge of the loop, `jump head(v2, b1, v3)`, becomes three pushes and three `local.set`s in reverse order, because a Wasm stack pops last-in first:

```wasm
        local.get $v2
        local.get $b1
        local.get $v3
        local.set $b
        local.set $a
        local.set $i
```

Pushing every argument before setting any parameter keeps an edge correct even when an argument is itself a parameter of the target block, as in a swap `jump head(i, b, a)`: setting `$a` first would lose the old `a` before it was read.

> **Try it.** [Select the back edge's block](lab:node?id=main/body) on the Stage and find the same three assignments in the WAT.

## Encoding by hand

The binary is built byte by byte. Each section is an id, a length and a body; numbers are LEB128 (seven bits per byte, the high bit saying "more follows"); the type section lists function signatures as `0x60`, the parameter types and the result types; imports come from the module `env` (`print_num`, `print_bool`, `print_end` and `fmod` for `%`); every function is exported under its own name. `main.js` also runs `fib(10)` through Wasm and through the interpreter and prints both (`55` and `55`): the specification stays the judge.

`main` repeats the loop instead of calling `fib`, so that the two can be compared side by side; a call would work too. The backend encodes a direct call between core functions as a Wasm `call`, and the type facts give a direct call's result the callee's declared type, so `v1 = core.call(@fib, 30)` is a `number` and may be printed. A `main` of three lines (`core.call`, `host.print`, `return`, in a block headed `entry throws unwind:` because a call may throw) gives a 340-byte module that prints the same `832040`.

> **Exercise.** Add a `%` to the loop (for example `v4 = num.mod(v3, 1000)` and pass `v4` instead of `v3`). Which import does the module now use, and why does Wasm need it at all?

## Where next

[Chapter 15](lab:book?ch=15) builds the backend step by step; [W-03](lab:preset?id=W-03) reads a WAT listing with a diamond, and the shelf doc on [WebAssembly](lab:doc?id=wasm) summarises the format.
