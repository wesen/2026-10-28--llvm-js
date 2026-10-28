# Language extensions: suspension, values, and dynamic code

This chapter follows the extension of the direct LLVM backend from ordinary
functions, objects and closures to generators, asynchronous execution, richer
values and runtime compilation. Read it with the implementation and the
extension validation records. The compiler remains based on Static Hermes
commit `f837b9dd8396ebf5c4e8115412417d273565f0fe`. Changes to the shared runtime
and frontend are included in the patch, alongside the LLVM emitter.

The central design rule is to preserve one managed JavaScript value model.
Generators, Promise reactions, private fields and dynamically compiled
closures all need to keep references to objects after an ordinary native
function returns. Reusing Hermes environments and its collector makes those
references interoperable. A second heap or a copied closure representation
would introduce synchronization and lifetime problems that LLVM alone cannot
solve. [14] [15]

## Generator functions become resumable native functions

Consider a small generator:

```javascript
function* counter(start) {
  let value = start;
  const increment = yield value;
  value += increment;
  return value;
}
const iterator = counter(10);
print(JSON.stringify(iterator.next()));
print(JSON.stringify(iterator.next(7)));
```

Calling `counter(10)` creates a generator object. The first `next()` enters
the body and produces an iterator-result object containing 10 and a false
completion flag. The second call provides 7 as the result of the suspended
`yield` expression, then completes with 17. An ordinary native function call
cannot retain its automatic local variables after returning, so the compiler
must make the suspension state explicit. [14] [20]

Hermes already has a suitable transformation,
`lib/Optimizer/Scalar/LowerGeneratorFunction.cpp`. The direct backend invokes
the shared module-lowering pipeline, which runs this transformation before
instruction selection. It creates an outer function that allocates the
persistent environment and an inner resumption function. The environment
holds the continuation index, execution state, exception-handler index, and
values that must survive suspension. The continuation index selects a block
of the inner function when it is called again.

A `SaveAndYieldInst` therefore does not survive into LLVM emission. Lowering
replaces it with stores of the next continuation and suspended state, followed
by a normal return of an iterator-result object. A later invocation loads
those cells and branches to the saved continuation. LLVM sees ordinary
functions, calls, loads, stores and control-flow edges; this implementation
does not use LLVM coroutine intrinsics. [14] [1]

| Stored execution state | Meaning | Relevant transition |
|---|---|---|
| Suspended start | The body has not begun | A normal next call starts execution |
| Executing | The resumption function is active | A reentrant resume raises TypeError |
| Suspended yield | The body returned a yielded value | Next, throw or return supplies a completion to the continuation |
| Completed | The body has finished or failed | Further operations follow the completed-generator protocol |

The new emitter case is `CreateGeneratorInst`. It supplies the generated
LLVM function address, the managed environment and the function descriptor
to `shllvm_generator`. The bridge delegates allocation and prototype behavior
to `_sh_ljs_create_generator_object`. The function descriptor remains owned
by the compilation unit; the environment remains managed by Hermes. The
bridge rejects a missing environment because the lowering must have created
one before this operation. [1] [2] [5]

This division is useful pedagogically. The lowering pass answers, “What
state must survive?” The emitter answers, “How is the resulting control flow
represented in LLVM?” The runtime answers, “How is the generator object
allocated, identified, and invoked?” Keeping these responsibilities separate
lets one inspect a generated `.ll` file without reconstructing the entire
JavaScript iterator protocol from machine instructions.

## Abrupt completions, delegation and iterator cleanup

Suspension becomes more difficult when it occurs inside exception handling.
A generator's `return(value)` request may enter a `finally` block that itself
yields. That yield postpones the pending return; it does not erase it. A
`throw(error)` request can likewise suspend during cleanup before the error
eventually escapes. The generator tests explicitly exercise both patterns.

The shared lowering rewrites generator exception regions into a resumption
dispatcher and an exception dispatcher. It cannot simply jump into an old
native stack frame whose exception handler has already been removed. The
saved handler state identifies where execution should continue after the
next exception. The direct emitter then uses the same caller-owned jump
buffer and volatile-root discipline described in the exception chapter.
The generator environment and the native exception frame solve different
lifetime problems. [14] [1] [2]

Delegation with `yield*` adds another object whose `next`, `throw` and
`return` methods can run user code. It also makes iterator closing observable.
A `for...of` loop that exits with `break` must give its iterator the
appropriate cleanup opportunity. Destructuring can close an iterator after
consuming only part of it. The new bridge exposes the existing iterator
begin, next and close operations rather than expanding their semantics into
unrooted native temporaries.

| Hermes instruction | LLVM bridge | Mutable state |
|---|---|---|
| `IteratorBeginInst` | `shllvm_iterator_begin` | Source slot may become the next-method slot |
| `IteratorNextInst` | `shllvm_iterator_next` | Iterator/index slot advances |
| `IteratorCloseInst` | `shllvm_iterator_close` | Runtime performs close and exception handling |
| `GetPNamesInst` | `shllvm_pnames` | Base, index, size and property-list slots |
| `GetNextPNameInst` | `shllvm_pname_next` | Current property and enumeration index |

The last two operations support `for...in` property enumeration. Their
bridges return a small integer condition after updating the rooted slots.
The emitter branches through its existing phi-copy edge mechanism. This
detail matters: a terminator that updates several pieces of iteration state
must write the slots before taking the successor edge, including when the
loop lives inside a generator state machine. [1] [2] [5]

The fixtures separate protocol concerns from lifetime concerns.
`generator_protocol.js` checks sent values, early completion, thrown
exceptions and reentrancy. `generator_delegation.js` checks delegated methods,
missing throw handlers, loop cleanup and destructuring. The finally fixture
checks pending completions. The enumeration fixture checks inherited and
deleted properties. The GC fixture suspends generators, collects, resumes
them and verifies that a native closure still shares the same mutable cell.

## Async functions use generators and Promise jobs

In this implementation an async function is lowered into a generator driven
by `HermesBuiltin_spawnAsync`. A yielded await operand is normalized to a
Promise. Fulfillment resumes the generator normally, rejection resumes it
with a throw, final return resolves the async result, and an uncaught error
rejects that result. The driver lives in
`lib/InternalJavaScript/02-AsyncFn.js`. The new LLVM generator creation path
therefore enables the central execution mechanism for ordinary async
functions as well. [16]

There are three distinct mechanisms to follow. First, frontend lowering
identifies suspension points and produces the generator. Second, Promise
reaction jobs decide when the continuation is eligible to run. Third, the
host's event loop drains those jobs. A correct lowering with a missing job
drain can terminate a process without producing the awaited output; a
correct job queue with an incorrect continuation can produce the wrong
values. The test harness checks explicit completion markers as well as
process exit codes and full output.

The console host already enables and drains Hermes's microtask queue. The
extension reuses that path through `shllvm_run`; it does not introduce a
second scheduler. Async tests cover ordinary values, fulfilled and rejected
Promises, thenables, nested scheduling, caught errors, cleanup, receiver
capture and collection while continuations remain pending. The native and
`lli` paths use the same runtime queue. [16] [17]

The first differential run found a shared-runtime ordering defect:
`Promise.all` handled already-fulfilled inputs synchronously on its ordinary
path. A minimal program queued a `Promise.all` reaction and a separate
resolved-Promise reaction. Node printed `tick` before `all`; the original
Hermes runtime reversed those lines. The fix always invokes the input's
`then` method and allows its reaction to run through the job queue. The
original failure and corrected runs are kept as separate evidence. [17]

Further targeted tests exercise subclass capabilities, the constructor's
`Symbol.species` property, thenable resolution, and fresh Promise identity.
These are runtime semantics, not LLVM instruction-selection details. The
shared Promise implementation was changed where the tests demonstrated a
concrete divergence. Consequently the C backend is still a valuable
comparison of code generators, but its runtime is now the patched runtime,
not an untouched upstream oracle.

Async generators add a queue of next, throw and return requests. A
particularly revealing regression enters an async generator's `finally`
block using `return("closed")`, then suspends on `await 0` inside that block.
The old async-generator driver resumed with another `return(0)`. This
abandoned the remaining cleanup and replaced the pending return value.
Resuming an internal await with `next(resolvedValue)` lets the generator
continue its saved cleanup and retain the original completion. The rejection
path still resumes with a throw. [18]

External return requests have a related but different rule: their argument
must be awaited before the resulting return or throw is injected into the
suspended generator. Source return expressions must also await inside their
original try/catch/finally region. Waiting only after the body has completed
is too late for a rejection to reach a surrounding catch. The frontend now
inserts the internal await at a return expression, and the queue driver awaits
an external return argument. Completed results do not acquire a redundant
second await job. Empty async generators still receive the Promise-returning
driver, and nested arrows retain their own return/await context. [18] [26] [27]

The transformation must visit expression roots as well as their children.
An await operand may itself be another await or an async-generator expression;
visiting only the operand's children skips that outer operation. Default
parameters can also contain nested function expressions. The visitor now
traverses parameter roots before body transformation and isolates each
function's context, including arrows. These rules prevent a nested function
from accidentally inheriting an enclosing async generator's return rewriting.
The parameter, nested-await and nested-yield fixtures exercise these cases
through both code generators. [26]

Async-generator syntax is selected with `-Xasync-generators`. The wrapper's
repeatable `--hermes-arg=-X...` option forwards such frontend choices and
records them in the build manifest. It accepts only frontend `-X` options so
that additional arguments cannot override output selection or replace the
direct backend with the C path. The tests keep the option explicit.

## BigInt, regular expressions and private state

BigInt literals need an exact representation. Converting
`123456789012345678901234567890n` through a floating-point Number would lose
information before the runtime ever received it. The emitter uses
`ParsedBigInt`, the same serialization facility used by the upstream C
backend, and copies its bytes into an immutable module-global byte pool.
The bridge receives both the address and exact byte count and constructs
the managed BigInt. Empty zero encodings have a harmless storage byte while
retaining their true logical count. [1] [15]

Arithmetic continues through the existing dynamic-value helpers. They
perform numeric conversion, choose Number or BigInt operations, and raise
the appropriate errors. Exponentiation is already lowered to a builtin in
the shared pipeline. The fixtures exercise alternate radices, integers
beyond 64 bits, signed division and remainder, shifts, exponentiation and
mixed-type errors. Merely demonstrating `1n + 2n` would not establish that
the literal representation or conversion rules are correct.

A RegExp literal similarly must not be implemented by calling the mutable
global `RegExp` binding. The new `CreateRegExpInst` case interns pattern and
flag strings in the compilation unit and calls the runtime literal helper.
Each execution creates a fresh RegExp object. The fixture checks captures,
global and sticky state, Unicode, replacement callbacks and independence
from a user-replaced global constructor. [1] [15]

Private fields require an unforgeable private-name identity and brand
checks. They are not ordinary properties whose names happen to begin with
a hash sign. The emitter now handles private-name creation, own-field add,
load and store, and the private-in operator. Shared lowering expands the
private-brand check before emission. Private methods and accessors use
these mechanisms through the existing frontend transformations.

The first bridge deliberately uses the runtime's supported uncached private
access path. This avoids guessing cache layout or lifetime. It also avoids
sharing an entry between two incompatible meanings: the field-access helper
uses the cache's slot field as an offset, whereas private membership can
use it as a boolean. A later optimization can add separate registered
caches after preserving those contracts. [15] [5]

The private-field fixture includes same-spelling names from different
classes, inheritance, static state, accessors, methods, failed receivers,
duplicate branding and stamping a non-extensible object. The combined GC
fixture retains a class instance containing a private BigInt, RegExp and
BigInt typed array through escaping native closures and an explicit
collection.

## Typed arrays reuse calls but require exotic property semantics

Ordinary `Uint8Array`, `Float64Array`, `BigInt64Array`, `ArrayBuffer` and
`DataView` expressions already lower to constructor, property and call
operations. They do not require a separate LLVM vector representation.
The backing store and view semantics belong to the managed runtime. This
is distinct from Hermes's internal specialized typed-object and fast-array
IR operations, which are not automatically covered by support for
JavaScript typed-array objects.

Validation covers shared buffers, view offsets, byte order, overlapping
copies, integer wrapping, clamping, floating values, callbacks, subarrays,
BigInt conversions and bounds errors. This revealed a shared-runtime
problem: writing `array[-1]` could create an ordinary property in Hermes.
The runtime's typed-array object path now classifies canonical numeric
index strings before ordinary property fallback. [19]

| Key | Classification | Consequence for a short typed array |
|---|---|---|
| Numeric `-0` | Converted property key is `"0"` | Addresses element zero |
| String `"-0"` | Canonical numeric index, invalid integer index | Does not become an ordinary property |
| `"-1"`, `"1.5"`, `"NaN"` | Canonical numeric indexes, invalid elements | Follow typed-array index rules |
| `"01"`, `"1.0"` | Not canonical Number spellings | Can be ordinary named properties |
| A valid in-range integer spelling | Canonical valid element index | Reads or writes the view's element |

The classification uses a fixed-size parsing buffer and the runtime's
Number-to-string round trip. It handles the special spellings for negative
zero, NaN and infinities. BigInt keys are converted through their exact
decimal strings, avoiding an incorrect preliminary rounding to Number.
The operation's stable specification name is
`CanonicalNumericIndexString`. [19] [21]

Even an invalid write can have observable conversion effects. Assigning an
object as a value may call its conversion method before the index is
discarded. The fix therefore uses the existing typed-array element setter,
with an out-of-range sentinel where appropriate, rather than returning early
and skipping conversion. Definitions and operations with a distinct
receiver have their own rules. The boundary fixture and separate
spec-directed receiver probe distinguish those cases.

The separate receiver probe records an observed difference between the
installed Node version and the current specification for an invalid index
with a distinct receiver. That difference is not hidden by changing the
Node oracle. The ordinary differential fixture uses a primitive right-hand
side for that case; the additional probe states its specification-derived
expected result and reports each engine's actual output. The applicable
distinct-receiver rule comes from the typed array's `[[Set]]` algorithm,
in addition to numeric-key classification. [19] [25]

The reverse direction matters too. An ordinary target with a typed-array
receiver must invoke the receiver's exotic definition operation. An invalid
canonical numeric key returns false without converting the value. The
runtime now routes that case through the typed-array definition path rather
than adding an ordinary property. The regression fixture checks both the
result and the absence of conversion side effects. [19] [25]

## Dynamic evaluation shares native environment cells

The existing runtime already implements indirect eval and the `Function`
constructor with its source compiler. The missing direct-backend mechanism
was lexical direct eval: evaluated code must be able to resolve and mutate
the caller's local bindings, including bindings that no static expression
otherwise uses. Passing only the source string to the old Static Hermes
helper would instead evaluate without the caller's lexical environment.

The extension adds explicit metadata and operands to `DirectEvalInst`.
Besides source and strictness, it carries the current physical scope,
environment, receiver, new target, captured arguments where applicable, and
the variables visible at that source location. The distinction between a
physical environment and a lexical scope is essential. Hermes can merge
several source blocks into one physical scope, so enumerating all physical
slots would expose out-of-scope names or select the wrong shadowed binding.
IR generation first determines the nearest visible declaration for each
identifier. The emitter then groups those bindings by their physical
environment. [22]

| Descriptor field | Purpose |
|---|---|
| UTF-8 identifier name | Resolves an identifier in the evaluated string |
| Native environment slot | Connects the resolved name to its actual mutable cell |
| TDZ and constness flags | Retains binding access and mutation rules |
| Scope order and slot count | Preserves physical environment depth and validates slot references |
| Rooted receiver and new target | Supplies caller invocation context to executed code |

The runtime compiler expects retained compiler scope metadata from a
bytecode parent. An AOT LLVM function has no such parent. The bridge builds
a small, non-executed synthetic parent from the descriptors, retains its
semantic and IR data, and maps its variables to the existing native
environment slots. It then invokes `compileEvalModule` and runs the resulting
bytecode with the caller's actual environment. The synthetic parent's code
is never executed after this remapping.

This design preserves cell identity. If evaluated code returns a closure
that changes a variable, a native closure reading that variable sees the
change. If the native function changes the variable later, the evaluated
closure sees the new value. Copying values into a temporary object and
copying them back after eval would fail for escaping closures and would
require special treatment of exceptions; the shared environment avoids
those problems. The resulting bytecode provider retains the compiler module.
The synthetic parent's `FunctionIR` ownership is transferred to that module
before the temporary parent provider is destroyed. Retaining only a shared
module pointer is insufficient: the temporary `BytecodeFunction` destructor
would otherwise delete its associated IR function. The explicit transfer
keeps the lexical metadata available for escaping closures and nested eval.
[22]

The optimizer also needs to know about this visibility. A binding used only
by eval cannot be deleted as unused. A binding assigned in evaluated code
cannot retain a stale native stack copy or a previously inferred constant.
The changes conservatively mark captured eval bindings as unknown reads and
writes, prevent their constant/stack promotion, and invalidate the relevant
frame-value knowledge. Scope hoisting must also retain the physical ancestors
of every eval-visible binding. The dependency is carried by the variables,
so a pass that examines only runtime scope values can miss it. Optimization
remains enabled for unrelated values.

Unknown JavaScript values and uninitialized bindings are different concepts.
Type inference therefore keeps the internal Empty/Uninit states while widening
an eval-visible binding to any ordinary value. Dropping Empty would erase a
required TDZ check in an optimized closure. Runtime compilation also restores
the caller's captured `arguments` binding and lexical scope when compiling a
nested eval; a synthetic parent must not initialize a replacement arguments
object over the shared native slot.

Nested direct eval needs the same environment identity after execution has
entered dynamically compiled bytecode. The interpreter now obtains the
current lexical scope from retained `DebugScopingInfo`, selects its register
or spilled environment, and calls `evalInEnvironment`. Dynamic compilation
retains semantic, IR and scope metadata even when the debugger is disabled.
It is eager and unoptimized in this implementation; rebuilding the synthetic
parent on each call is a clear performance tradeoff, not a cached JIT design.
[22]

Global invocation context is preserved through the synthetic metadata chain.
All artificial parents for a script caller are marked as program scopes, so
another nested eval cannot mistake them for real functions and accept global
`new.target`. Actual native constructors and functions introduced by evaluated
source still supply their own function context. This is an example of a
compiler implementation detail that must remain invisible to the language.

The helper is compiled into the full Hermes VM because the compiler and VM
implementation symbols are intentionally hidden from ordinary shared
library clients. It exposes one rooted-slot bridge entry point. Any C++
strings, compiler owners and RAII guards are destroyed before the bridge
uses Static Hermes's non-local exception transfer; jumping over live C++
destructors would otherwise invalidate cleanup assumptions. [22]

Dynamic source strings in this implementation compile to **Hermes
bytecode**. The statically known program and its native callbacks still
compile directly to LLVM IR. Runtime LLVM compilation of arbitrary strings
is not implemented. The full runtime compiler must therefore remain
available when using eval or Function.

## Validation and explicit language boundaries

The extension harness records Node script execution, the C backend where it
is a valid semantic oracle, four native LLVM combinations, and real `lli`
execution. It uses Hermes frontend `O0` and `O` and LLVM `O0` and `O2`
independently. For lexical eval, the old C helper's lack of local environment
support is recorded as an oracle limitation; it is not accepted as a passing
comparison. Runtime errors, compiler rejections and boundary probes are
recorded separately from successful source programs.

The final counts and file hashes appear in the validation chapter and
`docs/llvm/feature-work/` evidence. The first 24-case run is retained as
diagnostic history: it exposed four shared-runtime failures and is not the
release gate. Source fingerprints detect edits during a purported frozen
test run. The report must be regenerated only after the identified final
gate, rather than inferring success from an earlier partial run.

This remains a targeted host implementation. Direct string eval requires a
strict caller. A strict directive only inside the supplied string does not
currently bypass that restriction. General sloppy direct eval requires
dynamic introduction and lookup of caller `var` bindings; the bridge rejects
that case explicitly. Non-string arguments still pass through unchanged in
either caller mode. Class-private names and `super`
inside evaluated strings require additional class-context metadata.
Derived-constructor direct eval needs correct handling of the uninitialized
receiver before `super()` and is rejected by the LLVM emitter. Other
boundaries established by the final fixtures are stated with the evidence.
No complete ECMAScript or Test262 result, physical PicoCalc runtime port,
or compilation/performance speedup is claimed.

## Laboratory exercises

1. Compile `generator_finally.js` at both frontend optimization levels.
   Locate the generated resumption functions and the stores that precede
   their iterator-result returns. Explain which state must live on the heap.
2. Add a side effect to an iterator's `return` method. Predict the output
   for normal loop exhaustion, break, throw and one-element destructuring,
   then compare the prediction with native and JIT runs.
3. Write two Promise reactions whose order would change if a thenable were
   invoked synchronously. Explain which queued job accounts for each line.
4. Compare typed-array keys `"0"`, `"-0"`, `"00"` and numeric `-0`.
   Inspect own-property descriptors and explain why a dictionary model alone
   is insufficient.
5. Write a strict function that returns one native closure and one
   eval-created closure sharing a variable. Mutate through each closure,
   collect, and verify the other closure's observation.
6. Remove the eval-visible variable's protection from stack promotion in a
   disposable checkout. Construct a program that reveals the resulting stale
   native value. Restore the protection and explain the aliasing invariant.

## Extension references and source-reading guide

14. [Generator state-machine lowering][14], `lib/Optimizer/Scalar/LowerGeneratorFunction.cpp`. Follow scope creation, resumption,
    exception dispatch and crossing-value promotion.
15. [Value bridge implementation][15], `lib/BCGen/SH/LLVMNative/value_extensions.c`. Compare literal bytes, private-name
    operations and the documented cache choice with the public SH helpers.
16. [Async-function driver][16], `lib/InternalJavaScript/02-AsyncFn.js`. Trace one fulfilled and one rejected await
    through the generator resumption functions.
17. [Patched Promise implementation][17], `lib/InternalJavaScript/01-Promise.js`. Read the changes with the recorded
    ordering, species and thenable regression fixtures.
18. [Patched async-generator driver][18], `lib/InternalJavaScript/04-AsyncIterator.js`. Follow internal-await continuation
    separately from the queue's external return request.
19. [Typed-array property integration][19], `lib/VM/JSObject.cpp`. Read the canonical numeric-index
    helpers and the guarded paths in property access/definition.
20. [ECMAScript generator objects][20]. Normative protocol reference.
21. [ECMAScript canonical numeric index strings][21]. Stable operation anchor;
    section numbering can change in the living draft.
22. [Native lexical-eval runtime bridge][22], `lib/BCGen/SH/LLVMNative/eval_extensions.cpp`. Read together with the new IR
    operands, optimizer guards and eval fixtures.
23. [ECMAScript PerformEval][23]. Distinguishes direct/indirect evaluation and
    caller context.
24. [Extension test harness][24], `utils/test_shllvm_extensions.py`. Defines actual oracles, completion checks,
    optimization combinations, errors, fingerprints and result records.
25. [ECMAScript typed-array Set][25]. Distinguishes an element write from
    an operation with a different receiver.
26. [Async-generator frontend transformation][26], `lib/AST/AsyncGenerator.cpp`. Follow return expressions
    and nested function contexts before generator state-machine lowering.
27. [ECMAScript async-generator return resumption][27]. Normative reference
    for awaiting an external return argument.

[1]: ../../lib/BCGen/SH/LLVMNative/LLVMBackend.cpp
[2]: ../../lib/BCGen/SH/LLVMNative/runtime.c
[5]: https://github.com/facebook/hermes/blob/f837b9dd8396ebf5c4e8115412417d273565f0fe/include/hermes/VM/static_h.h
[14]: ../../lib/Optimizer/Scalar/LowerGeneratorFunction.cpp
[15]: ../../lib/BCGen/SH/LLVMNative/value_extensions.c
[16]: ../../lib/InternalJavaScript/02-AsyncFn.js
[17]: ../../lib/InternalJavaScript/01-Promise.js
[18]: ../../lib/InternalJavaScript/04-AsyncIterator.js
[19]: ../../lib/VM/JSObject.cpp
[20]: https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-generator-objects
[21]: https://tc39.es/ecma262/multipage/abstract-operations.html#sec-canonicalnumericindexstring
[22]: ../../lib/BCGen/SH/LLVMNative/eval_extensions.cpp
[23]: https://tc39.es/ecma262/multipage/global-object.html#sec-performeval
[24]: ../../utils/test_shllvm_extensions.py
[25]: https://tc39.es/ecma262/2026/multipage/ordinary-and-exotic-objects-behaviours.html#sec-typedarray-exotic-objects-set-p-v-receiver
[26]: ../../lib/AST/AsyncGenerator.cpp
[27]: https://tc39.es/ecma262/2026/multipage/control-abstraction-objects.html#sec-asyncgeneratorunwrapyieldresumption
