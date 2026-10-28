// SHLLVM_TEST: {"completion":"done: promise_thenable_jobs","family":"promises"}
async function main() {
  var events = [];
  var then = function (resolve) { events.push("then"); resolve(4); };
  Object.defineProperty(then, "call", {get: function () { throw new Error("read then.call"); }});
  Object.defineProperty(then, "bind", {get: function () { throw new Error("read then.bind"); }});
  var thenable = {};
  Object.defineProperty(thenable, "then", {get: function () { events.push("get"); return then; }});
  var resolved = Promise.resolve(thenable).then(function (value) { events.push("resolved:" + value); });
  events.push("sync");
  var tick = Promise.resolve().then(function () { events.push("tick"); });
  await Promise.all([resolved, tick]);
  print("thenable-order", events.join("|"));
  if (events.join("|") !== "get|sync|then|tick|resolved:4") throw new Error("thenable job order");

  events = [];
  var input = Promise.resolve(8);
  var adopted = new Promise(function (resolve) { resolve(input); }).then(function () {
    events.push("adopted");
  });
  var ticks = Promise.resolve().then(function () {
    events.push("tick-1");
  }).then(function () {
    events.push("tick-2");
  });
  await Promise.all([adopted, ticks]);
  print("adoption-order", events.join("|"));
  if (events.join("|") !== "tick-1|tick-2|adopted") throw new Error("adoption job order");

  var primitives = [null, undefined, true, false, 0, -0, ""];
  for (var i = 0; i < primitives.length; i++) {
    var value = primitives[i];
    var first = Promise.resolve(value);
    var second = Promise.resolve(value);
    print("fresh", i, first !== second, Object.is(await first, value), Promise.resolve(first) === first);
  }
}
main().then(function () { print("done: promise_thenable_jobs"); },
            function (error) { print("FAIL", error.name, error.message); });
