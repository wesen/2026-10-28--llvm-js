---
Title: Module boundaries causes priorities and follow-up designs
Ticket: LLVM-MODULES-002
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/docs/llvm/MODULES.md
      Note: Current supported host policy and boundaries
    - Path: repo://hermes/lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
      Note: Shared backend frame admission limit
    - Path: repo://hermes/utils/module-host/compiler.cjs
      Note: Static graph and binding transformation restrictions
    - Path: repo://hermes/utils/module-host/runtime.js
      Note: Evaluation completion and per-graph registry
    - Path: repo://hermes/utils/test_shllvm_test262.py
      Note: Classification and completion-marker evidence
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-29T09:32:29.217135606-04:00
WhatFor: ""
WhenToUse: ""
---

# Module follow-up inventory and bounded designs

## 1. Purpose and prioritization rule

Preserve every known module-host boundary, explain its cause, and record a bounded implementation approach so the work is not lost when the project moves to the native engine and JIT. This is a backlog ticket, not a requirement to implement every item before the engine is useful. The user's current direction is practical language coverage without unnecessary complexity.

The completed milestone is LLVM-MODULES-001 at code commit `185923d`, documented at `8db50e0`. It provides closed filesystem graphs, live bindings, namespaces, cycles, dynamic import of included modules, top-level await, and top-level for-await. The operational contract is `hermes/docs/llvm/MODULES.md`; the design and chronological diary remain in the original ticket. Do not rewrite their historical limits as current failures or imply that this follow-up is implemented.

Priority labels in this document are recommendations: P1 means useful for engine integration, P2 means implement when a supported application requires it, and P3 means retain as a known limit unless evidence justifies the complexity. A documented decision to defer is a valid backlog disposition, but is never a passing language test.

## 2. Complete boundary inventory

| ID | Boundary and current effect | Cause | Priority / ownership |
|---|---|---|---|
| M01 | Pending top-level await can outlive an empty task queue without a failure exit | Entry evaluation completion is not connected to process/engine lifecycle | P1; coordinate LLVM-JIT-001 |
| M02 | Dynamic import in ordinary script mode is unavailable | Script path has no module loader/referrer integration | P2; host integration |
| M03 | Direct eval in transformed modules is rejected | Dynamic compiler cannot reconstruct rewritten imported bindings | P2 if applications require it; coordinate LLVM-ECMA-002 |
| M04 | New runtime source files cannot be loaded | Graph and metadata are fixed at build time | P2 only with a runtime-loading use case |
| M05 | Bare packages, extension lookup, URLs, and paths outside root are rejected | Deliberately narrow filesystem resolution policy | P3; product-specific host policy |
| M06 | Non-empty import attributes are unsupported | No attribute-aware loading/module-type implementation | P2 if required; otherwise defer |
| M07 | Source-phase and deferred-phase imports are unsupported | Additional phase semantics not implemented | P3 unless selected profile/workload needs them |
| M08 | Large lowered bodies exceed 1,024 combined root/argument slots | Existing backend frame admission design | P2 based on real workload; backend ownership |
| M09 | Generated locations are not original-module source maps | Transformation provenance not propagated through the pipeline | P2 for usable diagnostics; full debugging can remain deferred |
| M10 | Arbitrary mutation of host-used built-ins is not qualified | JavaScript host uses public intrinsics beyond protected Promise reactions | P3 broad hardening; targeted fixes for observed failures |
| M11 | Independent compiled bundles have separate module registries | Host records are created per generated graph | P2 only if one engine must extend/share a graph |
| M12 | Evidence covers a selected profile, with two Node disagreements | Targeted validation is not full cross-engine or language conformance | Ongoing evidence maintenance, not a demand for full conformance |

M11 is an architectural consequence of the current generated host, highlighted for persistent-engine work. It is not a newly measured failed test. M05 includes intentionally unsupported query/fragment suffixes, backslashes, NUL, and implicit CommonJS fallback. Keep these resolution choices explicit even if other loading features are added.

## 3. M01: connect evaluation to host lifetime

A unit initializer can successfully start an asynchronous module whose entry has not completed. `runtime.js` exposes `run(id, onComplete, onError)`, but the normal generated entry does not publish a pending/completed state that the console loop inspects. The Test262 runner requires a completion marker; ordinary executable success does not provide the same proof.

The minimal design is an entry-state record with Pending, Fulfilled, and Rejected outcomes owned by the embedding. Connect existing completion/error callbacks to a small host notification mechanism. Keep the protocol private and reliable; do not use stdout text as the production embedding API. The exact bridge should be chosen alongside LLVM-JIT-001 so console and embedded modes use the same completion information without introducing a large scheduler abstraction.

```text
start entry:
    state = Pending
    run(entry, onFulfilled, onRejected)

onFulfilled:
    state = Fulfilled
onRejected(error):
    state = Rejected(error)

after supported job draining:
    if state is Fulfilled: report completed
    if state is Rejected: report error
    if state is Pending: report pending to embedding
```

For standalone commands, choose and document a nonzero incomplete-evaluation outcome when the host has no possible remaining work. An embedding with external future events may legitimately retain Pending. Do not infer impossibility merely because the current ready queue is empty; establish what timers and external sources the configured host owns. No arbitrary timeout or synthetic JavaScript rejection should replace the pending state.

Acceptance cases: synchronous completion, await fulfillment, await rejection, timer fulfillment, unresolved Promise with no future host work, and a cycle waiting on its own dynamic import. Preserve original errors. Verify that unresolved execution cannot be classified as completed and that supported timers are not prematurely abandoned.

## 4. M02: dynamic import from scripts

A script containing `import()` needs a referrer identity and access to a module registry. Its ordinary global declarations and receiver semantics must remain those of a script; wrapping the whole script as a module would be incorrect.

A bounded first version can lower script import expressions to a host request operation while keeping the rest of the script compilation unchanged. Supply the referrer source identity and a preincluded graph. Share that host with the entry's module requests. Literal targets can be discovered at build time; computed targets can continue to require explicit inclusion. Runtime loading is not a prerequisite.

Tests should include fresh request Promises, repeated namespace identity, missing targets, import rejection timing, and scripts retaining their own global semantics. The four ordinary-script unsupported variants in the selected module-code receipt are starting probes, not the entire acceptance suite.

## 5. M03: module lexical eval

The static compiler rewrites import references into live-cell access. Eval strings bypass that rewriting and cannot see the same source-level names automatically. The current compiler rejects unshadowed direct eval in transformed modules rather than executing an incorrect lexical environment.

The design must convey module-local declarations, imported binding identities, constness/immutability, initialization state, and the caller's lexical context to the dynamic compiler. Module strictness avoids general sloppy declaration injection, but imported bindings still require an appropriate immutable environment reference. Preserve sharing with native closures and eval-created closures; copying current values into an eval scope is insufficient.

Reuse the existing lexical-eval metadata mechanisms where they actually fit, after comparing them with the module cell representation. Do not force a general environment abstraction solely to make the APIs look uniform. LLVM-ECMA-002 owns general sloppy storage and private/super/derived-context extensions; this item should reference those designs without making all of them prerequisites.

Acceptance includes reads observing exporter updates, imported assignment failure, TDZ through a cyclic import, locals mutated by eval and observed natively, escaping eval-created closures after GC, shadowing, and nested eval. If real workloads do not need this, retain the explicit rejection as part of the practical profile.

## 6. M04, M05, and M11: loading, resolution, and registry identity

Runtime loading and package resolution are different features. Runtime loading obtains source after the executable is built; package resolution decides which source a request identifies. Neither follows automatically from adding ORC.

If a workload requires incremental modules, introduce one engine-owned module registry with canonical identities, load/link/evaluation states, and retained failures. Adapt discovery metadata into records without executing bodies prematurely. Avoid compiling each request into a separate isolated bundle that reruns shared dependencies. Concurrent or repeated requests must converge on one module identity while retaining distinct public Promises.

Select the execution path for new source explicitly. Existing Hermes bytecode compilation may be sufficient; native JIT units are another option after LLVM-JIT-001. Any mixed execution must share binding and object semantics. Do not claim that existing eval bytecode machinery already implements runtime ESM linking.

For a first extension, keep exact local relative paths and the root boundary. Network loading, package exports maps, extension search, CommonJS, and URL identity policies need separate use cases. Tests for incremental loading should cover duplicate aliases, static and dynamic cycles, cached evaluation errors, a failed importer followed by a valid importer, and the same dependency requested by separately submitted units.

## 7. M06 and M07: attributes and phases

Non-empty import attributes need a host decision about accepted keys and module types. Merely allowing the parser syntax would turn an explicit boundary into silently ignored semantics. A bounded implementation could support one concrete requested module type, define validation and identity rules, and test both static and dynamic imports, including getter effects and rejection behavior. JSON support is a possible use case, not a current requirement or an already chosen design.

Source and deferred phases need their own resolution/evaluation behavior. Preserve parser support sufficient for an explicit unsupported diagnostic, and require a design against the selected edition/proposal before admitting them. Record proposal membership separately from implementation status; not every test in a pinned Test262 checkout belongs to the project's chosen release profile.

The current selected receipt has eight attribute and three source-phase module rejections. Those numbers are baseline records, not a reason by themselves to implement a feature that has no practical consumer.

## 8. M08: large frames and lowering size

The retained `scripts/01-oversized-for-await-probe.mjs` in LLVM-MODULES-001 combines loop cases that exceed the backend's root/argument-slot bound. Splitting independent fixtures allowed semantic qualification but did not support the original combined program. Two selected Test262 variants also remain rejected for frame capacity.

Investigate actual slot usage before changing architecture. The backend already reuses a discard slot for unused results. Next candidates include liveness-based reuse of rooted storage or an overflow frame allocation strategy. Both must preserve collector visibility through calls, exceptions, suspension, and recursion. Raising the limit without stack measurements is not an adequate general solution.

Start from a real workload or retained oversized source, measure required slots and stack use, then select the smallest sufficient change. Acceptance requires formerly rejected programs plus forced-GC and exception regressions. This is a backend task shared with AOT and JIT, not a module-only feature.

## 9. M09 and M10: diagnostics and intrinsic robustness

A modest diagnostics improvement is to preserve original filenames and module identities through emitted metadata and error reports. Full source maps require correspondence through Babel transformation, Hermes lowering, LLVM debug information, and runtime stack presentation; do not promise that adding a Babel map alone makes native stacks accurate. First test useful filenames and attribution, then decide whether line-level mapping is needed.

The private moduleThen builtin protects tested Promise reactions, but the host still calls public operations such as Object and Reflect methods. Audit dependencies and add targeted regressions for realistic mutation cases. Capturing selected intrinsic references before source execution may be sufficient for some operations. Avoid copying the entire JavaScript runtime into native helpers as an unmeasured hardening project. Document unsupported hostile mutation rather than implying a sandbox.

## 10. M12: evidence maintenance and oracle qualifications

The completed module gate is 14/14 graph contracts, 56 native executions, and 14 real lli executions. The selected Test262 profile records 585 passes and 17 unsupported variants, comprising 396 runtime, 166 parsing, and 23 resolution passes. Babel and Node link-only checks are attributed separately from native body execution.

Two fixtures use specification-directed output: duplicate namespace reexport identity and numeric-looking namespace key order. Keep their oracle.json explanations and recorded Node 24.18.0 results. If a future Node version agrees, update the new receipt without rewriting the old evidence. A Node mismatch should trigger investigation, not automatic rewriting of expected output.

For each follow-up, run the targeted contracts and relevant regression gate at a meaningful integration checkpoint. Do not require the full historical 102,992-variant baseline for every change. Preserve unsupported categories and phase attribution. The practical goal is understood behavior for admitted programs, with evidence proportional to the risk.

## 11. Backlog disposition and completion rule

This ticket remains open while its inventory is useful and undecided work remains. Completing the design document does not mark the twelve follow-up items implemented. Each item should acquire one of these dispositions: implemented with evidence, deliberately retained boundary with rationale, or moved to a named child ticket. Revisit P2/P3 items when application requirements change rather than treating them as mandatory release gates.

The first coordinated action is M01 during engine lifecycle work. M02 is a small next host-integration candidate. M03 and incremental registry/loading design are larger changes and should not delay the initial in-process JIT unless a chosen application requires them. Frame capacity work should be driven by encountered programs. Attributes, extra phases, package loading, and broad mutation hardening remain deferred by default.

## 12. Primary local references

Read `hermes/docs/llvm/MODULES.md`, `hermes/utils/module-host/compiler.cjs`, `hermes/utils/module-host/runtime.js`, `hermes/utils/shllvm.py`, and `hermes/utils/test_shllvm_test262.py`. The original module ticket provides the detailed design, diary, initial/final evidence, and oversized probe. LLVM-ENGINE-001 defines engine ownership; LLVM-JIT-001 implements the shared runtime lifecycle. LLVM-ECMA-002 contains the separate dynamic-evaluation designs.

The vault report is `Projects/2026/10/29/PROJ - Direct LLVM JavaScript - ECMAScript Module Host Implementation.md` in `/home/manuel/code/wesen/go-go-golems/go-go-parc`. It provides the narrative explanation and measured checkpoint. This ticket owns future disposition, not historical result totals.
