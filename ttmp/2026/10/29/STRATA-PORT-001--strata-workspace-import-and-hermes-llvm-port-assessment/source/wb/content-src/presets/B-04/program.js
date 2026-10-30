// Sum the numbers in a list, reporting the entries that are not numbers.
function tally(items) {
  let sum = 0;
  for (let i = 0; i < items.length; i++) {
    try {
      if (typeof items[i] !== "number") throw new TypeError("entry " + i + " is not a number");
      sum = sum + items[i];
    } catch (e) {
      print(e.message);
    }
  }
  return sum;
}

print(tally([1, 2, "x", 4]));
