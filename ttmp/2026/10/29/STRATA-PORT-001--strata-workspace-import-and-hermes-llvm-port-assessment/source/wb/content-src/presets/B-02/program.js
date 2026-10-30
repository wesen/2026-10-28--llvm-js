// Two calls of one function: once with numbers, once with a string.
function sum(a, b) { return a + b; }

function sumTo(n) {
  let s = 0;
  for (let i = 1; i <= n; i++) s = sum(s, i);
  return s;
}

print(sum(1, 2), sum("1", 2));
print(sumTo(10));
