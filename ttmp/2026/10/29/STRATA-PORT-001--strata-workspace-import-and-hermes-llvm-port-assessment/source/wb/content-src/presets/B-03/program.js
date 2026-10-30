// x² + 2x + 3 by Horner's rule, one coefficient per turn of the loop.
function poly(x) {
  let acc = 0;
  for (let i = 1; i <= 3; i++) acc = acc * x + i;
  return acc;
}

print(poly(2));
