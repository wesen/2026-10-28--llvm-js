for (const file of ['./bad-link.mjs','./bad-star.mjs','./tdz-a.mjs','./reject.mjs','./syntax.mjs']) {
 let first, second;
 try {await import(file);} catch(error){first=error;}
 try {await import(file);} catch(error){second=error;}
 if(!first || !second || (file !== './syntax.mjs' && first !== second)) throw Error('cached error: '+file);
 print(file, first.name);
}
print('errors-ok');
if((await import('./value.mjs')).value!==1)throw Error('failed linking poisoned valid dependency');
