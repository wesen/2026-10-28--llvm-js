// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"The LLVM direct-eval extension retains the original global or function context through nested dynamic calls."}
"use strict";
try {
  eval("eval('new.target')");
  print("FAIL accepted global new.target");
} catch (error) {
  print("nested-global-new-target", error.name);
}
print("nested-global-arguments", eval("eval('typeof arguments')"));

// An arrow and nested lexical scopes remain in the script's function context.
const fromGlobalArrow = () => {
  const outer = 6;
  {
    const inner = 7;
    try {
      eval("eval('new.target')");
      print("FAIL accepted arrow global new.target");
    } catch (error) {
      print("nested-arrow-new-target", error.name, outer * inner);
    }
  }
};
fromGlobalArrow();

// Real functions still supply their own new.target, including functions
// introduced by the evaluated source rather than the native caller.
function Construct() {
  this.valid = eval("eval('new.target === Construct')");
}
print("nested-constructor-new-target", new Construct().valid);
const DynamicConstruct = eval(
    "(function DynamicConstruct() { " +
    "this.valid = eval('new.target === DynamicConstruct'); })");
print("dynamic-constructor-new-target", new DynamicConstruct().valid);
