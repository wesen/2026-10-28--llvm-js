// SHLLVM_TEST: {"completion":"done: promise_resolution","family":"promises"}
var calls = 0;
Promise.resolve({
  then: function (resolve, reject) {
    ++calls;
    resolve(11);
    reject("ignored");
    resolve(99);
    throw new Error("also ignored");
  }
}).then(function (value) {
  print("once", calls, value);
  return new Promise(function () { throw new RangeError("executor"); });
}).catch(function (error) {
  print(error.name, error.message);
  return 12;
}).finally(function () {
  print("finally-value");
  return Promise.resolve(999);
}).then(function (value) {
  print("preserved", value);
  return Promise.reject("reason").finally(function () { print("finally-reason"); });
}).catch(function (reason) {
  print("preserved-reason", reason);
  return Promise.resolve(1).finally(function () { throw new TypeError("replacement"); });
}).catch(function (error) {
  print(error.name, error.message);
  return Promise.resolve(Object.defineProperty({}, "then", {
    get: function () { throw new SyntaxError("then getter"); }
  }));
}).catch(function (error) {
  print(error.name, error.message);
  var cycle;
  cycle = Promise.resolve().then(function () { return cycle; });
  return cycle.catch(function (error) { print("cycle", error.name); });
}).then(function () {
  print("done: promise_resolution");
}, function (error) { print("FAIL", error.name, error.message); });
