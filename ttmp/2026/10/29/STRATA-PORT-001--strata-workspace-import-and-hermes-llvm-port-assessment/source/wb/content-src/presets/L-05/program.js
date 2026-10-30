// Pairs in a loop: pair(a, b) still needs b after allocating the pair object.
function pair(a, b) {
  const p = { first: a };
  p.second = b;
  return p;
}

let sum = 0;
for (let i = 0; i < 20; i++) {
  const x = pair({ n: i }, { n: 1 });
  sum = sum + x.first.n + x.second.n;
}
print(sum);
