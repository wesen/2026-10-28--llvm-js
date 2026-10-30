// Count positive and other entries, and remember which kind came last.
function classify(xs) {
  let pos = 0;
  let other = 0;
  let last = "none";
  let touched = false;          // written in the loop, never read: its parameters are dead
  for (let i = 0; i < xs.length; i++) {
    if (xs[i] > 0) {
      pos = pos + 1;
      last = "positive";
      touched = true;
    } else {
      other = other + 1;
      last = "other";
    }
  }
  return pos + " positive, " + other + " other, last " + last;
}

print(classify([3, -1, 4, -1, 5]));
