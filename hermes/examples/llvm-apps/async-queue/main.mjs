import {processJobs} from './queue.mjs';
const config = globalThis.APP_INPUT;
const result = await processJobs(config.jobs, config.concurrency, 3);
print(JSON.stringify({application:'async-queue',...result}));
