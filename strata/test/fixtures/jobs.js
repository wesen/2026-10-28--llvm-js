let n=0;
queueMicrotask(()=>{n++;print('micro',n);});
Promise.resolve(3).then(x=>{print('promise',x);return x+1;}).then(x=>print('next',x));
setTimeout(()=>print('timer',n),0);
print('sync');
