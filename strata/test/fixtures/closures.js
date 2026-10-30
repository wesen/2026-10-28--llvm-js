function counter(start){let n=start; return {inc:()=>++n,read:()=>n};}
let c=counter(10);print(c.inc(),c.read(),c.inc());
function fib(n){if(n<2)return n;return fib(n-1)+fib(n-2);}
print(fib(10));
let a=[];for(let i=0;i<3;i++){a[i]=()=>i;}print(a[0](),a[1](),a[2]());
