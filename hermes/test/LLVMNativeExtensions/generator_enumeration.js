// for-in maintains several mutable iterator slots across generator suspension.
function* keys(object) {
  for (const key in object) yield key + ":" + object[key];
}
const parent = {inherited: 7};
const object = Object.create(parent);
object.first = 1;
object.second = 2;
Object.defineProperty(object, "hidden", {value: 99, enumerable: false});
print("keys", JSON.stringify([...keys(object)]));
print("empty", JSON.stringify([...keys(null)]), JSON.stringify([...keys(undefined)]));
const deletion = {a: 1, b: 2, c: 3};
const seen = [];
for (const key in deletion) {
  seen.push(key);
  if (key === "a") delete deletion.b;
}
print("deleted", seen.join(","));
let total = 0;
for (const key in {a: 10, b: 20}) {
  for (const value of [1, 2, 3]) total += key === "a" ? value : value * 2;
}
print("nested-total", total);
