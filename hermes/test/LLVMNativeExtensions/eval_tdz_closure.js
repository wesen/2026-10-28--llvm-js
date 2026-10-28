// SHLLVM_TEST: {"family":"eval"}
"use strict";
function createReader() {
  // The eval makes the binding dynamically writable, but cannot turn its
  // uninitialized Empty sentinel into a regular JavaScript value by analysis.
  eval("0");
  return () => later;
  let later = 1;
}
const read = createReader();
try {
  print("incorrectly-returned", read());
} catch (error) {
  print("uninitialized-closure", error.name);
}
