function factory(seed) {
  class Stored {
    #n = seed;
    #pattern = /^(value):(\d+)$/;
    #array = new BigInt64Array([seed, seed + 1n]);
    read(text) {
      const match = this.#pattern.exec(text);
      return [this.#n.toString(), this.#array.join(","), match[1], match[2]].join("|");
    }
    add(n) { this.#n += n; }
  }
  const value = new Stored();
  return {read: text => value.read(text), add: n => value.add(n)};
}
const first = factory(1234567890123456n);
const second = factory(99n);
for (let i = 0; i < 10000; ++i) {
  const garbage = {array: new Uint8Array(32), pattern: /temporary/g};
  garbage.self = garbage;
}
gc();
first.add(2n);
print(first.read("value:42"));
print(second.read("value:7"));
