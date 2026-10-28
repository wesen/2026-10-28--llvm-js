// SHLLVM_TEST: {"family":"function"}
"use strict";
function makeTransient() {
  return Function(
      "'use strict'; let n = 5; " +
      "return eval('(function(delta) { return eval(\"n += delta\"); })');")();
}
const escaped = makeTransient();
gc();
print("after-parent-gc", escaped(2));
gc();
print("after-second-gc", escaped(3));
