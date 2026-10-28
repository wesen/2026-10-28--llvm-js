// SHLLVM_TEST: {"completion":"done: async_generator_return_order","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function main() {
  var events = [];
  async function* source() {
    try { yield 1; }
    finally { events.push("finally"); }
  }
  var generator = source();
  await generator.next();
  var returned = generator.return("closed").then(function () { events.push("returned"); });
  events.push("caller");
  var ticks = Promise.resolve().then(function () { events.push("tick-1"); })
    .then(function () { events.push("tick-2"); });
  await Promise.all([returned, ticks]);
  print("return-order", events.join("|"));

  events = [];
  async function* expression() {
    try {
      return {then: function (resolve) { events.push("return-thenable"); resolve(3); }};
    } finally { events.push("return-finally"); }
  }
  var first = expression().next().then(function (value) {
    events.push("result:" + value.value);
  });
  events.push("caller");
  await first;
  print("expression-order", events.join("|"));
}
main().then(function () { print("done: async_generator_return_order"); },
            function (error) { print("FAIL", error.name, error.message); });
