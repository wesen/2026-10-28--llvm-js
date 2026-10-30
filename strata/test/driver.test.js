"use strict";
const fs = require("node:fs"),
  path = require("node:path"),
  assert = require("node:assert/strict");
const { build } = require("../tools/strata-native");
const out = "/tmp/strata-driver-test";
fs.mkdirSync(out, { recursive: true });
const input = path.join(out, "input.js"),
  output = path.join(out, "program");
fs.writeFileSync(input, "print(42);");
build(input, { output, optimization: "2" });
const artifacts = ["", ".ll", ".bc", ".ir", ".build.json"].map(
  (s) => output + s,
);
const before = artifacts.map((f) => fs.readFileSync(f));
fs.writeFileSync(input, "async function f(){return 1;}");
assert.throws(() => build(input, { output }), /outside the native subset/);
artifacts.forEach((f, i) => assert.deepEqual(fs.readFileSync(f), before[i]));
assert.throws(() => build(input, { output: input }), /overwrite/);
assert.throws(
  () => build(input, { output, optimization: "7" }),
  /Optimization/,
);
const manifest = JSON.parse(before[4]);
assert.ok(manifest.compilerInputs["native/emitter.js"]);
assert.ok(manifest.runtimeLibraries["lib/libhermesvm.so"]);
assert.ok(manifest.executableSHA256);
console.log(
  "Failed compilation preserves five artifacts; source/output collision and invalid optimization rejected; manifest identities present",
);
