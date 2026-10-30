let a=0,b=1;
for(let i=0;i<12;i++){let next=a+b;a=b;b=next;}
print(a,b);
let n=5, sum=0;
while(n>0){sum+=n;n--;}
print(sum, true && 4, false || 7, null ?? 9);
