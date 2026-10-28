function inspect(a, b) { return arguments.length + ':' + arguments[0] + ':' + arguments[2]; }
function total() { let n = 0; for (let i = 0; i < arguments.length; ++i) n += arguments[i]; return n; }
function capture() { return () => arguments[0] + arguments[1]; }
print(inspect(7, 8, 9), total(1, 2, 3, 4, 32), capture(19, 23)());
