// typeof tests refine what the compiler knows about x on each branch.
function label(x) {
  let kind;
  if (typeof x === "number") kind = "number " + x * 2;
  else if (typeof x === "string") kind = "string of " + x.length;
  else kind = "something else";
  return kind;
}
print(label(21));
print(label("abc"));
print(label(null));
