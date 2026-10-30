// Two protected regions in one function, each with its own handler.
function readBoth(a, b) {
  let first = "none";
  try {
    first = a.value;
  } catch (e) {
    print("a failed: " + e.message);
  }
  let second = "none";
  try {
    second = b.value;
  } catch (e) {
    print("b failed: " + e.message);
  }
  return first + "/" + second;
}

const ok = { value: "x" };
const bad = { get value() { throw new Error("no value"); } };
print(readBoth(ok, bad));
print(readBoth(bad, ok));
