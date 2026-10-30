---
id: ssa
title: SSA with block parameters
group: Representation
about: Static single assignment as the workbench writes it: block parameters instead of phi nodes, edges that pass values, and how cells become SSA.
order: 3
---
# SSA with block parameters

Core IR is in **static single assignment** form (SSA): every value has exactly one definition, and a definition that appears once in the text is never assigned again. Where values from several paths meet, the workbench does not use the phi nodes of textbook SSA; it gives the meeting block **parameters**, and each edge into the block passes arguments. This doc explains the form, why it was chosen, and how the frontend's variables get into it. [I-01](lab:preset?id=I-01) and [I-03](lab:preset?id=I-03) show it in practice.

## One definition per value

In SSA a name is a value, not a variable. `v9 = js.mod(a2_1, b3_1)` defines `v9` once, and every use of `v9` means that one result. Facts about a value therefore never change with the position in the program: if `v9` is a number at one use, it is a number at all of them. This is what makes analyses and rewrites over SSA simple. Liveness asks where each value is used; constant folding replaces a value by a literal everywhere at once; the root planner asks which values are needed at each safepoint. None of them has to track "which assignment of this variable reaches here".

The verifier enforces the rule (`single-definition`) and its companion: a value may be used only where its definition **dominates** the use, that is, where every path from the entry passes through the definition first ([Dominance and dominance frontiers](lab:doc?id=dominance)).

## Block parameters instead of phi nodes

When a variable is assigned on two paths, SSA needs a new value where the paths meet. Textbook SSA writes a phi node at the top of the meeting block, `x3 = φ(x1, x2)`, which means "x1 if we came from the first predecessor, x2 from the second". Core IR writes the same thing as a parameter of the block and an argument on each edge:

```text
fn fixed(c: boolean, x: number) -> number {
entry:
  branch c, left(), join(x)
left():
  y = num.add(x, 1)
  jump join(y)
join(r: number):
  return r
}
```

The two forms mean the same, and a compiler can translate one into the other mechanically. The workbench uses block parameters for three reasons. First, the value passed is written on the edge it travels, so "what does this edge carry" is a property of the edge and not something to look up by predecessor order. Second, a block with parameters reads as a function: a loop header is a function of its loop-carried values, and the Stage draws the arguments on the edges. Third, it is what MLIR, Swift's SIL and several other modern IRs do, so the habit carries over.

## Edges pass everything at once

An edge passes all its arguments together. In Euclid's loop:

```text
while1(a2_1: any, b3_1: any) throws unwind:
  v5 = js.strict_ne(b3_1, 0)
  branch v5, body2(), endwhile3()
body2() throws unwind:
  v9 = js.mod(a2_1, b3_1)
  jump while1(b3_1, v9)
```

`jump while1(b3_1, v9)` sets `a2_1` to the old `b3_1` and `b3_1` to `v9` in one move. The JavaScript needed a temporary to swap `a` and `b`; the IR does not, because there is no moment between the two assignments. A backend that turns block parameters into registers or stack slots must preserve this (it copies through temporaries when a cycle needs it), and the Wasm backend does: it pushes every argument and then sets the parameters' locals in reverse order.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 210">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g font-size="11">
    <rect x="200" y="10" width="180" height="24" fill="none" stroke="currentColor" class="ink"/><text x="212" y="26">entry</text>
    <rect x="200" y="70" width="180" height="40" fill="none" stroke="currentColor" class="acc" stroke-width="1.6"/>
    <text x="212" y="86" class="b">while1(a2_1, b3_1)</text><text x="212" y="102" class="mut">b3_1 !== 0 ?</text>
    <rect x="200" y="150" width="180" height="40" fill="none" stroke="currentColor" class="ink"/>
    <text x="212" y="166">body2()</text><text x="212" y="182" class="mut">v9 = a2_1 % b3_1</text>
    <rect x="440" y="80" width="160" height="24" fill="none" stroke="currentColor" class="ink"/><text x="452" y="96">endwhile3: return a2_1</text>
  </g>
  <g fill="none" stroke="currentColor" class="ink">
    <line x1="290" y1="34" x2="290" y2="70" marker-end="url(#arrow)"/>
    <line x1="290" y1="110" x2="290" y2="150" marker-end="url(#arrow)"/>
    <line x1="380" y1="92" x2="440" y2="92" marker-end="url(#arrow)"/>
    <path d="M200,170 L150,170 L150,90 L200,90" marker-end="url(#arrow)"/>
  </g>
  <g font-size="10">
    <text x="298" y="55" class="it">(a, b)</text>
    <text x="298" y="134" class="mut">true</text>
    <text x="392" y="86" class="mut">false</text>
    <text x="20" y="134" class="it">(b3_1, v9)</text>
    <text x="20" y="148" class="mut">both at once</text>
  </g>
</svg>
```

**Figure 3.1.** The loop of `gcd` in block-parameter form. The edge into the loop passes the function's parameters; the back edge passes the next pair. Drawn from the IR of preset I-03.

## Reading the names

Names in the workbench's IR record where values came from, which helps when reading a long function. A name the frontend made has a hint and a running count: `length9` is the length read, `v9` an anonymous result, `c_steps3` the cell for `steps`. A parameter made by promotion takes the cell's name with a suffix: `a2_1` is the first parameter placed for `c_a2`, `count3_2` the second for `c_count3`. In IR built by hand with `g.fn`, a parameter name already used in the function is freshened with a digit (`i` becomes `i1`), because one function is one namespace; the builder's callbacks hand back the names it chose. None of this matters to the compiler, which compares values by identity, but it matters to a person reading a diff of two versions of a function.

## Implicit parameters

Two kinds of edge fill a parameter the edge does not list. An `invoke`'s normal edge passes the operation's result as the target's first parameter, and its throw edge passes the thrown value; a block-level exceptional exit (`throws to H(args)`) passes the thrown value first and then its listed arguments. The verifier counts these implicit parameters when it checks arity, and liveness treats them as defined by the edge. [Exceptional control flow](lab:doc?id=exceptions) covers them.

## From variables to SSA

JavaScript has variables, which change. The frontend does not try to build SSA itself: it gives every variable a **cell** (`cell.new`, `cell.load`, `cell.store`), which is always correct ([I-06](lab:preset?id=I-06)). The pass `promote-cells` then rebuilds the variables that only one function sees as SSA values, by the method of Cytron and colleagues (1991):

1. choose the cells used only by loads and stores in this function;
2. place a parameter for each at the iterated dominance frontier of the blocks that store to it;
3. walk the dominator tree, replacing each load by the value current at that point and appending the current values to edges into blocks with new parameters;
4. remove the parameters nothing uses.

The fourth step is the difference between minimal SSA and **pruned SSA**. [I-07](lab:preset?id=I-07) runs each step on one function; on the running example [B-01](lab:preset?id=B-01), 11 cells are promoted and 3 stay.

## What stays out of SSA

SSA covers values, not memory. A cell that a closure captures stays a cell, because another function may write it during any call; its loads and stores are ordinary operations with a behaviour (`reads cells`, `writes cells`), and rewrites such as store-to-load forwarding must respect calls in between ([I-08](lab:preset?id=I-08)). Object properties are memory too: `js.get` and `js.put` are operations, not values. A cell created or written inside a `try` also stays a cell when a later load could run after the handler, because a handler can receive only values available at the head of its block. Some IRs extend SSA to memory ("memory SSA"); the workbench does not, and lets operation contracts carry what memory SSA would.

[Chapter 3](lab:book?ch=3) defines core IR, and [Chapter 4](lab:book?ch=4) builds SSA from source step by step.
