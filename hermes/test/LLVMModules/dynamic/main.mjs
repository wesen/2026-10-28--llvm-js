let conversions = 0;
const specifier = {toString(){conversions++;return './counter.mjs';}};
const first = import(specifier);
if(conversions !== 1) throw Error('specifier conversion timing');
const second = import('./counter.mjs');
if(first === second) throw Error('fresh promises');
const a = await first;
const b = await second;
if(a !== b || a.value !== 1) throw Error('identity');
a.bump();
if(b.value !== 2) throw Error('dynamic live');
const computed = './' + 'counter.mjs';
if((await import(computed)) !== a) throw Error('computed');
let symbolRejected = false;
try { await import(Symbol('bad')); } catch(error) {symbolRejected = error instanceof TypeError;}
if(!symbolRejected) throw Error('symbol');
let missingRejected = false;
try { await import('./absent.mjs'); } catch(error) {missingRejected = true;}
if(!missingRejected) throw Error('missing');
print('dynamic-ok');
if((await import('./counter.mjs',{}))!==a)throw Error('empty options');
if((await import('./counter.mjs',{with:{}}))!==a)throw Error('empty attributes');
let badOptions=false;try{await import('./counter.mjs',1);}catch(e){badOptions=e instanceof TypeError;}
if(!badOptions)throw Error('invalid options');
