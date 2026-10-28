// SHLLVM_TEST: {"family":"eval","c_oracle":"skip","c_oracle_reason":"Escaped eval closures must capture the actual native Environment, which the inherited C helper does not pass."}
"use strict";
function build(seed) {
  let state = {value: seed, payload: [seed + 1]};
  const read = eval(
      "(function(step) { state.value += step; return state.value + ':' + state.payload[0]; })");
  return {
    dynamic: read,
    native: function() { return state.value; },
    replace: function(value) { state = {value: value, payload: [value + 1]}; }
  };
}
const first = build(10);
const second = build(100);
for (let i = 0; i < 15000; ++i) {
  const temporary = {items: [i, {value: i + 1}]};
  temporary.self = temporary;
}
gc();
print("retained-first", first.dynamic(2), first.native());
print("retained-second", second.dynamic(3), second.native());
first.replace(30);
gc();
print("shared-after-gc", first.dynamic(4), first.native());
