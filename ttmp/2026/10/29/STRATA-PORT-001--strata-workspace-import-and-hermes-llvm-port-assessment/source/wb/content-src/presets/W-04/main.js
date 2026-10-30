// W-04: LLVM IR in the shape of the Hermes LLVM backend, for the ledger. The text is
// printed and checked structurally in the page; it is never compiled, because LLVM is not
// in the page. Every number in it comes from the plan at L3.
const program = g.compile(g.pipeline(), source());

const text = program.ir('LLVM');
const defs = text.split('\n').filter(l => l.startsWith('define ')).length;
const decls = text.split('\n').filter(l => l.startsWith('declare ')).length;
print(`module: ${text.split('\n').length} lines, ${defs} functions, ${decls} declarations`);
for (const fn of program.functions()) {
  const p = program.plan(fn);
  print(`${fn}: shllvm_enter(…, i32 ${p.rootSlots + p.fixedSlots}, i32 ${p.argSlots}, …) · structural check ${program.st.llvm[fn].check.ok ? 'ok' : 'failed'}`);
}
return program;
