// Node harness: load the engine and the frontend, compile samples, run every mode, compare.
// Usage: node tools/harness.js [filter]
global.acorn = require('/opt/npm-tools/node_modules/acorn');
const path = require('path');
const strata = require(path.join(__dirname, '../site/js/core.js'));
require(path.join(__dirname, '../site/js/frontend.js'));
const { g } = strata;
const filter = process.argv[2] || '';

const SAMPLES = {
  arith: `print(1 + 2 * 3); print(7 % 3); print("a" + 1);`,
  loop: `let s = 0; for (let i = 0; i < 10; i++) { s = s + i; } print(s);`,
  fib: `function fib(n) { let a = 0, b = 1; for (let i = 0; i < n; i++) { const t = a + b; a = b; b = t; } return a; } print(fib(20));`,
  recurse: `function f(n) { return n < 2 ? n : f(n - 1) + f(n - 2); } print(f(15));`,
  closure: `function counter() { let n = 0; return () => { n = n + 1; return n; }; } const c = counter(); c(); c(); print(c());`,
  closures_loop: `const fs = []; for (let i = 0; i < 3; i++) { fs[i] = () => i; } print(fs[0]() + fs[1]() + fs[2]());`,
  objects: `const o = { x: 1, y: 2, sum() { return this.x + this.y; } }; o.x = 10; print(o.sum()); print(o.z);`,
  getter_throw: `const o = { get bad() { throw new TypeError("nope"); } }; try { print(o.bad); } catch (e) { print("caught " + e.message); }`,
  try_finally: `function f() { try { return 1; } finally { print("finally"); } } print(f());`,
  try_nested: `function f(x) { try { if (x) throw new Error("boom"); return "ok"; } catch (e) { return "caught:" + e.message; } finally { print("f done"); } } print(f(0)); print(f(1));`,
  uncaught: `function f() { throw new RangeError("deep"); } f();`,
  typeof_: `print(typeof 1); print(typeof "s"); print(typeof {}); print(typeof undefined); print(typeof (() => 1));`,
  valueOf: `const o = { valueOf() { print("valueOf"); return 41; } }; print(o + 1);`,
  jobs: `print("a"); queueMicrotask(() => print("job")); setTimeout(() => print("timer"), 0); print("b");`,
  promise: `Promise.resolve(5).then(v => print("then " + v)); print("sync");`,
  tdz: `function f() { print(x); let x = 1; } try { f(); } catch (e) { print("tdz " + e.message); }`,
  strings: "const n = 3; print(`n is ${n}!`);",
  logical: `print(0 || 5); print(1 && 2); print(null ?? "d");`,
  while_: `let i = 0, s = 1; while (i < 5) { s = s * 2; i++; } print(s); do { i--; } while (i > 0); print(i);`,
  forof: `let s = 0; for (const x of [1, 2, 3, 4]) { if (x === 3) continue; s = s + x; } print(s);`,
  arrays: `const a = [1, 2, 3]; a[3] = 4; print(a.length); print(a[1] + a[3]);`,
  try_vars: `let s = 0; try { s = 1; throw new Error("x"); } catch (e) { print(s); s = s + 10; } print(s);`,
  try_loop: `let n = 0; for (let i = 0; i < 4; i++) { try { if (i % 2 === 1) throw new Error("odd " + i); n = n + i; } catch (e) { print(e.message); } } print(n);`,
  getter_count: `let calls = 0; const o = { get v() { calls = calls + 1; return calls; } }; const a = o.v; const b = o.v; print(a, b, calls);`,
  nested_closures: `function outer() { let x = 1; function mid() { let y = 2; return () => x + y; } x = 10; return mid(); } print(outer()());`,
  methods_this: `const p = { k: 3, get double() { return this.k * 2; }, set k2(v) { this.k = v; } }; p.k2 = 7; print(p.double);`,
  ledger: `
function makeLedger(name) {
  let balance = 0;
  const log = [];
  return {
    name,
    deposit(x) { if (typeof x !== "number") throw new TypeError("amount must be a number"); balance = balance + x; log[log.length] = x; return balance; },
    get balance() { return balance; },
    count() { return log.length; },
  };
}
const l = makeLedger("main");
l.deposit(10); l.deposit(32);
try { l.deposit("x"); } catch (e) { print("rejected: " + e.message); }
print(l.name + " " + l.balance + " in " + l.count());
`,
};

function show(x) { return typeof x === 'string' ? x : JSON.stringify(x); }
let failures = 0;
for (const [name, text] of Object.entries(SAMPLES)) {
  if (filter && !name.includes(filter)) continue;
  let p;
  try { p = g.compile(g.pipeline(), g.source.text(text, { name })); }
  catch (e) { console.log(`✗ ${name}: compile threw ${e.stack}`); failures++; continue; }
  const errs = p.diagnostics.filter(d => d.severity === 'error');
  const spec = p.run({ mode: 'spec' });
  const plan = p.ok ? p.run({ mode: 'plan', gc: 'stress' }) : null;
  const same = plan ? JSON.stringify(spec.output) === JSON.stringify(plan.output) && spec.outcome.kind === plan.outcome.kind : false;
  const stale = plan ? plan.events.filter(e => e.kind === 'stale').length : '-';
  const ok = p.ok && same && !spec.error && stale === 0;
  if (!ok) failures++;
  console.log(`${ok ? '✓' : '✗'} ${name}: ${spec.outcome.kind} ${show(spec.output.join(' | '))}${plan ? '' : ' (no plan: ' + errs.map(e => e.rule + ' ' + e.message).join('; ') + ')'}${plan && !same ? '\n    plan: ' + plan.outcome.kind + ' ' + plan.output.join(' | ') + (plan.error ? ' ERR ' + plan.error : '') : ''}${stale ? ' stale=' + stale : ''}${spec.error ? ' ERR ' + spec.error : ''}`);
  if (process.env.V) { console.log(p.ir('L1')); console.log(p.trace.map(x => '  ' + x.pass + ': ' + x.note).join('\n')); }
}
console.log(failures ? `${failures} failing` : 'all passing');
process.exitCode = failures ? 1 : 0;
