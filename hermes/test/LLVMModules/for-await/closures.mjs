const captured=[];
for await(const value of [1,2])captured.push(()=>value);
if(captured[0]()!==1||captured[1]()!==2)throw Error('iteration bindings');
