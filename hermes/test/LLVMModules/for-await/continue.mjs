let iterations=0;
outer: for await(const value of [1,2]){iterations++;continue outer;}
if(iterations!==2)throw Error('label continue');
