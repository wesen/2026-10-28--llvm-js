// B-01: the running example, compiled with every default.
// program.js is the source; g.pipeline() is the default pipeline; the result is a Program.
const program = g.compile(g.pipeline(), source('program.js'));
print(program.functions().join(', '));
return program;
