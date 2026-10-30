// Six small functions, each with a different behaviour summary.
function add(a, b) { return a + b; }          // + may call valueOf: user code
function same(a, b) { return a === b; }       // === never calls user code
function make() { return { n: 1 }; }          // allocates a fresh object
function read(o) { return o.n; }              // a property read may run a getter
let count = 0;
function reset() { count = 0; }               // writes a cell that main shares
function bump() { count = count + 1; }        // a cell, and + on a value of unknown type

print(add(1, 2), same(1, 1), read(make()));
bump();
reset();
print(count);
