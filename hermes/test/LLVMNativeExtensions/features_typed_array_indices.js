function canonicalIndices() {
  const a = new Uint8Array([3, 4]);
  const invalid = [-1, "-1", "-0", 1.5, "1.5", NaN, "NaN",
    Infinity, "-Infinity", 2, 4294967295, "4294967296", 1e21];
  let conversions = 0;
  for (const key of invalid) {
    a[key] = {valueOf() { conversions++; return 7; }};
    print(String(key), a[key], key in a,
      Object.getOwnPropertyDescriptor(a, key) === undefined,
      Reflect.defineProperty(a, key, {value: 9}), delete a[key]);
  }
  print("converted", conversions, a.join(","));
  a[-0] = 8;
  a[1n] = 9;
  a[-1n] = 100;
  print("zero-and-bigint", a[0], a[1], a[-1n]);
  a["-1"] = 6;
  a["-0"] = 6;
  print("named", a["-1"], a["-0"], "-1" in a);
}

function ordinaryNamesAndDescriptors() {
  const a = new Uint8Array([1, 2]);
  const ordinary = ["01", "+1", "1.0", "1e0", " 1 ", "0x1",
    "9007199254740993", "not-a-number"];
  for (let i = 0; i < ordinary.length; i++) a[ordinary[i]] = 20 + i;
  print("ordinary", ordinary.map(key => a[key]).join(","), a.join(","));
  print("descriptor",
    Reflect.defineProperty(a, "0", {value: 42, configurable: true}),
    Reflect.defineProperty(a, "0", {configurable: false}),
    Reflect.defineProperty(a, "0", {writable: false}),
    Reflect.defineProperty(a, "0", {enumerable: false}),
    Reflect.defineProperty(a, "0", {get() { return 1; }}),
    a[0]);
  let converted = false;
  try {
    Object.defineProperty(a, "-1", {
      value: {valueOf() { converted = true; return 10; }}
    });
  } catch (e) { print("define-invalid", e.name, converted); }
  Object.preventExtensions(a);
  print("not-extensible", Reflect.set(a, "-1", 8), Reflect.set(a, "9", 8));
}

function conversionAndReceivers() {
  const a = new Uint8Array([1]);
  const b = new BigInt64Array([1n]);
  try { a[-1] = Symbol("value"); } catch (e) { print("number-conversion", e.name); }
  try { b[-1] = 3; } catch (e) { print("bigint-conversion", e.name); }
  let log = [];
  const key = {toString() { log.push("key"); gc(); return "-1"; }};
  const value = {valueOf() { log.push("value"); gc(); return 5; }};
  a[key] = value;
  print("ordering", log.join(","), a[-1]);
  const receiver = {};
  print("receiver",
    Reflect.set(a, "-1", 8, receiver),
    Object.prototype.hasOwnProperty.call(receiver, "-1"),
    Reflect.set(a, "0", 17, receiver), receiver[0], a[0]);
  let receiverConversions = 0;
  const convertedValue = {valueOf() { receiverConversions++; return 5; }};
  print("typed-receiver-invalid", Reflect.set({}, "-1", convertedValue, a),
    receiverConversions, a[-1]);
  print("typed-receiver-valid", Reflect.set({}, "0", convertedValue, a),
    receiverConversions, a[0]);
}

function numericPrototypeProperties() {
  const a = new Uint8Array([3]);
  const parent = Object.create(Uint8Array.prototype);
  parent["-1"] = 70;
  parent["1.5"] = 80;
  parent["99"] = 90;
  Object.setPrototypeOf(a, parent);
  print("prototype", a[-1], a["-1"], a[1.5], a[99],
    "-1" in a, "1.5" in a, "99" in a);
  a[-1] = 4;
  print("prototype-write", a[-1], parent["-1"]);
}

canonicalIndices();
ordinaryNamesAndDescriptors();
conversionAndReceivers();
numericPrototypeProperties();
