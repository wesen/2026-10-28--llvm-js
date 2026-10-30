// Promises: reactions are jobs too.
const p = Promise.resolve(1);
p.then(v => {
  print("first then: " + v);
  return v + 1;
}).then(v => print("second then: " + v));
p.then(v => print("another reaction on p: " + v));
queueMicrotask(() => print("plain job"));
print("sync");
