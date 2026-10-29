// SHLLVM_TEST: {"family":"objects","completion":"proxy-integrity-ok"}
function check(value, message) { if (!value) throw new Error(message); }
const target = {value: 1};
const trace = [];
const proxy = new Proxy(target, {
  preventExtensions(object) { trace.push('prevent'); return Reflect.preventExtensions(object); },
  ownKeys(object) { trace.push('keys'); return Reflect.ownKeys(object); },
  getOwnPropertyDescriptor(object, key) { trace.push('get'); return Reflect.getOwnPropertyDescriptor(object, key); },
  defineProperty(object, key, descriptor) { trace.push('define'); return Reflect.defineProperty(object, key, descriptor); }
});
Object.freeze(proxy);
check(trace.join(',') === 'prevent,keys,get,define', 'freeze trap order');
check(Object.isFrozen(target) && Object.isFrozen(proxy), 'target and proxy frozen');
check(Object.isSealed(proxy), 'frozen implies sealed');
const rejecting = new Proxy(Object.preventExtensions({x: 1}), {defineProperty(){return false;}});
let threw = false;
try {Object.freeze(rejecting);} catch(error) {threw = error instanceof TypeError;}
check(threw && !Object.isFrozen(rejecting), 'failed freeze remains writable');
const sealed = new Proxy({x: 1}, {});
Object.seal(sealed);
check(Object.isSealed(sealed) && !Object.isFrozen(sealed), 'seal without freeze');
const sentinel = {};
const abrupt = new Proxy({}, {preventExtensions(){throw sentinel;}});
try {Object.freeze(abrupt); throw Error('missing throw');} catch(error) {check(error === sentinel, 'trap error preserved');}
const indexed = Object.preventExtensions(Object.defineProperty({}, '10', {value: 1, configurable: false}));
const indexedProxy = new Proxy(indexed, {ownKeys(){return ['10'];}});
check(Reflect.ownKeys(indexedProxy).join(',') === '10', 'numeric target key invariant');
print('proxy-integrity-ok');
