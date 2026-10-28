// SHLLVM_TEST: {"kind":"runtime-error","expected_error":"TypeError","family":"promises"}
Promise.prototype.then.call({}, function () {});
