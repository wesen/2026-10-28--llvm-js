# WebAssembly by hand

The workbench has one backend whose output really runs: WebAssembly. The engine encodes a core IR function into a Wasm binary byte by byte, without a library, hands the bytes to the browser's `WebAssembly.Module`, and compares what the compiled code prints and returns with what the reference interpreter says. This chapter takes that encoder apart. It explains which programs it accepts (the core profile), how SSA values and block parameters become Wasm locals, how an arbitrary control-flow graph becomes structured Wasm control flow through a dispatch loop, and how the module is laid out in sections with LEB128 integers. It closes with the question that connects it to the rest of the book: how a JavaScript function, which is almost never in the core profile, can be brought into it.

## 15.1 The core profile

WebAssembly has numbers and nothing else: 32- and 64-bit integers and floats, locals, a stack, functions and structured control. It has no strings, objects, closures or garbage collector in the version the workbench targets, and no exceptions. So the encoder accepts only functions in the **core profile**: operations on numbers and booleans, direct calls between such functions, and `host.print` of numbers and booleans, with no `throw` and no `invoke`. The check is a walk over the function:

```js
// core.js
function wasmEligible(module, fn, types) {
  for (const b of fn.blocks) {
    for (const o of b.ops) {
      if (WASM_OPS[o.op] || o.op === 'num.mod' || o.op === 'core.copy') continue;
// …
      return `${o.op} in ${b.name} is outside the core profile (numbers, booleans, direct calls)`;
    }
    if (b.term.kind === 'invoke' || b.term.kind === 'throw') return `${b.term.kind} in ${b.name}: Wasm here has no exceptions`;
  }
// …
  for (const v of fn.values()) {
    if (!used.has(v) && fn.params.some(p => p.id === v)) continue;   // an unused parameter (such as `this`) is passed as 0
    const ty = types.typeOf(v); if (!ty.isBottom && !ty.le(t.number.join(t.boolean))) return `${v}: ${ty} is not a number or boolean`;
  }
  return true;
}
```

Every operation must have a Wasm opcode (`WASM_OPS`) or be one of the few handled specially, no block may end in `throw` or `invoke`, and every value must have a type at most `number | boolean`. An unused parameter is exempt, because a function from the JavaScript frontend always has a `this` parameter; it is passed as 0. The answer is either `true` or the first reason the function is refused, which the WAT view prints as a comment.

The ledger is entirely outside: `main` and `makeLedger` start with `cell.new`, `deposit` with `js.typeof`, and the other three with `cell.load_checked`. That is not a defect of the ledger. It uses closures, objects and exceptions, which is what JavaScript programs do, and none of them has a Wasm representation without a runtime. So this chapter uses the book's numeric companion, `fib` from FACTS.md. The shelf doc [WebAssembly in one page](lab:doc?id=wasm) summarises the parts of Wasm the encoder uses.

## 15.2 Values as locals

A Wasm function has numbered locals: its parameters first, then the locals it declares, each with one type. The encoder gives every SSA value of the function its own local, typed `i32` if its facts say boolean and `f64` otherwise, and adds one more `i32` local, `$blk`, used by the dispatch loop below. Block parameters are values like any other, so they are locals too, and an edge `jump for1(b4_1, v12, v17)` becomes a sequence of `local.set`s.

There is a subtlety in that sequence. The edge passes `b4_1` to the parameter `a3_1` and `v12` to `b4_1`: the second assignment reads the old `b4_1`, which the first must not have overwritten. The encoder handles this the way a stack machine makes easy. It pushes every argument first and then pops them into the parameters in reverse order, so all reads happen before any write:

```wasm
        local.get $b4_1
        local.get $v12
        local.get $v17
        local.set $i5_1
        local.set $b4_1
        local.set $a3_1
```

This is the **parallel copy** that SSA destruction always needs at block arguments, and on a stack machine it costs nothing extra. The LLVM printer of [Chapter 16](lab:book?ch=16) does the same thing with loads before stores.

## 15.3 The dispatch loop

Wasm has no `goto`. Its control flow is structured: `block … end` (a branch to it jumps forward to its end), `loop … end` (a branch to it jumps back to its start), `if … else … end`, and `br n`, which leaves the `n` innermost enclosing constructs. A control-flow graph with arbitrary edges, such as a loop whose header is reached from two places, does not map onto that directly. Compilers that care about speed reconstruct loops and ifs from the graph (the Relooper and Stackifier algorithms do this). The workbench uses the simplest construction that works for every graph, a **dispatch loop**: a variable holds the number of the next block, and one `br_table` at the top of a loop jumps to it.

```js
// core.js
    code.push(0x03, 0x40); w.push('  (loop $dispatch');
    for (let k = n - 1; k >= 0; k--) { code.push(0x02, 0x40); w.push(ind(2 + (n - 1 - k)) + `(block $${f.blocks[k].name}`); }
    code.push(0x20, ...leb(blk), 0x0e, ...leb(n), ...f.blocks.flatMap((_, i) => leb(i)), ...leb(n - 1));
```

The bytes are Wasm's own: `0x03 0x40` opens a `loop` with no result, then `n` nested `block`s (`0x02 0x40`) open with the last block of the function outermost and the first innermost. `0x20` is `local.get $blk` and `0x0e` is `br_table`, followed by a vector of `n` targets and a default. Target `i` is branch depth `i`, and leaving block `i` lands right after its `end`, where the encoder places the code of block `i`. So `$blk = i` followed by a branch to the top of the loop runs block `i`.

Each block's code ends with a transfer to the next, written by `goto`:

```js
// core.js
      const goto = (e, depth, extra) => {          // extra: 1 inside an if
        const tb = f.block(e.block);
        e.args.forEach((a, i) => push(a, depth, vt(f, tb.params[i].id)));
// …
        code.push(0x41, ...sleb(bi.get(e.block)), 0x21, ...leb(blk), 0x0c, ...leb(n - 1 - k + extra)); w.push(ind(depth) + `(local.set $blk (i32.const ${bi.get(e.block)}))`, ind(depth) + `br $dispatch`);
      };
```

It pushes the edge's arguments, pops them into the target's parameters as in 15.2, sets `$blk` to the target's index (`0x41` is `i32.const`, `0x21` is `local.set`) and branches (`0x0c` is `br`) to the loop. The depth is the only arithmetic: the code of block `k` sits inside the blocks `k + 1` to `n − 1`, which is $n - 1 - k$ constructs, so the loop is at depth $n - 1 - k$, one more inside an `if`. For `fib`, with five blocks, the code of `next3` (index 3) branches with depth $5 - 1 - 3 = 1$. Figure 15.1 shows the nesting.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 300">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="20" y="14" width="520" height="276" fill="none" stroke="currentColor" class="ink"/>
  <text x="28" y="30" font-size="11" class="b">loop $dispatch</text>
  <rect x="40" y="38" width="490" height="214" fill="none" stroke="currentColor" class="mut"/>
  <text x="48" y="52" font-size="11">block $endfor4</text>
  <rect x="60" y="58" width="460" height="160" fill="none" stroke="currentColor" class="mut"/>
  <text x="68" y="72" font-size="11">block $next3</text>
  <rect x="80" y="78" width="430" height="108" fill="none" stroke="currentColor" class="mut"/>
  <text x="88" y="92" font-size="11">block $body2</text>
  <rect x="100" y="98" width="400" height="62" fill="none" stroke="currentColor" class="mut"/>
  <text x="108" y="112" font-size="11">block $for1</text>
  <rect x="120" y="118" width="370" height="24" class="f-fill2" stroke="currentColor"/>
  <text x="128" y="134" font-size="11">block $entry · br_table $entry $for1 $body2 $next3 $endfor4 ($blk)</text>
  <rect x="100" y="142" width="400" height="0" fill="none" stroke="currentColor"/>
  <text x="108" y="156" font-size="10" class="lbl">code of entry · br depth 4</text>
  <text x="88" y="178" font-size="10" class="lbl">code of for1 · br depth 3 (4 in the if)</text>
  <text x="68" y="206" font-size="10" class="lbl">code of body2 · br depth 2</text>
  <text x="48" y="238" font-size="10" class="lbl">code of next3 · br depth 1</text>
  <text x="28" y="272" font-size="10" class="lbl">code of endfor4 · return</text>
  <path d="M 530 238 L 560 238 L 560 22 L 542 22" fill="none" stroke="currentColor" class="acc" marker-end="url(#arrow)"/>
  <text x="566" y="130" font-size="11" class="acc">br $dispatch</text>
  <text x="566" y="146" font-size="11" class="mut">after $blk := next</text>
</svg>
```

**Figure 15.1.** The dispatch loop of `fib`, from its WAT. Blocks nest with the last outermost; the code of each block follows its `end`; every edge sets `$blk` and branches back to the loop, at a depth that grows towards the inside.

The cost is one indirect jump per edge, which a fast compiler would avoid. The benefit is that the encoder needs no analysis of loops at all and handles any graph the IR can express, including irreducible ones.

## 15.4 Encoding a module by hand

A Wasm binary is a header and a sequence of sections. The header is eight bytes: the four bytes `\0asm` (`00 61 73 6d`) that identify a Wasm module, and the version `01 00 00 00`. Each section is an id byte, its size, and its contents. Sizes and most integers in Wasm are written in **LEB128**: seven bits per byte, low bits first, with the top bit of each byte set when more bytes follow. The encoder's helpers:

```js
// core.js
  const leb = n => { const out = []; do { let b = n & 0x7f; n >>>= 7; if (n) b |= 0x80; out.push(b); } while (n); return out; };
// …
  const section = (id, body) => [id, ...leb(body.length), ...body];
// …
  const bin = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, ...section(1, typeSec), ...section(2, importSec), ...section(3, funcSec), ...section(7, exportSec), ...section(10, codeSec)];
```

`leb` takes the low seven bits, shifts them off, and sets the continuation bit if anything is left. The code section of `fib` is 176 bytes long. Since $176 = 1 \cdot 128 + 48$, its size is two bytes: the low seven bits are $48 = \mathtt{0x30}$, with the continuation bit set that is $\mathtt{0x30} + \mathtt{0x80} = \mathtt{0xb0}$, and the remaining $1$ is the second byte, so the size is written `b0 01`. A signed variant, `sleb`, encodes the operands of `i32.const`, where the sign bit of the last byte matters.

The sections the encoder writes, in the order Wasm requires:

| id | section | holds | fib |
|---|---|---|---|
| 1 | type | one signature per import and per function | 24 B: 5 signatures |
| 2 | import | `env.print_num`, `env.print_bool`, `env.print_end`, `env.fmod` | 61 B |
| 3 | function | the signature index of each function | 2 B |
| 7 | export | each function by name | 7 B |
| 10 | code | locals and instructions of each function | 176 B |

With the header and each section's id and size bytes, that is $8 + 26 + 63 + 4 + 9 + 179 = 289$ bytes, the size FACTS.md reports. The imports come first in the function index space, so `fib` is function 4. Its body starts with its local declarations, eight entries of one local each: `01 7c` (an `f64`) for six of the values, `01 7f` (an `i32`) for the boolean `v8`, and a last `01 7f` for `$blk`. The parameters `this` and `n` are not declared again; they are locals 0 and 1. Figure 15.2 is the byte map.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 170">
  <text x="20" y="22" font-size="10" class="lbl">the 289 bytes of the fib module, to scale</text>
  <rect x="20" y="34" width="18" height="40" class="f-ink" stroke="currentColor"/>
  <rect x="38" y="34" width="59" height="40" class="f-fill2" stroke="currentColor"/>
  <rect x="97" y="34" width="144" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="241" y="34" width="9" height="40" class="f-fill2" stroke="currentColor"/>
  <rect x="250" y="34" width="21" height="40" class="f-fill" stroke="currentColor"/>
  <rect x="271" y="34" width="409" height="40" class="f-sel" stroke="currentColor"/>
  <text x="20" y="92" font-size="10" class="lbl">header 8</text>
  <text x="40" y="108" font-size="10" class="lbl">type 26</text>
  <text x="120" y="92" font-size="10" class="lbl">import 63</text>
  <text x="222" y="108" font-size="10" class="lbl">function 4</text>
  <text x="252" y="124" font-size="10" class="lbl">export 9</text>
  <text x="420" y="92" font-size="10" class="lbl">code 179 (size b0 01 = 176)</text>
  <text x="20" y="150" font-size="11" class="mut">00 61 73 6d 01 00 00 00 · 01 18 05 60 01 7c 00 … · 02 3d 04 03 65 6e 76 … · 03 02 01 04 · 07 07 01 03 66 69 62 00 04 · 0a b0 01 …</text>
</svg>
```

**Figure 15.2.** The module's sections to scale, each counted with its id and size bytes, from the encoder's output for `fib`. The bottom line shows each section's first bytes; `18` is 24 and `3d` is 61 in LEB128.

## 15.5 Running it in the page

The bytes go straight to the browser (or Node), with an import object that supplies the four host functions:

```js
// core.js
  const env = {
    print_num: x => line.push(x), print_bool: x => line.push(!!x),
    print_end: () => { output.push(line.map(v => (Object.is(v, -0) ? '0' : String(v))).join(' ')); trace.push({ type: 'print', values: line }); line = []; },
    fmod: (a, b) => a % b,
  };
  const mod = new WebAssembly.Module(bytes);
  const inst = new WebAssembly.Instance(mod, { env });
```

`host.print(a, b)` compiles to one `print_num` or `print_bool` call per argument and a final `print_end`, which joins the line exactly as the interpreter's `print` does, printing `-0` as `0`. `num.mod` calls the host's `fmod`, because Wasm has no floating-point remainder instruction and JavaScript's `%` on doubles is the C library's `fmod`. The result is a RunResult like any other, so `g.observe.equal` can compare it with the specification. For `fib(30)` both say `832040`; the interpreter takes 214 steps to get there. For `fib(78)` both say `8944394323791464`, the last Fibonacci number below $2^{53}$, exactly. For `fib(79)` both say `14472334024676220`, where the true value ends in `221`: above $2^{53}$ a double cannot hold every integer, and the compiled code rounds exactly as the interpreter does, because both compute with IEEE 754 doubles.

## 15.6 Getting JavaScript into the core profile

Compiled with the default pipeline, `fib` is refused: "js.lt in for1 is outside the core profile". The reason is the parameter. `n` comes from an unknown caller, so its type is `any`, so `i < n` may call `valueOf` on an object, so the frontend's `js.lt` stays a JavaScript operation. Nothing about the loop is the problem; the boundary is.

Two things together fix it. An **assumption**, `g.pipeline().assume({ fib: { n: 'number' } })`, sets the parameter's type to `number`; the frontend records it as a decision, "assumed n: number, unchecked; a JIT would guard this and deoptimise when it fails". Then the standard rewrites' `narrow-by-facts` turns each JavaScript operation whose operands are now known numbers into its numeric variant ([Chapter 10](lab:book?ch=10)): `js.lt → num.lt` at `fib/for1/0`, `js.add → num.add` at `fib/body2/0` and `fib/next3/1`, and `js.mul → num.mul` at `fib/next3/0`. Either step alone leaves `fib` refused: the assumption without narrowing still has `js.lt`, and narrowing without the assumption has no facts to narrow by. Together they give the L1 in FACTS.md, every operation numeric, and the 289-byte module above.

The assumption is the part to be careful with. Nothing checks it. A caller that passes a string gets whatever the compiled code does with a string converted at the Wasm boundary, and the specification of the original program may say something else. A tiered engine makes the same move with a guard: it compiles under the assumption, checks the parameter's type on entry, and when the check fails it abandons the compiled code and continues in the interpreter (deoptimisation). The workbench shows the first half of that design and states the second, which is why the decision record says "unchecked". [W-02 From JavaScript to Wasm](lab:preset?id=W-02) walks through both steps.

> **Try it.** [Load B-01](lab:preset?id=B-01), [switch the IR view to WAT](lab:level?l=WAT) and read the reasons each ledger function is refused. Then [load W-01 WebAssembly by hand](lab:preset?id=W-01), whose `main` and `fib` are written in core IR directly, [show fib](lab:fn?name=fib) and [run it as Wasm](lab:run?mode=wasm). [W-03 Reading WAT](lab:preset?id=W-03) annotates the dispatch loop.

## 15.7 The running example: what the ledger would need

The refusals of the ledger are a list of what a Wasm backend for real JavaScript would have to supply. Cells, objects and closures need a heap: either the Wasm garbage-collection extension's structs and references, or a heap of the compiler's own in linear memory, with the root plans of [Chapter 13](lab:book?ch=13) now describing a shadow stack in that memory, since Wasm locals are invisible to a collector written in Wasm. `js.typeof` and `js.get` need tagged values and calls into runtime helpers, the same helpers the LLVM backend calls. `throw` and the protected block in `main` need Wasm's exception-handling instructions or a status-return protocol ([Chapter 14](lab:book?ch=14)). None of this changes the encoder of this chapter: sections, LEB128, locals and the dispatch loop stay as they are, and each missing feature is a set of operations that gains a lowering. That is the same structure the LLVM backend has, which the next chapter shows.

## 15.8 Key points

The Wasm backend accepts functions in the core profile: numeric and boolean operations, direct calls and prints, without exceptions, with every value a number or a boolean. Each SSA value becomes a typed local, and block arguments become a parallel copy, pushes before pops. Arbitrary control flow becomes a dispatch loop: nested blocks, a `br_table` on a block variable, and a branch back to the loop at depth $n - 1 - k$ from block $k$. The binary is a header and five sections, sizes in LEB128, assembled by hand in about a hundred lines, and run with four host imports so its output can be compared with the specification. JavaScript reaches the core profile when its boundary types are known; an assumption provides them, narrowing uses them, and a real engine would guard the assumption.

## Exercises

1. Encode 300 in LEB128 by hand and check it against the size bytes of a section you make larger than that.
2. In [W-01](lab:preset?id=W-01), [open program.ir](lab:open?file=program.ir&find=fn%20fib), add a block to `fib` and predict the new branch depths of every `goto` before reading the WAT.
3. Write a core IR function that computes `x % y` and prints it, run it as Wasm, and find the `call $fmod` in the WAT. Why does the encoder not use `f64.div` and `f64.trunc` instead?
4. Call the Wasm `fib` with the string `"7"` and with an object, and compare with the specification of the original JavaScript. Which assumption-violating inputs happen to agree, and why?
5. A short project: replace the dispatch loop for functions whose graph is a single natural loop with a `loop` and an `if`, keeping the dispatch loop as the fallback, and measure the bytes saved on `fib`.
