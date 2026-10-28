// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"The inherited C direct-eval helper substitutes global this and has no caller argument environment."}
"use strict";
function inspect(first, second) {
  print("receiver", eval("this.tag"), eval("arguments[0] + arguments[1]"));
  const arrow = () => eval("this.tag + ':' + arguments[1]");
  print("arrow", arrow());
  print("ordinary-new-target", eval("new.target") === undefined);
}
inspect.call({tag: "bound"}, 6, 7);
function Construct(value) {
  this.value = value;
  this.check = eval("new.target === Construct");
  this.read = eval("(function() { return value; })");
}
const result = new Construct(44);
print("construct", result.value, result.check, result.read());
const strictReceiver = function() { return eval("this"); };
print("strict-null", strictReceiver.call(null) === null);
