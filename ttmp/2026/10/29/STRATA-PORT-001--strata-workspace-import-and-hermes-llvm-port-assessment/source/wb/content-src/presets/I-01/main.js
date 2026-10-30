// I-01: core IR by hand. g.fn(name, params, result, body) builds a function; the body adds
// blocks, and each block's callback gets a cursor $ and the block's parameters by name.
const { t } = g;

// fib(n): the loop carries i, a and b as block parameters of head.
const fib = g.fn('fib', { n: t.number }, t.number, (f, { n }) => {
  f.entry($ => $.jump(f.to('head', $.const(0), $.const(0), $.const(1))));
  f.block('head', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.branch($.op('num.lt', i, n), f.to('body', i, a, b), f.to('exit', a)));
  f.block('body', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.jump(f.to('head', $.op('num.add', i, $.const(1)), b, $.op('num.add', a, b))));
  f.block('exit', { r: t.number }, ($, { r }) => $.ret(r));
});

// choose(c): a branch and a merge; the merge receives the chosen value as a parameter.
const choose = g.fn('choose', { c: t.boolean }, t.number, (f, { c }) => {
  f.entry($ => $.branch(c, f.to('left'), f.to('right')));
  f.block('left', {}, $ => $.jump(f.to('join', $.const(10))));
  f.block('right', {}, $ => $.jump(f.to('join', $.const(20))));
  f.block('join', { v: t.number }, ($, { v }) => $.ret(v));
});

// main calls both directly and prints the results. A call may throw (the verifier cannot see
// into the callee), so the block must say where a throw goes: here, out of main ('unwind').
const main = g.fn('main', {}, t.number, f => {
  f.entry($ => {
    const x = $.call('fib', $.const(10));
    const y = $.call('choose', $.const(false));
    $.op('host.print', x, y);
    $.ret(x);
  }, { onThrow: 'unwind' });
});

print(g.verify(fib).ok ? 'fib verifies' : g.verify(fib).diagnostics);
const program = g.compile(g.pipeline(), g.module(main, fib, choose));
return program;
