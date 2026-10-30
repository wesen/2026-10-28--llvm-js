// A scaler: the inner function reads the captured k on every turn of the loop.
function makeScaler(k) {
  return xs => {
    let s = 0;
    for (let i = 0; i < xs.length; i++) s = s + xs[i] * k;
    return s;
  };
}
print(makeScaler(3)([1, 2, 3]));
