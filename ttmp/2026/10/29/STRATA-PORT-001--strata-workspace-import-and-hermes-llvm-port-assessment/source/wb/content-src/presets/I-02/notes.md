# Text, JSON and round trips

Core IR has two written forms. The **text form** is what the IR view prints and what a person writes in a `.ir` file; the **JSON form** is what a tool stores or sends. Both describe the same function, and a law checks that printing and parsing give it back unchanged. This preset reads `program.ir`, prints it, encodes it, decodes it and compares hashes, then runs the round-trip law on 200 generated functions.

> **Try it.** [Open program.ir](lab:open?file=program.ir&line=10) and [run it](lab:build): `main` prints `10 0` (15 clamped to 10, and -3 clamped to 0). [The Laws view](lab:law?name=roundTrip%28text%20and%20JSON%29) shows the round-trip law passing.

## The text form

A function is a header, blocks and a closing brace:

```text
fn clamp(x: number, lo: number, hi: number) -> number {
entry:
  below = num.lt(x, lo)
  branch below, out(lo), check(x)
check(y: number):
  above = num.gt(y, hi)
  branch above, out(hi), out(y)
out(r: number):
  return r
}
```

A block header is a name, optional parameters with types, and an optional exceptional exit (`throws unwind`, or `throws to H(args)`). Each following line is an operation (`name = op(args)`, or `op(args)` when there is no result) until the terminator. Operands are value names or literals: numbers, `"strings"`, `true`, `false`, `null`, `undefined`. Attributes go in brackets or after `@`: `core.call(@clamp, 15, 0, 10)` names its callee, `js.new_error[TypeError](msg)` its kind. Comments start with `//` or `;` and are dropped.

The first function of a file is the module's `main`, which is why `main` comes first in `program.ir`: `program.run()` starts there.

## Parsing is strict

The parser accepts what the printer writes and reports anything else with its line:

| text | error |
|---|---|
| an operation after `return v` | `block entry continues after its terminator (line 5)` |
| `num.add(a 1)` | `cannot read operand "a 1" (line 3)` |
| `a: numbr` | `unknown type numbr` |

Parsing does not check meaning: a parsed function can still use a value before it is defined or pass the wrong number of arguments. That is the verifier's job ([I-04](lab:preset?id=I-04)), which the pipeline runs right after the frontend.

## The JSON form

`g.ir.json.encode(fn)` writes the same structure as data: each block has `name`, `params`, `onThrow`, `throwArgs`, `ops` and `term`, and each operation is `{ op, args, result, attrs }`. Literals are written as `{ lit }` objects so that the string `"x"` cannot be confused with the value named `x`. For `clamp` the text is 223 bytes and the JSON 778; the JSON is longer and easier for a program to read without a parser.

## A hash says "the same function"

Every function has a content hash, computed from its JSON form. [Events](lab:show?view=events) shows the hash of `clamp` three times: as parsed, after a JSON round trip, and after printing and parsing again. They agree, so the three are the same function in every respect the compiler can see. The hash is what lets a cache, a diff or a law say "unchanged" without comparing text.

## The law

`g.law.roundTrip({ samples: 200 })` generates 200 random numeric functions with `g.gen.coreIR` (arithmetic, a diamond, a bounded loop, prints), prints and parses each one, encodes and decodes each one, and compares hashes. A printer that dropped a block parameter or a parser that misread a negative literal would fail it, and the report would carry the printed text and the reparsed text side by side.

> **Exercise.** In main.js, encode `clamp` to JSON, change one `"num.gt"` to `"num.ge"` in the JSON string, decode it and print it with `g.ir.text`. Does the hash change? Then add `print(g.ir.text(g.gen.coreIR({ seed: 4 })))` to see what the law generates.

## Where next

[Chapter 3](lab:book?ch=3) gives the grammar of the text form. [I-01](lab:preset?id=I-01) builds IR with the builder instead, and [M-01](lab:preset?id=M-01) runs the engine's laws together.
