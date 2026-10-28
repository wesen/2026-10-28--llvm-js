function greet(who) { return 'hello ' + who + '!'; }
print(greet('world'), '𝄞'.length, 'é'.charCodeAt(0), '𝄞'.charCodeAt(1));
print('abc'.slice(1), 'a\u0000b'.length, '\uD83D\uDE00'.length);
const o = {}; o['a\u0000b'] = 42; print(o['a\u0000b']);
