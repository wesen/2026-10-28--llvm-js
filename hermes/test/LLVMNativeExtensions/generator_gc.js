// A suspended environment and a native closure share live mutable cells.
function* retained(seed) {
  let state = {value: seed, text: "kept:" + seed};
  const read = () => state.value + ":" + state.text;
  yield read;
  state.value += 7;
  yield read;
  state = {value: state.value + 1, text: "replaced"};
  return read;
}
function churn() {
  for (let i = 0; i < 5000; ++i) {
    const garbage = {n: i, a: [i, i + 1], text: "garbage:" + i};
    if (garbage.a[1] !== i + 1) throw "allocation failure";
  }
  gc();
}
const iterator = retained(30);
const first = iterator.next().value;
churn();
print("suspended", first());
const second = iterator.next().value;
print("shared", first === second, first(), second());
churn();
const final = iterator.next();
print("completed", final.done, final.value === first, first());
churn();
print("escaped", final.value());
let sum = 0;
function* series(i) { const box = {n: i}; yield box; return box.n + 1; }
const suspended = [];
for (let i = 0; i < 80; ++i) {
  const gen = series(i);
  gen.next();
  suspended.push(gen);
}
churn();
for (const gen of suspended) sum += gen.next().value;
print("many", sum);
