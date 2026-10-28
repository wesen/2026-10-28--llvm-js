function Point(x, y) { this.x = x; this.y = y; }
Point.prototype.sum = function () { return this.x + this.y; };
const p = new Point(19, 23);
print(p.sum(), p instanceof Point, p.constructor === Point);
function Factory() { this.ignored = true; return {answer: 42}; }
function Primitive() { this.answer = 41; return 99; }
print(new Factory().answer, new Primitive().answer);
function inspect() { return new.target === inspect; }
print(inspect(), new inspect() instanceof inspect);
