function fact(n) { if (n <= 1) return 1; return n * fact(n - 1); }
function even(n) { return n === 0 ? true : odd(n - 1); }
function odd(n) { return n === 0 ? false : even(n - 1); }
function apply(fn, x) { return fn(x); }
const twice = x => x * 2;
function outer(x) { return function inner(y) { return x + y; }; }
print(fact(8), even(12), odd(13), apply(twice, 21), outer(19)(23));
