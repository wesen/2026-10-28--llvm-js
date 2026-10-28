// SHLLVM_TEST: {"family":"function", "completion":"function-source-boundaries-ok"}
function equal(actual, expected, label) {
  if (actual !== expected) throw new Error(label + ': ' + actual);
}
const stringify = Function.prototype.toString;
function original(a, b) { return a + b; }
Object.defineProperty(original, 'name', {get() {throw new Error('name observed');}});
Object.defineProperty(original, 'length', {get() {throw new Error('length observed');}});
equal(typeof stringify.call(original), 'string', 'ordinary source');
const bound = (function target() {}).bind(null);
Object.defineProperty(bound, 'name', {get() {throw new Error('bound name observed');}});
equal(/\[native code\]/.test(stringify.call(bound)), true, 'bound source');
const proxy = new Proxy(function () {}, {get() {throw new Error('proxy get');}});
equal(/\[native code\]/.test(stringify.call(proxy)), true, 'proxy source');
const revocable = Proxy.revocable(function () {}, {});
revocable.revoke();
equal(/\[native code\]/.test(stringify.call(revocable.proxy)), true, 'revoked proxy');
const ordinary = Function('a // trailing parameter comment', 'return a; // trailing body comment');
equal(ordinary(17), 17, 'Function comment boundary');
equal(typeof stringify.call(ordinary), 'string', 'dynamic source');
const GeneratorFunction = (function* () {}).constructor;
const generator = GeneratorFunction('a // trailing parameter comment', 'yield a; // trailing body comment');
equal(generator(18).next().value, 18, 'GeneratorFunction boundary');
const AsyncFunction = (async function () {}).constructor;
const asynchronous = AsyncFunction('a // trailing parameter comment', 'return a; // trailing body comment');
asynchronous(19).then(function (value) {
  equal(value, 19, 'AsyncFunction boundary');
  print('function-source-boundaries-ok');
});
