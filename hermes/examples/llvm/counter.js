// A native-compiled closure shares a mutable environment with its siblings.
function makeCounter(initial) {
  let value = initial;
  return {
    add: delta => { value += delta; return value; },
    read: () => value,
    snapshot: () => ({ value, description: "captured state" })
  };
}

const first = makeCounter(40);
const second = makeCounter(100);
print(first.add(1), first.add(1), first.read(), second.add(5));
print(JSON.stringify(first.snapshot()));

// A function can return a function, and ordinary array methods call it back.
function multiplyBy(scale) {
  return value => value * scale;
}
print([1, 2, 3].map(multiplyBy(7)).join(","));

// Constructors, inheritance, methods and lexical arrow this use the same
// runtime calling convention as plain source functions.
class CounterView {
  constructor(counter) { this.counter = counter; }
  reader() { return () => this.counter.read(); }
}
const readLater = new CounterView(first).reader();
first.add(8);
print(readLater());

// Exception edges preserve committed captured state.
try {
  first.add(2);
  throw { reason: "example", read: first.read };
} catch (error) {
  print(error.reason, error.read());
}
