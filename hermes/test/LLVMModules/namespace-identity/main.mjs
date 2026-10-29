import {same} from './hub.mjs';import * as original from './value.mjs';
if(same!==original)throw Error('namespace identity');print('namespace-identity-ok');
