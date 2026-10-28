// SHLLVM_TEST: {"completion":"done: async_exceptions","family":"async"}
async function recover() {
  var value = 0;
  try {
    await Promise.reject({code:"rejected"});
  } catch (error) {
    print("caught", error.code);
    value = await 2;
  } finally {
    value += await 3;
  }
  return value;
}
async function replaceReturn() {
  try { return await 7; }
  finally { return await 9; }
}
async function replaceThrow() {
  try { throw new Error("original"); }
  finally { await 0; throw new RangeError("final"); }
}
async function getterThrows() {
  try {
    await Object.defineProperty({}, "then", {
      get: function () { throw new TypeError("await getter"); }
    });
  } catch (error) {
    print(error.name, error.message);
    return await 23;
  }
}
async function main() {
  print("recovered", await recover());
  print("return", await replaceReturn());
  try { await replaceThrow(); }
  catch (error) { print(error.name, error.message); }
  print("getter", await getterThrows());
}
main().then(function () { print("done: async_exceptions"); },
            function (error) { print("FAIL", error.name, error.message); });
