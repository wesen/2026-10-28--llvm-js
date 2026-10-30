// A pair of boxes: the object p is still needed after two operations that may collect.
function pair(a, b) {
  const p = { first: a };
  p.second = b;
  return p;
}

const x = pair({ n: 1 }, { n: 2 });
print(x.first.n + x.second.n);
