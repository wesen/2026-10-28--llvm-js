import {get} from './main.mjs';
print('b-start');
await Promise.resolve();
print('b-end');
export function read(){return get();}
