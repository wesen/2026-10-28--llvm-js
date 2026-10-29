// SHLLVM_TEST: {"family":"eval","completion":"strict-source-eval-ok","c_oracle":"skip","c_oracle_reason":"The inherited C direct-eval helper lacks caller-environment semantics."}
function equal(actual, expected, label) {
  if (actual !== expected) throw new Error(label + ': ' + actual);
}
function sloppy(value) {
  let local = value;
  equal(eval('/* before directive */ "other"; "use strict"; local += 2; local'), value + 2, 'shared mutation');
  equal(local, value + 2, 'native read');
  eval('"use strict"; var introduced = 99;');
  equal(typeof introduced, 'undefined', 'no declaration leak');
  equal(eval('"use strict"; arguments[0]'), value, 'arguments');
  equal(eval('"use strict"; this'), this, 'receiver');
  const read = () => local;
  const write = eval('"use strict"; () => ++local');
  return [read, write];
}
const pair = sloppy.call({tag: 7}, 10);
if (typeof gc === 'function') gc();
equal(pair[1](), 13, 'escaped write');
equal(pair[0](), 13, 'native shared read');
function Constructor() {
  equal(eval('"use strict"; new.target'), Constructor, 'new.target');
  const arrow = () => eval('"use strict"; new.target');
  equal(arrow(), Constructor, 'arrow new.target');
}
new Constructor();
let globalRejected = false;
try { eval('"use strict"; new.target'); } catch (e) {globalRejected = e instanceof SyntaxError;}
equal(globalRejected, true, 'global new.target rejected');
const object = {};
equal(eval(object), object, 'non-string identity');
equal(eval(17), 17, 'non-string primitive');
const dynamic = Function('value', 'return eval(\'"use strict"; value + 3\');');
equal(dynamic(20), 23, 'bytecode sloppy caller');
const nested = Function('let n = 4; return eval(\'"use strict"; () => eval("++n")\');')();
if (typeof gc === 'function') gc();
equal(nested(), 5, 'nested bytecode and retained environment');
function strictErrors() {
  const fixed = 1;
  let rejected = false;
  try { eval('"use strict"; fixed = 2'); } catch (e) { rejected = e instanceof TypeError; }
  equal(rejected, true, 'const runtime error');
  rejected = false;
  try { eval('"use strict"; later'); } catch (e) { rejected = e instanceof ReferenceError; }
  let later = 1;
  equal(rejected, true, 'TDZ runtime error');
}
strictErrors();
print('strict-source-eval-ok');
