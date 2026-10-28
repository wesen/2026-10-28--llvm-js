// SHLLVM_TEST: {"completion":"done: promise_subclass","family":"promises"}
class DerivedPromise extends Promise {}
var original = DerivedPromise.resolve(13);
print("identity", DerivedPromise.resolve(original) === original,
      Promise.resolve(original) === original, original instanceof DerivedPromise);
original.then(function (value) {
  print("derived", value);
  return DerivedPromise.all([14, Promise.resolve(15)]);
}).then(function (values) {
  print("derived-all", values.join(","));
  class SpeciesPromise extends Promise {}
  Object.defineProperty(SpeciesPromise, Symbol.species, {get: function () { return Promise; }});
  var result = SpeciesPromise.resolve(16).then(function (value) { return value + 1; });
  print("species", result instanceof Promise, result instanceof SpeciesPromise);
  return result;
}).then(function (value) {
  print("species-value", value);
  print("done: promise_subclass");
}, function (error) { print("FAIL", error.name, error.message); });
