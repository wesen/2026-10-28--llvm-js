function sum(n) {
  let total = 0;
  for (let i = 0; i < n; i++) total += i;
  return total;
}
function factorial(n) {
  if (n < 2) return 1;
  return n * factorial(n - 1);
}
function counter(start) {
  let x = start;
  return {
    next: () => { x = x + 1; return x; },
    current: function() { return x; }
  };
}
const a = counter(10);
print(sum(10), factorial(6), a.next(), a.next(), a.current());
