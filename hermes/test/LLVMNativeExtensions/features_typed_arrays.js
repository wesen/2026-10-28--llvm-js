function storageAndViews() {
  const buffer = new ArrayBuffer(16);
  const bytes = new Uint8Array(buffer);
  const view = new DataView(buffer);
  view.setUint32(0, 0x12345678, true);
  print(bytes.slice(0, 4).join(","), view.getUint32(0, true), view.getUint32(0, false));
  const sub = bytes.subarray(1, 5);
  sub[0] = 99;
  const copy = bytes.slice(0, 4);
  copy[1] = 7;
  print(bytes[1], copy[1], sub.buffer === buffer, copy.buffer !== buffer);
  bytes.set([1, 2, 3, 4, 5], 0);
  bytes.set(bytes.subarray(0, 4), 1);
  print(bytes.slice(0, 5).join(","));
  print(ArrayBuffer.isView(bytes), ArrayBuffer.isView(view), ArrayBuffer.isView(buffer));
  print(view.byteLength, sub.byteOffset, sub.byteLength, bytes.BYTES_PER_ELEMENT);
}
function conversions() {
  print(new Int8Array([127, 128, -129, 256]).join(","));
  print(new Uint8Array([-1, 256, 257, NaN]).join(","));
  print(new Uint8ClampedArray([-1, 0.5, 1.5, 2.5, 254.5, 300]).join(","));
  print(new Int16Array([32768, -32769]).join(","));
  print(new Uint16Array([-1, 65536]).join(","));
  print(new Int32Array([2147483648, -2147483649]).join(","));
  print(new Uint32Array([-1, 4294967296]).join(","));
  const floats = new Float64Array([-0, Infinity, -Infinity, NaN, 1.25]);
  print(Object.is(floats[0], -0), floats[1], floats[2], Number.isNaN(floats[3]), floats[4]);
  print(new Float32Array([1.5, -2.25]).join(","));
}
function algorithmsAndBounds() {
  const a = new Uint16Array([4, 3, 2, 1]);
  print(a.map(x => x * 2).join(","), a.reduce((sum, x) => sum + x, 0));
  a.sort();
  print(a.join(","), a.slice(1, 3).join(","));
  a[99] = 7;
  a[-1] = 8;
  print(a[99], a[-1], a.length);
  try { new Uint32Array(new ArrayBuffer(7)); } catch (e) { print(e.name); }
  try { new Uint16Array(new ArrayBuffer(8), 1); } catch (e) { print(e.name); }
  try { new DataView(new ArrayBuffer(4)).getUint32(1); } catch (e) { print(e.name); }
  try { a.set([1, 2, 3], 3); } catch (e) { print(e.name); }
}
storageAndViews();
conversions();
algorithmsAndBounds();
