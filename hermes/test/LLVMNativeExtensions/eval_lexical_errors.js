// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"The inherited C direct-eval path lacks lexical binding and TDZ metadata."}
"use strict";
function guards() {
  const fixed = 4;
  try {
    eval("fixed = 9");
  } catch (error) {
    print("const", error.name, fixed);
  }
  try {
    eval("later");
  } catch (error) {
    print("tdz", error.name);
  }
  let later = 17;
  print("initialized", eval("later"));
  try {
    eval("const own = 1; own = 2;");
  } catch (error) {
    print("eval-local-const", error.name);
  }
  let local = 1;
  try {
    eval("local = 8; throw new Error('cross-boundary');");
  } catch (error) {
    print("caught", error.name, error.message, local);
  } finally {
    print("finally", local);
  }
  try {
    eval("let = ;");
  } catch (error) {
    print("syntax", error.name);
  }
  print("after-errors", eval("local + later"));
}
guards();
try {
  eval("new.target");
} catch (error) {
  print("global-new-target", error.name);
}
print("global-function-new-target",
      eval("(function() { return new.target; })()") === undefined);
