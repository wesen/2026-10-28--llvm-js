"use strict";
const assert = require("node:assert/strict");
const { compile } = require("../native/frontend");
const { compileNative } = require("../native/emitter");
const { allocate, check } = require("../native/roots");
const moduleIR = compile("let x={n:1};let y={n:2};print(x.n,y.n);", "roots.js");
const fn = moduleIR.fn(moduleIR.main),
  plan = allocate(fn, "reuse");
assert.equal(check(fn, plan.slotOf), true);
assert.throws(
  () => check(fn, Object.fromEntries(fn.values().map((v) => [v, 0]))),
  /collision/,
);
const source = "let x=0;\n" + "x=x+1;\n".repeat(1200) + "print(x);";
assert.throws(
  () => compileNative(source, { roots: "distinct" }),
  /exceeds 1024/,
);
const compiled = compileNative(source, { roots: "reuse" });
assert.ok(compiled.metadata.functions[0].rootSlots < 20);
const fs = require("node:fs");
fs.writeFileSync("/tmp/strata-wide.js", source);
console.log(
  JSON.stringify(
    {
      wide: compiled.metadata.functions[0],
      corruptAssignment: "rejected",
      distinct: "admission rejection",
    },
    null,
    2,
  ),
);
