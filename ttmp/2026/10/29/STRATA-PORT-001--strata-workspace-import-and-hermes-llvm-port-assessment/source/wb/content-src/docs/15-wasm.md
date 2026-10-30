---
id: wasm
title: WebAssembly in one page
group: Backends
about: The parts of WebAssembly the workbench's backend uses: modules and sections, LEB128, a typed stack machine, structured control flow, and the core profile it accepts.
order: 15
---
# WebAssembly in one page

WebAssembly (Wasm) is a portable binary format for code that browsers and other hosts compile to machine code. The workbench has a real Wasm backend: it encodes functions of core IR into a module byte by byte and hands the bytes to the browser's `WebAssembly.Module`, so Wasm mode runs native code produced in the page. This doc covers just the parts of Wasm that backend uses, and the restriction, the **core profile**, that keeps it small. [W-01](lab:preset?id=W-01), [W-02](lab:preset?id=W-02) and [W-03](lab:preset?id=W-03) show it; [Chapter 15](lab:book?ch=15) builds it.

## A module is a list of sections

A Wasm binary starts with eight bytes, `00 61 73 6d 01 00 00 00` (the characters `\0asm` and version 1), followed by sections. Each section is an id byte, a length and a body, so a reader can skip sections it does not need. The backend writes five:

| id | section | holds |
|---|---|---|
| 1 | type | each function signature: `0x60`, parameter types, result types |
| 2 | import | functions the host provides: `env.print_num`, `print_bool`, `print_end`, `fmod` |
| 3 | function | for each defined function, the index of its signature |
| 7 | export | each defined function under its own name |
| 10 | code | each function's locals and body |

For [W-03](lab:preset?id=W-03)'s Collatz loop the module is 454 bytes: 22 for types, 61 for imports (mostly the four names), 2 for the function section, 8 for exports and 342 for the one body.

## Numbers are LEB128

Lengths, counts, indices and integer constants are written in **LEB128**: seven bits per byte, low bits first, with the high bit of each byte saying whether another byte follows. 27 is the single byte `0x1b`; 300 is `0xac 0x02`. Signed constants (`i32.const`) use the signed variant, where the sign is carried by bit 6 of the last byte, so 97 needs two bytes while 27 needs one. Floating-point constants (`f64.const`) are always eight bytes of IEEE 754, which is why changing a double constant never changes a module's size.

## A typed stack machine

A function body is a sequence of instructions over an operand stack, with declared locals. `local.get $a` pushes a local; `f64.add` pops two doubles and pushes their sum; `local.set $v` pops into a local. The value types the backend uses are `f64` (every number) and `i32` (every boolean, and the dispatch index). The engine validates the whole module before running it: every instruction must find operands of the right types on the stack, which is the type checking an IR verifier does, done again by the host.

## Structured control flow

Wasm has no `goto`. Control flow is nested: `block … end` and `loop … end` introduce labels, and `br n` leaves the n-th enclosing block (jumping to its end) or restarts the n-th enclosing loop (jumping to its start). `if … else … end` branches on an `i32`. `br_table` is a jump table: it pops an index and branches to the label at that position.

Core IR has arbitrary edges between blocks, so the backend must express a control-flow graph with nested labels. It uses the simplest correct construction, a **dispatch loop**: a loop around one nested block per IR block, a `br_table` that leaves the block numbered by a local `$blk`, and the code of each IR block placed right after the end of its own nested block.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 290">
  <rect x="20" y="20" width="600" height="250" fill="none" stroke="currentColor" class="ink"/>
  <text x="30" y="36" font-size="11" class="b">loop dispatch</text>
  <rect x="40" y="46" width="560" height="194" fill="none" stroke="currentColor" class="mut"/>
  <text x="50" y="62" font-size="10" class="it">block exit</text>
  <rect x="60" y="70" width="520" height="144" fill="none" stroke="currentColor" class="mut"/>
  <text x="70" y="86" font-size="10" class="it">block body</text>
  <rect x="80" y="94" width="480" height="94" fill="none" stroke="currentColor" class="mut"/>
  <text x="90" y="110" font-size="10" class="it">block head</text>
  <rect x="100" y="118" width="440" height="32" class="f-fill" stroke="currentColor"/>
  <text x="110" y="138" font-size="10">block entry: br_table entry head body exit (blk)</text>
  <text x="110" y="172" font-size="10" class="acc">code of entry, then blk = 1; br dispatch</text>
  <text x="90" y="205" font-size="10" class="acc">code of head: if v1, blk = 2 else blk = 3; br dispatch</text>
  <text x="70" y="230" font-size="10" class="acc">code of body, then blk = 1; br dispatch</text>
  <text x="50" y="258" font-size="10" class="acc">code of exit: return r</text>
</svg>
```

**Figure 15.1.** The dispatch loop of `fib` ([W-01](lab:preset?id=W-01)), labels without their `$`. `br_table` leaves the block for the current IR block; execution continues after that block's end, where its code is. Each edge sets `blk` and branches back to the loop. Schematic.

Every edge then becomes "assign the target's parameters, set `$blk`, `br $dispatch`". A `branch` becomes an `if` with one edge in each arm. Block parameters become locals: an edge pushes all its arguments and then pops them into the target's locals, so a swap of two parameters stays correct. The construction costs an indirect jump per edge and needs no analysis. Production compilers instead recover nested loops and conditionals from the graph (the "relooper" and "stackifier" algorithms) and use the dispatch loop only for graphs that cannot be nested.

## The core profile

The backend accepts a function only if every value in it is proven to be a number or a boolean, its operations are the `num.*`, `i32.*`, `bool.*` and `core.*` ones, and its output goes through `host.print` of numbers and booleans. Anything else (an object, a closure, a string, a call that may run user code, a throw) is refused with the first reason it meets:

```text
js.lt in for1 is outside the core profile (numbers, booleans, direct calls)
```

The profile exists because Wasm has none of what JavaScript values need: no heap of objects with properties, no collector the module can use, no exceptions in its core instruction set. A backend for the whole language would compile a runtime into Wasm or rely on newer proposals (garbage-collected references, exception handling). The workbench's choice is the opposite: compile only what needs nothing, exactly, and let the type facts decide how much of a program that is. [W-02](lab:preset?id=W-02) shows a JavaScript function getting in: an unchecked assumption about its parameter and the standard rewrites narrow `js.lt` and `js.add` to `num.lt` and `num.add`.

## Running it

`program.run({ mode: 'wasm', entry, args })` encodes the eligible functions, instantiates the module with the four imports, calls the entry and collects the printed lines. The specification stays the judge: [W-01](lab:preset?id=W-01) prints `fib(10)` from both and compares. A function that captures variables, or whose result the facts cannot prove numeric, stays out; so does `main` in most JavaScript programs, because it creates closures.

## What this model leaves out

The backend uses no linear memory, no tables, no globals and no `i64` or `f32`. A direct call between core functions becomes a Wasm `call`, and its result has the callee's declared type, so a caller may compute with it and print it; a callee declared `-> any` takes its caller out of the profile. It encodes no custom name section, so browser developer tools show function indices rather than names. And it never runs a Wasm validator of its own: if it encoded something invalid, `WebAssembly.Module` would reject the bytes, which is the check it relies on.
