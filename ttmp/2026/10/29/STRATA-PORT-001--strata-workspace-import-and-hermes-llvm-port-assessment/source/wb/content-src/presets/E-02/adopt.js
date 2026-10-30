// Adoption: a reaction that returns a promise.
Promise.resolve(10).then(v => {
  print("returns a promise");
  return Promise.resolve(v * 2);
}).then(v => print("adopted: " + v));
queueMicrotask(() => print("tick 1"));
queueMicrotask(() => queueMicrotask(() => print("tick 2")));
queueMicrotask(() => queueMicrotask(() => queueMicrotask(() => print("tick 3"))));
print("sync");
