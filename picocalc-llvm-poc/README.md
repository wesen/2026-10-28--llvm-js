# PicoCalc LLVM World Lab

**Host-side proof of concept, derived from the provided PicoCalc OS design.** One host compiler service emits **LLVM IR directly** from the restricted JavaScript world source, then builds freestanding **RISC-V 32-bit ELF** code. A different process loads and executes those actual RV32 instructions inside a deterministic, resource-bounded world simulator. A world can be hot-reloaded with retained typed state and transactional effect delivery.

The October 28 direct-IR update is explained in [docs/DIRECT_LLVM.md](docs/DIRECT_LLVM.md), with a contemporaneous [engineering diary](docs/DIRECT_LLVM_DIARY.md). The original `TECHNICAL_REPORT` and `DIARY` describe the earlier C-generating release and remain historical reference material.

> **Scope:** This is **not** a complete JavaScript engine, ESP-IDF firmware, a physical ESP32-P4 emulator, an LLVM ORC JIT, or a secure isolation boundary. The source frontend is a *deliberately restricted JS/i32 subset*. LLVM compiles on the host on demand (a remote AOT / remote-JIT model); no LLVM runs inside the simulated device. The simulated CPU is RV32IM, a subset of the P4's RV32IMAFC, and instruction timing is not hardware-accurate.

## Quick start

Prerequisites on Linux x86-64: `python3`, `node` with TypeScript installed locally (`npm ci`) or globally (`NODE_GLOBAL_ROOT` set), `clang` targeting RISC-V, `llvm-as`, `opt`, `llvm-objdump`, `ld.lld`, `readelf`, and a C++17 compiler. The direct backend was validated with LLVM/Clang 18.1.3, TypeScript 5.8.3, and Node 24.22.1.

```bash
npm ci        # pinned TypeScript parser; runs only on the host
make build
make test
make demo
```

`make demo` starts the **separate** `jitd` compiler process using a Unix socket, compiles three versions of the world into different RV32 code slots, and drives the independent C++ simulator. Its console output and `logs/demo.jsonl` show state retention, epoch invalidation of old messages, and failed-migration rollback.

To watch a JavaScript file and compile it when you save:

```bash
python3 scripts/watch.py worlds/counter_v1.js
# At the prompt: add 3, double, state
# Edit the source in another terminal; successful save causes a reload.
```

There is no dynamic JS runtime in this simulated device lane. The host parses the existing small JS/i32 subset, emits textual LLVM IR, and invokes LLVM's IR input path directly. Each output ELF has a `.generated.ll` companion for inspection; no per-module C is emitted or parsed on the default path.

## Compile a module without the daemon

```bash
python3 compiler/compile.py worlds/counter_v1.js \
    -o artifacts/handbuilt.elf --base 0x100000

printf 'dispatch 1 3\nstatus\n' | \
    build/pico-sim --module artifacts/handbuilt.elf --cap emit
```

The earlier C backend is retained as an explicit oracle:

```bash
python3 compiler/compile.py worlds/counter_v1.js \
    -o artifacts/c_oracle.elf --backend c

# Independently assemble and verify the directly emitted IR.
llvm-as artifacts/handbuilt.generated.ll -o /tmp/handbuilt.bc
opt -passes=verify -disable-output /tmp/handbuilt.bc

# Regenerate six direct-IR artifacts plus ELF/disassembly/hot-reload evidence.
python3 scripts/collect_direct_llvm.py
```

The same native ABI can be used by freestanding C:

```bash
python3 compiler/compile.py worlds/native_counter.c \
    --language c -o artifacts/c_counter.elf --base 0x100000

printf 'dispatch 1 4\n' | \
    build/pico-sim --module artifacts/c_counter.elf --cap emit
```

The native C example invokes a second compiled function, exercises RISC-V `auipc`/`jalr`, creates a stack frame, and returns through the guest ABI. It does **not** call libc.

## Native module proof

```bash
readelf -h artifacts/counter_v1.elf
readelf -l artifacts/counter_v1.elf
readelf -d artifacts/counter_v1.elf
readelf -Ws artifacts/counter_v1.elf
llvm-objdump -d artifacts/counter_v1.elf
```

Expected: ELF32, little endian, RISC-V machine ID 243, `ET_EXEC`, loadable RX `PT_LOAD` segment, **no** `NEEDED` dynamic libraries, and no unresolved symbols (apart from the ELF symbol-table sentinel).

The default JS path invokes `clang -x ir --target=riscv32-unknown-elf -march=rv32im -mabi=ilp32`, with IR that contains wrapping i32 operations and no external runtime symbols. C input and `--backend c` additionally use `-ffreestanding -nostdlib -fno-builtin -fwrapv`. Linking uses `ld.lld -m elf32lriscv --no-undefined` and a temporary fixed-address linker script. The ELF images are **prelinked** to one of two code slots (0x100000 and 0x200000). Dynamic relocation on the device is **not** implemented.

The *host simulator executable* does use the host's ordinary C++ library; **guest modules** do not have a libc, crt, host file system, OS services, or dynamic loader.

## Interactive simulator commands

| Command | Meaning |
|---|---|
| `dispatch EVENT ARG` | Run a world turn with a bounded instruction budget |
| `queue EVENT ARG` | Queue an event tagged with the current epoch |
| `drain` | Deliver current-epoch events; reject stale events |
| `reload PATH SCHEMA` | Run shadow migration and atomically activate the other code slot |
| `status` | Show typed state, epoch, and active code slot |
| `capture PATH` | Write the simulated 320×320 RGB565 panel as a PPM file |
| `expect FIELD VALUE` | Assert `score`, `ticks`, `schema`, `flags`, or `epoch` |
| `quit` | Exit |

The simulator's guest memory consists of RX code segments (from ELF), writable 16-byte world state at `0x30000000`, and a writable 8 KiB stack at `0x80000000`. Each RV32 instruction consumes one unit of **fuel**. Loads, stores, and instruction fetches enforce simulated segment access rights. A single guest `ecall` boundary handles kernel-mediated capabilities. All proposed panel and log effects are staged and committed only after the entire turn returns successfully.

## Display demonstration

```bash
python3 compiler/compile.py worlds/display_v1.js \
    --base 0x100000 -o artifacts/display_v1.elf

printf 'dispatch 1 0\ncapture artifacts/demo.ppm\ndispatch 3 0\n' | \
    build/pico-sim --module artifacts/display_v1.elf --cap display
```

Version 1 draws a red header and several colored shapes via `cap.rect(x,y,w,h,rgb565)`. Event 3 draws black then aborts; the panel remains unchanged because effects were not committed. `artifacts/display.png` contains a sample screenshot from this simulator, **not** the original PicoCalc panel driver.

## Files

- `include/pico_abi.h`: shared freestanding ABI and RISC-V `ecall` stubs.
- `compiler/js2llvm.js`: direct AST-to-LLVM IR compiler for the existing restricted JS/i32 world ABI, using the TypeScript parser on the **host**.
- `compiler/js2c.js`: earlier restricted JS/i32-to-C compiler retained as the differential oracle.
- `compiler/compile.py`: Clang/LLVM+LLD cross-compiler, ELF and no-libc audit.
- `compiler/jitd.py`: separate persistent compiler daemon (Unix domain socket, JSON requests).
- `kernel/pico_sim.cpp`: ELF32 loader, RV32IM instruction runner, world state, capability checks, transactional effects, renderer, hot reload.
- `scripts/watch.py`: host-side edit/recompile/reload loop, checks reload acknowledgement.
- `scripts/demo.py`: reproducible, two-process end-to-end demo.
- `scripts/collect_direct_llvm.py`: six assembled/verified IR modules, native RV32 ELF files, disassembly, and an executed hot-reload trace.
- `worlds/`: JS versioned programs and one native C guest.
- `tests/`: integration, differential, service, bounds, rollback, and ISA tests.
- `docs/TECHNICAL_REPORT.md`: architecture, theory, implementation and device-port plan.
- `docs/DIARY.md`: chronological engineering notes including failures and fixes.
- `logs/`: captured verification, disassembly, and demonstration evidence.

## Security / semantics caveats

This **device-lane JS compiler** does not implement JavaScript objects, strings, `Number` as binary64, dynamic property lookup, closures, promises, the real PicoCalc `.prelude.js` grammar, or generic ECMAScript exceptions. It preserves the earlier i32-centric grammar and fixed `PicoState` structure. The companion Static Hermes backend is the separate dynamic-language implementation; these integer world tests do not establish a dynamic runtime on ESP32-P4. The device-lane tests compare supported operations against Node in a bounded domain, compare C and direct IR over seeded event sequences and integer edge cases, and test `-O0`, `-O2`, and `-Oz` lowering. These are not a test262 claim.

The module loader and RV32 interpreter are educational, not security hardened. A physical-device native module requires independent privilege isolation (PMP/U-mode or equivalent), verified memory layouts, cache coherency, and code-signature/provenance policy. Device executable memory, PSRAM XiP, FreeRTOS integration, timers, I²C/SPI, and USB transfer **have not been tested** in this host PoC.

See `docs/TECHNICAL_REPORT.md` for the actual host-to-device mapping and prioritized next steps.
