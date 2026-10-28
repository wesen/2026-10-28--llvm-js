function literals() {
  print(typeof 0n, String(0n), String(-1n));
  print(String(123456789012345678901234567890n));
  print(String(0xffffffffffffffffn), String(0o777777777777777777777n), String(0b101010n));
  print(100000000000000000000n === BigInt("100000000000000000000"));
}
function arithmetic(a, b) {
  print(String(a + b), String(a - b), String(a * b));
  print(String(a / b), String(a % b), String((-a) / b), String((-a) % b));
  print(String(a ** 3n), String(~a));
  print(String(a & b), String(a | b), String(a ^ b));
  print(String(a << 67n), String((-a) >> 3n), String(a << -2n));
  let c = a;
  print(String(c++), String(++c), String(c--), String(--c));
  print(a > b, a >= Number(b), 42n == 42, 42n === 42, 42n !== 42n);
  print(BigInt.asIntN(8, 255n).toString(), BigInt.asUintN(8, -1n).toString());
}
function errors() {
  try { print(1n + 1); } catch (e) { print(e.name); }
  try { print(+1n); } catch (e) { print(e.name); }
  try { print(1n >>> 1n); } catch (e) { print(e.name); }
  try { print(1n / 0n); } catch (e) { print(e.name); }
  try { print(2n ** -1n); } catch (e) { print(e.name); }
  try { print(BigInt(1.5)); } catch (e) { print(e.name); }
}
literals();
arithmetic(12345678901234567890n, 7n);
errors();
