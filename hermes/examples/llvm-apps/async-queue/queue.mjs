const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
export async function processJobs(jobs, concurrency, maxAttempts) {
  let cursor = 0, active = 0, peak = 0, cleaned = 0;
  const results = [], attempts = new Map();
  async function execute(job) {
    const token = {cancelled: job.cancelBefore};
    if (token.cancelled) return {id:job.id,status:'cancelled',attempts:0};
    active++; peak = Math.max(peak, active);
    try {
      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        attempts.set(job.id, attempt);
        try {
          await sleep(job.delay);
          if (job.cancelDuring) token.cancelled = true;
          if (token.cancelled) return {id:job.id,status:'cancelled',attempts:attempt};
          if (job.permanent || (job.transient && attempt === 1)) throw Error('work failed');
          const value = await Promise.resolve(job.payload * 3 + 1);
          return {id:job.id,status:'completed',attempts:attempt,value};
        } catch (error) {
          if (attempt === maxAttempts) return {id:job.id,status:'failed',attempts:attempt};
          await sleep(0);
        }
      }
    } finally { active--; cleaned++; }
  }
  async function worker() {
    while (cursor < jobs.length) {
      const job = jobs[cursor++];
      results.push(await execute(job));
    }
  }
  await Promise.all(Array.from({length:concurrency}, () => worker()));
  results.sort((a,b)=>a.id-b.id);
  if (active !== 0 || peak > concurrency || results.length !== jobs.length) throw Error('queue invariant');
  return {results,peak,cleaned,attempts:[...attempts.entries()].sort((a,b)=>a[0]-b[0])};
}
