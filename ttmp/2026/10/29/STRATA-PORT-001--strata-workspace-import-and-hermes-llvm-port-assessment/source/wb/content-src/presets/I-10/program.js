// Three ways out of try: a return, a caught throw that falls through, a throw from catch.
function attempt(x) {
  let steps = "start";
  try {
    if (x < 0) throw new RangeError("negative");
    if (x === 0) throw "zero";
    steps = steps + ", ok";
    return "returned " + x;
  } catch (e) {
    if (e === "zero") throw new TypeError("zero is not allowed");
    steps = steps + ", caught " + e.message;
  } finally {
    print("finally after " + steps);
  }
  return "fell through";
}

print(attempt(1));
print(attempt(-1));
try {
  attempt(0);
} catch (e) {
  print("main caught " + e.message);
}
