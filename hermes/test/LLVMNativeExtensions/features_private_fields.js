class Counter {
  #value;
  #twice() { return this.#value * 2; }
  static #created = 0;
  constructor(value) {
    this.#value = value;
    Counter.#created++;
  }
  get #adjusted() { return this.#value + 1; }
  set #adjusted(n) { this.#value = n - 1; }
  read() { return this.#value; }
  add(n) { this.#value += n; return this.#twice(); }
  adjusted(n) { this.#adjusted = n; return this.#adjusted; }
  reader() { return () => this.#value; }
  has(other) { return #value in other; }
  static count() { return Counter.#created; }
}
class Child extends Counter {
  #value = 100;
  both() { return this.read() + this.#value; }
}
function independentBrands() {
  class A { #x = "a"; read(other) { return other.#x; } }
  class B { #x = "b"; }
  const a = new A();
  print(a.read(a));
  try { print(a.read(new B())); } catch (e) { print(e.name); }
}
function duplicateInstallation() {
  class ReturnObject { constructor(object) { return object; } }
  class Stamp extends ReturnObject {
    #x = 17;
    static read(object) { return object.#x; }
  }
  const object = Object.preventExtensions({});
  new Stamp(object);
  print(Stamp.read(object), Object.getOwnPropertyNames(object).length);
  try { new Stamp(object); } catch (e) { print(e.name); }
}
const a = new Counter(10), b = new Counter(90), c = new Child(5);
const readLater = a.reader();
print(a.add(3), a.read(), b.read(), c.both(), Counter.count());
print(a.adjusted(31), a.read(), readLater());
print(a.has(a), a.has(c), a.has({}), Object.keys(a).length);
try { Counter.prototype.read.call({}); } catch (e) { print(e.name); }
try { a.has(42); } catch (e) { print(e.name); }
independentBrands();
duplicateInstallation();
