let closed=0;
const iterable={ [Symbol.asyncIterator](){return this;},next(){return Promise.resolve({value:4,done:false});},return(){closed++;return Promise.resolve({done:true});} };
outer: for await(const value of iterable){if(value!==4)throw Error('value');break outer;}
if(closed!==1)throw Error('break closing');
