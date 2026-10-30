// Pairs of programs that print the same text. Which pairs behave the same?
const zero = 0 * -1;           // -0
print(zero, 0 / 0);            // prints "0 NaN"
const a = {};
print(a, a);                   // one object, twice
