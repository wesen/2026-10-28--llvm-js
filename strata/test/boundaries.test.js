"use strict";
const assert = require("node:assert/strict");
const { compileNative } = require("../native/emitter");
const cases = [
  ["let f=function self(){return self;};", /current-callee/],
  ["function f(){return arguments;}", /arguments/],
  ["async function f(){return 1;}", /async and generator/],
  ["function* f(){return 1;}", /async and generator/],
  ['eval("1+2");', /direct eval/],
  ["class C {}", /classes/],
  ["print(1n);", /BigInt/],
  ["let [a]=[1];", /destructur/],
];
for (const [source, message] of cases)
  assert.throws(() => compileNative(source), message);
assert.throws(() => compileNative("let x="), /parse error/);
console.log(
  `${cases.length} unsupported-context contracts and one parse-error contract passed`,
);
