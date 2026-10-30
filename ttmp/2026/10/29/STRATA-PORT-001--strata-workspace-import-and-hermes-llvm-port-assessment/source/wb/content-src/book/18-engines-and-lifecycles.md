# Engines and lifecycles

Every chapter so far ran one program in a fresh machine and threw the machine away. A real JIT does not work like that. It keeps one runtime alive for a long time, accepts code in pieces, runs each piece, runs the jobs they schedule, and eventually shuts everything down in an order that never lets compiled code run against a dead runtime or a runtime call into freed code. This chapter describes the workbench's **engine**, an object that owns one execution domain and offers exactly those steps, and then a way to state and check the order of the steps: lifecycles as labelled transition systems, composed into products and searched for a violated invariant. By the end you will be able to model a shutdown protocol in a few lines and have the workbench find the shortest sequence of events that breaks it.

## 18.1 An engine is an execution domain

`g.engine(options)` makes an engine. It owns one heap, one microtask queue, one list of timers, the global object, and every unit of code it has accepted. Those things together are an **execution domain**: code admitted into the domain can share objects with other code in it, through globals or through values it returns, and nothing outside the domain can reach them.

The engine offers five operations, and they are the whole interface:

| call | does |
|---|---|
| `admit(program)` | check a compiled program and install its code; returns a code handle |
| `evaluateScript(code)` | run that unit's `main`: `fulfilled` or `rejected` |
| `runJobs({ budget })` | drain microtasks and timers ([Chapter 17](lab:book?ch=17)) |
| `metrics()`, `snapshot()`, `output()` | look without changing anything |
| `close()` | shut the domain down; every later call throws `EngineClosed` |

`engine.run(program)` is the three middle steps in a row. The separation is the point. Admission is a check that runs before any of the unit's code does; evaluation runs code; jobs run later code that evaluation scheduled. Each step can fail on its own, and each failure means something different to the host that called it. The project this workbench prepares for has the same split in its native engine, whose header exposes separate calls to compile, load, execute, drain and close.

The workbench's engine runs code with the reference interpreter by default, or in plan mode with the simulated collector (`g.engine({ mode: 'plan', gc: 'stress' })`), so everything earlier chapters said about roots still applies to code inside an engine.

## 18.2 Admission before execution

**Admission** decides whether a program may enter the domain. It is a function of the compiled program and the engine's requirements, and it must not run any of the program's code: a program that fails admission leaves the domain exactly as it was. Here is the workbench's implementation:

```js
// core.js
  admit(x) {
    this.check();
    const art = x && x.kind === 'artifact' ? x : x && x.kind === 'program' ? x.artifact : null;
    if (!art) throw new AdmissionError('admit takes a program or an artifact', { reason: 'not an artifact', ranCode: false });
    const prog = art.program;
    if (!prog.ok) throw new AdmissionError(`${prog.name} did not compile: ${(prog.diagnostics.find(d => d.severity === 'error') || {}).message}`, { reason: 'compile errors', ranCode: false });
    if (this.require) for (const [k, v] of Object.entries(this.require)) if (art.requires[k] && String(v) !== art.requires[k] && !art.requires[k].startsWith(String(v))) throw new AdmissionError(`strategy mismatch: ${k} is ${art.requires[k]} in the artifact and ${v} in the engine`, { reason: 'strategy mismatch', field: k, ranCode: false });
    const unit = this.units.length + 1, prefix = `u${unit}.`;
    const rename = new Map(prog.module.names().map(n => [n, prefix + n]));
// …
    this.units.push({ unit, name: prog.name, main: prefix + prog.module.main, functions: fns.length, retained: true, codeBytes: fns.reduce((s, f) => s + f.blocks.reduce((k, b) => k + 16 * (b.ops.length + 1), 0), 0) });
    return { kind: 'code', id: unit, name: prog.name, yamlTag: () => `code #${unit} ${prog.name}` };
  }
```

The first line refuses a closed engine. The next three find the **artifact**: the program's relocatable description, which records what the code requires of the runtime (`requires.roots`, `requires.exceptions`); anything else is refused at once. Then come two refusals of artifacts. Every refusal carries a `reason` and `ranCode: false`. A program with compile errors is refused with its first error. A program compiled for a different root strategy than the engine requires is refused before anything else happens, because code that keeps its roots in one layout cannot run against a runtime that scans another. The measured messages:

- `print(1 == 2)`: "program.js did not compile: the operator == is outside this subset; use === or !==".
- The ledger compiled with `roots('none')`: "program.js did not compile: c_ledger3 is live across js.closure at main/entry/1 but no root assigned".
- The ledger compiled with the default `stackReuse`, admitted into `g.engine({ strategies: { roots: 'distinct' } })`: "strategy mismatch: roots is stackReuse in the artifact and distinct in the engine".

> **Try it.** [Load E-05 Admission refuses](lab:preset?id=E-05), [open main.js](lab:open?file=main.js) and [show the Experiments](lab:show?view=experiments): a table of four programs refused, each with its reason and `ranCode: false`, and a fifth admitted for contrast. [broken.ir](lab:open?file=broken.ir) is the one that fails to verify.

If both checks pass, the engine copies the program's functions into the domain under fresh names. The first unit's functions become `u1.main`, `u1.makeLedger` and so on, the second unit's `u2.main`; calls inside a unit are renamed with it, so two units that both define `main` do not collide. Root plans are copied with the same renaming. The unit is recorded as **retained**: its code stays installed until the engine closes. The `codeBytes` figure is an estimate, 16 B per operation, not a measurement of machine code.

## 18.3 Evaluation, jobs and failure

`evaluateScript(code)` runs the unit's `main` and reports `fulfilled` or `rejected` with the thrown value's display. It does not run jobs. Those wait for `runJobs`, which drains the domain's queues no matter which unit filled them.

Separating the two exposes a state the host must handle. Consider a unit whose initialiser schedules work and then fails:

```js
queueMicrotask(() => print("job from failed unit"));
throw new Error("init failed");
```

`evaluateScript` returns `rejected` with `Error: init failed`. The job is already in the queue, and `runJobs` runs it: the output is `job from failed unit`, and `snapshot()` still lists the unit as retained. The failure did not undo the work the unit had already published. A closure handed to the queue, stored in a global, or returned to the host is reachable code, and freeing that code because its initialiser failed would leave the queue holding a pointer into nothing. That is the reason the workbench, like the native engine it models, retains code until the whole domain closes. The handoff that started this project records the same observation about its own engine: an initialiser can fail after publishing a callable object.

## 18.4 Several units in one domain

A host that loads plugins admits several units into one engine. They share the heap and the globals. An assignment to an undeclared name compiles to `js.global_put`, so this pair of units communicates through a global:

```js
// unit 1
registry = { plugins: 0 };
registry.plugins = registry.plugins + 1;
print("host ready");
// unit 2
registry.plugins = registry.plugins + 1;
print("plugin sees " + registry.plugins);
```

Admitting both and evaluating them in order prints `host ready`, `plugin sees 2`; afterwards the snapshot's globals include `registry`, and the metrics report two admitted units, both retained, 320 B of estimated code and 8 heap objects. [E-07 A plugin host](lab:preset?id=E-07) builds a larger host, three plugins and a dispatcher with one plugin refused ([open plugin-a.js](lab:open?file=plugin-a.js) to see one); [E-04 An engine: admit, evaluate, close](lab:preset?id=E-04) walks through the single-unit case and [E-05 Admission refuses](lab:preset?id=E-05) collects the refusals.

## 18.5 Lifecycles as labelled transition systems

An engine's calls are allowed only in some orders: no evaluation after close, no job into released code, no admission while a unit is executing. Instead of scattering checks for each order through the code, the workbench states the allowed orders as **labelled transition systems**. An LTS is a set of states, an initial state, and a set of transitions, each from a state to a state with a **label**, the name of the event that causes it. The **alphabet** of an LTS is the set of labels it mentions. An LTS accepts a sequence of labels if, from the initial state, each label in turn has a transition from the current state.

`g.machine(name)` builds one, state by state:

```js
const runtime = g.machine('runtime').state('alive').on('job', 'alive').on('destroy', 'dead').final('dead');
const code = g.machine('code').state('published').on('job', 'published').on('release', 'released')
  .state('released').on('job', 'crash');
```

The runtime is alive, may run any number of jobs, and is destroyed once. The code unit is published, may be entered by jobs, and is released once; a job arriving after release reaches the state `crash`, which stands for running freed code. Neither machine alone says anything about the order of destroy and release. That is the job of a third machine, the shutdown protocol, and of the product.

The engine's own state follows a smaller machine of the same kind, drawn in Figure 18.1: `ready`, `executing` while `evaluateScript` runs, and `closed`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 200">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <rect x="60" y="80" width="110" height="40" rx="0" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="92" y="105" font-size="12" class="b">ready</text>
  <rect x="300" y="80" width="120" height="40" class="ink f-fill2" stroke="currentColor" stroke-width="1"/>
  <text x="322" y="105" font-size="12">executing</text>
  <rect x="510" y="80" width="100" height="40" class="acc f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="537" y="105" font-size="12" class="b">closed</text>
  <line x1="20" y1="100" x2="58" y2="100" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <path d="M170,92 L298,92" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="188" y="86" font-size="10" class="it">evaluateScript</text>
  <path d="M300,110 L172,110" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="200" y="126" font-size="10" class="it">return or throw</text>
  <path d="M95,80 C80,40 145,40 130,78" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="64" y="38" font-size="10" class="it">admit, runJobs</text>
  <path d="M115,120 C115,180 560,180 560,122" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="300" y="172" font-size="10" class="it">close</text>
  <text x="470" y="60" font-size="10" class="mut">every call: EngineClosed</text>
</svg>
```

**Figure 18.1.** The engine's states as the workbench records them in `engine.state`: admission and jobs happen in `ready`, evaluation moves to `executing` and back, and `close` leads to `closed`, where every call throws. A schematic, not a measurement.

## 18.6 Products, invariants and search

Machines that describe parts of one system run together. Their **synchronised product** is an LTS whose states are tuples, one state per machine. A label moves the product if every machine whose alphabet contains the label has a transition for it from its current state; those machines move together, and machines that do not know the label stay where they are. A label that some machine knows but cannot take blocks the whole product. An **invariant** is a predicate on product states that must hold in every reachable one.

The shutdown protocol is the third machine. Two candidates:

```js
const releaseFirst = g.machine('close').state('open').on('release', 'half').state('half').on('destroy', 'done').final('done');
const destroyFirst = g.machine('close').state('open').on('destroy', 'half').state('half').on('release', 'done').final('done');
const prod = g.machine.product(runtime, code, releaseFirst)
  .invariant('no job runs released code', s => s.code !== 'crash');
g.check.machine(prod, { depth: 8 });
```

`g.check.machine` explores the product breadth first:

```js
// core.js
function checkMachine(prod, { depth = 12 } = {}) {
  const ms = prod.machines, alpha = ms.map(m => m.alphabet());
  const labels = new Set(alpha.flatMap(a => [...a]));
  const start = ms.map(m => m.initial), key = s => s.join('|');
  const seen = new Map([[key(start), null]]), queue = [[start, []]];
// …
  while (queue.length) {
    const [s, path] = queue.shift();
    for (const inv of prod.invariants) if (!inv.pred(view(s))) return { ok: false, violated: inv.name, trace: path, state: view(s), states: seen.size };
    if (path.length >= depth) continue;
    for (const l of labels) {
      const next = s.slice(); let possible = true, moved = false;
      ms.forEach((m, i) => {
        if (!alpha[i].has(l)) return;
        const to = m.trans.get(s[i]) && m.trans.get(s[i]).get(l);
        if (to === undefined) possible = false; else { next[i] = to; moved = true; }
      });
```

Each queue entry is a product state with the path of labels that reached it. When a state is taken off the queue, every invariant is checked on it, and the first violation returns with its path. Because the search is breadth first, that path is a shortest one. For each label, the inner loop applies the product rule literally: machines whose alphabet lacks the label are skipped, a machine that knows the label but has no transition makes it impossible, and the others move. `seen` makes each product state visited once, which bounds the search by the number of reachable tuples rather than the number of paths.

For `releaseFirst` the result is `{ ok: false, violated: 'no job runs released code', trace: ['release → alive, released, half', 'job → alive, crash, half'], states: 4 }`. Two events break the protocol: release the code, then let the still-alive runtime run one job. For `destroyFirst` the result is `{ ok: true, states: 3, transitions: 3 }`: once the runtime is dead it has no `job` transition, so the product cannot take `job` at all, and release is harmless. Figure 18.2 draws both state spaces.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 270">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="300" y="16" font-size="10" class="lbl">release first: 4 states</text>
  <rect x="20" y="56" width="150" height="34" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="28" y="77" font-size="10">alive, published, open</text>
  <rect x="250" y="56" width="160" height="34" class="ink f-fill" stroke="currentColor"/>
  <text x="258" y="77" font-size="10">alive, released, half</text>
  <rect x="500" y="56" width="160" height="34" class="acc f-sel" stroke="currentColor" stroke-width="1.6"/>
  <text x="510" y="77" font-size="10" class="b">alive, crash, half</text>
  <rect x="250" y="116" width="160" height="34" class="ink f-fill2" stroke="currentColor"/>
  <text x="262" y="137" font-size="10">dead, released, done</text>
  <line x1="170" y1="73" x2="248" y2="73" stroke="currentColor" class="ink" stroke-width="1.6" marker-end="url(#arrow)"/>
  <text x="186" y="67" font-size="10" class="it">release</text>
  <line x1="410" y1="73" x2="498" y2="73" stroke="currentColor" class="acc" stroke-width="1.6" marker-end="url(#arrow)"/>
  <text x="440" y="67" font-size="10" class="it">job</text>
  <line x1="330" y1="90" x2="330" y2="114" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="336" y="106" font-size="10" class="it">destroy</text>
  <path d="M60,56 C50,24 110,24 100,54" fill="none" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="112" y="34" font-size="10" class="it">job</text>
  <text x="300" y="182" font-size="10" class="lbl">destroy first: 3 states</text>
  <rect x="20" y="196" width="150" height="34" class="ink f-fill" stroke="currentColor" stroke-width="1.6"/>
  <text x="28" y="217" font-size="10">alive, published, open</text>
  <rect x="250" y="196" width="160" height="34" class="ink f-fill" stroke="currentColor"/>
  <text x="258" y="217" font-size="10">dead, published, half</text>
  <rect x="500" y="196" width="160" height="34" class="ink f-fill2" stroke="currentColor"/>
  <text x="512" y="217" font-size="10">dead, released, done</text>
  <line x1="170" y1="213" x2="248" y2="213" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="186" y="207" font-size="10" class="it">destroy</text>
  <line x1="410" y1="213" x2="498" y2="213" stroke="currentColor" class="ink" marker-end="url(#arrow)"/>
  <text x="430" y="207" font-size="10" class="it">release</text>
  <text x="252" y="254" font-size="10" class="mut">job impossible: the runtime has no job from dead</text>
</svg>
```

**Figure 18.2.** The reachable states of runtime × code × close for the two shutdown orders, as `g.check.machine` explores them. Top: releasing first reaches `crash` in two events, the shortest trace. Bottom: destroying first leaves no path that runs a job.

The workbench's `close()` reports "closed: runtime destroyed, then code released", the order the check accepts. The method itself only marks the engine closed; the state machines are where the order is argued for, and the argument is a search, not a review of prose. > **Try it.** [Load E-06 Lifecycles as state machines](lab:preset?id=E-06), [open main.js](lab:open?file=main.js) and [show the Laws](lab:show?view=laws): each checked product is one law, and a failing one carries its shortest trace as the counterexample.

[E-06](lab:preset?id=E-06) builds machines of this kind and lets you add one, such as a collector that may run during release, and watch the search find what it breaks. The shelf doc [Labelled transition systems](lab:doc?id=lts) defines products and invariants once more with smaller examples.

## 18.7 The running example: the ledger in an engine

Admitting the ledger into a fresh engine returns code handle 1. The snapshot shows one unit with six functions, retained, and the four builtin globals. `evaluateScript` returns `fulfilled` after 101 steps; the output so far is `rejected: amount must be a number` and `main 42 42`, and the metrics show 18 heap objects and one pending job, the audit. `runJobs()` returns `{ ran: 1, remaining: 0 }` and the third line, `audit 42`, appears; the step count is 134, the same as the stand-alone run in FACTS.md, and the code estimate is 1,248 B, 16 B for each of the 78 operations. In an engine made with `{ mode: 'plan', gc: 'stress' }`, `engine.run` produces the same three lines with 68 collections, and afterwards 16 of the 18 objects are still live.

> **Try it.** [Load B-01](lab:preset?id=B-01) and [ask the agent to run it in an engine](lab:ask?q=Admit%20this%20program%20into%20g.engine()%2C%20evaluate%20it%2C%20run%20its%20jobs%20and%20show%20me%20snapshot()%20and%20metrics()%20after%20each%20step.). Then ask it to admit the same program a second time into the same engine and explain why the second unit's `main` prints a second audit line.

After `close()`, calling `evaluateScript` on the ledger's handle throws `EngineClosed: the engine is closed`. [E-04](lab:preset?id=E-04) runs exactly this sequence in its `main.js`; [open it](lab:open?file=main.js) and [show the Experiments](lab:show?view=experiments) to read the result of each step in one table.

## 18.8 Key points

- An engine owns one execution domain: heap, queues, globals and every admitted unit; its interface is admit, evaluate, run jobs, look and close.
- Admission checks a program and its requirements before any of its code runs; a refused program leaves the domain unchanged and the error says why.
- Units are renamed on admission and retained until the engine closes, because a failed initialiser may already have published code that the queue or the heap can reach.
- A labelled transition system is states, an initial state and labelled transitions; a synchronised product moves machines together on shared labels.
- `g.check.machine` searches the product breadth first and returns the shortest trace to a violated invariant; releasing code before destroying the runtime fails in two events, destroying first passes.

## Exercises

1. Admit the ledger twice into one engine and evaluate both units. How many audit lines appear after `runJobs`, and what do `snapshot().units` and `metrics().code` report?
2. Compile the ledger with `roots('distinct')` and admit it into `g.engine({ strategies: { roots: 'distinct' } })`. Then try `arena`. Which refusals do you get, and from which line of `admit`?
3. Add a machine `collector` with states `idle` and `scanning` and labels `job` and `scan`, such that a scan may happen between jobs. Does it change either verdict of section 18.6? Explain from the product rule.
4. Model the failing initialiser of section 18.3: a machine for a unit with states `loading`, `published`, `failed`, and a label `enqueue` that publishes. Write an invariant that a released unit has no queued job, and find the shutdown order that satisfies it.
5. Project: write a machine for the engine of Figure 18.1 and check it in product with `code`, adding the invariant that no `evaluate` label happens in `closed`. Compare its state count with the number of distinct `snapshot()` results you can produce by calling the real engine.

[Chapter 19](lab:book?ch=19) turns from checking one model to checking the whole compiler: properties stated as laws and tested on programs the workbench generates itself.
