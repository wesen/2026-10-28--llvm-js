// A program with a closure that outlives the call that made it: the runtime must keep
// its code loaded for as long as the closure can still be called.
function makeGreeter(name) {
  return () => print("hello, " + name);
}
const greet = makeGreeter("engine");
queueMicrotask(greet);
print("queued");
