// Independent Node replay of the same source corpus; native lifetime assertions
// remain the responsibility of the embedding host and its collector.
import fs from 'node:fs';
import vm from 'node:vm';
globalThis.print = console.log;
for (const line of fs.readFileSync(process.argv[2], 'utf8').trimEnd().split('\n')) {
  const split = line.indexOf(' '), expected = line.slice(0, split), filename = line.slice(split + 1);
  let script;
  try { script = new vm.Script(fs.readFileSync(filename, 'utf8'), {filename}); }
  catch (error) {
    if (expected === 'parse-error' && error instanceof SyntaxError) continue;
    throw error;
  }
  if (expected === 'parse-error') throw Error('missing parse error');
  let threw = false;
  try { script.runInThisContext(); }
  catch (error) {
    if (expected !== 'execute-error' || error.message !== 'expected-plugin-failure') throw error;
    threw = true;
  }
  if (expected === 'execute-error' && !threw) throw Error('missing execution error');
}
