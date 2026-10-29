import {seen, call, readA} from './b.mjs';
export var value = 'A';
export function say() { return 'hoisted'; }
if (seen !== undefined || call !== 'hoisted' || readA() !== 'A') throw Error('cycle semantics');
print('cycles-ok');
