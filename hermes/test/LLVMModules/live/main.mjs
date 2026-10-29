import receiver, {count, increment} from './counter.mjs';
import * as ns from './counter.mjs';
if (count !== 1 || ns.count !== 1) throw Error('initial count');
increment();
if (count !== 2 || ns.count !== 2) throw Error('live count');
if (receiver() !== undefined) throw Error('import receiver');
if (Object.getPrototypeOf(ns) !== null || Object.isExtensible(ns)) throw Error('namespace shape');
if (Object.prototype.toString.call(ns) !== '[object Module]') throw Error('namespace tag');
const descriptor = Object.getOwnPropertyDescriptor(ns, 'count');
if (descriptor.value !== 2 || !descriptor.writable || descriptor.configurable || !descriptor.enumerable) throw Error('descriptor');
let threw = false;
try { ns.count = 9; } catch (error) { threw = error instanceof TypeError; }
if (!threw || count !== 2) throw Error('namespace mutation');
if (Reflect.defineProperty(ns, 'count', {value: 2}) !== true) throw Error('same value definition');
if (Reflect.defineProperty(ns, 'count', {value: 3}) !== false) throw Error('new value definition');
function shadow(count) { return count; }
if (shadow(17) !== 17 || this !== undefined || (() => this)() !== undefined) throw Error('scope');
print('live-ok');
