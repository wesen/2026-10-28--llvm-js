// SHLLVM_TEST: {"completion":"done: async_gc","family":"async"}
async function retain(seed) {
  var object = {seed:seed, payload:[seed + 1]};
  var read = () => object.payload[0];
  await Promise.resolve();
  for (var i = 0; i < 20000; ++i) {
    var temporary = {array:[i, {nested:i + 1}]};
    temporary.self = temporary;
  }
  gc();
  var increment = await {then: function (resolve) { resolve(2); }};
  object.payload[0] += increment;
  await 0;
  return [object.seed, read()];
}
Promise.all([retain(30), retain(60)]).then(function (values) {
  print("retained", JSON.stringify(values));
  print("done: async_gc");
}, function (error) { print("FAIL", error.name, error.message); });
