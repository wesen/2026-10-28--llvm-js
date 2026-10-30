// Arithmetic and comparison on objects call methods the program defines.
let calls = 0;
const price = {
  valueOf() { calls = calls + 1; print("valueOf ran"); return 40; },
};
const label = { toString() { return "tag"; } };

print(price + 2);              // valueOf, then 40 + 2
print(price < 50);             // valueOf again
print("item: " + label);       // no valueOf of its own, so toString
print("calls: " + calls);

const broken = { valueOf() { throw new RangeError("no price"); } };
try {
  print(broken * 2);
} catch (e) {
  print("caught " + e.message);
}
