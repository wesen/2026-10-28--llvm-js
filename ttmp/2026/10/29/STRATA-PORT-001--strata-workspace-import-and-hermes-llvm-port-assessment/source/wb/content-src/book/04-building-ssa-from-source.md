# Building SSA from source

JavaScript variables are assigned many times and shared between functions; SSA values are defined once and belong to one function. This chapter shows how Strata gets from the first to the second in two steps. The frontend resolves every name to its declaration and gives every variable a cell, which is always correct and never fast. Then the `promote-cells` pass turns every cell that only one function touches into SSA values, placing block parameters where control merges and renaming uses along the dominator tree. By the end you will be able to predict, for any variable in a program, whether it stays a cell or becomes values, and where its block parameters go.

## 4.1 Scopes, declarations and captures

The frontend uses the acorn parser to turn source text into a syntax tree, then makes two passes over the tree before it emits any IR. The first pass builds **scopes**. A function scope holds the function's parameters, its `var` declarations wherever they appear in its body, and `this` (arrow functions have none of their own). A block scope holds the `let`, `const` and function declarations written directly in that block. Every **declaration** gets a record with its name, its kind and a flag that starts false: `captured`.

The second pass resolves references. For each identifier it walks outward from the scope where the identifier appears until it finds a declaration of that name. If the declaration belongs to a different function from the use, the variable is **captured**: a function other than its own reads or writes it, so its storage must outlive a single call and be shared. The resolver sets the flag and records the variable in the free set of every function between the use and the declaration, since each of them must pass it inward when it creates the next closure.

Figure 4.1 shows the result for the ledger. Of its fourteen variables (counting each function's `this` and the catch parameter `e`), three are captured: `balance` and `log`, declared in `makeLedger` and used by the methods, and `ledger`, declared at the top level and used by the job passed to `queueMicrotask`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 290" font-size="11">
  <g fill="none" stroke="currentColor">
    <rect x="10" y="10" width="330" height="70" class="ink"/>
    <rect x="390" y="10" width="300" height="50" class="ink"/>
    <rect x="10" y="120" width="330" height="54" class="ink"/>
    <rect x="10" y="220" width="200" height="56" class="ink"/>
    <rect x="230" y="220" width="200" height="56" class="ink"/>
    <rect x="450" y="220" width="240" height="56" class="ink"/>
    <line x1="175" y1="80" x2="175" y2="118" class="hair"/>
    <line x1="340" y1="35" x2="388" y2="35" class="hair"/>
    <line x1="110" y1="174" x2="110" y2="218" class="hair"/>
    <line x1="290" y1="174" x2="330" y2="218" class="hair"/>
    <line x1="340" y1="160" x2="520" y2="218" class="hair"/>
  </g>
  <g class="ink">
    <text x="18" y="28" class="b">main (script)</text>
    <text x="18" y="48">declares: this, makeLedger, <tspan class="acc b">ledger</tspan></text>
    <text x="18" y="66" font-size="10" class="mut">catch block declares: e</text>
    <text x="398" y="28" class="b">arrow (the audit job)</text>
    <text x="398" y="48" font-size="10">declares nothing (no this of its own) · free: <tspan class="acc">ledger</tspan></text>
    <text x="18" y="138" class="b">makeLedger</text>
    <text x="18" y="160">declares: this, name, <tspan class="acc b">balance</tspan>, <tspan class="acc b">log</tspan></text>
    <text x="18" y="238" class="b">deposit</text>
    <text x="18" y="254" font-size="10">declares: this, amount</text>
    <text x="18" y="268" font-size="10">free: <tspan class="acc">balance</tspan>, <tspan class="acc">log</tspan></text>
    <text x="238" y="238" class="b">get_balance</text>
    <text x="238" y="254" font-size="10">declares: this</text>
    <text x="238" y="268" font-size="10">free: <tspan class="acc">balance</tspan></text>
    <text x="458" y="238" class="b">total</text>
    <text x="458" y="254" font-size="10">declares: this, sum; for block: i</text>
    <text x="458" y="268" font-size="10">free: <tspan class="acc">log</tspan></text>
  </g>
</svg>
```

**Figure 4.1.** The ledger's functions, the variables each declares, and the free variables each uses from an enclosing function. Thin lines join a function to the one it is nested in. The three captured variables are in the accent, where they are declared and where they are used.

## 4.2 Every variable a cell

The frontend's next decision is the simplest one that is always correct: every variable, captured or not, gets a **cell**, a heap box created with `cell.new` and accessed with `cell.load` and `cell.store`. A closure is created with `js.closure(@f, cells…)`, passing the cells of its free variables, and the closure's function receives them as its first parameters. Sharing is then automatic: two closures holding the same cell see each other's stores.

When the frontend enters a scope it creates the cells of every declaration in it:

```js
// frontend.js
  enterScope(scope, body) {
    for (const d of scope.decls.values()) {
      if (this.cellOf.has(d.id)) continue;
      if (d.kind === 'var') this.declareCell(d, lit(undefined));
      else if (d.kind === 'let' || d.kind === 'const') this.declareCell(d);   // uninitialized until its declaration runs
      else if (d.kind === 'function') this.declareCell(d, lit(undefined));
    }
    for (const st of body || []) if (st.type === 'FunctionDeclaration') {
      const d = scope.decls.get(st.id.name);
      this.emit('cell.store', this.cellOf.get(d.id), this.closure(st));
    }
  }
```

A `var` starts as `undefined`, as JavaScript requires; a `let` or `const` cell starts uninitialised, which is how the temporal dead zone of [Chapter 2](lab:book?ch=2) is represented; and function declarations are hoisted, their closures stored before any other statement of the scope runs. Reading a variable chooses between two loads:

```js
// frontend.js
  load(decl, node) {
    const c = this.cellRef(decl, node);
    const checked = (decl.kind === 'let' || decl.kind === 'const') && (decl.scope.fnScope !== this.scopeOf(node).fnScope || node.start < decl.node.end);
    return checked ? this.emit('cell.load_checked', c, { name: decl.name, node, hint: decl.name }) : this.emit('cell.load', c, { hint: decl.name });
  }
```

A `let` or `const` read from another function, or read at a position in the text before the declaration ends, gets the checked load that throws a ReferenceError on an uninitialised cell. Every other read is a plain load.

Here is `deposit` as the frontend emits it, at the level the workbench calls L1.cells:

```text
fn deposit(c_balance: cell, c_log: cell, this: any, amount: any) -> any {
entry throws unwind:
  c_this1 = cell.new(this)
  c_amount2 = cell.new(amount)
  amount3 = cell.load(c_amount2)
  v4 = js.typeof(amount3)
  v5 = js.strict_ne(v4, "number")
  branch v5, then1(), endif2()
then1() throws unwind:
  err6 = js.new_error[TypeError]("amount must be a number")
  throw err6
endif2() throws unwind:
  balance7 = cell.load_checked(c_balance)
  amount8 = cell.load(c_amount2)
  v9 = js.add(balance7, amount8)
  cell.store(c_balance, v9)
  amount10 = cell.load(c_amount2)
  log11 = cell.load_checked(c_log)
  log12 = cell.load_checked(c_log)
  length13 = js.get(log12, "length")
  js.put(log11, length13, amount10)
  balance14 = cell.load_checked(c_balance)
  return balance14
}
```

The parameter `amount` arrives as a value and is put straight into a cell, and each mention of `amount` in the source becomes a load. The frontend could have been cleverer here, but cleverness in a frontend is hard to test, and the uniform form has a property the next pass relies on: every variable is in a cell, so promotion has one case to handle.

> **Try it.** [Load I-06](lab:preset?id=I-06) to see a function at L1.cells beside its L1. Then [load J-01](lab:preset?id=J-01), a counter whose closures share one cell, and [show inc](lab:fn?name=inc): the cell arrives as its first parameter.

## 4.3 Which cells can become values

A cell can be replaced by SSA values when every use of it is a `cell.load` or `cell.store` in the function that created it. Passing the cell to `js.closure` is a different kind of use: another function will hold it, and its loads and stores may happen at any later time, so the cell must stay. A `cell.load_checked` also keeps the cell, because the check depends on the cell's state at run time. There is one more condition, about exceptions: a cell created or stored inside a `try` block stays a cell if any of its loads can run after the handler, for reasons [Chapter 5](lab:book?ch=5) explains.

These conditions are deliberately conservative. A compiler with more analysis could promote a captured variable that no closure ever writes, or remove a TDZ check it proves cannot fail. The workbench keeps the rule small enough to state in a sentence and lets the decision log show which cells it chose: every promotion is recorded as a decision with the reason "used only by loads and stores in this function".

> **Try it.** [Load I-08](lab:preset?id=I-08) for variables captured by closures that promotion must leave alone, and [S-04](lab:preset?id=S-04), where an early read of a `let` keeps its cell checked.

## 4.4 Placing block parameters at dominance frontiers

Promoting a cell means deciding, at every point, which SSA value the variable holds there. Within one block that is easy: after a store, the stored value; before any store, whatever the block started with. The difficulty is merges. Where two paths meet, and the variable was stored on one of them, the block needs a parameter that receives the right value from each incoming edge. Placing a parameter at every merge would be correct and wasteful; the question is where one is needed.

The answer uses dominance from [Chapter 3](lab:book?ch=3). The **dominance frontier** of a block $x$ is the set of blocks $y$ such that $x$ dominates a predecessor of $y$ but does not strictly dominate $y$ itself:

$$\mathrm{DF}(x) = \{\, y \mid \exists p \in \mathrm{pred}(y).\; x \text{ dom } p \;\wedge\; \neg (x \text{ sdom } y) \,\}.$$

Informally, $\mathrm{DF}(x)$ is where $x$'s influence ends: the first blocks reachable from $x$ that can also be reached another way. A store in $x$ is the latest store on some paths into $y$ but not on all of them, so $y$ needs a parameter. That parameter is itself a new definition, so its block's frontier needs one too; the set of blocks that need parameters is the **iterated dominance frontier** of the blocks that store the variable. This is the construction of Cytron, Ferrante, Rosen, Wegman and Zadeck (1991), the basis of LLVM's `mem2reg`, with block parameters in place of phi nodes:

```js
// core.js
  // Place block parameters at the iterated dominance frontier of each cell's stores.
  const placed = new Map();                       // block → [cell…] in parameter order
  for (const c of cells) {
    const defBlocks = new Set();
    for (const b of fn.blocks) for (const o of b.ops) if ((o.op === 'cell.store' && o.args[0] === c) || (o.op === 'cell.new' && o.result === c)) defBlocks.add(b.name);
    const work = [...defBlocks], has = new Set();
    while (work.length) {
      const x = work.pop();
      for (const y of df.get(x) || []) if (!has.has(y)) {
        has.add(y);
        if (!placed.has(y)) placed.set(y, []);
        placed.get(y).push(c);
        if (!defBlocks.has(y)) work.push(y);
      }
    }
  }
```

For each promotable cell, `defBlocks` holds the blocks that create or store it. The worklist takes a block, adds a parameter for the cell to each block in its frontier that does not have one yet, and puts each such block back on the worklist, since its new parameter is a definition whose frontier may need parameters too. The `has` set stops the iteration: each block gets at most one parameter per cell.

For `total`, the frontier is easy to compute by hand. The only block with two predecessors is the loop header `for1` (from `entry` and from `next3`). Walking up the dominator tree from `next3` towards $\mathrm{idom}(\mathit{for1}) = \mathit{entry}$ passes `next3`, `body2` and `for1`, so all three have `for1` in their frontier, and the entry has an empty frontier. `sum` is stored in `entry` and `body2` and `i` in `entry` and `next3`, so each gets one parameter at `for1`: `sum2_1` and `i3_1`, named after the cell with a suffix.

## 4.5 Renaming along the dominator tree

With parameters placed, the pass walks the dominator tree from the entry, carrying a map from each cell to its current value. Entering a block, the block's new parameters become the current values of their cells. Each `cell.load` of a promoted cell is deleted and its uses replaced by the current value; each `cell.store` is deleted and updates the current value; `cell.new` sets the initial value. At the block's terminator, the current value of each cell is appended to every outgoing edge whose target has a parameter for it. Then the children in the dominator tree are visited, each with its own copy of the map.

The walk follows dominance, not control flow, and that is what makes it correct: a block's dominator has run on every path to it, so the values current at the end of the dominator are the right defaults, except where a parameter overrides them, which is exactly where the frontier said other paths arrive. Figure 4.2 shows `total` before and after. In `endfor4`, a child of `for1` in the dominator tree, the load of `sum` becomes `sum2_1`, the header's parameter, and not `v12` from `body2`, which does not dominate it.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 330" font-size="10">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="10" y="10" width="300" height="300" class="mut"/>
    <rect x="380" y="10" width="310" height="300" class="ink"/>
    <rect x="400" y="40" width="270" height="26" class="ink"/>
    <rect x="400" y="96" width="270" height="44" class="ink f-fill"/>
    <rect x="400" y="168" width="270" height="34" class="ink"/>
    <rect x="400" y="230" width="270" height="34" class="ink"/>
    <rect x="545" y="276" width="140" height="26" class="ink"/>
    <line x1="530" y1="66" x2="530" y2="94" class="ink" marker-end="url(#arrow)"/>
    <line x1="470" y1="140" x2="470" y2="166" class="ink" marker-end="url(#arrow)"/>
    <line x1="470" y1="202" x2="470" y2="228" class="ink" marker-end="url(#arrow)"/>
    <path d="M400 247 H388 V112 H398" class="ink" stroke-width="1.6" marker-end="url(#arrow)"/>
    <path d="M640 140 V274" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="mut">
    <text x="18" y="26" class="lbl">L1.cells: sum and i in cells</text>
    <text x="18" y="48">entry: c_sum2 = cell.new(); store 0</text>
    <text x="18" y="62">       c_i3 = cell.new(); store 0</text>
    <text x="18" y="86">for1:  i4 = cell.load(c_i3)</text>
    <text x="18" y="100">       … js.lt(i4, length6)</text>
    <text x="18" y="124">body2: sum8 = cell.load(c_sum2)</text>
    <text x="18" y="138">       i10 = cell.load(c_i3)</text>
    <text x="18" y="152">       v12 = js.add(sum8, v11)</text>
    <text x="18" y="166">       cell.store(c_sum2, v12)</text>
    <text x="18" y="190">next3: i13 = cell.load(c_i3)</text>
    <text x="18" y="204">       v15 = js.add(n14, 1)</text>
    <text x="18" y="218">       cell.store(c_i3, v15)</text>
    <text x="18" y="242">endfor4: sum16 = cell.load(c_sum2)</text>
    <text x="18" y="256">       return sum16</text>
    <text x="18" y="290">20 ops, 3 cells (one for this), no block parameters</text>
  </g>
  <g class="ink">
    <text x="388" y="26" class="lbl">L1: promoted</text>
    <text x="408" y="57">entry: jump for1(0, 0)</text>
    <text x="408" y="112" class="b">for1(sum2_1, i3_1)</text>
    <text x="408" y="130">js.lt(i3_1, length6)</text>
    <text x="408" y="183">body2: v12 = js.add(sum2_1, v11)</text>
    <text x="408" y="197" class="mut">jump next3()</text>
    <text x="408" y="245">next3: v15 = js.add(n14, 1)</text>
    <text x="408" y="259" class="b">jump for1(v12, v15)</text>
    <text x="551" y="293">endfor4: return sum2_1</text>
  </g>
  <text x="480" y="157" class="mut" font-size="9">DF(body2) = DF(next3) = {for1}</text>
</svg>
```

**Figure 4.2.** `total` before and after promotion. Left, the loads and stores of the two cells (abridged from L1.cells). Right, the result: the two parameters placed at `for1`, the frontier of the blocks that store `sum` and `i`, and the back edge carrying the values current at the end of `next3`.

## 4.6 Pruning dead parameters

Placement at the iterated frontier is minimal in one sense (no parameter is placed where the frontier does not require one) but not in another: it places a parameter wherever a variable's value differs between paths, whether or not anything reads the variable there. Consider

```text
function f(c) {
  let x = 0;
  let y = 0;
  if (c) { x = 1; y = 2; }
  return x;
}
```

Both `x` and `y` are stored in the entry and in the `then` block, so both get a parameter at the merge `endif2`. Only `x` is read after it. The last step of the pass, `removeDeadParams`, marks a parameter live only if a real use reaches it, directly or through a chain of edge arguments into other live parameters, and deletes the rest together with the arguments that fed them. For `f`, `g.promoteCells` reports `params: 2, removedParams: 1`, and the result has one parameter:

```text
fn f(this: any, c: any) -> any {
entry throws unwind:
  b6 = js.truthy(c)
  branch b6, then1(), endif2(0)
then1() throws unwind:
  jump endif2(1)
endif2(x3_1: any) throws unwind:
  return x3_1
}
```

The literature calls the unpruned result minimal SSA and this one pruned SSA. The difference matters to later passes: every block parameter is a value the liveness analysis must track and, if it holds a reference, one the root plan of [Chapter 13](lab:book?ch=13) must consider.

> **Try it.** [Load I-07](lab:preset?id=I-07) to run `promote-cells` by hand on a function and compare the placed and removed parameter counts; [I-05](lab:preset?id=I-05) prints the dominator tree the pass walks.

## 4.7 The running example: eleven cells promoted, three kept

Across the ledger the frontend creates 14 cells, and `promote-cells` turns 11 of them into values: in `main`, those for `this`, `makeLedger` and the catch parameter `e`; in `makeLedger`, `this` and `name`; in `deposit`, `this` and `amount`; in `get_balance`, `this`; and in `total`, `this`, `sum` and `i`. The decision log lists each of them. Three stay: `c_balance` and `c_log` in `makeLedger`, which are passed to `js.closure` for the methods, and `c_ledger` in `main`, passed to the audit job's closure. Inside the methods, those cells arrive as parameters and are read with `cell.load_checked`, because the reads are in a different function from the `let` and `const` declarations.

Promotion is not cosmetic. Compiling the ledger with `g.pipeline().frontend({ promote: false })` keeps every cell: the program has 100 operations instead of 78, its spec run takes 187 steps instead of 134, and its root plans need 19 slots instead of 15, because every cell is a heap object that must be rooted across safepoints. Both versions print the same three lines; one is closer to what a machine should run.

> **Try it.** [Load B-01](lab:preset?id=B-01), [show deposit before promotion](lab:level?l=L1.cells) and then [after](lab:level?l=L1). In [the Events view](lab:show?view=events) the decisions list the 11 promotions by function and cell.

## 4.8 Key points

- The frontend resolves every name to its declaration; a variable used in a function other than its own is captured, and every function in between passes its cell.
- Every variable starts as a cell; closures receive the cells of their free variables as their first parameters, and `let` and `const` cells start uninitialised.
- A cell is promotable when only `cell.load` and `cell.store` in its own function use it, with one extra condition for protected regions.
- Block parameters go at the iterated dominance frontier of the blocks that store the cell; renaming walks the dominator tree carrying each cell's current value.
- Parameters nothing reads are removed, giving pruned SSA.
- In the ledger 11 of 14 cells are promoted; the three captured ones stay.

## Exercises

1. In B-01, add `let count = 0;` to `deposit` with `count = count + 1;` before the return, and predict whether `count` is promoted. Check the decision log.
2. Change the function `f` of Section 4.6 to `return x + y`. How many parameters does `endif2` have now, and how many were removed?
3. Compute the dominance frontiers of a function with a `while` loop whose body contains an `if` with an `else`. Which blocks get parameters for a variable assigned only in the `else` branch?
4. In J-01, add a second closure that only reads the counter. Does anything change in the IR of the first closure?
5. A short project: write a `main.js` that compiles a program with and without promotion and reports, per function, the number of cells, operations, steps and root slots in a `g.table`. Find a program where promotion saves more than half the steps.
