// SHLLVM_TEST: {"family":"error-timing", "completion":"language-error-timing-ok", "c_oracle":"record-only", "c_oracle_reason":"Inherited C frontend defaults reject these runtime errors; LLVM now enables compliance error timing by default."}
function checkError(fn, type, label) {
  try { fn(); } catch (e) {
    if (e.constructor !== type) throw new Error(label + ': ' + e);
    return;
  }
  throw new Error(label + ': no exception');
}
checkError(function () { const x = 1; x = 2; }, TypeError, 'const');
checkError(function () { const x = 1; x++; }, TypeError, 'const update');
checkError(function () { print(x); let x = 1; }, ReferenceError, 'TDZ read');
checkError(function () { x = 2; let x = 1; }, ReferenceError, 'TDZ write');
function neverCalled() { const x = 1; x = 2; }
class PrivateGetter {
  get #x() { return 1; }
  write() { this.#x = 2; }
}
checkError(function () { new PrivateGetter().write(); }, TypeError, 'private getter');
class PrivateSetter {
  set #x(value) {}
  read() { return this.#x; }
}
checkError(function () { new PrivateSetter().read(); }, TypeError, 'private setter');
class PrivateMethod {
  #x() {}
  write() { this.#x = 2; }
}
checkError(function () { new PrivateMethod().write(); }, TypeError, 'private method');
class Base { method() {} }
class Child extends Base {
  remove() { return delete super.method; }
}
checkError(function () { new Child().remove(); }, ReferenceError, 'delete super');
print('language-error-timing-ok');
