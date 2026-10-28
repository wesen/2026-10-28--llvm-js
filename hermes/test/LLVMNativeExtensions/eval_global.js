// SHLLVM_TEST: {"family":"eval"}
"use strict";
var evalGlobalValue = 7;
var indirect = eval;
print("indirect", indirect("evalGlobalValue + 5"));
print("comma", (0, eval)("var evalCreatedGlobal = 21; evalCreatedGlobal"));
function cannotSeeCaller() {
  var privateLocal = 99;
  return indirect("typeof privateLocal");
}
print("global-scope", cannotSeeCaller(), evalCreatedGlobal);
var marker = {name: "identity"};
print("non-string-indirect", indirect(marker) === marker, indirect(42));
try {
  indirect("function (");
} catch (error) {
  print("syntax", error.name);
}
try {
  indirect("throw new RangeError('from dynamic code')");
} catch (error) {
  print("throw", error.name, error.message);
}
