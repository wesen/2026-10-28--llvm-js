// Objects and closures, all synchronous.
const point = { x: 3, y: 4, norm2() { return this.x * this.x + this.y * this.y; } };
print(point.norm2());
