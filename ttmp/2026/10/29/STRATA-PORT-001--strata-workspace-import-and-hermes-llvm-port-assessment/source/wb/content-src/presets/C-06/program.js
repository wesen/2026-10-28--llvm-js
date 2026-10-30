// One + that means three different things, depending on what typeof has proved.
function describe(x) {
  if (typeof x === "number") return x + 1;
  if (typeof x === "string") return x + "!";
  return x + 1;
}
print(describe(41), describe("hi"), describe(true));
