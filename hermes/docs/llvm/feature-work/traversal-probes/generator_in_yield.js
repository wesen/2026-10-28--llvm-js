async function* outer() { yield (async function* () { return 3; })(); }
async function main() {
  var iterator = (await outer().next()).value;
  print(JSON.stringify(await iterator.next()));
}
main().then(function () { print("done: generator_in_yield"); }, function (error) { print("FAIL", error.name, error.message); });
