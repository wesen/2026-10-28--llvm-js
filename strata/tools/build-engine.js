#!/usr/bin/env node
"use strict";
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const parts = fs
  .readdirSync(path.join(root, "src/core"))
  .filter((n) => n.endsWith(".js"))
  .sort();
fs.mkdirSync(path.join(root, "lib"), { recursive: true });
function publish(name, data) {
  const destination = path.join(root, "lib", name);
  const temporary = destination + "." + process.pid + ".tmp";
  try {
    fs.writeFileSync(temporary, data);
    fs.renameSync(temporary, destination);
  } finally {
    fs.rmSync(temporary, { force: true });
  }
}
publish(
  "core.js",
  parts
    .map((n) => fs.readFileSync(path.join(root, "src/core", n), "utf8"))
    .join("\n"),
);
publish("frontend.js", fs.readFileSync(path.join(root, "src/frontend.js")));
