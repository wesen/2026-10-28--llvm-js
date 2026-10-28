# PicoCalc integration: the two execution targets

This change provides a direct LLVM backend at two different layers. Keeping
their evidence separate is essential to understanding what now works and
what a physical-device port still requires.

| Property | PicoCalc integer world lane | Static Hermes dynamic language lane |
|---|---|---|
| Frontend | Existing restricted TypeScript-parsed JS/i32 grammar | Actual Static Hermes parser and IR pipeline |
| New backend | `compiler/js2llvm.js` | `lib/BCGen/SH/LLVMNative/LLVMBackend.cpp` |
| Per-program output | Textual LLVM IR, then a prelinked ELF32 module | Textual LLVM IR calling the Static Hermes runtime bridge |
| Runtime values | Fixed `PicoState` and i32 temporaries | Hermes values, objects, closure environments, native function objects |
| Target evidence | RV32IM instructions executed in the existing simulator | Linux x86-64 native execution and host `lli`; see the final host validation records |
| Managed heap and collector | None | Actual host Static Hermes runtime owns the heap and collector |
| Reload behavior exercised | State-preserving generation replacement, migration rollback, stale-event rejection | Code/runtime lifetime must be retained as a generation; device integration is not implemented |
| Physical ESP32-P4 execution | Not tested | Not tested |

The integer lane's **24-test complete regression run** is recorded in
`picocalc-llvm-poc/logs/direct-llvm-tests-with-sockets-final.txt`. Its source
hashes and counts are in `logs/direct-llvm-validation.json`. The collector
`scripts/collect_direct_llvm.py` assembled and verified six directly emitted
modules, linked RV32IM ELF images, and ran an eleven-record reload scenario.
That scenario retained score 3 across a successful migration, reached score
43 under the new implementation, rejected a failing replacement, and then
reached score 129 using the still-active generation. The final epoch was 2.

These results support preservation of the original world protocol for the
exercised cases after removing the per-module C stage. They do not establish
that objects or closures run in the RV32 interpreter or on physical PicoCalc
hardware.

The host backend reuses the full dynamic Hermes runtime, including its heap,
collector, objects, and closure machinery, through a selected set of emitted
instructions. This does not mean complete ECMAScript acceptance. Generators,
direct `eval`, and regular-expression literals are rejected; typed-object
and private fixed-slot operations are outside this backend. The pinned frontend
also rejects the supplied `const` reassignment and some statically provable TDZ
violations during compilation, even inside `try`. Runtime TDZ behavior through
captured bindings is tested separately. See `evidence/validation.json`,
`evidence/driver-validation.json`, and `evidence/lexical-defaults-validation.json`.

## The shared architectural idea

Both lanes place the compiler on the host. A module's source becomes LLVM IR,
then native machine code. The integer lane's world supervisor owns execution
policy and capability access. Connecting the dynamic host runtime to that
supervisor remains integration work. LLVM is not the operating system,
JavaScript runtime, garbage collector, or state migration mechanism.

In the integer lane, the LLVM IR has no external runtime calls. Capability
requests use a RISC-V `ecall`, and the simulator enforces memory access and
instruction fuel. The ABI is a 16-byte `PicoState`, an 8 KiB stack, and one of
two prelinked code slots, `0x100000` and `0x200000`.

In the dynamic lane, generated IR calls the bridge in `runtime.c`, which in
turn uses Static Hermes's existing value operations, object model, closure
creation, environment stores, function call machinery, and garbage-collector
roots. The bridge is compiled once for its runtime configuration. Guest
program bodies do not pass through generated C.

## Why a closure changes the reload problem

A closure combines executable code with an environment containing captured
bindings. An object can retain a closure, and that closure can retain further
objects. Replacing a code pointer does not transfer this graph to another
runtime or make the old graph safe to collect.

The upstream `SHUnit` contract says that a unit, once associated with an
`SHRuntime`, persists until that runtime is destroyed. The generated native
function objects and their metadata refer to that unit. Unmapping an old
generation's machine code while a surviving closure can call it would violate
the lifetime contract.

For PicoCalc, the defensible first integration is therefore **one runtime per
world generation**:

1. Compile and validate a candidate module on the host.
2. Create the candidate runtime and instantiate the module without exposing
   live external effects.
3. Migrate a deliberately serialized state representation. Do not copy native
   pointers, Hermes values, object addresses, or closure environments between
   runtimes.
4. Check schema and resource policy; activate the candidate only after success.
5. Direct new events to the candidate generation and reject stale events using
   the existing epoch rule.
6. Release the old runtime, all old handles, and finally its code mapping after
   no invocation or externally held callback can reach it.

This sequence describes the required dynamic-world integration. The current
integer simulator already exercises its simpler fixed-state version. It does
not yet instantiate a Hermes runtime inside a world.

Plain JSON state may be sufficient for a first application, but it has its own
boundary: functions, object identity, cycles, undefined-valued properties,
BigInts, and non-finite numbers need an explicit policy. A closure is behavior
to recreate in the new generation, not a raw address to migrate.

## Transactional effects require host bindings

The existing simulator copies fixed state and stages panel/log effects until
the native turn completes. A dynamic runtime needs corresponding bindings
that append effect proposals to a generation-owned transaction. Direct access
to host file descriptors, panel drivers, or shared mutable objects would
bypass that protocol.

The host also needs to decide whether heap mutation itself rolls back. A
Hermes object modified during a failed call does not automatically return to
its prior value merely because effect delivery was canceled. Practical first
choices include application-level pure reducers over serialized state, a
fresh runtime for each speculative turn, or a separate snapshot/transaction
design. The present compiler change does not implement any of these dynamic
heap rollback strategies.

Likewise, the integer interpreter's instruction counter cannot simply be
reused for arbitrary native Hermes code. A device port needs a defined
interruption mechanism: explicit compiler-inserted polling, protected
execution with a timer and reliable unwind policy, or another independently
validated scheduling design. Garbage-collector safepoints and world fuel
checks are different mechanisms with different guarantees.

## What an RV32 Hermes port entails

The bridge currently contains a deliberate `sizeof(void *) == 8` assertion.
It prevents the tested host callback ABI from being advertised as an RV32
runtime ABI. Deleting that assertion is not a port.

The host emitter also admits at most 1,024 combined root/argument slots,
including scratch/minimum argument storage. That caps explicit tagged payload
at 8 KiB; it does not cap total native stack consumption. Root headers,
exception buffers, compiler spills, runtime frames, and recursion add storage.
This admission rule is distinct from the integer simulator's actual 8 KiB
guest-stack region.

The port has to establish at least these contracts:

- **Value and pointer model.** Check the selected Hermes VM model, tagged
  value representation, compressed pointers if enabled, heap address limits,
  and collector support for the intended target.
- **Calling convention.** Prove that the generated `i64` native function
  return and all bridge prototypes agree with the target C ABI. Aggregate
  returns, register allocation, alignment, and pointer widths require target
  validation, not host extrapolation.
- **Runtime services.** Supply allocation, stack bounds, platform atomics,
  exception machinery, standard-library dependencies, and any threading or
  timer services required by the selected runtime configuration.
- **Floating-point support.** JavaScript uses binary64 Numbers. RV32IM code
  requires suitable software helpers; a single-precision F extension alone
  does not provide double-precision execution. The actual hardware/toolchain
  configuration and runtime libraries must be tested together.
- **Collector and root correctness.** Rebuild the bridge against the exact
  target runtime. Verify root-frame alignment, write barriers, moved-object
  updates, allocation failure, and exception unwinding under collection
  stress on that target.
- **Executable code management.** Define executable memory placement,
  instruction-cache synchronization, loading/relocation, and generation
  lifetime. The prototype's two fixed synthetic slots are a test convention,
  not a physical-device memory map.
- **OS policy.** Connect capabilities, turn scheduling, input queues, display
  effects, memory budgets, state migration, and failure reporting to the
  actual PicoCalc nucleus. The current simulator does not implement the
  physical panel, FreeRTOS, USB, or hardware privilege boundaries.

Generating an RV32 object file can be a useful intermediate check, but it
does not demonstrate that its imports link, its collector works, or the
result fits the device. Conversely, host execution of object/closure tests
does demonstrate the new direct backend's behavior against the actual
Hermes runtime, within the recorded feature and test scope.

## Source references

- `include/hermes/VM/static_h.h`: `SHUnit` lifetime, `SHLocals`, object,
  environment, and call interfaces.
- `include/hermes/VMLayouts/sh_stack_frame_layout.h`: native Hermes register
  stack frame layout and call metadata.
- `lib/BCGen/SH/LLVMNative/runtime.c`: bridge representation assertions,
  runtime entry/exit, value helpers, and compilation-unit allocation.
- `lib/BCGen/SH/LLVMNative/LLVMBackend.cpp`: rooted values, control flow,
  closure creation, calls, and module descriptors.
- `picocalc-llvm-poc/include/pico_abi.h` and `kernel/pico_sim.cpp`: the separate
  fixed-state RV32 world contract and transactional supervisor.
- [LLVM RISC-V backend](https://llvm.org/docs/RISCVUsage.html): target support
  and ABI considerations; consult the version matching the deployed toolchain.
