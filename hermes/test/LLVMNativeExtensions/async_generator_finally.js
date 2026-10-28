// SHLLVM_TEST: {"completion":"done: async_generator_finally","family":"async-generators","hermes_flags":["-Xasync-generators"]}
var events = [];
async function* cleanup(mode) {
  try {
    yield 1;
    yield 2;
  } finally {
    events.push("start");
    events.push(await Promise.resolve("awaited"));
    await 0;
    events.push("end");
    if (mode === "return") return "override";
    if (mode === "throw") throw new RangeError("finally");
    if (mode === "yield") yield "cleanup";
  }
}
async function* rejectingCleanup() {
  try { yield 1; }
  finally { await Promise.reject(new TypeError("cleanup rejected")); }
}
async function main() {
  for (var mode of ["normal", "return", "throw", "yield"]) {
    events = [];
    var generator = cleanup(mode);
    await generator.next();
    try { print(mode, JSON.stringify(await generator.return("closed"))); }
    catch (error) { print(mode, error.name, error.message); }
    print("cleanup-events", events.join("|"));
    print("next", JSON.stringify(await generator.next()));
  }
  var rejecting = rejectingCleanup();
  await rejecting.next();
  try { await rejecting.return("closed"); }
  catch (error) { print("rejecting", error.name, error.message); }
  print("rejecting-done", JSON.stringify(await rejecting.next()));

  events = [];
  var thrown = cleanup("normal");
  await thrown.next();
  try { await thrown.throw(new Error("injected")); }
  catch (error) { print("thrown", error.name, error.message); }
  print("throw-events", events.join("|"));

  try {
    for await (var value of cleanup("throw")) {
      print("body", value);
      throw new Error("body wins");
    }
  } catch (error) { print("close-precedence", error.name, error.message); }
}
main().then(function () { print("done: async_generator_finally"); },
            function (error) { print("FAIL", error.name, error.message); });
