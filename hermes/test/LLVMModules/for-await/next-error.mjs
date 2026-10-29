const sentinel={};
const bad={ [Symbol.asyncIterator](){return this;},next(){throw sentinel;},return(){throw Error('must not close');} };
try{for await(const value of bad){}}catch(error){if(error!==sentinel)throw Error('next throw');}
