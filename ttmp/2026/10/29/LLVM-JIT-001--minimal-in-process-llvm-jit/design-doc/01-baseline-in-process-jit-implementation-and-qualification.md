---
Title: Baseline in-process JIT implementation and qualification
Ticket: LLVM-JIT-001
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/include/hermes/BCGen/SH/LLVM.h
      Note: Existing Hermes IR to textual LLVM API
    - Path: repo://hermes/include/hermes/VM/static_h.h
      Note: Guarded execution and persistent unit lifetime
    - Path: repo://hermes/lib/BCGen/SH/CMakeLists.txt
      Note: Current runtime bridge build/link targets
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
      Note: Creator-only output and internal unit metadata
    - Path: repo://hermes/utils/shllvm.py
      Note: Current external lli execution path
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T09:32:28.993135776-04:00
WhatFor: ""
WhenToUse: ""
---

# Minimal in-process JIT implementation and qualification

## 1. Result to deliver

Implement a persistent, single-thread-owned native engine that compiles admitted JavaScript through the existing Hermes-to-LLVM path and executes it in the same process. The engine must preserve one managed runtime across compilation requests and keep code valid for closures, objects, suspended generators, and jobs until engine shutdown.

This is a proposed implementation. Today `shllvm.py jit` launches `lli` as a subprocess. The initial design dependency is LLVM-ENGINE-001; this ticket implements its contracts. Full ECMAScript conformance and a speculative optimizing JIT are explicitly outside acceptance.

A baseline JIT performs native compilation on request. It can use LLVM's ordinary optimization passes without type speculation, profiling, deoptimization, or switching active frames between tiers. Begin with correctness at a simple optimization level, then qualify an optimized configuration through the same path.

## 2. Two checkpoints with distinct claims

**Checkpoint A: in-process IR execution.** Load backend-produced textual LLVM IR, verify it, compile it using LLVM ORC LLJIT, find the exported unit creator, and initialize it in a persistent Hermes runtime. No `lli`, external native linker, or per-unit executable is used for execution. The source frontend may still run separately to prepare fixtures. Report this as an IR execution host.

**Checkpoint B: source compilation API.** Refactor the existing frontend into a reusable per-request source-to-IR operation, preserving compiler options and diagnostics. Pass the emitted text buffer directly into the JIT. Two source submissions must compile and execute within one host process without spawning shermes. Report a source JIT only after this checkpoint passes.

The distinction prevents the first working LLVM lookup from being mistaken for completion of the whole request. Existing Babel module preprocessing may remain external build-time tooling; native in-process module parsing is not a hidden requirement.

## 3. Existing APIs and proposed components

| Existing code | Reuse or change |
|---|---|
| `hermes::sh::generateLLVM` | Reuse textual emission from Hermes IR. It does not parse JavaScript. |
| `BytecodeGenerationOptions.emitMain` and `.unitName` | Emit no main and a unique `sh_export_<name>` creator. |
| `_sh_init` / `_sh_done` | Manage one runtime per engine. Confirm initialization failure handling. |
| `_sh_unit_init_guarded` | Execute a creator while capturing a returned value or JavaScript exception. |
| Console binding lifecycle and `run_event_loop` | Reuse supported tasks while separating lifetime from one-shot main. |
| `shllvm_run` | Keep as the standalone path or factor common lifecycle internally; do not invoke per JIT request. |
| `SHUnit` ownership | Preserve code and metadata until runtime destruction. |

Proposed components are a private `NativeEngine` C++ class, an LLVM-facing compilation component, a frontend request function, a small host CLI, and integration tests. Suggested locations are a new `hermes/lib/LLVMJIT/` directory and `hermes/tools/shllvm-jit/`; inspect repository build conventions before fixing filenames. These paths are proposals, not existing APIs.

Keep the first interface small: load/compile, execute, drain supported jobs, and close. Avoid a plugin architecture, general remote executor, debugger protocol, or public unrooted value return API.

## 4. Build feasibility and runtime linkage

Add the JIT as an optional CMake target with an explicit LLVM development-package requirement. Existing AOT emission must continue to configure and build without that option. Audit the coexistence of Hermes's bundled `llvh` and installed LLVM; the textual IR boundary means no IR objects need to cross their APIs.

Before writing the full engine, build a minimal executable that creates LLJIT, links the chosen runtime bridge, and resolves one bridge function from the same runtime copy used by host initialization. Check loaded libraries and link commands for duplicate Hermes implementations. Select shared or static linkage based on this probe and record the decision in LLVM-ENGINE-001.

Inspect generated unresolved symbols rather than assuming every external starts with `shllvm_`. `_setjmp` is one known external in the emitter. Runtime helper resolution, C runtime symbols, and platform data layout must all be exercised by real emitted code. Start on the existing Linux x86-64 host profile.

## 5. Unit compilation and materialization

Each request gets an engine-local sequence number and an ASCII-safe creator name such as `engine_unit_7`. Do not derive exported symbols directly from arbitrary filenames. Source names remain diagnostic metadata. Internal globals can keep their existing internal linkage; reject unexpected exported symbol collisions.

The LLVM-side algorithm below is pseudocode. It describes ordering and ownership, not exact compilable API syntax:

```text
loadIR(request):
    require engine is open and called on owner thread
    parse text into an LLVM context owned by this request
    validate target triple and data layout against active JIT
    verify LLVM module
    require expected unit creator; reject executable main mode
    create a resource tracker for this unit
    add owned module/context to LLJIT
    look up the unique creator, forcing compilation/linking
    if materialization fails before runtime registration:
        remove unreferenced JIT resources when safe
        return diagnostic
    retain creator, tracker, source identity, and state
    return engine-local UnitId
```

Use the installed LLVM 18 `ThreadSafeModule` ownership model rather than retaining a temporary LLVMContext reference after adding a module. Although execution is single-threaded, the library's context ownership still matters. LLJIT is the initial candidate; do not add lazy function stubs or parallel compilation as part of this work.

Once a unit has been initialized in Hermes, its tracker remains retained until engine shutdown. A thrown initializer is not evidence that its code is unreachable: it may already have published a closure. Code unloading after successful registration is deliberately absent.

## 6. Initialization, shared values, and exception containment

Execute the creator through `_sh_unit_init_guarded` using the engine's existing runtime. Do not call generated `main`, which delegates to the one-shot lifecycle. Preserve the established SHLegacyValue ABI and pass runtime-owned roots where required.

A first shared-state fixture can use scripts rather than ESM lexical imports:

```javascript
// Unit A: compile and execute, then return to the host.
globalThis.shared = { value: 1 };
globalThis.increase = function () { return ++shared.value; };

// Unit B: compile after A has returned.
if (increase() !== 2 || shared.value !== 2)
  throw new Error('cross-unit state');
```

Force GC between these submissions through an existing supported runtime/test hook, located during implementation. Do not invent a public `gc()` function in documentation unless the configured host exposes one. A third fixture keeps an escaped closure from a unit that throws after publication, then calls it from a subsequent unit. This verifies the retain-on-exception lifetime rule.

The guarded result/exception is a managed value. Any formatting or host inspection that can allocate must retain it through the appropriate root mechanism. Initially return a copied diagnostic or status to C++ rather than exposing raw tagged values with unspecified lifetime. Add a rooted host-value API only if the first workload cannot be expressed without it.

## 7. Jobs and shutdown

Explicit job draining makes lifecycle ownership visible. Reuse the existing console/task implementation where its behavior matches the new operation; inspect whether its current drain waits for timers or runs only ready work before naming a public method. Do not promise nonblocking draining from an implementation that blocks.

For module input, unit initialization can merely start asynchronous evaluation. Distinguish initializer completion from module-entry completion. A small completion status bridge or host callback may be needed; this is coordinated with LLVM-MODULES-002. Returning success when no tasks remain but evaluation is pending is not acceptable evidence of completion. The first API may report Pending rather than implementing a general external event loop.

Close requires no active native call. Stop accepting submissions, resolve the host's pending-work shutdown policy, release bindings, destroy the Hermes runtime while its code remains mapped, free remaining host context, and then destroy LLJIT. No runtime may retain references into removed code. Test repeated engine creation and destruction and failure paths during partial construction.

## 8. Source frontend extraction

`compileFromCommandLineOptions()` currently coordinates source compilation using CLI state. Extract an internal source request boundary with explicit source text, source name, optimization choice, and unit-generation options. Keep command-line parsing at the CLI edge. Reuse semantic options required by the LLVM backend, including its established error timing and lexical-binding behavior.

Do not simply rerun global option parsing for every request: persistent compiler state and diagnostics can leak between submissions. Test a parse failure followed by valid source, two different filenames, and alternating optimization requests. Audit source buffer lifetime until emission finishes. The emitted textual LLVM buffer then follows the same verified load path as checkpoint A.

Module bundling remains the existing build-time path. A prebundled graph can be compiled through the new frontend. The host must not claim that separately submitted module bundles share one module registry; extending a registry is a separate loader design.

## 9. Test matrix and acceptance

| Contract | Required observation |
|---|---|
| One unit | Generated creator executes inside the host process. |
| Two units | Shared managed object and closure retain identity and state. |
| GC between calls | Escaped native closures and their code remain valid. |
| Initializer throws | Error reported; published closure remains valid; next valid unit executes. |
| Parse/verify/link error | Correct phase reported; no invalid creator called; host recovery tested where supported. |
| Duplicate creator / wrong target | Rejected before execution with actionable diagnostic. |
| Jobs | Supported Promise/timer work executes with explicit error/completion status. |
| Module bundle | Existing live and await graph examples work as compiled bundles. |
| Teardown | Repeated engine lifetimes do not call freed code or retain unintended runtime instances. |
| Source API | Source submissions compile in-process; no shermes or lli child process on this path. |
| AOT regression | Optional JIT additions do not break ordinary build/run or existing fixture results. |

Use focused lifecycle tests plus the existing core/extension gates at the integration milestone. Run sanitizer-enabled host/runtime builds where feasible, accurately qualifying generated-code instrumentation. Timeouts in a harness bound stalled tests; they are not a new language cancellation mechanism. Record compile latency and retained memory as measurements, with no speculative speed target.

Ticket completion requires both checkpoints, a documented build/run entry point, tests and failure evidence, and a diary of implementation decisions. It does not require full Test262, speculative optimization, full native eval, package loading, or live-code unloading.

## 10. Risks, stop conditions, and references

The highest risks are duplicate runtime linkage, incorrect SHUnit lifetime assumptions, unrooted exception values, mutable unit indices shared across engines, and frontend state leaking between requests. A failure in one of these areas should stop feature expansion until the invariant is understood. Avoid introducing generic compatibility adapters to conceal a mismatch.

Review `LLVMBackend.cpp::ModuleEmitter::generate`, `runtime.c::shllvm_run`, `static_h.h`, `shermes.cpp`, and `hermes/lib/BCGen/SH/CMakeLists.txt` first. Installed `/usr/lib/llvm-18/include/llvm/ExecutionEngine/Orc/LLJIT.h` provides `addIRModule`, `lookup`, `getDataLayout`, and ownership signatures. The [LLVM 18 ORC reference](https://releases.llvm.org/18.1.8/docs/ORCv2.html) explains the relevant library model. Follow exact installed headers for implementation, rather than copying a tutorial from another release.
