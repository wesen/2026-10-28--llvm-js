// Constants a compiler can work out before the program runs.
const width = 4 * 8;
const height = width / 2 + 1;
const area = width * height;
if (area > 500) {
  print("large " + area);
} else {
  print("small");
}
const label = "w" + width;
print(label);
