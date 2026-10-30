// count is captured by the closure, so it stays a cell; reads of it are cell.load operations.
function report(x) { print("report " + x); }
function makeCounter() {
  let count = 0;
  count = count + 1;
  const first = count;          // right after the store
  print("first " + first);
  const second = count;         // after a print, which cannot write a variable
  report(second);
  const third = count;          // after a call, which might
  return () => { count = count + third; return count; };
}
const next = makeCounter();
print(next(), next());
