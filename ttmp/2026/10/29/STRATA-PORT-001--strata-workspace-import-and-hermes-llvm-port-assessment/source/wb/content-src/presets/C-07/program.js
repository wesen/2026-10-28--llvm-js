// A function with neighbours that can and cannot be swapped.
function step(state, n) {
  const before = state.count;
  const doubled = n * 2;
  const same = n === doubled;
  state.count = before + 1;
  print(same);
  return doubled;
}
print(step({ count: 0 }, 3));
