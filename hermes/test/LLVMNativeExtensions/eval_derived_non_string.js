// SHLLVM_TEST: {"family":"eval","completion":"derived-eval-non-string-ok"}
function equal(actual, expected, label) {
  if (actual !== expected) throw new Error(label);
}
class Base {}
class Derived extends Base {
  constructor(value) {
    equal(eval(), undefined, 'missing argument before super');
    equal(eval(value), value, 'identity before super');
    const captured = () => eval(value);
    equal(captured(), value, 'arrow before super');
    super();
    equal(eval(value), value, 'identity after super');
    this.captured = captured;
  }
}
const sentinel = {toString() {throw new Error('non-string was converted');}};
for (const value of [undefined, null, false, 7, Symbol('x'), 9007199254740993n, sentinel]) {
  const object = new Derived(value);
  if (typeof gc === 'function') gc();
  equal(object.captured(), value, 'escaped arrow identity');
}
class ArgumentThrows extends Base {
  constructor() {
    let caught = false;
    try { eval((() => {throw sentinel;})()); }
    catch (error) {caught = error === sentinel;}
    equal(caught, true, 'argument exception before super');
    super();
  }
}
new ArgumentThrows();
print('derived-eval-non-string-ok');
