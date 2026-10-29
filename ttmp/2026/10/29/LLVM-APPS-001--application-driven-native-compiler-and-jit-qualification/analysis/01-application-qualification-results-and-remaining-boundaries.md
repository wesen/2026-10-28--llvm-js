---
Title: Application qualification results and remaining boundaries
Ticket: LLVM-APPS-001
Status: active
Topics:
    - llvm
    - javascript
    - application-qualification
DocType: analysis
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/examples/llvm-apps/README.md
      Note: Build and execution guide
    - Path: repo://hermes/examples/llvm-apps/persistent-host/main.cpp
      Note: Persistent native application
    - Path: repo://hermes/utils/qualify_shllvm_apps.py
      Note: Reproducible comparison runner and oracles
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T11:29:11.614007287-04:00
WhatFor: ""
WhenToUse: ""
---

# Application qualification: results and remaining boundaries

## Outcome and scope

Implemented all four LLVM-APPS-001 applications and a reproducible comparison runner. The final three-size, two-repetition campaign recorded **96 successful executions**, **nine known admission boundaries**, and **zero unexpected failures**. Nineteen recorded source/build identities were unchanged. The receipt also fingerprints 536 generated fixture and bundle files.

The nine boundaries are unoptimized fflate compilation attempts: two JIT attempts and one AOT build attempt at each of three sizes. They are not successful application executions. AOT compilation happens once per profile/scenario before repeated executable runs; JIT compilation happens in every fresh process. Thus these counts describe recorded outcomes rather than distinct source programs or conformance tests.

Implementation commits: `dc4ca9d` (all four applications and runner) and `0e3a448` (JSON input loading, counted admission diagnostics, rejection tests, and scaled-failure evidence). The final receipt uses the latter code. This campaign makes no full ECMAScript, browser, Node-host, sanitizer, leak-freedom, or production-service claim.

## Reproduce

Follow `hermes/examples/llvm-apps/README.md` to install pinned dependencies and build `shllvm-jit`, `shllvm-app-host`, `shermes`, and the runtime bridge. Then run:

```sh
python3 hermes/utils/qualify_shllvm_apps.py --output /tmp/application-results.json
python3 hermes/utils/test_shllvm_apps.py
```

For a small complete campaign, add `--sizes small --repeat 1`. For a single workload, use `--apps persistent-host` or another documented application name. The host build is optional with the existing `HERMES_BUILD_LLVM_JIT` CMake option. Local execution used Node v24.18.0, Python 3.13.2, and LLVM 18.1.3 on Linux x86-64.

The runner exits zero when all records are successful executions or the specifically recognized fflate O0 boundary. Read `summary` rather than equating a zero campaign exit with universal execution support. Unexpected exceptions, wrong output, missing completion, timeouts, and changed input fingerprints cause failure. Each command retains stdout, stderr, wall time, and peak process RSS. Timed-out process groups are killed together.

## Application contracts

### Data pipeline

The application parses JSON orders, validates identifiers and duplicate identities, rejects invalid amounts and quantities, normalizes customer identifiers, and aggregates integer totals by region. Fixtures contain deliberately invalid rows with independent expected rejection reasons. The Python fixture generator computes expected totals directly from intended record generation; the JavaScript implementation performs its own validation and aggregation through objects, sets, maps, arrays, and exceptions.

The campaign runs 32, 2,048, and 16,384 rows. Each size runs twice in Node, JIT O0/O, and AOT O0/O. All 30 executions pass. The same JSON input is provided to each mode. Amounts use integer minor units, so comparison does not depend on floating-point summation order.

### Asynchronous queue

Four workers process 12, 96, or 256 jobs. Work includes timers, successful payload calculation, one-time transient failures, terminal failures after three attempts, cancellation before starting, and cancellation after suspension. Cleanup runs in `finally`, and the final output records sorted terminal results, attempts, peak concurrency, and cleanup counts.

The independent expectation checks completed values and every terminal state. No fixed ordering of independent timer completions is required. All 30 executions pass after correcting input loading. Cancellation is cooperative application state; the engine does not gain a native execution interrupt API.

### Persistent embedding

The native application creates one Engine and reads a source corpus. Each successful plugin retains a private value, publishes a callable closure, updates the shared ledger, and schedules a callback. Every seventh-plugin interval injects a parse error and an initializer that publishes a closure before throwing. Later submissions verify that state and execute successfully. Forced collection occurs after each admitted submission, including throwing initializers, before later submissions and delayed callbacks use retained values.

The sizes contain 12, 80, and 240 plugin definitions. The largest corpus contains 344 submissions: 310 admitted units, 34 expected parse errors, and 34 expected initializer errors. Its final ledger contains 240 plugins with matching accumulated and callback totals. Node replays the same corpus for semantic comparison, while the C++ host checks native admission/error counts. All 18 executions pass across Node and both frontend profiles, with two repetitions per size.

The final report is scheduled after earlier callbacks. A successful initializer alone is insufficient; the host drains jobs and verifies the final JSON result. This application demonstrates retained native code and values within one engine. It does not establish bounded memory for unlimited units, concurrency, interruption, or a stable public host-value API.

### Third-party archive application

The application imports the unmodified fflate 0.8.2 browser ESM source. Four files cover empty content, repeated Unicode, JSON records, and deterministic patterned text. It exercises per-document gzip round trips, ZIP creation/extraction, streaming gzip callbacks, UTF-8 restoration, and malformed ZIP rejection. Fixed archive metadata makes output deterministic for the local comparison.

The runner independently decodes actual ZIP and gzip output with Python's standard library and checks restored bytes. It also compares normalized output with Node. This is stronger than accepting only same-library round trips. The largest input contains 238,191 bytes; the ZIP contains 24,877 bytes, with rolling checksum 3302722266. Node, optimized JIT, and optimized AOT agree. All 18 admitted executions pass across three sizes and two repetitions.

The unoptimized library module factory needs 1,084 roots and three argument slots. Its combined requirement exceeds the existing 1,024-slot bound, so nine recorded unoptimized attempts are rejected. The library was neither trimmed nor patched. The synchronous profile does not require Workers; Worker APIs remain untested and unsupported by this host.

## The scaled failure and its correction

The first scaled campaign recorded 92 successful executions, nine known library boundaries, and three unexpected queue failures. The counted diagnostic showed that the 256-job setup script required 2,329 root slots plus one argument slot. The queue body had not started: its input was emitted as a large object literal, so fixture construction itself became a compiler admission test.

The correction writes `APP_INPUT = JSON.parse(serializedInput)` uniformly across Node, AOT, and JIT. This preserves the intended data and exercises runtime parsing/allocation without creating thousands of AST expressions solely for fixture transport. The final campaign admits and executes every queue scenario. This correction does not alter the backend cap and does not resolve the separate fflate module-factory limit.

The earlier receipt is retained as `first-scaled-campaign.json.gz`; the initial small receipt is `small-initial.json.gz`. Historical failures remain visible rather than being overwritten by the successful rerun.

## Measurements and interpretation

The table below gives median wall time over two large-case executions and the maximum observed process peak RSS. Native JIT and embedding process times include compilation/materialization, execution, and host lifecycle. AOT rows measure the already-built executable; AOT compilation commands are retained separately in the receipt. Node includes its own startup and import costs. These scopes differ, so this is operational workload evidence, not a controlled speed comparison.

| Large workload | Mode/profile | Median process ms | Maximum RSS KiB |
|---|---|---:|---:|
| data-pipeline | aot/O | 219.3 | 29,480 |
| data-pipeline | aot/O0 | 190.0 | 29,860 |
| data-pipeline | jit/O | 1541.2 | 102,880 |
| data-pipeline | jit/O0 | 1564.0 | 103,052 |
| data-pipeline | node/- | 157.6 | 84,100 |
| async-queue | aot/O | 98.7 | 9,216 |
| async-queue | aot/O0 | 101.5 | 9,600 |
| async-queue | jit/O | 1435.4 | 76,464 |
| async-queue | jit/O0 | 1524.3 | 78,184 |
| async-queue | node/- | 247.2 | 49,440 |
| persistent-host | embedding/O | 3725.7 | 72,828 |
| persistent-host | embedding/O0 | 5527.2 | 72,916 |
| persistent-host | node/node | 117.0 | 52,000 |
| archive-library | aot/O | 1144.1 | 20,196 |
| archive-library | jit/O | 5466.6 | 107,972 |
| archive-library | node/- | 184.4 | 77,212 |

The persistent host additionally reports summed compile and execute durations separately. Compiler activity dominates this corpus because every plugin is a fresh source submission. Code is intentionally retained until close. Peak RSS cannot establish live retained heap size or leak freedom, and two repetitions do not establish stable performance distributions.

## Regression checks and evidence

The existing native lifecycle suite reports `engine-lifecycle-ok`, covering shared state, repeated engines, GC, exception recovery, invalid LLVM inputs, thread checks, and teardown. Existing driver publication checks pass 6/6, including preservation of existing output after oversized-frame rejection. The six new harness checks demonstrate rejection of incomplete or incorrect results even when a process prints plausible JSON or exits zero. No broad conformance rerun was necessary for the diagnostic-only compiler change.

Authoritative evidence is in `reference/evidence/final-application-campaign.json.gz`. It retains process commands and complete output including binary transport arrays. `receipt-hashes.json` checks the stored receipt bytes. Generated executables are not committed; deterministic fixtures and source bundles can be regenerated by the runner. Build and dependency identities are recorded in the receipt.

## Remaining work and disposition

The application campaign is complete under its documented bounded profile. The unoptimized library admission boundary is explicitly assigned to **LLVM-MODULES-002 M08** with its new real-world reproducer and required slot counts. M08 remains open. A future allocator change must preserve GC visibility and exception/recursion behavior; increasing the constant without stack analysis is not implied by this result.

Other existing engine boundaries remain: single-owner-thread use, retained code until engine destruction, process-global unit-index high-water storage, build-time module graph preparation, and no arbitrary runtime package loader. The applications do not require changing these contracts. Larger workloads, longer-running hosts, more libraries, and expanded host APIs can now be evaluated using the same receipt structure rather than speculative infrastructure.
