// SHLLVM_TEST: {"completion":"done: async_generators","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function* values() {
  yield 1;
  yield Promise.resolve(2);
  yield* [3, 4];
  return 99;
}
async function main() {
  var collected = [];
  for await (var value of values()) collected.push(value);
  print("for-await", collected.join(","));
  var finalized = false;
  async function* closeable() {
    try { yield 5; yield 6; }
    finally { await 0; finalized = true; }
  }
  for await (var next of closeable()) {
    print("break", next);
    break;
  }
  print("closed", finalized);
}
main().then(function () { print("done: async_generators"); },
            function (error) { print("FAIL", error.name, error.message); });
