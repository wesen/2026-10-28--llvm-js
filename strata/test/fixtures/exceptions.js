let cell={n:0};let o={get x(){cell.n++;throw cell;}};
try{o.x;}catch(e){print(e===cell,cell.n);}
try{try{throw 'a';}catch(e){print(e);throw 'b';}}catch(e){print(e);}
function f(x){try{if(x)throw 'bad';return 42;}finally{print('cleanup');}}
print(f(false));try{f(true);}catch(e){print(e);}
function g(){try{return 1;}finally{return 2;}}print(g());
try{throw new Error('oops');}catch(e){print(e.name,e.message);}
