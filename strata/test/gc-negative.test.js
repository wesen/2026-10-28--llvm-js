"use strict";
// Test-only mutation: hide every native root from the collector. Never exposed
// as a compiler option. The control must run successfully before mutation.
const fs = require("node:fs"),
  path = require("node:path"),
  assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const { build } = require("../tools/strata-native");
const dir = "/tmp/strata-gc-negative";
fs.mkdirSync(dir, { recursive: true });
const input = path.join(dir, "input.js");
fs.writeFileSync(input, "const value={answer:42};gc();print(value.answer);");
const { output, manifest } = build(input, {
  output: path.join(dir, "control"),
  buildDir: process.argv[2] || "hermes/build-strata-gcstress",
  optimization: "2",
});
function run(command, args) {
  const r = spawnSync(command, args, { encoding: "utf8", timeout: 30000 });
  if (r.error) throw r.error;
  return r;
}
const control = run(output, ["-gc-sanitize-handles=1"]);
assert.equal(control.status, 0, control.stderr);
assert.equal(control.stdout, "42\n");
const original = fs.readFileSync(output + ".ll", "utf8");
const mutant = original.replace(
  /(@shllvm_enter\(ptr %shr, ptr %storage, i32 )\d+/g,
  "$10",
);
assert.notEqual(mutant, original);
const ll = path.join(dir, "mutant.ll"),
  bc = path.join(dir, "mutant.bc"),
  exe = path.join(dir, "mutant");
fs.writeFileSync(ll, mutant);
let r = run(path.join(manifest.llvmBin, "llvm-as"), [ll, "-o", bc]);
assert.equal(r.status, 0, r.stderr);
const command = manifest.commands.find((c) => path.basename(c[0]) === "clang");
const args = command.slice(1);
args[0] = bc;
args[args.length - 1] = exe;
r = run(command[0], args);
assert.equal(r.status, 0, r.stderr);
r = run(exe, ["-gc-sanitize-handles=1"]);
fs.writeFileSync(path.join(dir, "mutant.stderr.txt"), r.stderr);
assert.notEqual(r.status, 0);
assert.match(r.stderr, /AddressSanitizer/);
const result = {
  control: { status: control.status, stdout: control.stdout },
  mutation: "native registered root count set to zero",
  mutant: { status: r.status, signal: r.signal, asan: true },
  buildDir: manifest.buildDir,
  runtimeLibraries: manifest.runtimeLibraries,
};
fs.writeFileSync(
  path.join(dir, "result.json"),
  JSON.stringify(result, null, 2) + "\n",
);
console.log(JSON.stringify(result, null, 2));
