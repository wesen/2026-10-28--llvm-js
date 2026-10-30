// The ledger's total loop, on its own: sum the entries of an array.
function total(log) {
  let sum = 0;
  for (let i = 0; i < log.length; i++) sum = sum + log[i];
  return sum;
}
print(total([10, 32]));
