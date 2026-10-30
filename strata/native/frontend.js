"use strict";
require("../tools/build-engine.js");
global.acorn = require("../vendor/acorn.js");
const strata = require("../lib/core.js");
require("../lib/frontend.js");
function compile(source, filename) {
  const module = strata.frontend.compile(source, {
    name: filename,
    native: true,
  });
  for (const fn of module.functions.values()) strata.g.promoteCells(fn);
  const checked = strata.g.verify(module);
  if (!checked.ok) throw new Error(JSON.stringify(checked.diagnostics));
  return module;
}
module.exports = { compile, strata };
