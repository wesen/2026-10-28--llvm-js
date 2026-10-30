// I-10: try, catch and finally lowered. Every way out of the protected region becomes a
// completion record (normal, return or throw); finally runs once, then the record says where to go.
const program = g.compile(g.pipeline(), source('program.js'));

const kinds = ['completion.normal', 'completion.return', 'completion.throw', 'completion.is', 'completion.value'];
for (const k of kinds) print(k, program.find(s => s.op === k).map(s => s.id).join(', '));
return program;
