function total(n) {
  let s = 0;
  for (let i = 0; i < n; i++) {
    const box = { v: s + i };
    const spare = { v: i + 1 };
    s = box.v;
  }
  return s;
}
print(total(4));
