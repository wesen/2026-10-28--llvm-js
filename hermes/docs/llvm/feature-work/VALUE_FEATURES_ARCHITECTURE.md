# Values and object features in the direct LLVM backend

This chapter explains the RegExp, BigInt, private-field and typed-array
extensions. The implementation sources are the
[LLVM emitter](../../../lib/BCGen/SH/LLVMNative/LLVMBackend.cpp),
[value bridge](../../../lib/BCGen/SH/LLVMNative/value_extensions.c), and
[shared property implementation](../../../lib/VM/JSObject.cpp).

## 1. Separating compiled control flow from language operations

LLVM understands integers, pointers, memory and control-flow graphs. A
JavaScript value has a richer meaning: addition can add two Numbers, add two
BigInts, concatenate strings, or call an object's conversion method before
doing any of these. The backend therefore emits LLVM instructions for the
program's control flow and calls existing Hermes runtime operations for
JavaScript semantics.

Every live JavaScript value occupies an eight-byte registered root slot. The
emitter passes the address of that slot to bridge functions. If a runtime
operation allocates and garbage collection moves an object, the collector can
update the registered slot. The next operation reads its current contents.
An unregistered LLVM temporary containing a heap pointer could become stale
across such a call.

The bridge's public signatures use pointers and fixed-width integers. Native
Hermes data structures remain on the runtime side. This keeps LLVM's emitted
module independent of C bitfield layouts and most VM structure offsets; the
current callback ABI still deliberately targets the supported host64
configuration. See the contract in
[runtime.h](../../../lib/BCGen/SH/LLVMNative/runtime.h).

| Source-language operation | Compiler work | Runtime work |
|---|---|---|
| RegExp literal | Intern pattern and flag strings; emit a creation call | Parse/create the RegExp object |
| BigInt literal | Serialize its exact bytes into an immutable native pool | Allocate the managed BigInt |
| BigInt arithmetic | Select the existing dynamic operator helper | Apply BigInt arithmetic and coercion rules |
| Private field | Preserve its private-name value and object operand | Check the brand and access private storage |
| Typed-array operation | Reuse construction, calls and property access | Apply view, buffer, conversion and index rules |

## 2. RegExp literals require fresh mutable objects

A RegExp pattern looks like a constant, but a RegExp object can have mutable
state. For a global expression, successful matching advances `lastIndex`.
Repeated evaluation of the same source literal must therefore create fresh
objects.

The emitter stores the literal's pattern and flags in the compilation unit's
string table. At each execution of `CreateRegExpInst`, the bridge calls
`_sh_ljs_create_regexp` using the unit's registered symbols. This construction
does not consult a user replacement of the global `RegExp` function. The
fixture checks both independent literal instances and a replaced global
constructor, as well as captures, Unicode matching, sticky/global state,
replacement callbacks and invalid runtime patterns.

## 3. BigInt constants must never pass through floating point

A JavaScript Number cannot represent every large integer exactly. Converting
a BigInt literal to a double and then reconstructing it would therefore lose
information before the program began.

The LLVM emitter uses the same `ParsedBigInt` representation as the original
C emitter. It copies the serialized bytes into a deduplicated native constant
pool and passes the original byte count to `shllvm_bigint`. The bridge calls
the VM's BigInt allocator. A zero-length representation can use a padded
one-byte LLVM global while still passing a zero byte count; storage padding
does not change the value.

The byte pool contains ordinary immutable bytes, not GC pointers. The
allocated BigInt is a managed value and goes directly into a root slot. These
two lifetimes must not be confused.

Arithmetic reuses Hermes's dynamic helpers. This matters for negative integer
division and remainder, arbitrary-size shifts, Number/BigInt mixing errors,
division by zero and unsupported unsigned shifts. Exponentiation is already
expanded by the shared SH lowering pipeline. The tests check these operations
with large exact values instead of relying only on small literals.

## 4. A private name is an identity, not a public string key

Two classes may each declare `#value` without sharing access to one another's
storage. The source spelling provides a description; the runtime's private
name provides the distinct identity.

The emitter creates the private-name value and passes it to the existing
private add, get, set and membership helpers. These helpers enforce receiver
brand checks and keep private fields out of public property enumeration.
Methods, accessors and lexical arrow captures are lowered by the existing
frontend into functions and these primitive operations.

The first implementation uses the helpers' supported null-cache path. This
requires no new compilation-unit cache allocation. If caching is added later,
membership and field-access cache entries must stay separate: the former
stores a boolean in its slot field, while the latter stores a field offset.
Sharing one entry between these purposes would be incorrect.

The private-field fixture checks inherited access, independent brands,
private methods and accessors, static storage, bad receivers, duplicate
installation, and stamping a private field onto a nonextensible object.

## 5. Typed arrays use different property rules from ordinary objects

Typed arrays were already reachable through generic constructor, call and
property lowering. The new tests validate shared buffers, DataView byte
order, overlapping copies, clamping, integer wrapping, floating-point values,
bounds and BigInt views.

Those tests also found an existing VM defect: assigning `array[-1] = 8`
created a named property. A typed array must classify canonical numeric keys
before taking the ordinary-property path.

The correction recognizes a key by converting its candidate number back to
the same string. Thus `"1"` is numeric, whereas `"01"` and `"1.0"` remain
ordinary names. Numeric `-0` first becomes the property key `"0"`; the literal
string `"-0"` remains an invalid numeric index. NaN, infinities, fractional
values and out-of-range integers are also invalid element indices.

Assignment and definition have different conversion order. An assignment to
an invalid index still performs the typed array's Number or BigInt value
conversion when the receiver is the array itself. An invalid
`Object.defineProperty` operation fails before converting its supplied value.
The correction delegates conversion to the established typed-array setter
and validates definitions separately. The normative algorithms are
[CanonicalNumericIndexString](https://tc39.es/ecma262/2026/multipage/abstract-operations.html#sec-canonicalnumericindexstring)
and the
[TypedArray exotic methods](https://tc39.es/ecma262/2026/multipage/ordinary-and-exotic-objects-behaviours.html).

## 6. What the evidence establishes

The initial C-backend comparison at Hermes O0 and O matched Node for RegExp,
BigInt, private fields, BigInt typed arrays and combined GC stress. It exposed
the negative-index defect in the ordinary typed-array fixture. After the
shared-runtime correction and complete coordinated build 8, the expanded
canonical-index/receiver fixture and directed receiver probe passed C,
native LLVM and lli. `values-final-probes.json` records the six Hermes
executions and unchanged source/binary fingerprints. The parent report
records the full combined optimization matrix.

Independent implementations are useful references, but they are not the
specification. A directed distinct-receiver test exposed a Node v24.22.1
value-conversion difference; its precise expected behavior and actual Node
output are preserved in the
[specification-directed probe](typed-array-receiver-spec-probe.md).

These changes validate the stated feature families and preserve explicit
unsupported-operation diagnostics elsewhere in the backend. They do not
establish conformance for every ECMAScript feature or every combination of
dynamic evaluation and class lexical metadata.
