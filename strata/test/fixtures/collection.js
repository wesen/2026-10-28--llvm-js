const holder={value:11};
function capture(){let value={n:3};return ()=>{gc();value.n++;return value.n;};}
const f=capture();gc();print(holder.value,f(),f());
let saved;
try{let object={n:17};saved=()=>object.n;gc();throw object;}catch(e){gc();print(e.n,saved());}
queueMicrotask(()=>{gc();print(holder.value,saved());});
