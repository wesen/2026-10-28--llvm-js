// Two numeric functions and one that is not.
function hyp(a, b) {
  return a * a + b * b;
}

function isBig(x) {
  return x > 100;
}

function label(o) {
  return o.name + "!";
}

print(hyp(3, 4));
print(isBig(hyp(8, 9)));
print(label({ name: "box" }));
