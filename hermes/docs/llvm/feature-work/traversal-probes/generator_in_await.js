async function main() {
  var iterator = await (async function* () { yield 2; })();
  print(JSON.stringify(await iterator.next()));
}
main().then(function () { print("done: generator_in_await"); }, function (error) { print("FAIL", error.name, error.message); });
