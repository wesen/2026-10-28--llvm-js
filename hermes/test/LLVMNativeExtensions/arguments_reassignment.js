// SHLLVM_TEST: {"family":"arguments", "completion":"arguments-reassignment-ok"}
function check(value, expected, label) {
  if (value !== expected) throw new Error(label + ': ' + value);
}
function replace(a) {
  const original = arguments;
  check(original[0], 7, 'initial argument');
  arguments = 42;
  check(arguments, 42, 'replacement');
  check(original[0], 7, 'old object retained');
  arguments += 1;
  check(arguments, 43, 'compound assignment');
  arguments++;
  check(arguments, 44, 'update');
  [arguments] = [45];
  check(arguments, 45, 'destructuring');
}
replace(7);
function capture(a) {
  const read = () => arguments;
  const write = value => arguments = value;
  check(read()[0], a, 'arrow initial');
  write('arrow');
  check(arguments, 'arrow', 'arrow write');
  arguments = 'outer';
  check(read(), 'outer', 'arrow read');
  return [read, write];
}
const pair = capture(8);
gc();
pair[1]('escaped');
check(pair[0](), 'escaped', 'escaped arrow cell');
function defaultParameter(value = (arguments = 91)) {
  return arguments;
}
check(defaultParameter(), 91, 'parameter default');
function* generator() {
  arguments = 12;
  yield arguments;
  arguments = 13;
  yield arguments;
}
const g = generator();
check(g.next().value, 12, 'generator first');
gc();
check(g.next().value, 13, 'generator second');
check(Function('arguments = 42; return arguments')(), 42, 'Function body');
function shadow(arguments) {
  arguments = 99;
  return arguments;
}
check(shadow(1), 99, 'parameter shadow');
try {
  Function('"use strict"; arguments = 1;');
  throw new Error('strict assignment accepted');
} catch (e) {
  check(e.constructor, SyntaxError, 'strict syntax');
}
async function asyncReplace() {
  arguments = 100;
  await Promise.resolve();
  gc();
  check(arguments, 100, 'async retained');
  arguments = 101;
  return arguments;
}
asyncReplace().then(function (value) {
  check(value, 101, 'async result');
  print('arguments-reassignment-ok');
});
