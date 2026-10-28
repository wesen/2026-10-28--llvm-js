// SHLLVM_TEST: {"completion":"done: async_closures","family":"async"}
function counter(start) {
  var value = start;
  return {
    add: async delta => {
      await Promise.resolve();
      value += delta;
      await 0;
      return value;
    },
    read: () => value
  };
}
function capture(value) {
  return async () => {
    await 0;
    return this.tag + ":" + arguments[0];
  };
}
class Reader {
  constructor(value) { this.value = value; }
  async read(delta) {
    await 0;
    var fn = async () => { await 0; return this.value + delta; };
    return await fn();
  }
}
async function main() {
  var a = counter(40), b = counter(100);
  print("captures", await a.add(1), await a.add(2), a.read(), await b.add(5), a.read());
  print("lexical", await capture.call({tag:"receiver"}, 19)());
  print("method", await new Reader(20).read(2));
}
main().then(function () { print("done: async_closures"); },
            function (error) { print("FAIL", error.name, error.message); });
