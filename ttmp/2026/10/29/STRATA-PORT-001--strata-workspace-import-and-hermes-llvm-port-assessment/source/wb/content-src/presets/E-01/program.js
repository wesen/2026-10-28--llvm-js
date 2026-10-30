// Run to completion, then the microtask queue, first in first out.
print("script start");
queueMicrotask(() => {
  print("job A");
  queueMicrotask(() => print("job E, queued by job A"));
});
queueMicrotask(() => print("job B"));
queueMicrotask(() => {
  throw new Error("job C fails");
});
queueMicrotask(() => print("job D still runs"));
print("script end");
