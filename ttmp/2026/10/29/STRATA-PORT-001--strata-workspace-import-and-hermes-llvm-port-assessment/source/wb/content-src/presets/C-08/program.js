// A property read and an addition inside try: both may throw through a helper.
function f(o) {
  try {
    return o.x + 1;
  } catch (e) {
    return 0;
  }
}
print(f({ x: 1 }), f(null));
