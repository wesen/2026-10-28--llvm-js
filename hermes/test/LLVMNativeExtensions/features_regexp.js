// Literal creation must bypass a user-replaced global RegExp constructor.
function literals() {
  const nativeRegExp = RegExp;
  globalThis.RegExp = function () { throw new Error("wrong constructor"); };
  const literal = /hello/i;
  globalThis.RegExp = nativeRegExp;
  print(literal.test("HeLLo"), literal.source, literal.flags);
}
function captureAndState() {
  const re = /([a-z]+)-(\d+)/gi;
  const first = re.exec("One-12 TWO-34");
  print(first[0], first[1], first[2], first.index, re.lastIndex);
  const second = re.exec("One-12 TWO-34");
  print(second[0], second[1], second[2], second.index, re.lastIndex);
  print(re.exec("One-12 TWO-34"), re.lastIndex);
  const sticky = /a/y;
  sticky.lastIndex = 1;
  print(sticky.test("ba"), sticky.lastIndex);
  print(sticky.test("ba"), sticky.lastIndex);
}
function literalIdentity() {
  const list = [];
  for (let i = 0; i < 3; ++i) list.push(/x/g);
  list[0].lastIndex = 8;
  print(list[0] !== list[1], list[1] !== list[2], list[1].lastIndex);
}
function unicodeAndReplacement() {
  print(/^.$/u.test("\uD83D\uDE80"), /^.$/.test("\uD83D\uDE80"));
  print(/a.b/s.test("a\nb"), /^b/m.test("a\nb"));
  const named = /(?<word>[a-z]+):(?<digits>\d+)/;
  const match = named.exec("item:2048");
  print(match.groups.word, match.groups.digits);
  print("a1 b2".replace(/([a-z])(\d)/g, (_, a, b) => a.toUpperCase() + (+b + 1)));
  print("one,two;three".split(/[,;]/).join("|"));
  try { new RegExp("["); } catch (e) { print(e.name); }
  try { new RegExp("a", "gg"); } catch (e) { print(e.name); }
}
literals();
captureAndState();
literalIdentity();
unicodeAndReplacement();
