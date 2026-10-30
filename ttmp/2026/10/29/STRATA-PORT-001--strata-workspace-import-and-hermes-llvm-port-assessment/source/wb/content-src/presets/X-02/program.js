// Two numeric loops. Called with numbers, but nothing in the source says so.
function mean(xs, n) {
  let s = 0;
  for (let i = 0; i < n; i++) s = s + xs[i];
  return s / n;
}
function scale(k, n) {
  let acc = 0;
  for (let i = 0; i < n; i++) acc = acc + k * i;
  return acc;
}
print(mean([3, 5, 7, 9], 4));
print(scale(3, 20));
