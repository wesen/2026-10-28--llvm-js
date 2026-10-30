// Compile program.js with the default pipeline and return the Program.
// Change the pipeline here (for example g.pipeline().rewrites(g.rewrites.standard()))
// and rerun to compare what the compiler does with the same source.
const program = g.compile(g.pipeline(), source('program.js'));
return program;
