// finally with return: the cleanup runs on every way out of the protected region.
function withResource(name, work) {
  print("open " + name);
  try {
    return work();
  } finally {
    print("close " + name);
  }
}

function parsePositive(x) {
  if (typeof x !== "number") throw new TypeError("expected a number");
  if (x < 0) return 0;
  return x;
}

print(withResource("a", () => parsePositive(5)));
print(withResource("b", () => parsePositive(-2)));
try {
  withResource("c", () => parsePositive("x"));
} catch (e) {
  print("caught " + e.message);
}
