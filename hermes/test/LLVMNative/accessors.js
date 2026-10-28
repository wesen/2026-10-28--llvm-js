let trace = '';
const o = {
  _x: 10,
  get x() { trace += 'g'; return this._x; },
  set x(v) { trace += 's'; this._x = v; },
  add(v) { this.x = this.x + v; return this.x; }
};
print(o.add(32), trace, o._x);
Object.defineProperty(o, 'hidden', {value: 8, enumerable: false});
print(o.hidden, Object.keys(o).join(','));
