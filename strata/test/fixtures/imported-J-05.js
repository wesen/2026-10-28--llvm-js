// An event queue: synchronous code, microtasks, promise reactions and timers, in order.
const log = [];
function note(s) { log[log.length] = s; print(s); }

note("script start");
setTimeout(() => note("timer 20"), 20);
setTimeout(() => {
  note("timer 0");
  queueMicrotask(() => note("microtask from timer 0"));
}, 0);
Promise.resolve(1)
  .then(v => { note("then " + v); return v + 1; })
  .then(v => note("then " + v));
queueMicrotask(() => note("microtask"));
note("script end");
queueMicrotask(() => print(log.length + " notes so far"));
