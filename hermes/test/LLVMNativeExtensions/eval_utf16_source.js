// SHLLVM_TEST: {"family":"eval","completion":"eval-utf16-source-ok","c_oracle":"skip","c_oracle_reason":"The C direct-eval helper does not provide the local bindings used by the nested eval case."}
function equal(actual, expected, label) {
  if (actual !== expected) throw new Error(label);
}
function direct(source) {'use strict'; return eval(source);}
function sloppyStrictSource(source) {return eval('"use strict"; ' + source);}
const indirect = eval;
const sources = [String.fromCharCode(0xD800), String.fromCharCode(0xDC00),
                 String.fromCharCode(0xD83D, 0xDE00), String.fromCharCode(0, 0x41)];
for (const text of sources) {
  const literal = "'" + text + "'";
  equal(direct(literal), text, 'direct literal units');
  equal(sloppyStrictSource(literal), text, 'strict directive parser units');
  equal(indirect(literal), text, 'indirect literal units');
  equal(Function('return ' + literal)(), text, 'Function body units');
  equal(direct('`' + text + '`'), text, 'template units');
  equal(direct('String.raw`' + text + '`'), text, 'raw template units');
  equal(direct('/' + text + '/').test(text), true, 'regexp units');
}
// A valid surrogate pair must become one source code point for identifier
// classification, rather than two separately encoded surrogate code points.
const identifier = String.fromCodePoint(0x10400);
equal(direct('let ' + identifier + '=23; ' + identifier), 23, 'astral identifier');
const lone = String.fromCharCode(0xD800);
let invalidIdentifier = false;
try { direct('let ' + lone + '=1;'); }
catch (error) {invalidIdentifier = error instanceof SyntaxError;}
equal(invalidIdentifier, true, 'lone surrogate is not identifier');
const dynamic = Function('source', '"use strict"; return eval(source);');
equal(dynamic("'" + lone + "'"), lone, 'bytecode caller units');
function nested() {
  'use strict';
  const source = "'" + lone + "'";
  return eval('() => eval(source)');
}
const closure = nested();
if (typeof gc === 'function') gc();
equal(closure(), lone, 'nested eval units after GC');
print('eval-utf16-source-ok');
