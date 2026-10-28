# Value extensions: emitter integration

The implemented bridge is `lib/BCGen/SH/LLVMNative/value_extensions.c/.h`.
Compile the new C source in the same object target as `runtime.c`, so both
static and shared bridge targets receive these entry points. No change to the
existing unit layout or creation signature is required.

## RegExp literals

Handle `CreateRegExpInst` before the generic unsupported-instruction case:

```cpp
} else if (auto *x = llvh::dyn_cast<CreateRegExpInst>(&i)) {
  call("shllvm_regexp", {
      ptr(slot(x)), ptr("%shr"), ptr("%unit"),
      u32(module_.string(x->getPattern()->getValue().str())),
      u32(module_.string(x->getFlags()->getValue().str()))});
```

This uses the registered unit symbols. Each execution creates a fresh RegExp
object and bypasses a user-replaced global RegExp constructor.

## Exact BigInt constants

Include `hermes/Support/BigIntSupport.h`. Add `LiteralBigInt` to `isConstant`.
ModuleEmitter needs an interned byte pool, separate from the string pools:

```cpp
std::map<std::vector<uint8_t>, unsigned> bigintIDs;
std::vector<std::vector<uint8_t>> bigints;

unsigned bigint(llvh::ArrayRef<uint8_t> bytes) {
  std::vector<uint8_t> key(bytes.begin(), bytes.end());
  auto entry = bigintIDs.emplace(key, bigints.size());
  if (entry.second)
    bigints.push_back(std::move(key));
  return entry.first->second;
}
```

In `FunctionEmitter::emitConstant`, before ordinary Number handling:

```cpp
} else if (auto *n = llvh::dyn_cast<LiteralBigInt>(value)) {
  auto parsed = bigint::ParsedBigInt::parsedBigIntFromNumericValue(
      n->getValue()->str());
  if (!parsed) {
    fail(nullptr, "invalid BigInt literal representation");
    return;
  }
  auto bytes = parsed->getBytes();
  unsigned id = module_.bigint(bytes);
  call("shllvm_bigint", {
      ptr(slot(value)), ptr("%shr"),
      ptr("@shllvm_bigint" + std::to_string(id)), u32(bytes.size())});
```

In `ModuleEmitter::emitData`, after the existing generic `array` lambda:

```cpp
for (unsigned id = 0; id != bigints.size(); ++id) {
  auto bytes = bigints[id];
  if (bytes.empty())
    bytes.push_back(0);
  auto name = "shllvm_bigint" + std::to_string(id);
  array(name.c_str(), "i8", bytes);
}
```

The bridge receives the actual byte count, even for a padded empty zero literal.
This is the same `ParsedBigInt` serialization used by the C emitter and avoids
Number precision loss or dependence on a mutable global BigInt constructor.
Existing dynamic arithmetic wrappers already delegate to BigInt-aware Hermes
operations. Shared SH lowering handles exponentiation through the builtin call
path. Focused tests must still check signed division/remainder, shifts,
exponentiation, coercion errors and exact large values at O0/O.

## Private names, fields, methods, accessors and brands

Place these cases before generic ordinary property/BinaryOperator cases:

```cpp
} else if (auto *x = llvh::dyn_cast<CreatePrivateNameInst>(&i)) {
  auto *name = llvh::cast<LiteralString>(x->getSingleOperand());
  call("shllvm_private_name", {
      ptr(slot(x)), ptr("%shr"), ptr("%unit"),
      u32(module_.string(name->getValue().str()))});
} else if (auto *x = llvh::dyn_cast<LoadOwnPrivateFieldInst>(&i)) {
  call("shllvm_private_get", {
      ptr(slot(x)), ptr("%shr"), ptr(slot(x->getObject())),
      ptr(slot(x->getProperty()))});
} else if (auto *x = llvh::dyn_cast<StoreOwnPrivateFieldInst>(&i)) {
  call("shllvm_private_set", {
      ptr("%shr"), ptr(slot(x->getObject())), ptr(slot(x->getProperty())),
      ptr(slot(x->getStoredValue()))});
} else if (auto *x = llvh::dyn_cast<AddOwnPrivateFieldInst>(&i)) {
  call("shllvm_private_add", {
      ptr("%shr"), ptr(slot(x->getObject())), ptr(slot(x->getProperty())),
      ptr(slot(x->getStoredValue()))});
```

`BinaryPrivateInInst` is an instruction tag, not a concrete C++ class. Add the
following case inside the existing `BinaryOperatorInst` value-kind switch:

```cpp
case ValueKind::BinaryPrivateInInstKind:
  call("shllvm_private_in", {
      ptr(slot(x)), ptr("%shr"), ptr(slot(x->getLeftHandSide())),
      ptr(slot(x->getRightHandSide()))});
  return;
```

`PrivateBrandCheckInst` is already lowered by shared SH lowering, before
PeepholeLowering. Preserve the runtime's private-name representation and field
operations rather than treating private names as string properties.

The access and membership helpers accept a NULL inline cache; source inspection
verified the explicit null checks in `lib/VM/StaticH.cpp`. The new bridge uses
this correct uncached path. No private cache allocation, lifetime registration,
or SHLLVMUnit metadata changes are necessary.

If caches are added later, field-access caches and private-membership caches
must have distinct entries: the runtime uses their slot member as a field
offset and a boolean respectively. Sharing one cache across those operation
kinds would be incorrect even if the private symbol and object shape match.

## Typed arrays

Ordinary TypedArray, ArrayBuffer and DataView syntax uses existing constructor,
property and call lowering. It should not be confused with Hermes IR's
specialized internal fast-array instructions. The added fixtures exercise
buffer sharing, byte order, overlapping copies, integer conversion, clamping,
bounds, callbacks, and BigInt arrays/DataView operations.

Initial comparison also exposed a shared VM bug: negative numeric indices
were becoming ordinary named properties. The focused fix in
`lib/VM/JSObject.cpp` recognizes canonical numeric keys, distinguishes the
string `"-0"` from numeric `-0`, preserves conversion-before-bounds behavior
for assignments, rejects invalid numeric property definitions, and routes
named property bytecodes to the same typed-array semantics.

## Fixtures and evidence

Fixtures are in `test/LLVMNativeExtensions/features_*.js`:

- `features_regexp.js`
- `features_bigint.js`
- `features_private_fields.js`
- `features_typed_arrays.js`
- `features_bigint_typed_arrays.js`
- `features_values_gc.js`
- `features_typed_array_indices.js`

`values-initial-oracles.json` records initial actual Node and C-backend probes.
It is diagnostic evidence, not a declaration that the direct backend has
passed before root integrates and rebuilds the emitter.
