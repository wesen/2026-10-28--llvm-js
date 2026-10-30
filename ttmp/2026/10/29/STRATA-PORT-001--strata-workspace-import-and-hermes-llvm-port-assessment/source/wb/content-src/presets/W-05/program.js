// A counter: makeCounter returns a closure that captures n and step.
function makeCounter(step) {
  let n = 0;
  return () => {
    n = n + step;
    return n;
  };
}

const tick = makeCounter(5);
tick();
print(tick());
