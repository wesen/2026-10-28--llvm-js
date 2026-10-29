const original=Promise.prototype.then;
Promise.prototype.then=function(){throw Error('public then was called by module host');};
await 0;
Promise.prototype.then=original;
const module=await import('./value.mjs');
if(module.value!==7)throw Error('dynamic value');
Promise.prototype.then=original;
print('intrinsic-jobs-ok');
