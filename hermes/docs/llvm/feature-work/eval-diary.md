# Dynamic evaluation implementation diary

## 2026-10-28 — Baseline investigation

The direct LLVM backend initially rejected `DirectEvalInst`. Indirect eval and
the `Function` constructor already have VM builtins, so their missing work is
end-to-end validation and keeping the runtime compiler enabled. The upstream C
backend's `_sh_ljs_direct_eval` calls `vm::directEval` with a null environment.
Consequently its results are not a valid oracle for lexical direct eval.

Read the IR builder, semantic resolver, SH instruction selector, native VM
environment helpers, `evalInEnvironment`, `compileEvalModule`, and the GC-safe
coding skill before selecting the implementation. Native SH environments are
real Hermes `Environment` objects, which can be captured by bytecode closures.
This is the key interoperability point.

## Design decision — strict lexical eval uses the existing runtime compiler

The runtime compiler's local-eval entry point requires retained IR and semantic
scope data. A generated LLVM unit has no bytecode parent to supply that data.
The extension therefore reconstructs a small **non-executed scope parent** from
native binding descriptors. The descriptors record identifier names, lexical
rules, environment order, and actual native slot indexes. The scope parent is
compiled with metadata retained; its variables are then mapped to the native
slot indexes. `compileEvalModule` resolves the requested string in these scopes.
`Runtime::runBytecode` receives the actual native environment and the caller's
`this` and `new.target` values. Evaluated closures therefore share the original
bindings instead of capturing a copied snapshot.

Dynamic strings compile to Hermes bytecode and execute in the existing VM. The
surrounding statically known program still compiles directly to LLVM IR. This
distinction must be explicit in the architecture report.

Sloppy direct string eval can introduce new `var` bindings into its caller.
The upstream native frontend has no dynamic lookup machinery for this operation.
The bridge will reject that case with a `SyntaxError` until that machinery exists.
Non-string eval arguments still return unchanged, as JavaScript requires.

## Optimization and GC constraints

Direct eval must retain visible variables even when no static expression reads
them. It may also assign a different value or type to a local variable. Explicit
IR operands and conservative optimizer handling keep these variables in shared
environments and invalidate cached frame values across calls. Environment and
argument operands are rooted by the generated LLVM frame. The runtime extension
must finish C++ RAII cleanup before invoking SH's non-local exception transfer.

## Validation record

Implementation and differential validation are in progress. This section will
be updated with commands, observed failures, corrections, and final results;
no unrun test is claimed as passing.

## 2026-10-28 — First implementation completed

Added `eval_extensions.h/.cpp`. The bridge is compiled inside the full VM, where
the intentionally hidden compiler and VM symbols can be called. Only its C
entry point is exported to generated LLVM modules. The compiler scaffold uses
one anonymous function per physical environment, including environments with
zero visible bindings. It never invents a JavaScript-visible marker variable.

An important correction came from reading IRGen: ordinary source blocks can
share one `VariableScope`. Listing all variables in that scope would expose
names outside their lexical block and select the wrong shadowed declaration.
The new `DirectEvalInst` records the nearest semantic declaration for each
visible name at the original source location. Descriptor generation groups
those selected bindings by their actual physical environment. Implicit
`arguments` is eagerly captured when eval is present, and its hidden native
slot is given the one intentional source-level alias `arguments`.

Added conservative handling in store-once analysis, stack promotion, frame
load/store optimization, and function analysis. An eval-visible binding cannot
be treated as a constant or cached forever in a native stack slot. Existing
memory type inference already treats an unknown user as an arbitrary value,
so it did not need a new special case.

Two semantic traps were addressed before the first native build. First, using
`const` declarations in the scaffold would make the existing semantic checker
reject writes during compilation; JavaScript instead requires a catchable
runtime `TypeError`. The scaffold now uses `let` and restores the native
Variable's constness before eval compilation. Eval compilation also enables
the existing deferred-check mode for constants declared inside the evaluated
source. Second, a function scaffold could accidentally make `new.target` legal
in global eval. Global eval text receives a separate non-executed global-syntax
validation before the lexical compile.

Added six positive differential fixtures and one explicit feature-boundary
fixture. All seven scripts ran successfully in Node with `--expose-gc`. The
positive expectations include shared writes in both directions, changes of
value type, block shadowing, out-of-scope names, const errors, TDZ errors,
ordinary/arrow `this` and `arguments`, constructor `new.target`, thrown values,
and escaped dynamic closures after garbage collection. The sloppy-boundary
script is valid JavaScript in Node and is deliberately labeled as a native
feature restriction, not a language-conformance error.

Remaining explicit boundaries under review: constructor eval before `super`,
class home-object/private-name metadata, and direct eval invoked from dynamic
bytecode (whose inherited opcode still lacks lexical integration). They must
receive diagnostics or a real metadata path before support is claimed.

## 2026-10-28 — Emission probes and ownership review

Ran every eval fixture through the newly built compiler at frontend `-O0` and
`-O`, followed by LLVM 18 `llvm-as` for successful modules. The unoptimized
positive fixtures assembled. The intended derived-constructor diagnostic
appeared at both optimization settings. Several optimized fixtures correctly
failed the emitter's environment-chain check; this exposed an additional
optimizer assumption in `ScopeHoisting`. That pass knew about explicit
`ResolveScopeInst` uses but not about environments reached by an evaluated
string. An optimized closure could therefore lose its lexical parent's
environment even while `DirectEvalInst` still retained its variables. The
queued fix adds captured-binding parent scopes to the existing dependency
analysis, preserving optimization for unrelated scopes.

A lifetime review found another subtlety beyond ordinary shared ownership:
`BytecodeFunction::~BytecodeFunction` destroys its associated IR Function.
Destroying the non-executed synthetic provider would therefore destroy the
Module's remembered top-level Function while the eval provider still shared
the Module. The planned ownership transfer clears the synthetic bytecode
functions' `functionIR` pointers only after successful eval compilation.
The shared Module's owning compiled-functions list then releases those
metadata-only functions at Module destruction. The error path keeps its
ordinary cleanup. A second reviewer independently checked that ownership
relationship in the source.

Prepared separate nested-eval tests, including a returned bytecode closure that
performs another eval after the original native caller has returned and after
GC, and a strict `Function`-created function whose eval captures locals. Both
fixtures match their expected output in Node. They are awaiting the interpreter
metadata integration and native validation.

## 2026-10-28 — First native results and nested-eval integration

The coordinated build compiled the new IR, bridge, and emitter successfully.
Its shared-library link first exposed a CMake integration issue: the new source
was added directly to the full VM static archive without PIC. The build owner
enabled PIC on that target and relinked successfully. This was a build-system
problem, not a language semantic failure.

The first unoptimized native probes match Node for
`eval_closure_gc.js`, `eval_global.js`, `eval_lexical_bindings.js`,
`eval_lexical_errors.js`, `eval_this_arguments.js`, and
`function_constructor.js`. Evidence is recorded in
`eval-initial-native-probes.json`. In particular, the const/TDZ error classes,
mutation in both directions, arguments captured through an arrow, constructor
`new.target`, and closure survival after GC all match. The initial nested-eval
probe produced the predicted missing-global `ReferenceError`, confirming that
the inherited interpreter opcode also needed lexical integration. Boundary
fixtures rejected as designed; the initial simple probe script labeled them
as failures because it had no boundary-metadata logic. Those records remain
unaltered and must not be cited as positive semantic passes.

Implemented the additional scope-hoisting dependency and ownership transfer
described above. Native descriptor sizes and member offsets now have compile
time assertions matching the LLVM host64 ABI. Global/derived-constructor
context is stored at the original eval site and copied during IR cloning,
rather than inferred from the function that happens to own the instruction
after optimization. This preserves top-level-arrow rules and remains correct
if a function is inlined. Scaffolding declarations now use `var`; actual TDZ and
const rules still come from the original Variable metadata. This also allows
an inherited non-strict identifier such as `let` to be represented without
introducing a synthetic-source syntax error.

The interpreter's direct-eval slow path now reads `DebugScopingInfo` at the
current bytecode instruction, obtains its environment from the recorded frame
register or spilled environment slot, roots it with `Locals`/`PinnedValue`, and
calls `evalInEnvironment` with the caller's `this` and `new.target`. Missing
metadata receives an explicit error; it never silently substitutes the global
environment. Runtime source compilation now retains scope metadata even in a
build with `HERMES_ENABLE_DEBUGGER=OFF`, and enables TDZ/deferred const checks.
Lazy compilation and the full runtime optimization pipeline are disabled on
this path until they have an equivalent metadata-preservation contract. This
is a deliberate memory/compilation-speed tradeoff for correct local eval.

The new build and the full optimized/native/JIT differential gate remain
pending at this entry.

## 2026-10-28 — Complete focused matrix, first iteration

The interpreter change initially failed to compile because
`PinnedValue<Environment>` requires a typed object value, not assignment of a
generic `PinnedHermesValue`/`GCHermesValue`. Corrected both extractions with
`vmcast<Environment>` followed immediately by assignment to the existing local
root, matching the debugger's established representation. There is no
allocating call between extracting the raw pointer and rooting it.

Ran the complete focused eval/Function matrix against build 8: both Hermes
frontend levels, both LLVM levels, all native executions, and real `lli`, with
Node and required C oracles. Input fingerprints remained unchanged. The result
was **12 of 14 case contracts passed**, including all five explicit boundaries.
The failed evidence is retained in `eval-build8-validation.json`, not overwritten
with a success summary.

Two failures were informative. First, nested eval immediately inside an
eval-program body reported missing scope metadata. Comparing `doItInScope` with
ordinary program/function generation revealed that it did not establish the
current lexical scope. Its bytecode locations therefore had no usable scope
index. Second, a `Function`-created function's direct eval shared ordinary
locals correctly, but its caller-arguments expression produced `NaN`. The
saved `EvalCompilationData` deliberately contained a null arguments operand,
and eval IRGen never restored a caller arguments capture. Both paths now retain
and restore that metadata. Eval through an arrow also preserves its inherited
capture state instead of constructing a new ES5 argument/this context.

Three additional focused probes are recorded in
`eval-build8-extra-probes.json`. A transient `Function` parent whose returned
eval closure performs another eval after GC passed at both frontend settings;
no speculative generic-provider ownership change was made. Nested global
context testing was blocked by the missing lexical-scope metadata and will be
repeated after that correction. The third probe demonstrated a real optimizer
bug: a closure reading a never-initialized `let` threw `ReferenceError` at O0,
but returned an invalid value printed as `NaN` at O. Type inference's early
`Any` return for an eval user discarded the `Empty` possibility from the
binding's initialization stores. The correction unions arbitrary JavaScript
values while continuing to scan those stores. Synthetic variable types now
also include `Empty` whenever the original binding obeys TDZ.

Added permanent regressions for the TDZ optimization failure, the passing
transient-parent lifetime case, and an escaped arrow from a `Function` body
performing nested eval of its inherited `this` and `arguments` after GC.
These corrections await the next coordinated build.

## 2026-10-28 — Nested global context retained through eval

Build 9's concrete native probes now match Node at both frontend optimization
levels for nested lexical eval, `Function` caller arguments and escaped arrows,
and the never-initialized captured `let` regression. The evidence is preserved
in `eval-build9-concrete-probes.json`. One remaining probe exposed a distinct
semantic-context bug: `eval("eval('new.target')")` in a strict script was
incorrectly accepted, even though the first-level global syntax check correctly
rejected a direct `new.target` expression. Nested global `arguments` remained
undefined, and the real constructor control already passed.

The scaffold's anonymous functions are only metadata containers; none runs.
Their retained `FunctionInfo` records nevertheless looked like real function
contexts to `SemContext::nearestNonArrow` during a second eval compilation.
The bridge now marks every synthetic parent as a program node when the original
caller has global context. The existing semantic walk then skips those levels
and reaches the actual global function. Ordinary and constructor callers keep
their function context. Functions introduced inside the evaluated string also
keep their own normal metadata.

Added `eval_nested_global.js` with direct and arrow-origin nested global
rejections, a nested global-arguments check, and both native and dynamically
created constructor controls. This change is confined to compile-time metadata;
it introduces no new GC roots, allocations, or runtime ownership changes. The
fixture's Node oracle passed, printing both expected `SyntaxError` results,
undefined global `arguments`, and true for both constructor controls. Native
validation is pending the next coordinated build at this entry.

## 2026-10-28 — Final frozen validation

The completed `extension-final-validation.json` records **53 of 53 extension
contracts passed**, with no skipped cases, no partial selection, and unchanged
source/binary fingerprints. The eval/Function portion contains **12 positive
programs, three runtime boundary rejections, and two compiler boundary
rejections**. Each positive program matched Node under all four native
combinations of Hermes O0/O and LLVM O0/O2, and under the real `lli` JIT at
Hermes O / LLVM O2: **48 native comparisons and 12 JIT comparisons**. This
includes nested global `new.target` rejection and both real-constructor
controls, shared lexical mutation, captured TDZ errors, and escaped eval
closures after GC.

The three runtime boundaries (sloppy caller, enclosing class private names,
and method `super`) produced the declared rejection in **12 native runs and
three JIT runs**. Direct eval in derived constructors and their arrow contexts
passed the separate compiler-rejection and output-publication contracts at
both frontend optimization levels. These are explicit support boundaries,
not successful comparisons with Node's behavior for those valid programs.

Five positive programs also matched the existing C backend at both frontend
levels. Seven positive lexical/context fixtures and the three runtime
boundary fixtures exclude that C oracle for documented reasons: its native
direct-eval entry does not supply the required caller environment or context.
Those exclusions do not skip LLVM execution or the applicable Node oracle.
The C and LLVM paths share the patched runtime and frontend, so their
agreement is a useful second code-generation check, not an independent
language implementation. This targeted host matrix does not establish full
ECMAScript conformance or a device execution result.
