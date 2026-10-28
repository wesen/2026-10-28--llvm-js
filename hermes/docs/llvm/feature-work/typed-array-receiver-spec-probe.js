// Spec-directed probe: see typed-array-receiver-spec-probe.md.
// It intentionally does not use Node output as the expected result.
const array = new Uint8Array([1]);
const receiver = {};
let conversions = 0;
const value = {valueOf() { conversions++; return 7; }};
print("invalid", Reflect.set(array, "-1", value, receiver), conversions,
  Object.prototype.hasOwnProperty.call(receiver, "-1"));
try {
  print("symbol", Reflect.set(array, "-1", Symbol("unused"), receiver));
} catch (e) { print("symbol", e.name); }
try {
  print("bigint", Reflect.set(new BigInt64Array(1), "-1", 3, receiver));
} catch (e) { print("bigint", e.name); }
print("valid", Reflect.set(array, "0", 17, receiver), receiver[0], array[0]);
