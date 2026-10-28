# Direct LLVM IR for the PicoCalc integer world ABI

## Outcome and scope

The default JavaScript compilation path now emits LLVM IR directly. It accepts
the same bounded integer world programs that the original prototype exercised,
produces actual RV32IM instructions, and runs them in the existing world
simulator. State rollback, staged effects, instruction fuel, schema migration,
generation changes, and stale-event rejection remain properties of that same
simulator and ABI.

This lane is the small device-oriented regression target. The separate Static
Hermes work handles dynamic JavaScript functions, objects, and closures. A
successful integer-world test is not evidence that a moving garbage collector,
JavaScript heap, or full Hermes runtime executes on ESP32-P4.

## 1. The compilation boundary

Previously, `compiler/js2c.js` parsed source with TypeScript and printed a C
function. Clang then parsed and lowered that C to LLVM IR before optimizing and
selecting RISC-V instructions. The new `compiler/js2llvm.js` prints LLVM IR
itself. `compiler/compile.py` uses `clang -x ir`, which selects the LLVM IR
reader. It then uses the same RISC-V target, optimizer selection, linker, ELF
audit, and simulator as before.

This removes the per-module C source representation and C frontend. It does
not remove the JavaScript parser, LLVM IR parser, LLVM optimizer, machine-code
generator, or linker. Textual IR is a deliberate first interface: students can
inspect every emitted instruction, assemble it with `llvm-as`, and verify it
independently with `opt -passes=verify`.

The LLVM language reference specifies the types, instruction syntax, control
flow, and memory operations used here. The implementation uses opaque `ptr`
operands and explicit pointee types on loads and GEP instructions. See the
[LLVM Language Reference](https://llvm.org/docs/LangRef.html) and
[Clang command-line reference](https://clang.llvm.org/docs/ClangCommandLineReference.html).

## 2. Values and arithmetic

An expression in the frontend returns two pieces of compiler data: an LLVM
operand name or literal, and whether the inherited integer language treats
that value as unsigned. All runtime arithmetic values occupy 32 bits.

| Source role | LLVM representation | Comparison interpretation |
|---|---|---|
| `arg`, local variables | `i32` | signed |
| `state.score`, `state.ticks`, `state.flags` | `i32` field | signed |
| `event`, `version`, `state.schema` | `i32` | unsigned |
| comparison result | `i1`, extended to `i32` | integer 0 or 1 |
| `state` | `ptr` | only fixed field access is accepted |

LLVM `i32` has no intrinsic signedness. The compiler chooses `icmp slt` or
`icmp ult`, for example, according to the source operation. The original C
backend declared event/version/schema as `uint32_t`; mixed comparisons follow
that C integer contract. This is intentionally not a claim of ordinary
JavaScript binary64 behavior.

Addition, subtraction, and multiplication omit LLVM's `nsw` and `nuw` flags.
Those flags would permit optimizations based on the absence of overflow. The
inherited language explicitly uses wrapping arithmetic, corresponding to the
original C route's `-fwrapv` setting. The direct emitter therefore makes no
such promise.

## 3. Variables and memory

Mutable local variables receive one `alloca i32` each in the LLVM function's
entry block. Assignments become stores and uses become loads. LLVM's
optimization pipeline can subsequently promote eligible allocas to SSA
registers. This keeps the first compiler implementation straightforward:
source mutation does not require the frontend to construct all variable phi
nodes itself.

The state structure is declared as:

```llvm
%PicoState = type { i32, i32, i32, i32 }
```

For example, `state.score += arg` becomes a field address, load, wrapping add,
and store:

```llvm
%p = getelementptr %PicoState, ptr %state, i32 0, i32 1
%old = load i32, ptr %p, align 4
%next = add i32 %old, %arg
store i32 %next, ptr %p, align 4
```

The LLVM data layout is explicitly RV32, with a 32-bit pointer and a 128-bit
stack-alignment convention. This is target-specific IR for the existing
world ABI, not an attempt to hide the device's representation behind a
target-independent pointer model.

The entry-alloca strategy is explained in LLVM's
[mutable-variable tutorial](https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl07.html).

## 4. Branches, loops, and short circuiting

An `if` statement creates branch targets for its arms and a join block. A
`while` statement creates a test block, body block, and exit block. Every LLVM
basic block ends in exactly one terminator.

Short-circuit expressions need special treatment because their right-hand
side can call a capability or mutate state. The frontend emits a conditional
branch before emitting that operand. A phi node joins the already-known
logical result with the evaluated right-hand result. The right predecessor is
the actual block where nested evaluation finished, which matters when the
right operand contains another short-circuit expression.

As in the original integer/C subset, `&&` and `||` produce integer 0 or 1.
They do not return one of their operands as general JavaScript does. The
tests deliberately check skipped abort calls, nested logical expressions,
and an assignment that must happen only along one path.

Unreachable source is still validated. An unsupported expression after
`return` is an error, rather than silently disappearing from source-language
validation.

## 5. Capability calls

The simulator exposes three services: emit, abort, and rectangle drawing.
Generated LLVM uses `call ... asm sideeffect "ecall"` with fixed-register
constraints. Register `x17` (`a7`) contains the capability number; registers
`x10` onward carry arguments; `x10` also carries the result. The memory
clobber communicates that the call can observe or change memory.

These details were compared with Clang's lowering of the existing
`include/pico_abi.h` inline assembly. The guest contains no libc calls and
imports no dynamic runtime. LLD is still invoked with `--no-undefined`; both
the host audit and the simulator validate ELF structure independently.

This also explains the runtime boundary: LLVM does not implement rollback.
The simulator runs a turn with copied state and staged effects. It commits
them only if native execution returns successfully. A capability failure or
fuel exhaustion discards that tentative state. Changing the frontend does
not change this transaction protocol.

## 6. Tools, evidence, and reproducibility

Validation used LLVM/Clang 18.1.3 and Node 24.22.1, with TypeScript 5.8.3 pinned
in `package-lock.json`. The direct update has 24 test methods, including the
original world/service regressions and eight direct-backend methods. The
successful complete run is recorded in
`logs/direct-llvm-tests-with-sockets-final.txt`. The initial sandbox run is retained
separately: its only failure was lack of permission to bind the existing
Unix-domain compiler-service socket.

The tests include:

- Independent LLVM assembly and verification of emitted IR.
- Execution of generated RV32 code at O0, O2, and Oz.
- 200 seeded event comparisons against the original C backend.
- The original 160 event comparisons against Node in the bounded domain.
- Signed/unsigned comparisons and wrapping integer edge cases.
- Branches, local variables, loops, phi nodes, and short-circuit side effects.
- Retention of a previously compiled ELF when replacement compilation fails.
- State/effect rollback, display rollback, migration failure, stale messages,
  denied capabilities, and instruction-budget termination.

`python3 scripts/collect_direct_llvm.py` creates six `.generated.ll` files,
assembles and verifies each, links six freestanding RV32 ELF modules, records
an actual hot-reload scenario, and captures the ELF audit and disassembly.
`logs/direct-llvm-evidence.json` identifies source hashes, tool versions,
module hashes, compile-phase durations, and trace records. Durations are
observations from this shared host; they are not a controlled speedup study.

## 7. Language limits and next extension

The direct lane rejects objects, closures, strings, arbitrary function calls,
division, exception handling, async functions, generators, optional chaining,
and other unimplemented AST forms before emitting a completed module. It also
rejects malformed signatures and undefined local references. Keeping those
rejections explicit prevents the device regression path from masquerading as
the separate dynamic JavaScript engine.

The useful next exercise is to add an explicitly typed helper-function ABI to
this restricted lane, preserving the simulator's stack limit and instruction
budget. That is distinct from importing a complete dynamic JavaScript runtime.
Before moving the richer Static Hermes lane onto the device, the runtime,
collector roots, exceptions, code ownership, host bindings, and physical
memory model all need a matching device implementation and execution evidence.
