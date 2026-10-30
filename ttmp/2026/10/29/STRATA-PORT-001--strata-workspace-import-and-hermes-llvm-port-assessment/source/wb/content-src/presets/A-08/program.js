// Objects that must survive the calls and allocations between their definition and last use.
function describe(user) {
  const name = user.name;                 // a property read: may run a getter, may collect
  const tags = [name, "member"];          // an allocation
  const line = name + ": " + tags.length;
  print(line);
  return tags;
}
const tags = describe({ name: "ada" });
print(tags[1]);
