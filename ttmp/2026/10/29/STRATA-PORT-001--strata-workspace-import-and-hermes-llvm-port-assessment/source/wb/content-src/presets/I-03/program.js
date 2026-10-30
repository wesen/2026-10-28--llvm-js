// Euclid's algorithm: each turn replaces (a, b) by (b, a % b).
function gcd(a, b) {
  while (b !== 0) {
    const r = a % b;
    a = b;
    b = r;
  }
  return a;
}

// Two nested loops: the inner one restarts j for every i.
function triangle(n) {
  let count = 0;
  for (let i = 1; i <= n; i++) {
    for (let j = 0; j < i; j++) count = count + 1;
  }
  return count;
}

print(gcd(1071, 462), triangle(4));
