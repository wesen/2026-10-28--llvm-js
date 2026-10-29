import {summarize} from './model.mjs';
const rows = JSON.parse(globalThis.APP_INPUT.json);
const result = summarize(rows);
if (result.accepted + result.rejected.length !== rows.length) throw Error('lost records');
print(JSON.stringify({application:'data-pipeline', ...result}));
