const sentinel={};let closed=0;
const iterable={ [Symbol.asyncIterator](){return this;},next(){return {value:4,done:false};},return(){closed++;throw Error('ignored cleanup error');} };
try{for await(const value of iterable){throw sentinel;}}catch(error){if(error!==sentinel)throw Error('throw preserved');}
if(closed!==1)throw Error('throw closing');
