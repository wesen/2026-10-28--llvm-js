// SHLLVM_TEST: {"completion":"done: promise_species","family":"promises"}
async function main() {
  class OtherPromise extends Promise {}
  class SelectedPromise extends Promise {}
  var speciesReads = 0;
  Object.defineProperty(SelectedPromise, Symbol.species, {
    get: function () { speciesReads++; return OtherPromise; }
  });
  var selected = SelectedPromise.resolve(3).then(function (value) { return value + 1; });
  print("selection", selected instanceof OtherPromise,
        selected instanceof SelectedPromise, speciesReads);
  print("selection-value", await selected);

  var constructorReads = 0, symbolReads = 0;
  var source = Promise.resolve(5);
  var constructor = {};
  Object.defineProperty(constructor, Symbol.species, {
    get: function () { symbolReads++; return Promise; }
  });
  Object.defineProperty(source, "constructor", {
    get: function () { constructorReads++; return constructor; }
  });
  var child = source.then(function (value) { return value + 1; });
  print("lookups", constructorReads, symbolReads);
  print("lookups-value", await child);

  class DefaultPromise extends Promise {}
  Object.defineProperty(DefaultPromise, Symbol.species, {value: null});
  var fallback = DefaultPromise.resolve(7).then();
  print("null-species", Object.getPrototypeOf(fallback) === Promise.prototype, await fallback);
  var noConstructor = Promise.resolve(8);
  noConstructor.constructor = undefined;
  print("undefined-constructor", await noConstructor.then());
  var noSpecies = Promise.resolve(9);
  noSpecies.constructor = {};
  print("undefined-species", await noSpecies.then());

  for (var badConstructor of [null, 17, "constructor"]) {
    var invalid = Promise.resolve(10);
    invalid.constructor = badConstructor;
    try { invalid.then(); } catch (error) { print("constructor-error", error.name); }
  }
  for (var badSpecies of [{}, [], () => {}]) {
    var invalid = Promise.resolve(11);
    invalid.constructor = {[Symbol.species]: badSpecies};
    try { invalid.then(); } catch (error) { print("species-error", error.name); }
  }
  var thenGets = 0;
  var generic = {constructor: {[Symbol.species]: () => {}}};
  Object.defineProperty(generic, "then", {get: function () { thenGets++; }});
  try { Promise.prototype.finally.call(generic, undefined); }
  catch (error) { print("generic-validation", error.name, thenGets); }

  var proxyGets = 0;
  var proxiedConstructor = new Proxy(function Constructor() {}, {
    get: function (target, key) { proxyGets++; return Reflect.get(target, key); }
  });
  var genericResult = Promise.prototype.finally.call({
    constructor: {[Symbol.species]: proxiedConstructor},
    then: function () { return "generic-result"; }
  }, undefined);
  print("constructor-no-get", genericResult, proxyGets);

  class FinallyPromise extends Promise {}
  var original = new FinallyPromise(function (resolve) { resolve(12); });
  Object.defineProperty(FinallyPromise, "resolve", {
    get: function () { throw new Error("finally must not read C.resolve"); }
  });
  var final = original.finally(function () { print("finally-ran"); return 99; });
  print("finally-constructor", final instanceof FinallyPromise);
  print("finally-value", await final);
}
main().then(function () { print("done: promise_species"); },
            function (error) { print("FAIL", error.name, error.message); });
