// L-04: a plan with a hole. The 'none' strategy assigns no root slots at all, and the
// plan checker reports every value that a safepoint needs and does not get. The program
// does not compile: the errors are the point. Change 'none' to 'stackReuse' to compare.
const program = g.compile(g.pipeline().roots('none'), source());

for (const fn of program.functions()) {
  for (const m of program.plan(fn).missing) print(`${m.at} ${m.op}: ${m.value} is ${m.how} it (${m.why})`);
}
return program;
