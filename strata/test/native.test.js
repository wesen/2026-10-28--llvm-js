"use strict";
const fs = require("node:fs"),
  path = require("node:path"),
  assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const { build } = require("../tools/strata-native");
const out = process.argv[2] || "/tmp/strata-native-tests";
const buildDir = process.argv[3];
const stress = process.argv[4] === "stress";
fs.mkdirSync(out, { recursive: true });
const files = fs
  .readdirSync(path.join(__dirname, "fixtures"))
  .filter((f) => f.endsWith(".js"))
  .sort();
const rows = [];
for (const name of files) {
  const input = path.join(__dirname, "fixtures", name);
  const oracle = spawnSync(
    process.execPath,
    [
      "--expose-gc",
      "-e",
      "globalThis.print=(...xs)=>console.log(xs.map(String).join(' '));require('node:vm').runInThisContext(require('node:fs').readFileSync(process.argv[1],'utf8'),{filename:process.argv[1]});",
      input,
    ],
    { encoding: "utf8", timeout: 30000 },
  );
  const expectedError =
    name === "imported-J-07.js" ? "Error: missing field price" : null;
  assert.equal(oracle.status, expectedError ? 1 : 0, oracle.stderr);
  if (expectedError) assert.ok(oracle.stderr.includes(expectedError));
  for (const roots of ["distinct", "reuse"])
    for (const optimization of ["0", "2"]) {
      try {
        const { output, manifest } = build(input, {
          output: path.join(out, name + "-" + roots + "-O" + optimization),
          optimization,
          roots,
          buildDir,
        });
        const actual = spawnSync(
          output,
          stress ? ["-gc-sanitize-handles=1"] : [],
          { encoding: "utf8", timeout: 120000 },
        );
        assert.ok(
          !/AddressSanitizer|LeakSanitizer|runtime error:/.test(actual.stderr),
          actual.stderr,
        );
        assert.equal(actual.status, expectedError ? 1 : 0, actual.stderr);
        assert.equal(actual.stdout, oracle.stdout);
        if (expectedError)
          assert.ok(actual.stderr.includes(expectedError), actual.stderr);
        rows.push({
          name,
          optimization,
          strategy: roots,
          stress,
          buildDir: manifest.buildDir,
          sourceSHA256: manifest.sourceSHA256,
          llvmSHA256: manifest.llvmSHA256,
          executableSHA256: manifest.executableSHA256,
          runtimeLibraries: manifest.runtimeLibraries,
          compilerInputs: manifest.compilerInputs,
          outcome: expectedError ? "expected-language-error" : "normal",
          ok: true,
          output: actual.stdout,
          roots: manifest.functions.map((f) => ({
            name: f.name,
            roots: f.rootSlots,
          })),
        });
        console.log("PASS", name, roots, "O" + optimization);
      } catch (e) {
        rows.push({
          name,
          optimization,
          strategy: roots,
          ok: false,
          error: e.message,
        });
        console.error("FAIL", name, "O" + optimization, e.message);
      }
    }
}
fs.writeFileSync(
  path.join(out, "results.json"),
  JSON.stringify(rows, null, 2) + "\n",
);
console.log(`${rows.filter((r) => r.ok).length}/${rows.length} passed`);
process.exitCode = rows.some((r) => !r.ok) ? 1 : 0;
