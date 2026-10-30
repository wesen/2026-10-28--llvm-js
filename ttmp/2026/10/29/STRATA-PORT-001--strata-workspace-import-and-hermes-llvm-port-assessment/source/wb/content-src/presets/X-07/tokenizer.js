// A tokenizer: one pass over a string, one object per token.
function isDigit(c) { return c >= "0" && c <= "9"; }
function isSpace(c) { return c === " "; }

function tokenize(text) {
  const tokens = [];
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (isSpace(c)) { i = i + 1; continue; }
    if (isDigit(c)) {
      let value = 0;
      while (i < text.length && isDigit(text[i])) {
        value = value * 10 + (text[i] - "0");
        i = i + 1;
      }
      tokens[tokens.length] = { kind: "num", value };
      continue;
    }
    tokens[tokens.length] = { kind: "op", value: c };
    i = i + 1;
  }
  return tokens;
}

const ts = tokenize("12 + 345 * 6");
let line = "";
for (const t of ts) line = line + t.kind + ":" + t.value + " ";
print(line);
print(ts.length + " tokens");
