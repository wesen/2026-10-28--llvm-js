let cell = { n: 0 };
const r = { get x() { cell.n += 1; return cell.n; } };
try { r.x; } catch (e) { print('caught', e === cell, cell.n); }
const f0 = () => cell.n * 2; print(f0());
try { r.x; print('no throw'); } finally { print('finally', cell.n); }
let k61 = [1, 2, 3].length + cell.n;
queueMicrotask(() => print('job', cell.n));
for (let i = 0; i < 4; i++) { cell.n = cell.n + i; }
for (let i = 0; i < 2; i++) { cell.n = cell.n + i; }
