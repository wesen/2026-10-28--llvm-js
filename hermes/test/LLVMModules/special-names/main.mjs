import * as ns from './value.mjs';
if(ns.__proto__!==1||ns['10']!==1)throw Error('special names');
if(Object.keys(ns).join(',')!=='10,2,__proto__,change')throw Error('namespace order');
ns.change();if(ns.__proto__!==2)throw Error('special live binding');
print('special-names-ok');
