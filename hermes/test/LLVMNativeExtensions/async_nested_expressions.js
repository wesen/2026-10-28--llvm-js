// SHLLVM_TEST: {"completion":"done: async_nested_expressions","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function* nestedAwait() {
  return await await Promise.resolve(1);
}
async function* delegatedAwait() {
  yield* await await Promise.resolve([2, 3]);
}
async function nestedInAwait() {
  var iterator = await (async function* () { yield 4; })();
  return (await iterator.next()).value;
}
async function* nestedInYield() {
  yield (async function* () { return 5; })();
}
function* nestedInOrdinaryYield() {
  yield (async function* () { return 6; })();
}
async function yieldAwaitOrder() {
  var events = [];
  async function* source() { yield await Promise.resolve(7); }
  var yielded = source().next().then(function () { events.push("yield"); });
  var ticks = Promise.resolve().then(function () { events.push("tick-1"); })
    .then(function () { events.push("tick-2"); });
  await Promise.all([yielded, ticks]);
  var order = events.join("|");
  if (order !== "tick-1|tick-2|yield") throw new Error(order);
  print("yield-await-order", order);
}
async function main() {
  print("nested-await", JSON.stringify(await nestedAwait().next()));
  var values = [];
  for await (var value of delegatedAwait()) values.push(value);
  print("delegated-await", values.join(","));
  print("await-operand", await nestedInAwait());
  var iterator = (await nestedInYield().next()).value;
  print("yield-operand", JSON.stringify(await iterator.next()));
  var ordinary = nestedInOrdinaryYield().next().value;
  print("ordinary-yield-operand", JSON.stringify(await ordinary.next()));
  await yieldAwaitOrder();
}
main().then(function () { print("done: async_nested_expressions"); },
            function (error) { print("FAIL", error.name, error.message); });
