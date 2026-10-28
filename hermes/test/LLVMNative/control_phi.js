function fib(n) {
  let a = 0, b = 1;
  for (let i = 0; i < n; ++i) { const old = a; a = b; b = old + b; }
  return a;
}
function loop() {
  let n = 0, sum = 0;
  while (true) {
    ++n;
    if (n % 2 === 0) continue;
    if (n > 12) break;
    sum += n;
  }
  return sum;
}
print(fib(20), loop());
let calls = 0;
function touch(x) { ++calls; return x; }
print(false && touch(1), true || touch(2), touch(0) || touch(42), calls);
