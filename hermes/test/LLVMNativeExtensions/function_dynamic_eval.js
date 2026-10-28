// SHLLVM_TEST: {"family":"function"}
"use strict";
const dynamicFactory = Function(
    "seed",
    "'use strict'; " +
    "let local = seed; " +
    "const read = eval('(function(step) { local += step; return local; })'); " +
    "return {read: read, native: function() { return local; }, " +
    "nested: function() { return eval('local'); }};");
const object = dynamicFactory(40);
print("function-eval", object.read(2), object.native(), object.nested());
gc();
print("function-eval-retained", object.read(3), object.nested());
const identity = Function(
    "first",
    "'use strict'; return eval('arguments[0] + this.increment');");
print("function-eval-context", identity.call({increment: 5}, 7));
const arrowFactory = Function(
    "first",
    "'use strict'; return () => eval(\"eval('this.increment + arguments[0]')\");");
const arrow = arrowFactory.call({increment: 9}, 8);
gc();
print("function-arrow-eval-context", arrow());
