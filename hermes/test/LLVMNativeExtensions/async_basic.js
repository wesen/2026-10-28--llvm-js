// SHLLVM_TEST: {"completion":"done: async_basic","family":"async"}
async function immediate(value) { return value; }
async function work(value) {
  var first = await value;
  var second = await Promise.resolve(first + 1);
  return second * 2;
}
async function main() {
  print("values", await immediate(7), await work(8));
  print("thenable", await work({then: function (resolve) { resolve(9); }}));
  print("primitive", await null, await undefined, await false);
  var log = [];
  async function order() {
    log.push("before");
    await 0;
    log.push("after");
  }
  var pending = order();
  log.push("caller");
  await pending;
  print("order", log.join("|"));
  if (log.join("|") !== "before|caller|after") throw new Error("await was synchronous");
}
main().then(function () { print("done: async_basic"); },
            function (error) { print("FAIL", error.name, error.message); });
