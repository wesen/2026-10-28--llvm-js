// W-01: WebAssembly by hand. Core IR with only numbers, booleans and direct calls is the
// "core profile"; the Wasm backend encodes it to a real binary (sections, LEB128 numbers,
// one f64 local per value, a dispatch loop over the blocks) and the browser runs it.
const program = g.compile(g.pipeline(), source('program.ir'));

const w = program.wasm();
print(`Wasm module: ${w.bytes.length} bytes, functions ${w.ok.join(', ')}`);
print('first bytes: ' + Array.from(w.bytes.slice(0, 8), b => b.toString(16).padStart(2, '0')).join(' '));

// Run the exported fib directly, and compare with the interpreter.
const viaWasm = program.run({ mode: 'wasm', entry: 'fib', args: [10] });
const viaSpec = program.run({ mode: 'spec', entry: 'fib', args: [10] });
print(`fib(10): wasm ${viaWasm.outcome.value}, spec ${viaSpec.outcome.value}`);
return program;
