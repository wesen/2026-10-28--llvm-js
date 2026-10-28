# Async, Promise, and extension validation diary

Date: 28 October 2026. This log records observable engineering work and
decisions; it does not contain a private reasoning transcript.

## Baseline inspection

The existing direct backend calls the real Static Hermes runtime and its
console event loop. `StaticHInit.cpp` enables the native microtask queue for
CLI execution. `ConsoleBindings.cpp::run_event_loop` drains microtasks before
processing timers and after each timer task. Therefore ordinary Promise jobs
already have an execution mechanism.

The frontend lowers async functions to a generator closure passed to the
`HermesBuiltin_spawnAsync` builtin. `lib/InternalJavaScript/02-AsyncFn.js`
drives that generator with `next` and `throw`, resolves the async return value,
and rejects uncaught exceptions. The missing native generator emission is
therefore the central backend dependency for async/await.

## Reproduced inherited Promise.all ordering defect

The existing Promise implementation deliberately optimized an already-fulfilled
input in `Promise.all` by invoking the element resolver synchronously unless
the runtime enabled test262 mode. The source comment itself acknowledged that
this collapses an observable microtask step.

The two-line probe in `promise-all-order-probe.js` schedules a resolved
`Promise.all` callback and a separate resolved-Promise callback. Actual output
before the change:

- Node: `tick`, then `all`.
- Unmodified C-emission path with the original Hermes runtime: `all`, then `tick`.

Both processes exited successfully, so an exit-code-only test would miss this
semantic difference. The new Promise fixture preserves this ordering check.

The fix always invokes `nextPromise.then(resolveElement, capReject)`, matching
the required PromiseReactionJob ordering and observable `then` access. It
removes the test262-only correctness gate; it does not add a new scheduling
system or change the LLVM bridge.

Reference: ECMAScript `PerformPromiseAll` in
https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-performpromiseall.
The runtime rebuild and post-change execution are performed by the parent
build owner; this entry records the reproduced failure and source correction,
not an unperformed success claim.

## Test harness and first integration pass

Added ten initial asynchronous/Promise fixtures with explicit completion
markers. Node executed all ten successfully. Coverage includes primitive and
thenable awaits, closures, lexical `this` and `arguments`, try/catch/finally,
retention across `gc()`, async iteration, queued generator requests, Promise
combinators, resolution/rejection, and subclasses. Separate fixtures exercise
uncaught errors and invalid syntax.

Implemented `utils/test_shllvm_extensions.py`. The default gate uses two
frontend optimization settings, two LLVM optimization settings, and the real
`lli` JIT for every executable fixture. Node runs each source as a script via
`vm.runInThisContext`; this avoids accidentally testing CommonJS lexical scope
when validating dynamic eval. The inherited C backend is required by default.
Explicit C-oracle limitations are recorded separately with a reason and actual
outcome; they never become successful C comparisons.

Added repeatable frontend `--hermes-arg=-X...` options to the Python driver for
async-generator fixtures. Validation rejects output/backend switches in this
option, and build manifests retain the arguments. The rejection of
`--hermes-arg=-emit-c` was checked before runtime tests.

The build owner ran the first integration matrix: 20 of 24 selected source
cases passed. All generator and initial value features except the known typed
array indexing case passed. The shared runtime produced three asynchronous
failures: async-generator finalization in two fixtures and Promise subclass
species selection. Both C and direct LLVM reproduced them. The first pass is
diagnostic evidence, not the release gate: the input fingerprint also detected
the generator GC fixture being strengthened during that run.

Evidence: `extension-first-pass.json`, `extension-first-pass.log`,
`initial-native-probes.json`, and `async-generator-close-c-probe.json` in this
directory. The corrected `Promise.all` order was already successful in the
first direct LLVM probes and matrix.

## Async-generator return and finally correction

`04-AsyncIterator.js` drives the transformed synchronous generator with a
Promise request queue. A yield tagged as kind 0 represents an internal await.
The old code reused a pending `return` request when that await completed. If
`return("closed")` entered a `finally` block containing `await 0`, it resumed
with `return(0)`. This skipped the remainder of cleanup and replaced the
original return value.

Changed kind-0 fulfillment to resume with `next(resolvedValue)`. The underlying
generator retains its pending completion while the finally body executes.
Rejection still resumes with `throw(error)`, which can replace that completion.
No IRGen or event-loop change was needed.

Added `async_generator_finally.js` to check normal cleanup, a finally return
overriding the original return, a finally throw, yielding during cleanup,
rejection during cleanup, injected throw after an await, and original loop-body
exception precedence during async iterator close. Node's complete expected
outputs are saved in `async-promise-node-oracles.json`.

## Promise species and reaction scheduling

The previous `then` and `finally` implementation explicitly ignored
`Symbol.species`. Added the default static species getter and shared
SpeciesConstructor selection with null/undefined fallback, observable lookup
ordering, and invalid-constructor rejection. `finally` now uses the abstract
PromiseResolve operation instead of reading a user-overridable `C.resolve`.

The existing subclass path also routed results through an intermediate core
Promise. This introduced a second reaction job. The corrected handler settles
the selected constructor's capability in the original reaction job. Added
`promise_species.js` and `promise_subclass_order.js` to cover selection,
single-read getters, invalid species, generic finally validation without a
premature `then` read, proxy constructor inspection, and relative microtask
ordering between core and subclass Promises.

The JavaScript builtin requires a side-effect-free constructor predicate. Added
`HermesInternal.isConstructor` using the existing VM operation and predefined
symbol. The new native wrapper performs no allocation and reads an argument
already rooted in the native call frame. Before editing VM code, read the
repository's `gc-safe-coding` skill and complete `doc/GCSafeCoding.md`; no new
legacy GCScope or unrooted value was introduced.

## Thenable jobs and public Promise identity

A focused probe found two additional shared-runtime defects. For a thenable,
Node printed `sync|then|tick|resolved:4`; the C runtime printed
`then|sync|resolved:4|tick`. The runtime invoked the thenable synchronously.
The same probe found `Promise.resolve(0) === Promise.resolve(0)` true in Hermes
and false in Node because public resolve returned a cached Promise.

Changed resolution to read `then` synchronously but invoke it in a queued
NewPromiseResolveThenableJob, including adoption of another core Promise.
Captured intrinsic `Reflect.apply` avoids observing a then function's user
`call` or `bind` properties. Public `Promise.resolve` now allocates a fresh
wrapper for non-Promise values; private await caches remain inaccessible.
Added `promise_thenable_jobs.js` to check thenable lookup/invocation order,
adoption order, fresh primitive wrappers, exact-Promise identity, and negative
zero preservation.

The pre-change commands and actual output are preserved in
`promise-thenable-order-probe.json`; the source probe is kept alongside it.
After adding these regressions, all 14 positive async/Promise fixtures pass
Node. Rebuilt C/native LLVM/JIT validation is pending the coordinated runtime
rebuild at this diary entry.

## Reference material checked

The implementation decisions were checked against the following primary
ECMAScript algorithms, accessed 28 October 2026. Stable section anchors are
used because section numbers change between specification editions.

- [SpeciesConstructor](https://tc39.es/ecma262/multipage/abstract-operations.html#sec-speciesconstructor): constructor and species lookup, default selection, and constructibility validation.
- [NewPromiseReactionJob](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-newpromisereactionjob): settling a reaction's capability within the same job.
- [NewPromiseResolveThenableJob](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-newpromiseresolvethenablejob): deferring invocation of a thenable until surrounding execution completes.
- [PromiseResolve](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise-resolve): exact-Promise identity and fresh capabilities for other resolutions.
- [Promise.prototype.finally](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise.prototype.finally): species selection and abstract PromiseResolve, without consulting a public resolve override.
- [AsyncGeneratorYield](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-asyncgeneratoryield): queued resumptions and normal/abrupt completion handling.

These algorithms support the targeted contract choices; the regression suite
does not assert complete Promise branding, cross-realm behavior, or full
ECMAScript conformance.

## Rebuilt focused gate: all initial corrections pass

After the coordinated fourth build, ran the async/Promise selection with both
frontend settings, both native LLVM settings, and real `lli`. The process
exited 0: **17/17 source contracts, 68/68 native contracts, and 17/17 JIT
contracts passed**. This comprises 14 positive programs and three expected
uncaught errors. Every C oracle matched Node at both frontend levels. Input
fingerprints were unchanged throughout this focused run.

Evidence: `async-promise-fixed-pass.json` and
`async-promise-fixed-pass.log`. These are preserved as historical validation of
that build, not overwritten by the subsequent return-protocol work.

## Return values, source cleanup, and async request completion

A further focused helper probe found a distinct case: passing a rejected
Promise to `asyncGenerator.return()` must deliver its rejection at the suspended
yield, where an enclosing catch may recover. The old helper called the
underlying synchronous generator's return immediately, skipped that catch, and
only observed the rejection after the generator had closed. The native Node
generator recovered and yielded a value; the helper rejected instead.

Fixing only request entry would still add an extra microtask when the driver
awaited the final iterator value. The correction therefore makes the two
required await points explicit:

1. The AST transformation rewrites a source `return expression` to await the
   expression within the source generator's try/catch/finally context.
2. The runtime awaits an external `return(value)` argument before injecting
   its return or throw completion into the suspended generator.

Once the underlying generator reports completion, the driver can complete the
request directly. It does not add an extra await or unwrap a Promise that an
async delegate legitimately returns as the final result's value. Completed
next/throw requests are drained iteratively, preventing a long queued tail
from consuming recursive native stack frames. Return requests in that tail
still await their arguments.

The AST visitor treats nested arrows as separate function contexts. It also
wraps empty async generators, whose iterator methods still must return
Promises and expose `Symbol.asyncIterator`.

Added `async_generator_return_values.js`, `async_generator_return_order.js`,
`async_generator_queue_completion.js`, and `async_timers.js`. The last case
checks cancellation, microtasks between timer callbacks, and awaiting a timer
resolution. The queue case creates 2,052 requests and runs `gc()` before
settlement. All four new sources pass Node; their outputs are retained in
`async-return-node-oracles.json`.

The helper-only before/after evidence is
`async-return-rejection-helper-probe.json` and
`async-return-fixed-helper-probe.json`. The corrected helper matches native
Node for return-argument rejection, return-expression rejection, and relative
return/tick ordering. This isolates the JavaScript driver behavior; rebuilt
AST-to-C and AST-to-LLVM validation remains the next gate.

Reference:
[AsyncGeneratorUnwrapYieldResumption](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-asyncgeneratorunwrapyieldresumption).

## Final review: interrupted gate and parameter-expression traversal

The build-9 focused gate was interrupted after eleven positive cases had
completed. Its retained JSON explicitly says `complete: false`: the eleven
cases passed all 44 native executions, eleven real `lli` executions, and 22 C
oracle executions. Both previously oversized unoptimized programs,
`async_generator_finally.js` and `async_generator_return_values.js`, are among
these completed cases. No failure is recorded, but this partial run does not
provide a completed input-identity check or a release result. The final full
gate must establish those independently. The partial evidence remains in
`async-promise-final-pass.json` and its log.

A source review then found that function declarations and function expressions
visited only their bodies. Arrow functions already visited their parameters,
but a nested async generator in another function's default parameter could
remain untransformed. A concrete build-9 probe covered defaults in ordinary
declarations, ordinary function expressions, async functions, and async
generators. Node returned Promise-valued iterator results yielding 1, 2, 3,
and 4. Both Hermes frontend O0 and O with LLVM O2 produced caught TypeErrors
for all four cases. An ordinary async-function default remained correct.
The source and outputs are preserved in
`traversal-probes/generator_in_parameters.js` and
`async-parameter-traversal-build9.json`.

The correction visits every parameter node before transforming or moving a
function's parameters. Parameter traversal uses a fresh non-async-generator
context, so an enclosing generator cannot rewrite another function's default
expressions as its own suspension points. Nested functions still establish
their own context, and the visitor restores the previous state before visiting
the body. The existing early return for lazy function bodies is preserved.
The permanent `async_parameter_expressions.js` fixture covers all four failed
forms and the working ordinary-async control. Runtime validation of the
correction awaits the coordinated final build; no passing result is inferred
from the source change itself.

## Final frozen validation: async and Promise contracts pass

The coordinated final build and complete extension matrix are now verified.
`extension-final-validation.json` records 53/53 source contracts passing,
`complete: true`, `partial_gate: false`, no skipped cases, and unchanged input
fingerprints. Filtering its actual records by the `async`, `async-generators`,
and `promises` families yields **24/24 contracts**: twenty positive programs,
three expected runtime errors, and one invalid-await compiler rejection.

The 23 executable async/Promise contracts passed all **92 native executions**
(frontend O0/O crossed with LLVM O0/O2), **23 real `lli` executions**, and
**46 C oracle executions**. These totals include the three expected-error
contracts; the positive-program totals are 80 native, twenty `lli`, and forty
C executions. Every executable contract matched Node's declared result.
The invalid-await fixture passed all six compiler/driver publication checks
across the two frontend settings.

Coverage includes await values and exceptions, captures and GC, timer/job
ordering, async-generator queues and delegation, return/finally behavior,
completed requests, Promise combinators and resolution, species and subclass
ordering, thenable jobs, and expected Promise errors. Both
`async_nested_expressions.js` and `async_parameter_expressions.js` matched Node
through all four native combinations, real `lli`, and both C configurations.
This closes the pending validation for operand and parameter traversal. The
earlier interrupted focused evidence remains unchanged. These are targeted
host contracts, not a full ECMAScript conformance result.
