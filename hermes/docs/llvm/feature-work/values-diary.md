# Value features engineering diary

Date: 28 October 2026. Observable actions, design decisions and results are
recorded here; this is not a private reasoning transcript.

## Runtime contracts inspected

Read the repository's GitHub development guidance and GC-safe coding skill.
Inspected the original C emitter's BigInt serialization, RegExp creation,
private-name creation and private-field operations. Inspected the actual
StaticH runtime implementations to establish null-cache behavior and root
requirements.

The existing root-slot ABI can expose all of these operations without creating
a second value representation. Added `value_extensions.c` and
`value_extensions.h`; the wrappers accept caller-owned rooted values and write
the result directly back to a rooted slot. RegExp pattern/flag symbols remain
rooted by the registered compilation unit. BigInt literal bytes have native
unit lifetime and do not contain heap pointers.

## BigInt representation

The implementation plan uses the same ParsedBigInt byte representation as the
upstream C emitter. The LLVM emitter must intern these exact bytes separately
from strings, add LiteralBigInt to the rooted-constant set, and call the bridge
to create the managed BigInt. Converting a literal through double would lose
precision. Calling the global BigInt constructor would introduce observable
dependence on a user-replaced global.

Existing runtime arithmetic helpers cover BigInt arithmetic and errors;
exponentiation is already lowered through a builtin by the shared pipeline.
Tests include values larger than 64 bits, alternate radices, signed
division/remainder, shifts, exponentiation and mixed-type errors.

## Private access and caches

The SH private-field helper APIs explicitly permit a null inline cache. The
first lowering therefore uses that correct path and requires no new unit
cache allocation or weak-cache rooting. This also avoids an important trap:
private-membership caches store a boolean in their slot field, while field
access caches store an actual field offset. Those two operation kinds must
never share one cache entry.

Private names are preserved as the runtime's private-name values, not public
strings. Shared lowering already expands PrivateBrandCheckInst. Fixtures
exercise private fields, methods, accessors, static storage, inherited access,
independent same-spelling brands, failed receiver checks, duplicate stamping
and non-extensible object stamping.

## Typed arrays and RegExp

Ordinary typed-array construction and methods already use the existing generic
constructor/property/call path. New fixtures exercise real buffer and view
semantics, overlapping set, clamping, numeric conversion and bounds. BigInt
typed arrays depend on the newly added BigInt literal path.

RegExp tests check literal identity, captures, lastIndex, sticky/global flags,
Unicode code points, dotAll/multiline behavior, replacement callbacks, named
captures, and invalid runtime RegExp construction. A replaced global RegExp
constructor must not intercept literal creation.

## Validation in progress

Created six source fixtures and began independent Node and unchanged C-backend
probes at Hermes O0/O. Results are retained in values-initial-oracles.json,
including failures and differences if present. Direct LLVM validation follows
emitter integration and rebuild by the parent task.

## Initial oracle results and corrective work

The six initial programs compiled successfully through the original C backend
at Hermes O0 and O. Five matched Node exactly: RegExp, BigInt, private fields,
BigInt typed arrays, and the combined GC stress program. The ordinary typed
array program disagreed on one observable value: after `a[-1] = 8`, Hermes
returned `8` and Node returned `undefined`. All other output in that program
matched. The complete initial JSON is retained without overwriting it.

Source inspection traced the discrepancy to the ordinary property fallback in
`JSObject::putComputedWithReceiver_RJS` and an existing typed-array TODO in
`defineOwnComputedPrimitive`. After coordinating file ownership, added a
focused fix in `lib/VM/JSObject.cpp`. A fixed stack buffer and Hermes's existing
number parser/formatter implement the canonical numeric string roundtrip;
ordinary names such as `"01"` and `"1.0"` remain ordinary properties. No object
layout or GC metadata changed. New string roots use Locals and PinnedValue.

The property operations now preserve the distinction between numeric `-0`
(property `"0"`) and string `"-0"` (invalid typed-array index). Invalid writes
still call the existing typed-array setter so ToNumber/ToBigInt conversion,
observable valueOf calls, exceptions, and detached-buffer checks remain in
the runtime's established implementation. Definitions validate the index and
attributes before attempting value conversion.

Added `features_typed_array_indices.js` for invalid numeric keys, canonical
versus noncanonical spellings, own descriptors, nonextensible arrays, same-
receiver conversion failures, GC during key/value conversion, distinct
Reflect.set receivers, and shadowed numeric prototype entries. Node completes
this differential fixture successfully. A syntax-only C++ compile using the
actual build compilation flags passes.

## Independent-reference limitation

A focused test uncovered a separate Node v24.22.1 discrepancy with the current
ECMA-262 TypedArray [[Set]] algorithm. For an invalid canonical numeric index
and a distinct Receiver, the specified operation succeeds without converting
the value. This Node build instead invokes valueOf, and throws for Symbol or
Number-to-BigInt values in that case. The VM fix follows the specification.
This difference is preserved in `typed-array-receiver-spec-probe.js` and
`typed-array-receiver-spec-probe.md`, separate from the ordinary differential
matrix. The matrix still exercises a distinct receiver using a primitive
numeric value on which both implementations agree.

The initial emitter integration note mistakenly treated BinaryPrivateInInst
as a C++ class. The integrated build identified it as an instruction tag;
the correct dispatch is a ValueKind case within BinaryOperatorInst. The
integration note has been corrected and the runtime bridge contract did not
change.

## Cross-component review

Reviewed the integrated generator, iterator, for-in, BigInt and private-field
LLVM emission against the original C emitter and the actual StaticH helper
signatures. Confirmed operand order, mutable iterator slots, branch polarity,
registered root-slot storage, native function metadata lifetime, and BigInt
pool ownership. No concrete ABI or GC blocker was found in these new paths.

Reviewed the dynamic-evaluation bridge without editing its owner's files.
Confirmed that the child bytecode provider shares the compiler Module and
retains the parent semantic context. Caller values are borrowed from existing
LLVM root slots, and C++ owners are destroyed before the SH exception longjmp.

Reported two concrete concerns to the evaluation owner and parent task: the
ordinary-function metadata scaffold does not supply class home-object or
private-name lexical context for valid method eval expressions, and the
documented EvalError for unsupported sloppy string eval initially differed
from the implementation's SyntaxError. Their final handling belongs to the
evaluation component's report and tests.

The evaluation owner then identified an ownership detail missed by the first
review: BytecodeFunction's destructor explicitly deletes its FunctionIR, even
when the containing Module is shared. Rechecked the full destruction path.
deleteBodyExceptEvalData moves retained synthetic functions, including the
global function, into Module's owning compiledFunctions list. Nulling only
the synthetic parent's BytecodeFunction FunctionIR links after successful
eval compilation transfers cleanup to that Module list and preserves the
top-level metadata pointer needed by nested eval. The evaluated provider
continues to own its own FunctionIR normally, and unsuccessful compilation
keeps the original cleanup path. This corrected review was sent to the
evaluation owner and parent task before the final build.

## 2026-10-28 — Focused execution and final receiver correction

After coordinated build 4, the original typed-array program, canonical-index
boundary program, and specification-directed receiver probe all passed
through C at Hermes O, native LLVM at Hermes O / LLVM O2, and lli at the same
settings. The two normal fixtures matched Node; the receiver probe matched
all four specification-derived lines. Complete commands, output and artifact
hashes are retained in `values-build4-probes.json`.

Read-only inspection also identified the reverse receiver case:
`Reflect.set({}, "-1", value, typedArrayReceiver)`. The target is ordinary, so
the early typed-array target check cannot enforce the receiver's exotic
definition rules. Prepared a focused patch while the shared build ran, then
applied it after completion and the checks above. It delegates canonical keys
on typed receivers to `defineOwnComputedPrimitive` before ordinary property
addition. The fixture now checks invalid and valid reverse-receiver writes
and their conversion counts.

Using the expanded fixture with the still-unmodified build 4 binary preserved
the concrete remaining failure: invalid assignment returned true instead of
false. Neither implementation converted the value, and valid-index writes
matched. The actual before-guard results are in
`typed-array-receiver-before-guard.json`. Source is now stable for the next
coordinated rebuild and final matrix. No result from the pending guard build
is claimed here.

## 2026-10-28 — Async transformation review

During the consolidated build, independently reviewed the new async-generator
return transformation and request driver without editing their owner's
files. Found that the new arrow-function visitor isolated its body correctly
but skipped default parameter expressions, unlike the prior generic visitor.
A nested async generator in an arrow default would therefore escape this
transformation. Reported the narrow correction—traverse the arrow's children
while the enclosing-generator flag is false—to the async owner and parent.
The owner confirmed the issue and will add the corresponding regression at
the next coordinated source-edit checkpoint.

## 2026-10-28 — Final value-component verification and freeze

After coordinated build 8 completed and the parent verified that Ninja had
no remaining work, reran the expanded canonical-index/receiver fixture and
the normative distinct-receiver probe through all three routes: the C
emitter with the shared updated runtime, direct native LLVM, and lli.
All six Hermes executions exited successfully and matched their expected
output. The reverse receiver regression now returns false without conversion
for the invalid key and converts once for the valid element.

The normal fixture matches Node v24.22.1. The normative probe continues to
match the specification's four lines on all three Hermes routes while
preserving the known Node difference as an explicit nonmatching reference
record. This is an oracle limitation, not a suppressed assertion.

`values-final-probes.json` records commands, full outputs, exit statuses,
timings and SHA-256 hashes of the checked source files, compiler and bridge/
VM binaries before and after execution. The hashes were unchanged throughout
the run. Source and regression fixtures for this component are now frozen;
the parent task owns the full combined optimization matrix and release
packaging.

## Final frozen extension gate

The complete extension-final-validation.json records 7 of 7 passing
rich-value fixtures, with 28 native LLVM output comparisons, 7 real lli
comparisons and 14 matching C executions. All are positive language cases.
The complete 53-case gate used unchanged source and binary inputs and no
selection, quick mode or JIT skip. The separate typed-array distinct-receiver
specification probe and its recorded Node-version discrepancy remain separate
from these differential fixture results. Earlier failures are retained.
