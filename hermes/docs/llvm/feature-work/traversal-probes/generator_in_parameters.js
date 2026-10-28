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
    try {
      var iterator = await factories[i]();
      var result = iterator.next();
      print(names[i], result instanceof Promise, JSON.stringify(await result));
    } catch (error) {
      print(names[i], error.name, error.message);
    }
  }
  print("ordinary-async-default", await defaultAsync());
}
main().then(function () { print("done: generator_in_parameters"); },
            function (error) { print("FAIL", error.name, error.message); });
