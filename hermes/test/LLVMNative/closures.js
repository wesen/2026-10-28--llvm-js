function counter(start) {
  let n = start;
  return { inc: () => ++n, dec: function () { return --n; }, read: () => n };
}
const a = counter(40), b = counter(100);
print(a.inc(), a.inc(), a.dec(), a.read(), b.inc(), a.read());
function nested(a) { return b => c => a + b + c; }
const f = nested(7)(11);
print(f(24), f(25));
function recursiveClosure() {
  let f = n => n === 0 ? 0 : n + f(n - 1);
  return f;
}
print(recursiveClosure()(20));
