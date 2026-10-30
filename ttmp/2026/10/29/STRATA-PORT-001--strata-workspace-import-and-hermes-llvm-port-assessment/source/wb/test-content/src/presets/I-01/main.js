// Test fixture: compile program.js with the default pipeline.
const program = g.compile(g.pipeline(), source());
print('functions:', program.functions());
return program;
