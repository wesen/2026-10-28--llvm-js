class Base {
  constructor(x) { this.x = x; }
  answer() { return this.x; }
  get value() { return this.x; }
  static label() { return 'base'; }
}
class Derived extends Base {
  constructor(x, delta) { super(x); this.delta = delta; }
  answer() { return super.answer() + this.delta; }
  capture() { return n => this.answer() + n; }
}
const d = new Derived(30, 5);
print(d.answer(), d.value, d.capture()(7), d instanceof Derived, d instanceof Base, Derived.label());
try { Base(1); } catch (e) { print(e.name); }
