# Engineering diary - PicoCalc LLVM World Lab

**Work completed in this response, 28 October 2026.** These are chronological development notes reconstructed directly from commands, test output, and source edits in this run. They are **not** a transcript of hidden reasoning or subagent sessions. Times are intentionally not invented.

## D0. Re-establish the original application model

**Inputs inspected:** `picocalc-os-src(2).zip`, `picocalc-os(1).zip`, plus the provided paper archive. The original `README.md`, `js/system.json`, and `js/apps/snake.js` gave the most relevant implementation contract.

The existing OS uses a C nucleus, separate QuickJS worlds, a single virtual execution lane, per-world budgets, message queues, STM32 keyboard and ST7365P display simulation, capability handles, a compositor, and a rule that effects occur only after successful execution segments. The ESP32-P4 is the proposed replacement CPU module, not the stock RP2040. I decided to avoid pretending a one-session experiment could port all of this. The target of the proof became the native compiler/world ABI and hot reload, grounded in the original world's **commit-on-success** and **generation replacement** semantics.

## D1. Tool and hardware feasibility

Commands inspected `clang`, `ld.lld`, `llvm-objdump`, `g++`, `node`, `python3`, and availability of QEMU/Unicorn. Clang 17 with the RISC-V backend, LLD and LLVM objdump are present. Neither RISC-V QEMU nor Unicorn was available. TypeScript was present as a global Node module.

I compiled a small function with:

```bash
clang --target=riscv32-unknown-elf -march=rv32im -mabi=ilp32 -c ...
```

`llvm-objdump` confirmed `elf32-littleriscv` instructions. I chose RV32IM rather than the full ESP32-P4 RV32IMAFC so that a small instruction runner could be implemented without emulating FPU, atomics, or compressed instructions. The P4 accepts RV32IM as a subset. The runner is not a physical emulator and has no meaningful timing equivalence to the device.

## D2. Define the freestanding guest ABI

Added `include/pico_abi.h` with a 16-byte `PicoState`, deterministic event numbers, a guest 8 KiB stack convention, and RISC-V `ecall` stubs. A guest calls the kernel with `a7` (capability number) and `a0...` (arguments); no guest libc or OS calls are required. The C++ host's libc is allowed, because the model isolates that from freestanding guest code.

The guest is allowed to access its own copied state and stack, but not arbitrary simulator memory. I chose prelinked code slots `0x100000` and `0x200000` as a way to test generation switching before building a relocation engine. These **are not** asserted to be ESP32-P4 memory addresses.

## D3. Build the JavaScript frontend and compiler

Added `compiler/js2c.js`, which uses TypeScript's AST parser, rejects unsupported constructs, and maps a tiny `step(state,event,arg)` program to C. It restricts state properties to `schema`, `score`, `ticks`, and `flags`, permits only known capability functions, and requires `export const schema = N`.

Added `compiler/compile.py`, which compiles the generated C with `clang --target=riscv32-unknown-elf -march=rv32im -mabi=ilp32 -nostdlib -ffreestanding -fno-builtin -fwrapv`, then calls `ld.lld -m elf32lriscv` with a fixed-address linker script. It rejects unresolved imports, unexpected architecture or program-header layout, and RX/WX errors. The first counter program produced a 4,996-byte ELF32 with a 108-byte executable segment. It contains no linked libc or dynamic dependency.

**Design limitation:** Generated C arithmetic is a strict i32 research subset, not ECMAScript Number arithmetic. After implementation, I removed division and shifts from the accepted frontend rather than silently giving the user the wrong semantics. More complete JS requires an interpreter/GC and deoptimization integration.

## D4. Build the target simulator and execute a real guest

Added `kernel/pico_sim.cpp`: an ELF32 loader, memory segments with R/W/X flags, an RV32IM instruction interpreter, `ecall` handling, per-turn instruction budgets, and typed state copy-on-execute. It initially failed to compile because a shift expression attempted to assign to a `const` local. Fixed the expression and rebuilt.

First executed a compiled counter world from `artifacts/counter_v1.elf`. The simulator loaded machine code, ran it, received an `ecall`, and emitted JSON:

```json
{"event":"dispatch","ok":true,"epoch":1,"schema":1,"score":4,"ticks":1,"flags":0,"steps":15,"effects":[4]}
```

This is actual guest instruction execution, not executing the generated C on x86. The simulation nevertheless interprets each RV32 instruction, so benchmark results cannot be projected onto the real P4.

## D5. Implement hot reload, epochs and transactional turns

Added a `World` with a single active module, committed state, pending event deque, and epoch. A `reload` command loads the new code in the opposite slot, runs `pico_world_migrate` with a tentative state copy, and commits both code and state only when migration succeeds. Queued events retain their old epoch and are discarded after a successful generation switch.

The first integrated scenario exercised:

- Version 1 increments the score by `arg`.
- Version 2 increments by `10 * arg` and sets a migration flag.
- The world retains score through reload.
- A queued event from the previous epoch is not delivered.
- A third module aborts during migration; the old module stays active.

The recorded trace ends at score 53 and epoch 2. This is in `logs/demo.jsonl`.

## D6. Separate the JIT compiler as a process

Added `compiler/jitd.py`, a Unix-socket daemon that accepts JSON-line requests and runs LLVM through child processes. The simulator never imports LLVM, Clang, Node, TypeScript or C. Added `scripts/demo.py`, which starts the daemon, submits the three JS source versions, launches the simulator, runs a scenario, and shuts the compiler down. This proves process separation, although it is a trusted local development protocol rather than a hardened network service.

Added `scripts/watch.py` to monitor on-disk source revisions and send the new program to `jitd`. A crucial correctness choice: the watcher reads the simulator's reload acknowledgment, and only updates its notion of the active code slot after success. Failed migrations can then be corrected without the client and device disagreeing on which slot is active. Verified interactive commands `state`, `add 7`, and `double`.

## D7. Create negative tests and an independent oracle

Added Python `unittest` cases for freestanding ELF properties, malformed ELF and WX segment rejection, capability denial, fault rollback, fuel budget exhaustion, migration rollback, stale message rejection and schema incompatibility.

Added an independent comparison against Node. For each of two compiled JS source variants, 80 deterministic randomly generated event/argument pairs are executed both in the Node VM and as cross-compiled RV32. State score, tick count and emitted values agree in this controlled subset (160 input comparisons). This is **not** a broader ECMAScript conformance claim.

One test initially failed because a regular expression incorrectly matched the normal zero-index `UND` symbol-table row plus the beginning of the following line. Fixed it by checking symbol table rows separately. No guest import was actually unresolved.

## D8. Find a genuine ISA interpreter bug with an extra C fixture

I added `worlds/native_counter.c` to exercise a native internal function call instead of only straight-line JavaScript lowering. That program initially ran until fuel exhaustion. The `PICO_TRACE` diagnostic showed repeated instruction fetches at PC `0x10001c` (`auipc ra, 0`). The interpreter had implemented `AUIPC` and `LUI` register results but had forgotten to advance `pc` to the next instruction. Once these two cases were corrected, the guest executed `auipc`/`jalr`, entered its `multiply_three` helper, returned using the guest stack and completed correctly with score 12 for argument 4.

This was the most useful negative experiment: elementary arithmetic smoke tests had missed a control-flow invariant, while the native C function fixture exposed it immediately. `PICO_TRACE=1` was kept as an opt-in debug facility.

## D9. Add an actual display-effect proof

Extended the ABI with `PICO_CAP_RECT` and added a simulated 320 by 320 RGB565 panel in the host world. The first drawing version proposes a white background, a red header, blue bar and green cursor. The kernel validates each rectangle, stages it, and changes its framebuffer only after the turn succeeds.

The failure branch submits a black clear then invokes `abort(99)`. Before and after PPM captures produced identical SHA-256 values:

```
2055648ded724ad4b0ac182038ca4c12802e86e82645774a9751d1c877acf594
```

This demonstrates transactional drawing; it is **not** an emulation of ST7365P SPI commands. A PNG conversion of the simulated RGB565 output is preserved as `artifacts/display.png`.

## D10. Verification and current status

`make test` passes 16 integration/unit tests including Node comparison, guest C calls and stack, loader rejection, runtime limits, daemon protocol and display rollback. A representative host C++ build with AddressSanitizer and UndefinedBehaviorSanitizer also ran the compilation/reload scenario without a sanitizer error. An additional audit records target machine, linkage and disassembly. No performance claims are made about the real ESP32-P4.

A later regression test also compiled the same JavaScript through LLVM `-O0`, `-O2`, and `-Oz`; all produced the same expected target state and effects.

Outstanding major limitations: no full JS semantics or QuickJS replacement; no physical SPI/I2C/USB integration; no direct device execution or executable-memory publication proof; no relocatable module format; no instruction-accurate cycle model; no authenticated transport or hardened sandbox; only one world and a simple state schema; no true interpreter/JIT tiering, GC safepoints, or deoptimization. The next research milestone should prove real executable memory plus a relocatable native loader, then select and integrate a mature JS frontend and runtime.
