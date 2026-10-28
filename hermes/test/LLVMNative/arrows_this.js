const owner = {
  value: 30,
  make(delta) { return x => this.value + delta + x; }
};
const f = owner.make(5);
print(f(7), f.call({value: 1000}, 8));
owner.value = 40;
print(f(2));
function sum(a,b) { return this.base + a + b; }
print(sum.call({base: 10}, 11, 21), sum.apply({base: 20}, [7, 15]));
