const a = [1, 2, 3, 4];
const doubled = a.map(x => x * 2);
const selected = doubled.filter(x => x > 3);
print(doubled.join(','), selected.reduce((sum,x) => sum + x, 0));
a.push(5);
print(a.pop(), a.length, a[2]);
const sparse = [7,,9];
print(sparse.length, 1 in sparse, sparse[1] === undefined);
const fs = [];
for (let i = 0; i < 4; ++i) { fs.push(() => i); }
print(fs[0](), fs[1](), fs[2](), fs[3]());
