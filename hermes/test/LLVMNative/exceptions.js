function nested(n) {
  let total = 1;
  try {
    try { total += 2; if (n) throw {n: n, run: () => 40}; }
    finally { total += 4; }
    total += 8;
  } catch (e) {
    total += e.n + e.run();
  } finally { total += 16; }
  return total;
}
print(nested(0), nested(3));
function returns() { try { return 10; } finally { return 42; } }
print(returns());
let log = '';
for (let i = 0; i < 4; ++i) {
  try { if (i === 1) continue; if (i === 3) break; log += i; }
  finally { log += 'f'; }
}
print(log);
try { const f = () => 1; new f(); } catch (e) { print(e.name); }
try { print(notDefinedHereLLVM); } catch (e) { print(e.name); }
