// SHLLVM_TEST: {"completion":"done: promise_combinators","family":"promises"}
Promise.all([1, Promise.resolve(2), {then: function (resolve) { resolve(3); }}])
.then(function (values) {
  print("all", values.join(","));
  return Promise.allSettled([Promise.resolve(4), Promise.reject("bad"), 5]);
}).then(function (values) {
  print("settled", JSON.stringify(values));
  return Promise.race([Promise.resolve("first"), Promise.resolve("second")]);
}).then(function (value) {
  print("race", value);
  return Promise.any([Promise.reject("no"), Promise.resolve("yes")]);
}).then(function (value) {
  print("any", value);
  return Promise.any([Promise.reject("a"), Promise.reject("b")]).catch(function (error) {
    print("any-error", error.name, error.errors.join(","));
  });
}).then(function () {
  return Promise.all([]);
}).then(function (values) {
  print("empty-all", values.length);
  return Promise.allSettled([]);
}).then(function (values) {
  print("empty-settled", values.length);
  print("done: promise_combinators");
}, function (error) { print("FAIL", error.name, error.message); });
