// The Fibonacci loop in JavaScript. Nothing here says n is a number.
function fib(n) {
  let a = 0, b = 1;
  for (let i = 0; i < n; i++) {
    const t = a + b;
    a = b;
    b = t;
  }
  return a;
}

print(fib(30));
