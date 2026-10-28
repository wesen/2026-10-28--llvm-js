async function* nested() { return await await Promise.resolve(1); }
nested().next().then(function (value) { print(JSON.stringify(value)); })
  .then(function () { print("done: nested_await"); }, function (error) { print("FAIL", error.name, error.message); });
