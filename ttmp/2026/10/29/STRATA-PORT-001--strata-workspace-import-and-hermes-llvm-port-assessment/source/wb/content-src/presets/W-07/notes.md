# The structural checker

The workbench prints LLVM IR but cannot hand it to LLVM, so it checks the text itself. This preset takes the emitted text of `readBoth` (the two-`try` function from [W-06](lab:preset?id=W-06)), breaks it in six ways, and runs `g.llvm.check` on each version. The [Experiments view](lab:show?view=experiments) shows which breakages the checker reports and which it does not see. The last two rows are the lesson: well-formed text can still be wrong.

> **Try it.** [Open the Experiments view](lab:show?view=experiments), then [open main.js](lab:open?file=main.js&find=const cases) to see how each case edits the text.

## What it checks

`g.llvm.check(text, declarations)` makes one pass over the lines. Its first lines collect what is defined:

```js
// core.js
function checkLLVM(text, declarations = []) {
  const errors = [], lines = text.split('\n').map(l => l.replace(/;.*$/, ''));
  const callable = new Set(declarations.map(d => /@([\w.]+)\(/.exec(d)[1]));
  for (const l of lines) { const m = /^define [^@]*@([\w.]+)\(/.exec(l.trim()); if (m) callable.add(m[1]); }
```

Comments are stripped first. The callable names are the declared helpers plus every function the text defines. A second sweep records every local that appears on the left of `=` and every label, and reports a label defined twice. The main sweep then checks four rules: a label must be preceded by a terminator (`br`, `ret`, `unreachable` or the end of a `switch`), every `label %x` must name a label that exists, every `%name` used must be defined somewhere, and every `call … @f(` must name something callable.

## What it catches

| case | reported |
|---|---|
| as emitted | nothing |
| rethrow without unreachable | the block before h.catch1: does not end in a terminator |
| an undeclared helper | @shllvm_env_peek is called but not declared |
| a local never defined | %t99 is used but never defined |
| a branch to a missing label | branch to unknown label %b.endtry7 |
| a value from a block that does not dominate | nothing |
| catch1 without its try_state reset | nothing |

These are the mistakes an emitter makes when its bookkeeping slips: a block that falls through, a helper renamed on one side only, a temporary counter that skipped a number, a block that was renamed. The emit pass runs the checker on every function and turns a failure into a warning in the diagnostics, so the mistake shows up in the status pill the moment it is made.

## What it misses

The sixth case passes the temporary `%t0`, loaded in `b.endtry5`, to a store in `b.try3`. LLVM's verifier would reject it twice: `%t0` is an `i64` where a `ptr` is expected, and its definition does not dominate the use, so on the path through `b.try3` it has no value. The workbench's checker knows neither types nor dominance; it only knows that `%t0` is defined somewhere in the function.

The seventh case deletes one line: the store of `0` into `try_state` that opens the handler `catch1` ([W-06](lab:preset?id=W-06) explains why every block outside a protected region has one). Without it the state is still `1` inside `catch1`, so an exception thrown there would dispatch back to `catch1` instead of leaving the function. No local is undefined and every label exists; the error is in what the code means. Only a test that runs the code, or a checker that knows the protocol, can find it.

> **Try it.** [Ask the agent to write a protocol check](lab:ask?q=Write%20a%20check%20over%20program.ir('LLVM')%20that%20reports%20an%20unprotected%20block%20reached%20from%20a%20protected%20one%20without%20a%20try_state%20store) for the seventh case.

## Why a weak checker is still worth having

Structural checks are cheap, local and run on every compile, and they find the most common emitter mistakes at the moment they happen. They do not replace LLVM's verifier (`opt -passes=verify`), which knows types, dominance and every instruction's rules, and which is the first thing to run on this text once LLVM is available outside the page ([Chapter 21](lab:book?ch=21)). The workbench's division of labour is deliberate: the IR is verified for real (the core IR verifier checks dominance with a counter-path), and the printed LLVM text is checked only for the shape mistakes a printer makes.

> **Exercise.** Add an eighth case that defines the same label twice (duplicate the line `b.try6:`). Which rule reports it, and in which sweep? Then extend the idea: write, in `main.js`, a check that every `store volatile i32 N, ptr %try_state` uses an `N` that appears in the dispatch `switch`.

## Where next

[Chapter 16](lab:book?ch=16) covers the text and its checker; [W-04](lab:preset?id=W-04) reads a function's frame, and the shelf doc on the [Hermes LLVM backend](lab:doc?id=hermes-llvm) says what a real build adds.
