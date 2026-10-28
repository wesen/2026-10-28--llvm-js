let trace = '';
const a = {valueOf() { trace += 'a'; return 10; }};
const b = {valueOf() { trace += 'b'; return 32; }};
print(a + b, trace, 'value=' + a, +b);
print(null == undefined, null === undefined, '42' == 42, '42' === 42);
print(1 / -0, 0 / 0 === 0 / 0, 4294967295 >>> 0, -1 >>> 1);
print(typeof a, typeof (() => 1), typeof undefined, typeof null);
