// A counter with closures: three functions share one variable.
function makeCounter(start) {
  let count = start;
  return {
    inc: () => { count = count + 1; return count; },
    dec: () => { count = count - 1; return count; },
    reset: () => { count = start; return count; },
  };
}

const a = makeCounter(0);
const b = makeCounter(100);
a.inc(); a.inc(); a.inc();
b.dec();
print("a " + a.inc() + ", b " + b.dec());
a.reset();
print("a after reset " + a.inc());
