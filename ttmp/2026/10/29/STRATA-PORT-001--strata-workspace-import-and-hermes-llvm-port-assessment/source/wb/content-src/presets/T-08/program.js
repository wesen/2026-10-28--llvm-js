// Constants, a branch on them, and an unused value: work for every canonical rewrite.
function size(n) {
  const unit = 2 * 4;
  const spare = n * unit;          // never used
  if (unit > 5) return n + unit;
  return n;
}
print(size(3), size(10));
