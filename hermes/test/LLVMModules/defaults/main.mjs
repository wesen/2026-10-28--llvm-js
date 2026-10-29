import Own from './static-name.mjs';
if(Own.name()!=='own')throw Error('own static name');
import f from './function.mjs';
import C from './class.mjs';
import a from './arrow.mjs';
if(f.name!=='default'||C.name!=='default'||a.name!=='default')throw Error('default names');
if(f()!==1||C.value!==2||a()!==3)throw Error('default values');
print('defaults-ok');
