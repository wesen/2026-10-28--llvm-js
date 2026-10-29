if(import.meta !== import.meta || Object.getPrototypeOf(import.meta)!==null)throw Error('meta');
if(!import.meta.url.endsWith('/main.mjs'))throw Error('url');
if(typeof arguments!=='undefined')throw Error('arguments leak');
let caught=false;try{arguments;}catch(e){caught=e instanceof ReferenceError;}
if(!caught)throw Error('arguments reference');
const arrow=()=>typeof arguments;
if(arrow()!=='undefined')throw Error('arrow arguments');
function ordinary(){return arguments[0];}
if(ordinary(42)!==42)throw Error('ordinary arguments');
print('meta-ok');
