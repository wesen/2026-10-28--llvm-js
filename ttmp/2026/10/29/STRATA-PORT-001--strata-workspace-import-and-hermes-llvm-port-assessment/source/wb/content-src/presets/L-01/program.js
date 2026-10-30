// Areas of boxes: property reads, arithmetic, a call.
function area(box) {
  return box.w * box.h;
}

function scale(n) {
  return n * 2 + 1;
}

const box = { w: 3, h: 4 };
print(area(box) + scale(5));
