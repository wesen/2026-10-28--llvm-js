// SHLLVM_TEST: {"completion":"done: async_generator_queue","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function* queued() {
  var first = yield await Promise.resolve("first");
  try {
    yield "received:" + first;
  } catch (error) {
    yield "caught:" + error;
  } finally {
    await 0;
    print("finalized");
  }
  return "finished";
}
async function main() {
  var generator = queued();
  var one = generator.next("ignored");
  var two = generator.next("sent");
  var three = generator.throw("problem");
  print("queued", JSON.stringify(await Promise.all([one, two, three])));
  print("return", JSON.stringify(await generator.return("closed")));
  print("done", JSON.stringify(await generator.next()));
}
main().then(function () { print("done: async_generator_queue"); },
            function (error) { print("FAIL", error.name, error.message); });
