// wide(8), as main.js generates it: eight objects, all live until the sum.
function wide() {
  const o0 = { i: 0 };
  const o1 = { i: 1 };
  const o2 = { i: 2 };
  const o3 = { i: 3 };
  const o4 = { i: 4 };
  const o5 = { i: 5 };
  const o6 = { i: 6 };
  const o7 = { i: 7 };
  let sum = 0;
  sum = sum + o0.i;
  sum = sum + o1.i;
  sum = sum + o2.i;
  sum = sum + o3.i;
  sum = sum + o4.i;
  sum = sum + o5.i;
  sum = sum + o6.i;
  sum = sum + o7.i;
  return sum;
}
print(wide());
