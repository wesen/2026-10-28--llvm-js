// B-04: a loop with a try inside, to read the Stage by. Compile with every default;
// the header runs it in plan mode with GC stress so the path and root overlays have data.
const program = g.compile(g.pipeline(), source('program.js'));
return program;
