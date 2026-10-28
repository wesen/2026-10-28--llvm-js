// SHLLVM_TEST: {"completion":"done: async_generator_queue_completion","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function* once() {
  await 0;
  return 1;
}
async function main() {
  var generator = once();
  var requests = [generator.next()];
  for (var i = 0; i < 2048; i++) {
    requests.push(i % 7 === 0 ? generator.throw("queued:" + i) : generator.next());
  }
  requests.push(generator.return(Promise.resolve("completed-return")));
  requests.push(generator.throw("completed-throw"));
  requests.push(generator.next());
  gc();
  var results = await Promise.allSettled(requests);
  var fulfilled = 0, rejected = 0;
  for (var i = 0; i < results.length; i++) {
    results[i].status === "fulfilled" ? fulfilled++ : rejected++;
  }
  print("queue", results.length, fulfilled, rejected);
  print("first", JSON.stringify(results[0]));
  print("tail", JSON.stringify(results.slice(-3)));
}
main().then(function () { print("done: async_generator_queue_completion"); },
            function (error) { print("FAIL", error.name, error.message); });
