// The Collatz walk from 27 takes 111 steps to reach 1; the other loop never ends.
function collatz(n) {
  let steps = 0;
  while (n !== 1) {
    n = n % 2 === 0 ? n / 2 : 3 * n + 1;
    steps = steps + 1;
  }
  return steps;
}

print(collatz(27));

let spins = 0;
while (true) spins = spins + 1;
