// SHLLVM_TEST: {"completion":"done: promise_order","family":"promises"}
var events = [];
var all = Promise.all([Promise.resolve(3)]).then(function (values) {
  events.push("all:" + values[0]);
});
var tick = Promise.resolve().then(function () { events.push("tick"); });
var nested = Promise.resolve().then(function () {
  events.push("outer");
  Promise.resolve().then(function () { events.push("inner"); });
});
events.push("sync");
Promise.all([all, tick, nested]).then(function () {
  var actual = events.join("|");
  if (actual !== "sync|tick|outer|all:3|inner")
    throw new Error("Promise reaction order: " + actual);
  print(actual);
  var gets = 0;
  var input = Promise.resolve(7);
  var originalThen = input.then;
  Object.defineProperty(input, "then", {
    get: function () { ++gets; return originalThen; }
  });
  return Promise.all([input]).then(function (values) {
    if (gets !== 1 || values[0] !== 7)
      throw new Error("Promise.all must observe then");
    print("then-get", gets, values[0]);
  });
}).then(function () {
  print("done: promise_order");
}, function (error) { print("FAIL", error.name, error.message); });
