// A job queued from synchronous code runs after it.
const log = [];
queueMicrotask(() => print("job sees " + log.length + " entries"));
log[0] = "first";
log[1] = "second";
print("sync done");
