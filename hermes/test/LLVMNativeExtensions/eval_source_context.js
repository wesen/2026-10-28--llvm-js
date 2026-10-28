// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"Source-site lexical and new.target context is recorded only by the LLVM direct-eval extension."}
function sloppyEnclosing() {
  // This inherited name cannot be written as a strict lexical declaration in
  // the synthetic scope scaffold, even when the eval text does not use it.
  var let = 6;
  var ordinary = 20;
  return function strictChild() {
    "use strict";
    return eval("ordinary + 2");
  };
}
print("inherited-name", sloppyEnclosing()());
const globalArrow = () => {
  "use strict";
  return eval("new.target");
};
try {
  globalArrow();
} catch (error) {
  print("arrow-global-new-target", error.name);
}
const globalArguments = () => {
  "use strict";
  return eval("typeof arguments");
};
print("arrow-global-arguments", globalArguments());
function ordinaryContext() {
  "use strict";
  function inner() { return eval("new.target"); }
  return inner();
}
print("ordinary-context", ordinaryContext() === undefined);
