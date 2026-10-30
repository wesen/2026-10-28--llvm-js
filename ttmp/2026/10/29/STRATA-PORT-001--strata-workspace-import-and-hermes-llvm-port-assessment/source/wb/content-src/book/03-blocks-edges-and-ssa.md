# Blocks, edges and SSA

This chapter defines core IR, the form in which Strata holds a program for most of its life. Core IR is a control-flow graph whose nodes are blocks of operations and whose edges carry values, and every value in it is defined exactly once. You will learn what each part of the form is, why the workbench passes values along edges as block parameters instead of using the phi nodes of most textbooks, how a loop is written, how the form is printed, parsed and stored, and what the verifier checks before any pass is allowed to trust it. The chapter ends with dominance, the relation that makes "defined before used" precise in a graph.

## 3.1 Functions, blocks and terminators

A **function** in core IR has a name, typed parameters, a result type and a list of **blocks**. A block has a name, its own typed parameters, a list of **operations** and exactly one **terminator**. An operation names its result, its kind and its operands: `v2 = num.add(i1, 1)` adds the value `i1` to the literal `1` and names the result `v2`. Operations with no useful result, such as `host.print(v)`, have no name. Some operations carry attributes in brackets or after an `@`: `js.new_error[TypeError](msg)` and `js.closure(@deposit, c_balance3, c_log4)`.

Terminators end a block and say where control goes: `jump B(args)` goes to `B`; `branch c, T(args), F(args)` goes to `T` when `c` is true and `F` otherwise; `return v` and `throw v` leave the function; `unreachable` asserts that control never arrives; and `invoke`, which [Chapter 5](lab:book?ch=5) introduces, calls an operation with separate destinations for normal completion and for an exception. Each target named by a terminator is an **edge** of the function's **control-flow graph**, the directed graph whose nodes are the blocks. The first block is the entry.

Nothing in a block's middle can transfer control, and nothing can enter a block except at its top. This is the property that makes a block useful: within it, operations run in order, every time, so facts about one point of a block follow from facts about its start.

## 3.2 Static single assignment, with block parameters

Core IR is in **static single assignment** form, or **SSA**: every value has exactly one definition in the text of the function. A name therefore means one thing everywhere it appears, and a fact about it ("`v2` is a number", "`v2` is unused") is a fact about one definition. Compilers since the late 1980s have used SSA for this reason: it turns questions about variables, which change, into questions about values, which do not.

Source programs assign variables more than once, so SSA needs a way to merge. If `x` is set to 1 on one branch and 2 on the other, the code after the branches needs a single name for "whichever one happened". The classic answer, from Cytron, Ferrante, Rosen, Wegman and Zadeck (1991), is a **phi node** at the top of the merge block: `x3 = φ(x1, x2)`, read as "`x1` if control came from the first predecessor, `x2` if from the second". LLVM uses phi nodes.

Core IR uses **block parameters** instead. The merge block declares a parameter, and each edge into it passes an argument:

```text
then1():
  jump join(1)
else1():
  jump join(2)
join(x: number):
  host.print(x)
```

The two forms say the same thing, and each can be translated into the other mechanically. The workbench uses parameters for three reasons. The arguments live on the edges, which is where their meaning is: "the value `x` has when we arrive from `then1`". A block has no special first instructions whose evaluation rules differ from every other operation's. And the analyses of [Chapter 9](lab:book?ch=9) handle the merge with one edge rule (substitute the edge's arguments for the target's parameters) instead of a special case for phi nodes. The same choice is made by MLIR and by Swift's SIL.

> **Try it.** [Load I-01](lab:preset?id=I-01), which builds functions with block parameters through the API. Then [load I-03](lab:preset?id=I-03) and [show gcd on the Stage](lab:fn?name=gcd): the loop's carried values are the labels on its back edge.

## 3.3 Loops as edges that carry arguments

A loop is a cycle in the control-flow graph, and the values that change from one turn to the next are the arguments of the edge that closes the cycle. Here is a Fibonacci function written with the workbench's builder:

```js
const fib = g.fn('fib', { n: t.number }, t.number, (f, { n }) => {
  f.entry($ => $.jump(f.to('head', $.const(0), $.const(0), $.const(1))));
  f.block('head', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.branch($.op('num.lt', i, n), f.to('body', i, a, b), f.to('exit', a)));
  f.block('body', { i: t.number, a: t.number, b: t.number }, ($, { i, a, b }) =>
    $.jump(f.to('head', $.op('num.add', i, $.const(1)), b, $.op('num.add', a, b))));
  f.block('exit', { r: t.number }, ($, { r }) => $.ret(r));
});
```

`f.block` adds a block and hands its callback a cursor `$` and the block's parameters; `$.op` appends an operation and returns its result's name; `f.to` builds an edge. The builder is ordinary JavaScript, so a generator or a test can make IR without writing text. Printed, the function is:

```text
fn fib(n: number) -> number {
entry:
  jump head(0, 0, 1)
head(i: number, a: number, b: number):
  v1 = num.lt(i, n)
  branch v1, body(i, a, b), exit(a)
body(i1: number, a1: number, b1: number):
  v2 = num.add(i1, 1)
  v3 = num.add(a1, b1)
  jump head(v2, b1, v3)
exit(r: number):
  return r
}
```

The parameters of `body` were requested as `i`, `a` and `b`, but `head` already defines those names, and SSA allows one definition per name, so the builder freshened them to `i1`, `a1` and `b1`. Figure 3.1 draws the graph. The entry edge starts the loop with `(0, 0, 1)`; the back edge from `body` carries `(v2, b1, v3)`, the next index and the next pair; the exit edge carries `a`, the answer.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 330" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="230" y="10" width="140" height="34" class="ink"/>
    <rect x="200" y="90" width="200" height="50" class="ink"/>
    <line x1="200" y1="108" x2="400" y2="108" class="hair"/>
    <rect x="120" y="200" width="200" height="64" class="ink"/>
    <line x1="120" y1="218" x2="320" y2="218" class="hair"/>
    <rect x="390" y="200" width="140" height="44" class="ink"/>
    <line x1="390" y1="218" x2="530" y2="218" class="hair"/>
    <line x1="300" y1="44" x2="300" y2="88" class="ink" marker-end="url(#arrow)"/>
    <path d="M260 140 V198" class="ink" marker-end="url(#arrow)"/>
    <path d="M360 140 V170 H460 V198" class="ink" marker-end="url(#arrow)"/>
    <path d="M120 232 H60 V115 H198" class="ink" stroke-width="1.6" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="240" y="32" class="b">entry</text><text x="282" y="32" font-size="10">jump head(0, 0, 1)</text>
    <text x="208" y="103" class="b">head(i, a, b)</text>
    <text x="208" y="124" font-size="10">v1 = num.lt(i, n)</text>
    <text x="208" y="136" font-size="10" class="mut">branch v1</text>
    <text x="128" y="213" class="b">body(i1, a1, b1)</text>
    <text x="128" y="234" font-size="10">v2 = num.add(i1, 1)</text>
    <text x="128" y="248" font-size="10">v3 = num.add(a1, b1)</text>
    <text x="128" y="260" font-size="10" class="mut">jump head(v2, b1, v3)</text>
    <text x="398" y="213" class="b">exit(r)</text>
    <text x="398" y="236" font-size="10">return r</text>
  </g>
  <g class="mut" font-size="10">
    <text x="306" y="70">(0, 0, 1)</text>
    <text x="268" y="176">true: (i, a, b)</text>
    <text x="400" y="164">false: (a)</text>
    <text x="64" y="104">back edge: (v2, b1, v3)</text>
  </g>
  <text x="10" y="300" class="lbl mut">fib's control-flow graph; edge labels are the arguments each edge passes</text>
</svg>
```

**Figure 3.1.** `fib` as a graph. Every edge passes arguments to its target's parameters; the heavy back edge from `body` to `head` carries the loop's state into the next turn.

The step count of a run follows from the graph. The entry's jump is one step; each turn of the loop runs two steps in `head` (the comparison and the branch) and three in `body`; the last visit to `head` takes two more and `exit` one. For $n$ turns that is

$$1 + 5n + 2 + 1 = 5n + 4,$$

so `fib(10)` takes 54 steps and `fib(0)` takes 4, which is what `g.semantics().run(fib, { args: [10] })` reports, with the value 55.

## 3.4 Text, JSON and round trips

Core IR has two external forms. The text form above is what the views print and what a person writes; `g.ir.parse(text)` reads it and `g.ir.text(fn)` prints it, with comments after `;` or `//`. The JSON form is for storage and tools; `g.ir.json.encode(fn)` gives, for `head` (wrapped here):

```text
{"name":"head","params":[{"id":"i","type":"number"},{"id":"a","type":"number"},{"id":"b","type":"number"}],
 "onThrow":null,"throwArgs":[],"ops":[{"op":"num.lt","args":["i","n"],"result":"v1","attrs":{}}],
 "term":{"kind":"branch","cond":"v1","t":{"block":"body","args":["i","a","b"]},"f":{"block":"exit","args":["a"]}}}
```

Operands are value names as strings, or literals as `{"lit": 0}`. The two forms must agree with each other and with the in-memory function, and that agreement is a property the workbench tests rather than hopes for: `g.law.roundTrip()` generates 100 random functions, prints and reparses each one, encodes and decodes it, and compares content hashes. It passes. A law like this one costs a few lines and catches a whole class of bug, a printer that drops an attribute or a parser that misreads a negative literal, before anything downstream depends on the text. [Chapter 19](lab:book?ch=19) makes laws a method.

> **Try it.** [Load I-02](lab:preset?id=I-02) to print, parse and encode a function and to run the round-trip law on it.

## 3.5 The verifier

Every pass in the pipeline assumes its input is well-formed core IR. The `verify` pass makes that assumption true or stops compilation, with one diagnostic per broken rule. The rules are: every value has one definition; every block has a terminator, and every target block exists; every operation is known and has the right number of operands; every edge passes as many arguments as its target has parameters, and each argument's type fits its parameter's type; an operation that may throw sits in a block that says where exceptions go; and every use of a value is **dominated** by its definition, which Section 3.6 defines. Unreachable blocks are reported as warnings.

Each rule has a message that names the place. Six small broken functions, verified, give:

```text
dominance       v2 is defined in left but used in done, which left does not dominate (path entry → right → done)
edge-arity      edge entry→done passes 2 arguments; done expects 1
arity           num.add takes 2 operands, got 1
edge-type       edge entry→done passes "text": string to x: number
may-throw-without-exit  js.get may throw but entry has no exceptional exit; use invoke or declare "throws to <block>" or "throws unwind"
terminator      block entry has no terminator
```

The dominance check is the most interesting, because "defined before used" is easy to say for straight-line code and needs care in a graph:

```js
// core.js
  forEachUse(fn, (v, at) => {
    const d = defs.get(v);
    const where = { block: at.block.name, op: `${fn.name}/${at.block.name}/${at.term ? 'term' : at.index}` };
    if (!d) { err('undefined-value', `${v} is used in ${at.block.name} but never defined`, where); return; }
    if (d.kind === 'param') return;
    const useNode = at.head ? at.block.name : at.block.name + '#body';
    if (d.kind === 'block-param') {
      if (!dom.dominates(d.block, useNode)) err('dominance', `${v} (a parameter of ${d.block}) does not dominate its use in ${at.block.name}`, where);
      return;
    }
    if (d.block === at.block.name) {
      if (at.head || d.index >= at.index) err('dominance', `${v} is used in ${at.block.name} before it is defined`, where);
      return;
    }
    if (!dom.dominates(d.block + '#body', useNode)) {
      const path = counterPath(fn, d.block, at.block.name);
```

For every use it finds the definition. A function parameter is defined before everything. A block parameter must dominate the use's block. A use in the same block as its definition must come after it. Otherwise the defining block must dominate the using block, and when it does not, `counterPath` searches for a path from the entry to the use that avoids the definition: the proof that the value might not exist when it is read. Each block is treated as two nodes, its head and its body, so that a block's exceptional exit can leave from the head; [Chapter 5](lab:book?ch=5) needs that.

> **Try it.** [Load I-04](lab:preset?id=I-04), which feeds the verifier seven functions that each break one rule and [tabulates the diagnostics](lab:show?view=experiments).

## 3.6 Dominance

A block $a$ **dominates** a block $b$ when every path from the entry to $b$ passes through $a$. Every block dominates itself, and the entry dominates everything reachable. Among the blocks that dominate $b$ other than $b$ itself, the closest is its **immediate dominator**, $\mathrm{idom}(b)$; every block except the entry has exactly one, so the immediate dominators form a tree, the **dominator tree**. For `fib` the tree is short: $\mathrm{idom}(\mathit{head}) = \mathit{entry}$, $\mathrm{idom}(\mathit{body}) = \mathit{head}$ and $\mathrm{idom}(\mathit{exit}) = \mathit{head}$. So `head` dominates `exit`, and `body` does not: control can reach `exit` without ever entering `body`, when $n = 0$.

Dominance is what SSA's single definition needs. If a value's definition dominates every use, then on every path to a use the definition has already run, so the value exists. Figure 3.2 shows the first broken function of Section 3.5: `v2` is defined in `left` and used in `done`, and the path `entry → right → done` reaches the use without passing the definition. The fix is a block parameter: `done(x)` with `jump done(v2)` from `left` and `jump done(0)` from `right`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 290" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="130" y="10" width="110" height="34" class="ink"/>
    <rect x="30" y="100" width="130" height="34" class="ink"/>
    <rect x="210" y="100" width="110" height="34" class="acc"/>
    <rect x="130" y="190" width="110" height="34" class="ink"/>
    <line x1="160" y1="44" x2="100" y2="98" class="ink" marker-end="url(#arrow)"/>
    <line x1="210" y1="44" x2="262" y2="98" class="acc" stroke-width="1.6" marker-end="url(#arrow)"/>
    <line x1="100" y1="134" x2="160" y2="188" class="ink" marker-end="url(#arrow)"/>
    <line x1="262" y1="134" x2="210" y2="188" class="acc" stroke-width="1.6" marker-end="url(#arrow)"/>
    <rect x="470" y="10" width="90" height="30" class="ink"/>
    <rect x="390" y="100" width="80" height="30" class="ink"/>
    <rect x="480" y="100" width="80" height="30" class="ink"/>
    <rect x="570" y="100" width="80" height="30" class="ink"/>
    <line x1="500" y1="40" x2="436" y2="98" class="ink" marker-end="url(#arrow)"/>
    <line x1="515" y1="40" x2="520" y2="98" class="ink" marker-end="url(#arrow)"/>
    <line x1="530" y1="40" x2="606" y2="98" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink">
    <text x="140" y="31" class="b">entry</text><text x="182" y="31" font-size="10">branch v1</text>
    <text x="38" y="121">left: v2 = …</text>
    <text x="218" y="121" class="acc">right</text>
    <text x="138" y="211">done: return v2</text>
    <text x="515" y="30" text-anchor="middle">entry</text>
    <text x="430" y="120" text-anchor="middle">left</text>
    <text x="520" y="120" text-anchor="middle">right</text>
    <text x="610" y="120" text-anchor="middle">done</text>
  </g>
  <g class="mut" font-size="10">
    <text x="20" y="252">the graph: the accent path entry → right → done reaches the use of v2</text>
    <text x="20" y="268">without passing its definition in left</text>
    <text x="390" y="160">the dominator tree: idom of done is entry,</text>
    <text x="390" y="176">so left does not dominate done</text>
  </g>
</svg>
```

**Figure 3.2.** A use not dominated by its definition. Left, the control-flow graph of the broken function with the verifier's counter-path in the accent; right, its dominator tree, in which `done` hangs from `entry` and not from `left`.

The workbench computes dominators with the iterative algorithm of Cooper, Harvey and Kennedy: visit the nodes in reverse postorder, set each node's immediate dominator to the intersection of its processed predecessors' dominators (walking up the tree from both until the walks meet), and repeat until nothing changes. On `fib` it converges in 2 rounds. [Chapter 4](lab:book?ch=4) uses the tree to build SSA from source, and [Chapter 8](lab:book?ch=8) explains why iterating to "nothing changes" is guaranteed to stop.

> **Try it.** [Load I-05](lab:preset?id=I-05) to tabulate the immediate dominators, the dominator tree and the dominance frontiers of a function with a loop and a diamond inside it, then [show parity on the Stage](lab:fn?name=parity).

## 3.7 The running example: total's loop

The ledger's `total` is the loop `for (let i = 0; i < log.length; i++) sum = sum + log[i]`. After the frontend and `promote-cells` it reads:

```text
fn total(c_log: cell, this: any) -> any {
entry throws unwind:
  jump for1(0, 0)
for1(sum2_1: any, i3_1: any) throws unwind:
  log5 = cell.load_checked(c_log)
  length6 = js.get(log5, "length")
  v7 = js.lt(i3_1, length6)
  branch v7, body2(), endfor4()
body2() throws unwind:
  log9 = cell.load_checked(c_log)
  v11 = js.get(log9, i3_1)
  v12 = js.add(sum2_1, v11)
  jump next3()
next3() throws unwind:
  n14 = js.mul(i3_1, 1)
  v15 = js.add(n14, 1)
  jump for1(v12, v15)
endfor4() throws unwind:
  return sum2_1
}
```

It is the same shape as `fib`. The loop header `for1` has two parameters, `sum2_1` and `i3_1`, the two variables the loop changes; the entry passes `(0, 0)`, and the back edge from `next3` passes `(v12, v15)`, the new sum and the new index. The `for` statement's update clause became its own block, `next3`, because `continue` jumps there. `n14 = js.mul(i3_1, 1)` is how the frontend writes `i++`: the postfix increment first converts `i` to a number, and multiplying by 1 is the conversion.

The verifier accepts it. Its dominator tree is $\mathrm{idom}(\mathit{for1}) = \mathit{entry}$, $\mathrm{idom}(\mathit{body2}) = \mathit{for1}$, $\mathrm{idom}(\mathit{next3}) = \mathit{body2}$ and $\mathrm{idom}(\mathit{endfor4}) = \mathit{for1}$. That is why `endfor4` returns `sum2_1` and not `v12`: `endfor4` is dominated by `for1`, whose parameter is in scope there, but not by `body2`, where `v12` is defined. When the log is empty, control goes from `for1` to `endfor4` without ever running the body, and `v12` would not exist.

> **Try it.** [Load B-01](lab:preset?id=B-01), [show total on the Stage](lab:fn?name=total) and [select the loop header](lab:node?id=total/for1). The Inspector lists its two parameters; the back edge from `next3` is labelled with the arguments it passes.

## 3.8 Key points

- Core IR is a control-flow graph of blocks; a block is operations in order followed by one terminator, and control enters only at its top.
- Every value is defined once (SSA). Merges and loops pass values along edges to block parameters, which say the same as phi nodes with the values placed on the edges.
- A loop's changing state is the argument list of its back edge.
- The text and JSON forms are tested against the in-memory form by a round-trip law.
- The verifier checks definitions, terminators, operations, edge arity and types, exceptional exits and dominance, and reports each failure at its place, with a counter-path for dominance.
- Block $a$ dominates block $b$ when every path from the entry to $b$ passes through $a$; a definition must dominate its uses.

## Exercises

1. Write `fib` in the text form with the loop test at the bottom (a `do … while` shape) and check with `g.verify` and a run that it still returns 55 for 10. How many steps does it take now, and why?
2. Remove one argument from the back edge of `fib` and verify. Then add it back with the wrong type (`"x"`). Read both messages.
3. Write the broken function of Figure 3.2 and fix it with a block parameter on `done`; confirm the verifier accepts the fix.
4. Compute by hand the dominator tree of a function whose entry branches to `a` and `b`, both of which jump to `c`, which loops back to `a`. Check it with `g.dominators(fn).idom`.
5. A short project: write a function with the builder that computes $\sum_{i<n} i^2$ with two nested loops (the inner one adding `i` to itself `i` times), print it, verify it, and run it for $n = 5$.
