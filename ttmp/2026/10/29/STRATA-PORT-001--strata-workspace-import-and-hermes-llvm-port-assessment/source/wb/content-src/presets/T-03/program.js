// x * 1 is x only when x is already a number.
function count(n) {
  let steps = 0;
  for (let i = 0; i < n; i++) steps = steps + 2;   // i++ multiplies i by 1 (ToNumeric)
  return steps;
}
function asNumber(x) { return x * 1; }              // "5" * 1 is 5, not "5"
print(count(5), asNumber("5") + 1);
