# Strata Workbench: build contract

The internal contract between the engine (`site/js/core.js`, `site/js/frontend.js`), the workbench shell (`site/js/app.js` and friends), the agent (`site/js/agent.js`) and the content (presets, book, docs, reference). Everything here is binding; if a piece needs something not listed, add it here first.

Names: the app is **Strata Workbench** (header: "Strata" in bold, "workbench" small). The engine namespace is `strata.g` (the `g` of the API page). The book is **Compilers from First Principles**. Look and writing follow the three Form Skate design systems in `/home/claude/ds/` (workbench = shell, agent = agent panel, stage = the drafting-sheet view), adapted to a compiler.

## 1. Files

```
site/
  index.html                 shell markup, loads everything below in this order
  css/kiln.css               workbench tokens.css + components/bundle.css (copied), then fixes
  css/agent.css              agent tokens + bundle.css (copied)
  css/stage.css              stage tokens.css (st-* colours) + overlay css + @font-face Plex Mono
  css/strata.css             app-specific rules (stage sheet, IR view, facts tables…)
  fonts/ibm-plex-mono-latin-{400,500,600,700}-normal.woff2
  js/vendor/acorn.js         acorn 8.18.0 UMD (window.acorn), MIT
  js/vendor/katex.min.js     KaTeX 0.16.47 (window.katex), MIT; render with { output: 'mathml', throwOnError: false }
  js/core.js                 the engine: window.strata (also module.exports in Node)
  js/frontend.js             JS subset → core IR: adds strata.frontend (uses window.acorn or require('acorn'))
  content/presets.js         window.STRATA_CONTENT.presets = [...]        (generated)
  content/book.js            window.STRATA_CONTENT.book = {...}           (generated)
  content/docs.js            window.STRATA_CONTENT.docs = [...]           (generated)
  content/reference.js       window.STRATA_CONTENT.reference = "md"       (generated)
  js/markdown.js             window.StrataMarkdown.render(md, opts) → html string
  js/stage.js                window.StrataStage: the CFG drafting sheet (SVG)
  js/agent.js                window.StrataAgent: the agent panel
  js/app.js                  host, dock, layouts, every other view, lab links, presets store
content-src/                 sources for site/content/*.js (built by tools/build-content.js)
  presets/<ID>/meta.json     { id, title, group, about, tries:[…], view:{…}, chapters:[…], docs:[…] }
  presets/<ID>/main.js       the script (required)
  presets/<ID>/program.js    optional JS source the script compiles
  presets/<ID>/<other files> optional (e.g. core.ir)
  presets/<ID>/notes.md      the Notes view (required)
  book/book.json             { title, subtitle, parts:[{id,title,about}], chapters:[{n,part,slug,title,about,presets,docs,file}] }
  book/<file>.md             one chapter each
  docs/<nn>-<slug>.md        frontmatter: id, title, group, about, order
  reference.md               the API reference (one page; the agent receives it whole)
tools/
  build-content.js           content-src → site/content/*.js (node, no deps)
  harness.js                 node: load core.js+frontend.js+acorn, run a preset headless, print YAML
  preset-check.js            node: run every preset (or one id) headless; fail on error
  book-check.js              node: the book checker (see §8)
```

Node can load the engine: `const strata = require('./site/js/core.js'); require('./site/js/frontend.js')` with `global.acorn = require('/opt/npm-tools/node_modules/acorn')` set first. npm is not reachable; use only the local copies under `/opt/npm-tools/node_modules` and `/opt/node-tools/node_modules`.

## 2. The engine surface the shell uses

`window.strata` has:

- `g`: the API namespace (fully documented in `content-src/reference.md`).
- `version`: string.
- `yaml(value)`: compact YAML text (the agent's result format; rules from the agent design system's yaml table).
- `runScript(code, scope, { timeoutMs })` → `Promise<ScriptResult>`: runs `code` as the body of an async function with every key of `scope` as a parameter (strict mode). `ScriptResult = { ok, ms, value, logs: [string], error?: { message, line } }`.
- `presetScope(files, { log })` → the scope a preset's `main.js` runs with: `g`, the units (`bytes kib mib slots jobs ms count`), `files` (read-only map of the preset's files: `files['program.js']`), `source(name = 'program.js')` = `g.source.text(files[name], { name })`, `print`, `log`, `console`.
- `classify(value)` → `{ program?, run?, laws?, results?, table?, other? }`: what a script returned, so the shell can fill views. A script may return a Program, a RunResult, a LawReport, a Results table, an object holding any of those under those keys (`{ program, run, laws, results }`), or anything else (shown in Events as YAML).

### Program (`kind: 'program'`), from `g.compile(pipeline, source)`

| member | returns |
|---|---|
| `name` | source name (e.g. `program.js`) |
| `functions()` | `['main', 'total', …]` (main first) |
| `ir(level, { fn, format })` | text (default) or JSON string; levels `'L0'` source, `'L1'` core IR, `'L2'` runtime IR, `'L3'` execution plan, `'LLVM'` LLVM IR text, `'WAT'` WebAssembly text (only for functions the Wasm backend accepts; otherwise a one-line reason) |
| `cfg(fn, level = 'L1')` | `{ name, entry, params:[{id,type}], blocks:[{ name, params:[{id,type}], ops:[{ id, text, op, args:[id], results:[id], invoke:bool, mayThrow:bool, safepoint:bool }], term:{ kind:'jump'|'branch'|'return'|'throw'|'invoke'|'unreachable', text, edges:[{ to, args:[id], kind:'jump'|'true'|'false'|'normal'|'throw' }] } }] }`; an invoke is the block's terminator |
| `facts(fn)` | `{ live:{ in:{blk:[ids]}, out:{blk:[ids]}, across:{opId:[ids]} }, types:{ id:'int32'|'number'|'string'|'boolean'|'object'|'any'|… }, safepoints:[opId], idom:{blk:blk}, iterations:{ liveness:n, types:n } }` |
| `steps(fn, analysis)` | fixed-point iterations: `[{ i, block, before:{in,out}, after:{in,out}, changed }]` (`'liveness'`, `'types'`) |
| `plan(fn)` | `{ strategy, rootSlots, fixedSlots, argSlots, frameBytes, peakLive, slots:[{ slot, values:[id] }], safepoints:[{ op, live:[id], rooted:[id], missing:[id] }], reps:{ id:'tagged'|'f64'|'i32'|'bool' }, unwind:[{ op, handler, strategy, restores:[…] }] }` |
| `perm(opId)` | `{ op, contract:{ behaviour, obligations }, erase, merge, move, duplicate, hoist, speculate, because:{ erase:[…], … } }` (values `true`, `false`, or a condition string) |
| `why(target)` | an object explaining a value, op, slot (`'slot:fn/3'`) or block |
| `find(pred)` | ops matching `pred(op)` |
| `diagnostics` | `[{ severity:'error'|'warning'|'info', kind, message, at:{ fn, block, op } \| { file, line, col } }]` |
| `trace` | `[{ pass, level, ms, note }]` |
| `decisions` | `[{ by, at, fired, because }]` |
| `summary()` | `{ profile, frontend, providers, strategies, checks, counts:{ functions, blocks, ops, values } }` |
| `run(opts)` | RunResult, see below |
| `pipeline`, `source` | the pipeline value; the L0 source text |

`opId`s are `fn/block/index` (e.g. `total/body/2`; the terminator is `fn/block/term`). Value ids are SSA names unique per function (`v12`, parameter names as written).

### RunResult (`kind: 'run'`), from `program.run({ mode, gc, budget, args })`

- `mode`: `'spec'` (the reference interpreter on L1, default), `'plan'` (the L3 executor with the simulated moving collector), `'wasm'` (functions the Wasm backend accepts; others fall back with a diagnostic).
- `gc`: `'off' | 'alloc' | 'stress'` (stress: collect at every safepoint). Only `plan` collects.
- Result: `{ kind:'run', mode, outcome:{ kind:'normal'|'throw'|'diverge'|'error', value }, output:[string], events:[{ n, type, … }], steps, records:[{ n, fn, block, op, text, value, depth }] (first 4,000), metrics:{ steps, calls, collections, moved, peakRootSlots, rootBytes, jobs, maxDepth }, error?:{ message, at } }`.
- Event types: `print`, `call`, `return`, `throw`, `catch`, `job`, `collect`, `stale` (a use of a value whose object moved without a root: the plan's bug), `timer`, `error`.

### LawReport (`kind: 'laws'`) and Results (`kind: 'results'`)

- LawReport: `{ kind:'laws', laws:[{ name, ok, samples, counterexample?, minimized?, note }] }`.
- Results: `{ kind:'results', title, columns:[{ key, label, unit }], rows:[{…}], best?, note }` (from `g.search.*`, `g.study`, `g.table`).

## 3. Views

One capitalised word each, with a lowercase about. Left tile: **Notes** (what this preset is about), **Code** (the preset's files, editable), **Agent** (a coding agent with an eval tool), **Docs** (compiler topics, one each), **Book** (the textbook: Compilers from First Principles), **Reference** (the API, one page). Right top: **Stage** (the control-flow graph as a drafting sheet). Right bottom: **IR** (every level of the program as text), **Facts** (analysis results and fixed-point steps), **Plan** (root slots, safepoints and unwinding), **Machine** (the reference interpreter, step by step), **Events** (output, diagnostics and decisions), **Laws** (properties and counterexamples), **Experiments** (design spaces and comparisons).

Header: name; preset menu (`I-03 Loops and block arguments`, "edited" when files changed); **Run** (Ctrl/⌘+Enter: rerun main.js); run mode segmented Spec · Plan · Wasm; GC segmented Off · Alloc · Stress; a function picker; the status pill (`ok · 3 functions · 9 blocks · 41 ops`, accent when errors); the outcome pill (`normal 7 · 212 steps`, accent on throw/error/stale); Layout ▾; theme switch.

### The Stage (drafting sheet)

SVG, drawn in the stage's look: paper ground (`st-bg`), ink hairlines, Plex Mono labels 9.5 px, hatching for tone, a scale-free sheet with a title block bottom right (STRATA · fn name · level · facts). Blocks are boxes with a header line `name(params)` and one line per op; edges are orthogonal lines with arrowheads; back edges route around the left; exceptional edges dashed. Overlays (toggle menu **Show ▾**), each with one hue by meaning from the stage's list: `live` live-across sets (st-blue), `safepoints` collecting ops (st-amber), `types` value types (ink-2 labels), `roots` slot numbers (st-violet), `path` the executed path from the last run (st-blue path, ticks per step, the last block bold), `exceptional` throw edges (st-teal), `stale` stale uses and missing roots (st-rec), `iteration` the previous fixed-point iteration (st-ghost). Click a block or op to select it: accent outline; the side column (Inspector) shows contract, permissions with reasons, facts, slot, and lab links. Levels L1 · L2 · L3 segmented in the stage toolbar.

## 4. Presets

Built-in presets come from `STRATA_CONTENT.presets` (read-only; editing makes them "edited", **Revert all edits** restores them). A viewer's own presets have ids `U-01`, `U-02`… and live in the db collection `presets` (doc id = preset id), falling back to `localStorage` (`strata.v1.presets`) when `claude.use('db')` is `null`. Save as… copies the current files and notes into a new U preset.

Preset JSON: `{ id, title, group, about, tries:[string], files:{ 'main.js': string, … }, notes: md, view:{ fn, level, tab, overlays:[…], mode, gc }, chapters:[n], docs:[id] }`.

Groups and id letters: **B** Basics, **S** Semantics, **I** IR, **C** Contracts, **A** Analysis, **T** Transforms, **L** Lowering, **W** Backends, **E** Engine, **X** Experiments, **M** Method, **J** JavaScript scenarios, **U** your own.

## 5. lab: links

`[text](lab:…)` in notes, docs, book, reference and agent answers. The shell implements:

| link | does |
|---|---|
| `lab:preset?id=I-03` | load a preset |
| `lab:book?ch=4&at=slug` | open a chapter (`P`, numbers, `A`, `B`) at a heading |
| `lab:doc?id=ssa&at=slug` | open a doc |
| `lab:open?file=main.js&line=12` or `&find=text` | open a file in Code |
| `lab:fn?name=total` | show a function on the Stage |
| `lab:node?id=total/body/2` | select an op or block (`total/body`) |
| `lab:level?l=L3` | stage and IR level |
| `lab:overlay?name=live&on=1` | toggle an overlay |
| `lab:run?mode=plan&gc=stress` | set the run mode and rerun |
| `lab:step?n=40` | move the Machine view to step n |
| `lab:analysis?name=liveness&i=2` | show fixed-point iteration i in Facts and on the Stage |
| `lab:law?name=…` | run a law of the loaded preset (its script must return a LawReport) |
| `lab:show?view=plan` | bring a view forward |
| `lab:build` | rerun main.js |
| `lab:ask?q=…` | put a question in the agent's composer (never sends) |

## 6. The agent

As the Form Skate Agent system: one view, threads, Mode (Auto · Ask · Read-only), Model (Fast · Balanced · Deep → `modelTier` quick/default/complex), Thinking (Auto · Low · Med · High → `effort`), one tool `eval`, steps with code, time and YAML result, snapshot of files before each step and revert, `[context]` block on the latest turn, instructions plus the whole Reference on the first. Storage `localStorage` prefix `strata.v1.`.

The eval scope (`labScope(host)`):

| group | names |
|---|---|
| files | `files.list()`, `files.read(path, from?, to?)`, `files.grep(pattern, path?)`, `files.edit(path, find, replace)`, `files.write(path, src)` |
| the program | `run()` (rerun main.js → `{ ok, ms, kind, errors }`), `program()` (the current Program), `ir(level, fn)`, `cfg(fn)`, `facts(fn)`, `steps(fn, analysis)`, `plan(fn)`, `perm(opId)`, `why(target)`, `diagnostics()`, `exec(opts)` (run the current program: a RunResult summary) |
| the engine | `g`, `strata`, units, `compile(src, pipeline?)` (`src` text or `g.source`) |
| presets | `presets.list()`, `presets.get(id)`, `presets.save({ title, group?, about, files, notes, tries? })` → new U id, `presets.edit(id, patch)` (U presets only), `presets.remove(id)` (U only), `presets.load(id)` |
| the bench | `notes()`, `setNotes(md)`, `doc(id)`, `book.contents()`, `book.chapter(n)`, `book.search(text)`, `book.open(n, at?)`, `link(href)`, `select(id)`, `show(view)`, `overlay(name, on)` |
| helpers | `console`, `log`, `lab` |

Read-only blocks: `files.edit`, `files.write`, `run`, `setNotes`, `presets.save/edit/remove`.

## 7. Engine scope (what core.js implements)

Implemented for real, with the API page's names where they fit:

- Units and layouts; types and representations; behaviour (`g.fx`) and obligations (`g.ob`); standard operation sets with contracts and reference steps (`g.ops`, `g.opsets`); derived permissions with reasons (`g.perm`, `g.perm.explain`); variants and narrowing.
- Core IR: builder `g.fn`, text parser/printer `g.ir.parse` / `g.ir.text`, JSON; verifier `g.verify` (dominance, single definition, edge arity and types, terminators, may-throw exits, unreachable blocks).
- Frontend: a JavaScript subset (functions, closures, let/const, objects with getters, arrays, loops, if, try/catch/finally, throw, print, typeof, ===, string concatenation, queueMicrotask, Promise.resolve().then, setTimeout) to core IR, with every variable a cell first and a **promote-cells** pass building SSA (mem2reg).
- The reference interpreter (`g.semantics()`), observations and `g.observe.equal`, profiles.
- One fixed-point solver (`g.solve`) with lattices (`g.lattice.*`) and analyses (`g.analysis.*`: liveness, safepoints, typeFacts, dominators); iteration recording.
- Rewrites with side conditions (`g.rewrite`, `g.rewrites.*`: canonical, constFold, eraseDead, naiveDce, narrow, forwardCells, simplifyBranch), refinement checks.
- Passes and pipelines (`g.pass`, `g.pipeline()`, `.check()`, `.passes()`, `.insert()`), `g.compile`, Program.
- Lowering: runtime IR bound to provider helpers with obligations; root strategies (`distinct`, `stackReuse`, `arena`, `none` for demonstrations); the plan checker; the L3 executor with a simulated moving collector that poisons moved addresses; exception strategies (`setjmp`, `statusReturn`) as plan annotations.
- Backends: LLVM IR text in the shape of the existing Hermes backend (`define internal i64 @fn(ptr %shr)`, `@shllvm_*` helper calls), with a small structural checker; WebAssembly for the `core` profile (numbers, booleans, int32, calls between such functions) encoded to a real binary and run with `WebAssembly.instantiate`, plus WAT text.
- Engine: `g.engine()` with admit, run, jobs, output, metrics, close; `g.machine` state machines with a synchronized product and a bounded checker.
- Laws (`g.law.*`), generators (`g.gen.coreIR`), shrinking; designs, objectives, ranking, search, results tables.

## 8. Writing rules for content

Notes, docs and book follow the workbench system's *Writing a book section* and *docs and notes* guides, adapted: no em dashes; the flagged word list; British spelling; units with a space; numbers only from runs of the engine (say how they were measured, e.g. "measured with `node tools/harness.js I-03`"); terms bold where defined; lab: links that resolve (preset ids, chapters, docs, files of the loaded preset); figures as `svg` blocks with classes only (`ink mut acc hair`, `f-ink f-mut f-acc f-fill f-fill2 f-paper f-sel`, `lbl it b`, `dash dot`), viewBox ≤ 720 wide, caption `**Figure N.k.**`; code quotations: a `js` block whose first line is `// core.js` or `// frontend.js` must quote real lines of that file (`// …` skips). `tools/book-check.js` enforces the errors and warnings of that guide.
