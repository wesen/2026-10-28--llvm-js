// I-02: text, JSON and round trips. Core IR has a text form (what the IR view prints) and a JSON
// form; parsing what was printed gives the same function back, and a law checks it on many.
const text = files['program.ir'];
const mod = g.ir.parse(text);                       // two functions: a Module
const clamp = mod.fn('clamp');

const printed = g.ir.text(clamp);                   // comments are gone, layout is canonical
const json = g.ir.json.encode(clamp);
const back = g.ir.json.decode(json);
print('text bytes', printed.length, '· JSON bytes', json.length);
print('hash of the parsed function', clamp.hash(), '· after JSON', back.hash(), '· after reprinting', g.ir.parse(printed).hash());

const laws = g.laws([g.law.roundTrip({ samples: 200 })]);
const program = g.compile(g.pipeline(), source('program.ir'));
return { program, laws };
