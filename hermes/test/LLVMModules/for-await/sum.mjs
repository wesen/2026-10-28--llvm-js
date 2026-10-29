let total=0;
for await(const value of [Promise.resolve(1),2,3])total+=value;
if(total!==6)throw Error('async from sync');
