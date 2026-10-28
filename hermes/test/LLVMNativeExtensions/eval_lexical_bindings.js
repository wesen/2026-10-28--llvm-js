// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"The inherited C DirectEval helper does not receive the caller lexical environment."}
"use strict";
function outer(seed) {
  let value = seed;
  const fixed = 10;
  function inner(addend) {
    let local = addend;
    return eval(
        "value += local; " +
        "({read: function() { return value; }, " +
        "write: function(next) { value = next; }, " +
        "fixed: fixed, argument: arguments[0]})");
  }
  const box = inner(2);
  print("read-write", value, box.read(), box.fixed, box.argument);
  value = 20;
  print("native-to-dynamic", box.read());
  box.write(31);
  print("dynamic-to-native", value);
  eval("value = 'changed type'");
  print("type-change", typeof value, value);
}
outer(5);
function shadowing() {
  let item = 1;
  {
    let item = 8;
    print("inner", eval("item"));
    eval("item += 2");
    print("inner-write", item);
  }
  print("outer", item, eval("item"));
  {
    let invisible = 100;
    print("inside", invisible);
  }
  print("outside", eval("typeof invisible"));
}
shadowing();
function identity() {
  const object = {};
  print("non-string-direct", eval(object) === object, eval(37), eval());
  function replacement(x) { return x + "!"; }
  const original = globalThis.eval;
  globalThis.eval = replacement;
  print("overridden", eval("ordinary"));
  globalThis.eval = original;
}
identity();
