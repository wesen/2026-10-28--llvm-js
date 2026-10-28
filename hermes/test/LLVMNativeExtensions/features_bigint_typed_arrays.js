const buffer = new ArrayBuffer(24);
const signed = new BigInt64Array(buffer);
const unsigned = new BigUint64Array(buffer);
signed[0] = -1n;
signed[1] = 9223372036854775808n;
signed[2] = 18446744073709551617n;
print(signed.join(","), unsigned.join(","));
unsigned[1] = 18446744073709551614n;
print(signed[1].toString(), unsigned[1].toString());
const view = new DataView(buffer);
view.setBigInt64(0, -1234567890123456789n, true);
print(view.getBigInt64(0, true).toString());
view.setBigUint64(8, 0x0123456789abcdefn, false);
print(view.getBigUint64(8, false).toString(16));
const values = new BigInt64Array([3n, -4n, 2n]);
values.sort();
print(values.join(","), values.map(x => x * 2n).join(","));
print(values.reduce((sum, x) => sum + x, 0n).toString());
try { signed[0] = 1; } catch (e) { print(e.name); }
try { new Uint32Array([1n]); } catch (e) { print(e.name); }
try { signed.set(new Uint32Array([1])); } catch (e) { print(e.name); }
