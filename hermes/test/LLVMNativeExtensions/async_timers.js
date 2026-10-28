// SHLLVM_TEST: {"completion":"done: async_timers","family":"async"}
var events = ["script"];
Promise.resolve().then(function () { events.push("microtask"); });
var cancelled = setTimeout(function () { throw new Error("cancelled timer ran"); }, 0);
clearTimeout(cancelled);
setTimeout(function () {
  events.push("timer-1");
  Promise.resolve().then(function () { events.push("microtask-1"); });
}, 0);
setTimeout(function () {
  events.push("timer-2");
  Promise.resolve().then(function () { events.push("microtask-2"); });
}, 0);
async function main() {
  var value = await new Promise(function (resolve) {
    setTimeout(function () { events.push("timer-3"); resolve(6); }, 0);
  });
  events.push("await:" + value);
  var order = events.join("|");
  if (order !== "script|microtask|timer-1|microtask-1|timer-2|microtask-2|timer-3|await:6") {
    throw new Error(order);
  }
  print(order);
}
main().then(function () { print("done: async_timers"); },
            function (error) { print("FAIL", error.name, error.message); });
