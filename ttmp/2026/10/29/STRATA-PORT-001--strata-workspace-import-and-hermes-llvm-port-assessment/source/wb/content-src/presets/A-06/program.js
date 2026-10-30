// Two mutually recursive functions, a reporter that uses them, and one function nobody calls.
function isEven(n) { return n === 0 ? true : isOdd(n - 1); }
function isOdd(n) { return n === 0 ? false : isEven(n - 1); }
function report(n) { return n + (isEven(n) ? " is even" : " is odd"); }
function unused() { return report(1); }
print(report(7));
