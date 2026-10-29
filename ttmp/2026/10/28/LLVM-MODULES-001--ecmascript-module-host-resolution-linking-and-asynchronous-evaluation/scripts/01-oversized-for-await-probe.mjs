let total=0;
for await (const value of [Promise.resolve(1),2,3]) { total+=value; }
if(total!==6)throw Error('async from sync');
let closed=0;
const iterable={ [Symbol.asyncIterator](){return this;}, next(){return Promise.resolve({value:4,done:false});}, return(){closed++;return Promise.resolve({done:true});} };
outer: for await(const value of iterable){ if(value!==4)throw Error('async value'); break outer; }
if(closed!==1)throw Error('break closing');
const sentinel={};
try {for await(const value of iterable){throw sentinel;}}catch(error){if(error!==sentinel)throw Error('throw preserved');}
if(closed!==2)throw Error('throw closing');
const bad={ [Symbol.asyncIterator](){return this;}, next(){throw sentinel;}, return(){throw Error('must not close');} };
try {for await(const value of bad){}}catch(error){if(error!==sentinel)throw Error('next throw');}
let iterations=0;
outer: for await(const value of [1,2]){iterations++;continue outer;}
if(iterations!==2)throw Error('label continue');
let captured=[];
for await(const value of [1,2])captured.push(()=>value);
if(captured[0]()!==1||captured[1]()!==2)throw Error('iteration bindings');
print('for-await-ok');
