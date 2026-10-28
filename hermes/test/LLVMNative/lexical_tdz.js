function test() {
  const read = () => value;
  try { read(); } catch (e) { print(e.name); }
  let value = 42;
  return read;
}
const f = test();
print(f());
let outer = 7;
{ let outer = 11; print(outer); }
print(outer);
const obj = {n: 1};
obj.n = 42;
print(obj.n);
