import {value} from './base.mjs';
print('a-start');
await Promise.resolve();
print('a-end');
export const a = value + 1;
