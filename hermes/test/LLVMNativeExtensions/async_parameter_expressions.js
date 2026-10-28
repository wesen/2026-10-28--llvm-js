// SHLLVM_TEST: {"completion":"done: async_parameter_expressions","family":"async-generators","hermes_flags":["-Xasync-generators"]}
function declared(generator = async function* () { yield 1; }) {
  return generator();
}
var expression = function (generator = async function* () { yield 2; }) {
  return generator();
};
async function asynchronous(generator = async function* () { yield 3; }) {
  return generator();
}
async function* outerGenerator(generator = async function* () { yield 4; }) {
  yield* generator();
}
function defaultAsync(callback = async function () { return 5; }) {
  return callback();
}
async function main() {
  var names = ["declaration", "expression", "async-function", "async-generator"];
  var factories = [declared, expression, asynchronous, outerGenerator];
  for (var i = 0; i < factories.length; i++) {
    var iterator = await factories[i]();
    var result = iterator.next();
    if (!(result instanceof Promise)) throw new Error(names[i] + " result");
    var resolved = await result;
    if (resolved.done || resolved.value !== i + 1) {
      throw new Error(names[i] + " value");
    }
    print(names[i], JSON.stringify(resolved));
  }
  print("ordinary-async-default", await defaultAsync());
}
main().then(function () { print("done: async_parameter_expressions"); },
            function (error) { print("FAIL", error.name, error.message); });
