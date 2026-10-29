import {read} from './b.mjs';
export let state = 'initial';
export function get(){ return state; }
print('a-start');
await Promise.resolve();
state='ready';
print('a-end',read());
