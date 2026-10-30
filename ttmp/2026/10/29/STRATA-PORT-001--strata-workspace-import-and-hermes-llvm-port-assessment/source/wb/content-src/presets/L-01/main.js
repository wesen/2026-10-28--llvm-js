// L-01: from core IR to the runtime (L2). Every operation is bound to one of three things:
// an inline instruction (num.mul → fmul), a runtime helper (js.get → shllvm_get) or a
// direct call (core.call → @square). The binding keeps the contract's obligations, so L2
// still says which calls may collect and which may throw through setjmp.
//
// scale's parameter is assumed to be a number, so the standard rewrites narrow its
// arithmetic to num.* and those operations lower inline. Delete the assume() and rerun.
const pipe = g.pipeline().assume({ scale: { n: 'number' } }).rewrites(g.rewrites.standard());
const program = g.compile(pipe, source('program.js'));

// A second module in core IR shows the third binding, a direct call.
const direct = g.compile(g.pipeline(), source('direct.ir'));
print(direct.ir('L2'));

return program;
