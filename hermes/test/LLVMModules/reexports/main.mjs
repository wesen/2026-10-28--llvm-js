import * as ns from './hub.mjs';
import {value, bump, other} from './hub.mjs';
if(value!==1 || ns.value!==1 || other.value!==1)throw Error('reexport');
bump();
if(value!==2 || ns.value!==2 || other.value!==2)throw Error('reexport live');
if('default' in ns)throw Error('star default');
print('reexports-ok', Object.keys(ns).join(','));
