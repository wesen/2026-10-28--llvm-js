// A small program for a pipeline to work on.
function area(w, h) { return w * h; }
const sizes = [[2, 3], [4, 5]];
let total = 0;
for (const s of sizes) total = total + area(s[0], s[1]);
print(total);
