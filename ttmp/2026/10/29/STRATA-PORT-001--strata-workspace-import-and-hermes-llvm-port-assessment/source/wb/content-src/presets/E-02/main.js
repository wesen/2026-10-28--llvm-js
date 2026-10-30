// E-02: promises and then. A promise's reactions are jobs on the same microtask queue
// as queueMicrotask; then() returns a new promise that its reaction resolves.
const program = g.compile(g.pipeline(), source('program.js'));

// adopt.js: a reaction that returns a promise, against three counting jobs.
const adopt = g.compile(g.pipeline(), source('adopt.js')).run();
print('adopt.js: ' + adopt.output.join(' | '));
return program;
