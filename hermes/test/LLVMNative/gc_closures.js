function make() {
  let state = {n: 1, words: ['alive', 'after', 'collection']};
  return () => { state.n += 1; return state; };
}
const kept = make();
const roots = [];
for (let i = 0; i < 50000; ++i) {
  const o = {i, text: 'garbage-' + i, list: [i, i + 1, i + 2]};
  o.self = o;
  if (i % 5000 === 0) roots.push(() => o.i);
}
print('gc-hook', typeof gc);
gc();
print(kept().n, kept().words.join(' '), roots.map(f => f()).join(','));
