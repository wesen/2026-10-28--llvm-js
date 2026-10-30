// pair allocates and reads; store writes a shared variable.
function pair(a, b) {
  const p = { a, b };
  const first = p.a;          // a property read: may run a getter, may collect
  return [first, p];          // an allocation: may collect
}
let last = null;
function store(x) { last = x; }   // writes a cell another function reads

const r = pair(1, 2);
store(r);
print(r[0], r.length, last === r);
