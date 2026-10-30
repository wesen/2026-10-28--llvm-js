// Timers fire in order of their due time, each after the microtask queue is empty.
setTimeout(() => print("timer at 10 ms"), 10);
setTimeout(() => print("timer at 0 ms"), 0);
setTimeout(() => {
  print("timer at 5 ms");
  queueMicrotask(() => print("job queued by the 5 ms timer"));
  setTimeout(() => print("timer set at 5 ms for 2 ms later"), 2);
}, 5);
setTimeout(() => print("second timer at 0 ms"), 0);
queueMicrotask(() => print("job"));
print("script");
