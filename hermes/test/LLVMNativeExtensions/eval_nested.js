// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"The static C DirectEval entry lacks the native caller Environment; nested dynamic calls use the shared interpreter metadata path."}
"use strict";
function makeNested(seed) {
  let value = seed;
  const dynamic = eval(
      "let inner = 3; " +
      "eval('value += inner'); " +
      "(function(delta) { return eval('value += delta'); })");
  print("nested-initial", value);
  return {
    dynamic: dynamic,
    native: function() { return value; },
    write: function(next) { value = next; }
  };
}
const pair = makeNested(5);
gc();
print("escaped-nested", pair.dynamic(4), pair.native());
pair.write(30);
gc();
print("nested-shared", pair.dynamic(2), pair.native());
print("nested-completion", eval("eval('6 * 7')"));
print("nested-non-string", eval("eval(13)"));
