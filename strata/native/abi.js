"use strict";
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const header = path.resolve(
  __dirname,
  "../../hermes/lib/BCGen/SH/LLVMNative/runtime.h",
);
const source = fs.readFileSync(header, "utf8");
const clean = source.replace(/\/\*[\s\S]*?\*\//g, "");
function type(s) {
  if (s.includes("*")) return "ptr";
  if (/uint64_t/.test(s)) return "i64";
  if (/(u?int32_t)/.test(s)) return "i32";
  if (/double/.test(s)) return "double";
  if (/\bvoid\b/.test(s)) return "void";
  throw new Error(`Unsupported ABI type: ${s}`);
}
const signatures = new Map();
for (const m of clean.matchAll(
  /(void\s*\*?|uint64_t|uint32_t|int32_t)\s+(shllvm_\w+)\s*\(([^)]*)\)\s*;/g,
)) {
  signatures.set(m[2], {
    result: type(m[1]),
    args:
      m[3].trim() === "void"
        ? []
        : m[3]
            .split(",")
            .filter((s) => s.trim())
            .map(type),
  });
}
// Pointer return declarations have no space between * and the identifier.
for (const m of clean.matchAll(/void\s*\*\s*(shllvm_\w+)\s*\(([^)]*)\)\s*;/g))
  signatures.set(m[1], {
    result: "ptr",
    args: m[2]
      .split(",")
      .filter((s) => s.trim() && s.trim() !== "void")
      .map(type),
  });
signatures.set("_sh_check_native_stack_overflow", {
  result: "void",
  args: ["ptr"],
});
signatures.set("_setjmp", { result: "i32", args: ["ptr"] });
const codes = {};
for (const m of clean.matchAll(/\b(SHLLVM_\w+)\s*=\s*(\d+)/g))
  codes[m[1]] = Number(m[2]);
module.exports = {
  signatures,
  codes,
  header,
  sha256: crypto.createHash("sha256").update(source).digest("hex"),
};
