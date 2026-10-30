// W-05: closures and calls in the LLVM text. A closure is a function index plus the cells
// it captures; a call passes its arguments through the caller's outgoing area, argv.
const program = g.compile(g.pipeline(), source());

for (const fn of program.functions()) {
  const text = program.ir('LLVM', { fn });
  const closures = (text.match(/call void @shllvm_closure/g) || []).length;
  const calls = (text.match(/call void @shllvm_call/g) || []).length;
  print(`${fn}: ${closures} closures, ${calls} calls, argv of ${program.plan(fn).argSlots} slots`);
}
return program;
