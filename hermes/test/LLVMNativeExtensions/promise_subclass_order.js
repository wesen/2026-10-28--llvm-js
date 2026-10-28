// SHLLVM_TEST: {"completion":"done: promise_subclass_order","family":"promises"}
class DerivedPromise extends Promise {}
var events = [];
var derived = DerivedPromise.resolve(1).then(function () {
  events.push("derived:1");
}).then(function () {
  events.push("derived:2");
});
var core = Promise.resolve(1).then(function () {
  events.push("core:1");
}).then(function () {
  events.push("core:2");
});
Promise.all([derived, core]).then(function () {
  var actual = events.join("|");
  if (actual !== "derived:1|core:1|derived:2|core:2") throw new Error(actual);
  print(actual);
  print("done: promise_subclass_order");
}).catch(function (error) { print("FAIL", error.name, error.message); });
