let n=0;
let o={a:4,get x(){n++;return this.a;},set x(v){this.a=v+1;}};
print(o.x,n);o.x=8;print(o.x,n);
let a=[1,2,3];a.push(4);print(a.length,a.join('-'));
print(JSON.stringify({a:o.a,b:'hello'}));
