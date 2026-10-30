// Factorial by recursion: each call is a frame of its own.
function fact(n) {
  if (n <= 1) return 1;
  return n * fact(n - 1);
}

print(fact(4));
