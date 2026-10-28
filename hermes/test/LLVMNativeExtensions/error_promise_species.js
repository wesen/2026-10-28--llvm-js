// SHLLVM_TEST: {"kind":"runtime-error","expected_error":"TypeError","family":"promises"}
var promise = Promise.resolve(1);
promise.constructor = {[Symbol.species]: () => {}};
promise.then(function (value) { print(value); });
