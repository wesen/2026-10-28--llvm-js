// W-06: try/catch in the LLVM text. readBoth has two protected regions. The setjmp
// protocol saves one jump buffer per function; a volatile try_state records which region
// is current, and catch.dispatch switches on it after a long jump.
const program = g.compile(g.pipeline(), source());

const text = program.ir('LLVM', { fn: 'readBoth' });
for (const line of text.split('\n')) if (/try_state|_setjmp|switch|label %h\./.test(line)) print(line.trim());
return program;
