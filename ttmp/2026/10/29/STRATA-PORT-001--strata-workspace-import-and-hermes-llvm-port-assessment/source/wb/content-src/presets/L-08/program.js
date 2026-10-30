// A read that may throw, inside try, with an object made before the try and used in catch.
function risky(o) {
  const box = { v: 1 };
  try {
    return o.x + box.v;
  } catch (e) {
    print("caught " + e.message + " " + box.v);
    return -1;
  }
}

print(risky({ x: 1 }));
print(risky({ get x() { throw new Error("no x"); } }));
