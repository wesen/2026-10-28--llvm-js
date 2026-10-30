// n is shared by makeCounter and the closure inc: one cell, two functions.
function makeCounter() {
  let n = 0;
  const inc = () => { n = n + 1; };
  inc();
  n = n + 10;
  inc();
  return n;                     // 12: inc changed n behind makeCounter's back
}
print(makeCounter());

// A let in a for loop is a new binding each turn, so each closure keeps its own i.
const fns = [];
for (let i = 0; i < 3; i++) fns[i] = () => i;
print(fns[0]() + fns[1]() + fns[2]());
