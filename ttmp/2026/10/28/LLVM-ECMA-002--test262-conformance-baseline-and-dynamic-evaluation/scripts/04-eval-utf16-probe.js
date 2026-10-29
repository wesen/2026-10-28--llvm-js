// Diagnostic probe: compare code units without terminal Unicode rendering.
function readUnit(codeUnit) {
  'use strict';
  const source = "'" + String.fromCharCode(codeUnit) + "'";
  return eval(source).charCodeAt(0);
}
for (const codeUnit of [0x41, 0xD800, 0xDC00]) {
  print(codeUnit, readUnit(codeUnit));
}
