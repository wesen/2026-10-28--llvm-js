// Diagnostic probe, not an additional Test262 result.
(0, eval)('var baselineInjectedVar = 9;');
print('configurable', Object.getOwnPropertyDescriptor(globalThis, 'baselineInjectedVar').configurable);
let baselineLexical = 'outside';
try { print('lexical', (0, eval)('baselineLexical')); }
catch (error) { print('lexical-error', error.name); }
(0, eval)('"use strict"; var baselineStrictPrivateVar = 1;');
print('strict-var-visible', typeof baselineStrictPrivateVar);
