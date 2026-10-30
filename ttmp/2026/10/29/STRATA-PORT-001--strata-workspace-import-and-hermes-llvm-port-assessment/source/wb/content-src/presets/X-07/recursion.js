// Recursion: a recursive sum over a nested structure and a recursive Fibonacci.
function fib(n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

function depthSum(tree) {
  if (typeof tree === "number") return tree;
  let s = 0;
  for (const child of tree.children) s = s + depthSum(child);
  return s;
}

const tree = { children: [1, { children: [2, 3, { children: [4] }] }, 5] };
print("fib(12) = " + fib(12));
print("sum = " + depthSum(tree));

function countDown(n) { return n === 0 ? 0 : countDown(n - 1); }
try { countDown(1000); } catch (e) { print(e.name + ": " + e.message); }
