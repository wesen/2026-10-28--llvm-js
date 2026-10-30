# Your own operation

The engine's operations are values, and so are yours. `main.js` defines three: `c05.square`, which squares a number and does nothing else; `c05.lying_square`, which also prints a line but declares the behaviour `none`; and `c05.honest_square`, which prints the same line and declares `host(print)`. It registers them as a set, compiles the core IR in `program.ir` that uses all three, and shows what the canonical rewrites do with each.

> **Try it.** [Open program.ir](lab:open?file=program.ir), then [show Events](lab:show?view=events). Without rewrites the output is `squaring 3 / squaring 4 / 49`; with the canonical set it is `squaring 4 / 49`. One printed line disappeared.

## Defining an operation

An operation has a name, operand and result types, a behaviour, obligations, a reference step (what it means, as a function the interpreter calls) and a lowering:

```js
const square = g.op('c05.square').operands(t.number).results(t.number)
  .behaviour(g.fx.none).step((m, [x]) => x * x)
  .lower({ helper: 'c05_square' }).about('x times x').build();
```

The step receives the machine and the operand values. `.lower({ helper })` names the runtime function L2 binds it to; in [the LLVM text](lab:level?l=LLVM) `a = c05.square(7)` becomes `call void @c05_square(ptr %r.a, ptr %shr, ptr %scratch)`: the result through an out pointer, the runtime, then the operand (the literal 7, written to the scratch slot first). `g.opset('c05').ops(square, lying, honest).register()` makes the parser, the verifier, the interpreter and the rewrites know all three. The registry is global for the page, which is why the names carry a prefix.

## The contract is a promise

[Show the contract table](lab:show?view=experiments). `c05.square` and `c05.lying_square` both read `none` and get every permission; `c05.honest_square` reads `host(print)` with `mayCollect`, and gets none. The table cannot see the steps: the lying operation's step calls `m.print`, but its declared behaviour says it touches nothing. Everything downstream believes the declaration.

[Look at main in L1](lab:fn?name=main). The canonical set's `erase-dead-result` erased `b = c05.square(a)`, which is right: nobody uses `b`, and squaring is invisible. It also erased `c = c05.lying_square(3)`, because `perm.erase` said `true`, and with it the line `squaring 3`. It kept [d = c05.honest_square(4)](lab:node?id=main/entry/1) although `d` is unused too, because its behaviour talks to the host.

## Catching the lie

The script checks the rewrite against the specification on this program:

```js
laws: g.laws([g.law.refines(g.rewrites.eraseDead, { corpus: [source('program.ir')] })]),
```

[The Laws view](lab:show?view=laws) shows `refines(erase-dead-result)` failing: before, the trace is `squaring 3`, `squaring 4`, `49`; after, it is `squaring 4`, `49`. The rewrite is the standard one and is correct for every operation whose contract is honest; the counterexample is evidence against the contract, not the rewrite. This is the general shape of contract bugs: an operation that does more than it declares makes sound transformations unsound, and the specification is the only thing that notices.

> **Try it.** In main.js, change the lying operation's behaviour to `g.fx.host('print')` and [rerun](lab:build). The law passes, the canonical output keeps `squaring 3`, and the table shows the permissions it lost.

## What a behaviour must be

A behaviour is sound when it is an upper bound on what the step can do on every input. Declaring more than the step does is always safe and costs permissions; declaring less is a bug. `g.fx.none` claims: no reads, no writes, no fresh identities, no throws, no divergence, no user code, no host. `c05.square` meets that claim for every number. A square of a non-number would be a different question, which is why the operand type is `t.number`: it states what the step may assume. The verifier checks types where values flow along edges; an operand type on a literal is a promise the code that uses the operation must keep.

> **Exercise.** Define `c05.safe_div` with operands `t.number, t.number`, a step that returns `a / b`, and behaviour `g.fx.none`. Is that honest? (In JavaScript, `1 / 0` is `Infinity`, not an error.) Then define `c05.checked_div` whose step throws on a zero divisor, and choose its behaviour and obligations. Use both in program.ir and compare their rows in the contract table.

## Where next

[Chapter 6](lab:book?ch=6) introduces contracts and the operation sets; [C-08](lab:preset?id=C-08) covers sets and providers; [C-06](lab:preset?id=C-06) shows variants, operations whose smaller contract holds under a fact. The doc [Refinement and why passes compose](lab:doc?id=refinement) explains what `g.law.refines` checks.
