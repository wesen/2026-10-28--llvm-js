// SHLLVM_TEST: {"family":"function"}
"use strict";
var functionGlobalValue = 11;
var sum = Function("left", "right", "return left + right;");
print("parameters", sum(4, 8), sum.length, sum.name);
function constructOutsideScope() {
  var functionGlobalValue = 1000;
  var privateLocal = 50;
  return new Function(
      "increment",
      "return [functionGlobalValue + increment, typeof privateLocal];");
}
print("global-closure", constructOutsideScope()(3).join("|"));
var makeCounter = Function(
    "seed",
    "return function(step) { seed += step; return seed; };");
var counter = makeCounter(20);
print("dynamic-closure", counter(2), counter(5));
var Constructor = Function("value", "this.value = value; this.target = new.target;");
var instance = new Constructor(33);
print("construct", instance.value, instance instanceof Constructor,
      instance.target === Constructor);
print("this", Function("'use strict'; return this;").call(null) === null);
try {
  Function("bad parameter!", "return 0;");
} catch (error) {
  print("syntax", error.name);
}
