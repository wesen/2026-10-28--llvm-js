# Meaning first

Before a compiler can be right, something has to say what right means. This chapter introduces the workbench's answer: a **reference interpreter** for core IR that is written to be read, not to be fast, and that serves as the **specification** of every program the workbench compiles. You will see how it runs a program step by step, the four ways a run can end, what it records as the observable behaviour of a run, and when two runs count as the same. Every later chapter checks a transformation by comparing what it produces with what this interpreter says, so the definitions here are the ones the whole book leans on.

## 2.1 Why a compiler needs a specification

An optimiser rewrites programs, and every rewrite is a claim: this program and that one do the same thing. A lowering pass makes a different kind of claim: this machine-level program does what that IR program does. To test either claim you need an independent account of what a program does. There are three places to get one. The ECMAScript specification is the authority on JavaScript, but it is prose, several hundred pages of it, and nothing can run it directly. An existing engine such as Hermes can run programs, but its own optimisations are exactly the kind of code under test, and its answers come without reasons. The third option is to write an interpreter for the compiler's own IR, small enough to audit, and to define the meaning of a JavaScript program as what that interpreter does with the IR the frontend produces.

The workbench takes the third option. Its interpreter runs core IR; `g.semantics().run(target)` runs a function, a module, a compiled Program or a source text, and `program.run()` with the default `mode: 'spec'` does the same for a compiled program. Any other mode, such as plan mode, which runs the lowered program with a moving collector, or Wasm mode, which runs a WebAssembly binary, is correct exactly when it agrees with spec mode. The frontend's translation from JavaScript to core IR is part of the meaning, and [Chapter 4](lab:book?ch=4) reads it closely.

> **Try it.** [Load S-01](lab:preset?id=S-01) and [show the Machine](lab:show?view=machine). The slider moves through the run one step at a time, and each step names the operation, its frame and the value it produced.

## 2.2 Frames, environments and steps

The interpreter keeps a stack of **frames**, one per active call. A frame holds the function, an **environment** mapping each SSA value to what it holds, and the operation it is at. Running a function means starting at its first block and executing operations until a terminator says where to go. The heart of it is this loop:

```js
// core.js
    try {
      let block = fn.blocks[0], incoming = [];
      for (;;) {
        block.params.forEach((p, i) => frame.env.set(p.id, incoming[i]));
        let next = null;
        for (let i = 0; i < block.ops.length && !next; i++) {
          const o = block.ops[i];
          frame.at = `${fn.name}/${block.name}/${i}`;
          let v;
          try { v = this.exec(o, frame); }
// …
          if (o.result) frame.env.set(o.result, v);
          this.tick(fn, block, i, opText(o), v);
        }
// …
        switch (term.kind) {
          case 'jump': this.tick(fn, block, 'term', termText(term)); incoming = edgeArgs(term.to); block = fn.block(term.to.block); break;
          case 'branch': {
            const c = this.value(term.cond, frame);
            this.tick(fn, block, 'term', termText(term), c);
            const e = this.truthy(c) ? term.t : term.f;
            incoming = edgeArgs(e); block = fn.block(e.block); break;
          }
```

Entering a block binds its parameters to the values the incoming edge carried. Each operation is executed by `exec`, which looks up the operation's definition and calls its **step function**, the few lines of JavaScript that say what that operation does; the result is stored under the operation's name. `tick` counts a **step** and appends a record of it. A `jump` evaluates its edge arguments and moves to the target; a `branch` tests its condition with JavaScript truthiness and takes one of two edges. The parts left out handle `return`, `throw`, `invoke` and exceptions, which [Chapter 5](lab:book?ch=5) covers.

A step is counted when an operation or terminator finishes, which is why a call's record appears after the records of the callee it ran. For a two-line program the whole run fits on a page:

```text
function sq(x) { return x * x; }
print(sq(3) + 1);

1 main/entry/0     d1  js.closure(@sq)            → #8 fn @sq
2 sq/entry/0       d2  js.mul(x, x)               → 9
3 sq/entry/term    d2  return v5                  → 9
4 main/entry/1     d1  js.call(f3, undefined, 3)  → 9
5 main/entry/2     d1  js.add(r5, 1)              → 10
6 main/entry/3     d1  host.print(v6)             → undefined
7 main/entry/term  d1  return undefined           → undefined
```

The `d1` and `d2` columns are frame depths. `#8` is an **object identity**: the interpreter numbers every object it allocates, and the closure for `sq` was the eighth (the first seven are the builtins installed at start, such as `print` and `Promise`). Figure 2.1 draws the state the interpreter maintains.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 270" font-size="11">
  <g fill="none" stroke="currentColor">
    <rect x="10" y="30" width="200" height="170" class="ink"/>
    <rect x="22" y="140" width="176" height="48" class="ink f-fill"/>
    <rect x="22" y="84" width="176" height="48" class="ink"/>
    <rect x="250" y="30" width="250" height="170" class="ink"/>
    <rect x="540" y="30" width="150" height="70" class="ink"/>
    <rect x="540" y="130" width="150" height="70" class="ink"/>
  </g>
  <g class="ink">
    <text x="10" y="20" class="lbl">frames</text>
    <text x="30" y="158" class="b">main</text><text x="30" y="174" font-size="10">at main/try3/1 · env: c_ledger3 …</text>
    <text x="30" y="102" class="b">deposit</text><text x="30" y="118" font-size="10">at deposit/then1/term · amount "five"</text>
    <text x="250" y="20" class="lbl">heap (object identities)</text>
    <text x="262" y="54" font-size="10">#10 cell balance = 42</text>
    <text x="262" y="72" font-size="10">#11 cell log = #12</text>
    <text x="262" y="90" font-size="10">#12 array [10, 32]</text>
    <text x="262" y="108" font-size="10">#13 the ledger {name, deposit, balance, total}</text>
    <text x="262" y="126" font-size="10">#14 fn @deposit (captures #10, #11)</text>
    <text x="262" y="144" font-size="10">#17 TypeError: amount must be a number</text>
    <text x="262" y="186" font-size="10" class="mut">#1 to #7: builtins installed at start</text>
    <text x="540" y="20" class="lbl">jobs and timers</text>
    <text x="552" y="54" font-size="10">microtasks: empty</text>
    <text x="552" y="72" font-size="10">timers: empty</text>
    <text x="540" y="120" class="lbl">output</text>
    <text x="552" y="154" font-size="10" class="mut">nothing printed yet</text>
  </g>
  <text x="10" y="230" class="mut" font-size="10">The state at step 53 of the ledger's run: deposit("five") has just executed its throw terminator.</text>
  <text x="10" y="248" class="lbl mut">schematic; identities and values from the run's records</text>
</svg>
```

**Figure 2.1.** What the reference interpreter keeps: a stack of frames with their environments, a heap of numbered objects, the queues of jobs and timers, and the output. This is the ledger at step 53, the moment `deposit` throws.

## 2.3 How a run ends

A run has one of four **outcomes**. It is `normal` when the main function returns and the job queues empty; `throw` when an exception escapes main or a job, with the thrown value; `diverge` when the run uses up its step budget, 200,000 steps unless you pass another; and `error` when the engine itself had to stop, for example because a lowered program read a reference the collector had freed. The first three are behaviours of the program. The fourth is a fault in the compiler or the plan, and a comparison involving it says so instead of pretending to an answer.

Two small programs show the middle two. `function f() { throw new RangeError("deep"); } f();` ends with outcome `throw` and the display `RangeError: deep`. `let i = 0; while (true) { i = i + 1; }` ends with `diverge` after 200,001 steps, or after 1,001 with `run({ budget: 1000 })`. The interpreter cannot decide whether a loop terminates, and neither can anything else, so divergence is defined relative to a budget, and two runs are only compared on equal budgets.

> **Try it.** [Load S-05](lab:preset?id=S-05) to watch a loop exhaust its budget, and [S-01](lab:preset?id=S-01) to step through a program that ends normally.

## 2.4 Observations, and what counts as the same

A run produces a lot of detail: every step, every intermediate value, every object identity. Most of it is not behaviour. A compiler that removes a redundant load changes the step count and the numbering of values without changing anything a user could see. So the specification separates the run into **observations**: the values passed to `print`, in order; the outcome; the thrown value, if any (compared by what it prints as, `RangeError: deep`); and, for programs with jobs, the order in which the jobs' effects appear. Two runs are equivalent when their observations are equal.

"Equal" needs two refinements. Numbers are compared by **SameValue**, the comparison JavaScript's `Object.is` performs: it distinguishes `-0` from `0` and treats `NaN` as equal to itself. That matters because `print(0 * -1)` and `print(0)` both display `0`, but the first observation is `-0`, and a compiler that rewrote `0 * x` to `0` would change it. The workbench's comparison reports this case by name:

```text
equal: false, at: trace[0] argument 0
rule: SameValue distinguishes -0 and +0
```

Objects are compared by identity, up to a renaming. The left run may call its object `#8` and the right run `#12`; that is fine, as long as the correspondence is consistent: whenever the left run shows the same object twice, the right run must too, and two different objects on the left must stay two on the right. The comparison builds this correspondence as it goes:

```js
// core.js
function observeEqual(a, b, opts = {}) {
  const map = new Map(), back = new Map();
  const same = (x, y, at) => {
    const rx = x && typeof x === 'object' && 'ref' in x, ry = y && typeof y === 'object' && 'ref' in y;
    if (rx || ry) {
      if (!(rx && ry)) return { equal: false, at, left: x, right: y, rule: 'an object against a primitive' };
      if (map.has(x.ref) && map.get(x.ref) !== y.ref) return { equal: false, at, rule: 'identity: one object on the left is two on the right' };
      if (back.has(y.ref) && back.get(y.ref) !== x.ref) return { equal: false, at, rule: 'identity: two objects on the left are one on the right' };
      map.set(x.ref, y.ref); back.set(y.ref, x.ref); return null;
    }
    if (!Object.is(x, y)) {
      const signedZero = typeof x === 'number' && typeof y === 'number' && x === 0 && y === 0;
      return { equal: false, at, left: x, right: y, rule: signedZero ? 'SameValue distinguishes -0 and +0' : 'values differ' };
    }
    return null;
  };
```

`map` sends left identities to right ones and `back` the other way; requiring both keeps the correspondence one to one, which is the precise meaning of "up to renaming". Figure 2.2 shows it on two runs that print three objects each.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 230" font-size="11">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g fill="none" stroke="currentColor">
    <rect x="40" y="40" width="60" height="30" class="ink"/><rect x="120" y="40" width="60" height="30" class="ink"/><rect x="200" y="40" width="60" height="30" class="ink"/>
    <rect x="40" y="140" width="60" height="30" class="ink"/><rect x="120" y="140" width="60" height="30" class="ink"/><rect x="200" y="140" width="60" height="30" class="ink"/>
    <line x1="70" y1="70" x2="70" y2="138" class="ink" marker-end="url(#arrow)"/>
    <line x1="150" y1="70" x2="150" y2="138" class="ink" marker-end="url(#arrow)"/>
    <line x1="230" y1="70" x2="230" y2="138" class="ink" marker-end="url(#arrow)"/>
    <rect x="400" y="40" width="60" height="30" class="ink"/><rect x="480" y="40" width="60" height="30" class="ink"/><rect x="560" y="40" width="60" height="30" class="ink"/>
    <rect x="400" y="140" width="60" height="30" class="ink"/><rect x="480" y="140" width="60" height="30" class="acc"/><rect x="560" y="140" width="60" height="30" class="ink"/>
    <line x1="430" y1="70" x2="430" y2="138" class="ink" marker-end="url(#arrow)"/>
    <line x1="510" y1="70" x2="510" y2="138" class="acc" marker-end="url(#arrow)"/>
    <line x1="590" y1="70" x2="590" y2="138" class="ink" marker-end="url(#arrow)"/>
  </g>
  <g class="ink" text-anchor="middle">
    <text x="70" y="60">#8</text><text x="150" y="60">#9</text><text x="230" y="60">#8</text>
    <text x="70" y="160">#9</text><text x="150" y="160">#8</text><text x="230" y="160">#9</text>
    <text x="430" y="60">#8</text><text x="510" y="60">#9</text><text x="590" y="60">#8</text>
    <text x="430" y="160">#8</text><text x="510" y="160" class="acc">#8</text><text x="590" y="160">#8</text>
  </g>
  <g class="mut" font-size="10">
    <text x="10" y="30">left: print(a, b, a)</text><text x="10" y="194">right: print(y, x, y)</text>
    <text x="370" y="30">left: print(a, b, a)</text><text x="370" y="194">right: print(a, a, a)</text>
    <text x="150" y="216" text-anchor="middle">equal: #8 ↔ #9 and #9 ↔ #8 throughout</text>
    <text x="510" y="216" text-anchor="middle">not equal: #9 would map to #8, already taken by #8</text>
  </g>
</svg>
```

**Figure 2.2.** Identity up to renaming. On the left the two runs number their objects differently but use them in the same pattern, so they are equal. On the right the left run prints two distinct objects where the right run prints one object three times; the comparison fails at argument 1 with "identity: two objects on the left are one on the right".

## 2.5 Coercion runs user code

An addition in JavaScript is not one operation. `a + b` first converts both operands to primitives, and converting an object calls its `valueOf` method (or `toString`, depending on the hint), which is ordinary user code. This program prints four lines, not two:

```text
const o = { valueOf() { print("valueOf ran"); return 41; } };
print(o + 1);
print(o < 50);

valueOf ran
42
valueOf ran
true
```

Comparison converts too. For the compiler this is the most important fact about JavaScript's operators: `js.add`, `js.lt` and their relatives may run arbitrary code, which may print, throw, allocate or change any object. That is why the frontend emits `js.add` and not `num.add` for `+`, and why `js.add`'s contract, which [Chapter 6](lab:book?ch=6) states, says `callsUser`. A compiler may use `num.add` only where it can prove both operands are numbers; [Chapter 10](lab:book?ch=10) shows the rewrite that does this.

> **Try it.** [Load S-06](lab:preset?id=S-06), [open program.js at the first valueOf](lab:open?file=program.js&line=4) and then [show the Machine](lab:show?view=machine): the steps of `valueOf` run at frame depth 2, in the middle of one `js.add` in `main`.

## 2.6 The temporal dead zone

A `let` or `const` variable exists from the start of its scope but may not be read until its declaration has run; the interval is called the **temporal dead zone**. Reading it there throws a ReferenceError:

```text
function f() { print(x); let x = 1; }
try { f(); } catch (e) { print(e.name + ": " + e.message); }

ReferenceError: cannot access x before initialization
```

The interpreter models this with a cell that starts uninitialised. The frontend creates the cell for `x` without a value and reads it with `cell.load_checked`, an operation whose step throws if the cell still holds the uninitialised marker:

```text
fn f(this: any) -> any {
entry throws unwind:
  c_x2 = cell.new()
  x3 = cell.load_checked(c_x2)
  host.print(x3)
  cell.store(c_x2, 1)
  return undefined
}
```

The frontend uses the checked load only where the check could fail: when the read is textually before the declaration, or in a different function from it, as in the ledger's `get_balance`, which reads `balance` from `makeLedger`'s scope and cannot know whether the declaration has run. A read after the declaration in the same function is a plain `cell.load`. The check is part of the meaning, and a compiler must preserve it or prove it unnecessary.

> **Try it.** [Load S-04](lab:preset?id=S-04). The program reads a `let` too early; [show the Events](lab:show?view=events) for the ReferenceError and its message.

## 2.7 Profiles

Not every program needs every feature, and not every claim covers every program. A **profile** names the operation sets a program may use and the observations a correctness claim about it preserves. The workbench defines three. `core` admits numeric and boolean operations, direct calls and `print`, and observes output and outcome. `js-sync` adds JavaScript values, objects, closures and cells, and also observes thrown values, object identity and heap mutations seen later. `js-async`, the default, adds jobs, promises and timers, and also observes job order.

Profiles matter in two ways. A backend can be honest about its scope: the WebAssembly backend of [Chapter 15](lab:book?ch=15) compiles the `core` profile and refuses the rest with a reason. And a claim can be precise: a rewrite proved correct for `js-sync` says nothing about the order of jobs. Running a program under a profile it does not fit fails before the first step, with the first operation that is out of bounds.

> **Try it.** [Load S-03](lab:preset?id=S-03) to run three programs, one numeric, one with objects and one with a job, under all three profiles. [S-02](lab:preset?id=S-02) collects the comparisons of Section 2.4, and [J-06](lab:preset?id=J-06) runs recursive functions deep enough to see frames pile up.

## 2.8 The running example: the ledger's run

The ledger runs for 134 steps in spec mode, with 8 calls, 18 allocations (the 7 builtins, then 5 closures, 3 cells, an array, the ledger object and one TypeError) and a frame depth of at most 2. Its events tell the story of the run:

| step | event | where |
|---|---|---|
| 53 | throw `TypeError: amount must be a number` | `deposit/then1/term` |
| 53 | catch, handler `catch1` | `main/try3/1` |
| 55 | print `rejected: amount must be a number` | `main/catch1` |
| 97 | print `main 42 42` | `main/endtry2` |
| 99 | job enqueued (queue length 1) | `main/endtry2` |
| 132 | print `audit 42` | `arrow`, after main returned |

Three of these are observations: the three prints, in that order. The throw and catch are not observations by themselves, because the exception never escapes; what is observable is the printed message that results. The run uses `job.enqueue`, so it is outside the `js-sync` profile (`g.semantics().profile('js-sync').run(program)` stops with `outside profile js-sync: job.enqueue in main/endtry2`) and inside `js-async`, where the order of the audit line after `main 42 42` is part of the behaviour. And `"rejected: " + e.message` in the catch block is a `js.add` whose right operand comes from a property read: in this program both are strings, but nothing in `main` can prove that, so the addition keeps its `callsUser` contract.

When [Chapter 1](lab:book?ch=1) ran the same program in plan mode with a collection at every safepoint, the workbench compared that run with this one and reported `equal: true` over 3 observations. That comparison is the pattern for the rest of the book.

## 2.9 Key points

- The workbench's meaning of a program is what its reference interpreter does with the core IR the frontend produces; every other mode is correct when it agrees.
- The interpreter keeps frames with environments, a heap of numbered objects, job queues and output, and counts a step each time an operation or terminator completes.
- A run ends `normal`, `throw`, `diverge` (out of budget) or `error` (an engine fault); the first three are behaviour.
- Runs are compared on observations: printed values, outcome, thrown value and job order, numbers by SameValue and objects by identity up to a one-to-one renaming.
- JavaScript's operators convert objects by calling user code, so `js.add` and its relatives may do anything; a compiler earns `num.add` only by proof.
- Reading a `let` in its temporal dead zone throws, and the IR makes the check explicit with `cell.load_checked`.
- A profile names the operations a program may use and the observations a claim preserves.

## Exercises

1. In S-01, step to the record of `js.call` in `main` and explain why its step number is larger than the steps of the callee's body.
2. Write a program whose output differs between `print(x * 0)` for `x = -1` and for `x = 1` only in SameValue, and check with `g.observe.equal` that the workbench tells the two runs apart.
3. Give an object both `valueOf` and `toString`, each printing its name, and find which one `"" + o`, `o + 1` and `o < 1` call. Compare with what the ledger's catch block would do if `e.message` were such an object.
4. Change S-04 so the early read happens in a nested function called after the declaration. Does the frontend still emit `cell.load_checked`? Does the run throw?
5. A short project: define a profile with `g.profile.define` that admits `core` and `js.value` only, and find a program from the J presets that fits it and one that does not, printing the first operation out of bounds.
