// W-03: reading WAT, and the binary behind it. The Collatz loop has a loop, a diamond that
// joins, a remainder (an import, since Wasm has no f64 remainder) and a boolean (an i32).
const program = g.compile(g.pipeline(), source('program.ir'));
const { bytes } = program.wasm();

// Walk the binary: after the 8-byte header, each section is an id, a LEB128 length, a body.
const names = { 1: 'type', 2: 'import', 3: 'function', 7: 'export', 10: 'code' };
const rows = [];
let at = 8;
while (at < bytes.length) {
  const id = bytes[at++];
  let size = 0, shift = 0, b;
  do { b = bytes[at++]; size |= (b & 0x7f) << shift; shift += 7; } while (b & 0x80);
  rows.push({ id, section: names[id] || '?', bytes: size, startsAt: at });
  at += size;
}
const spec = program.run(), wasm = program.run({ mode: 'wasm' });
print(`spec: ${spec.output} in ${spec.steps} interpreter steps; wasm: ${wasm.output}`);
return { program, results: g.table(rows, { title: `Sections of the ${bytes.length}-byte module` }) };
