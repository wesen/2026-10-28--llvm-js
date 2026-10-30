# Brief for content authors (presets, notes, docs, chapters)

You are writing content for the Strata workbench, an artifact that compiles a JavaScript subset in the page and shows every stage. Read, in this order: `content-src/reference.md` (the API, also the agent's briefing), `content-src/PLAN.md` (every preset, doc and chapter, with fixed ids), `content-src/presets/B-01/` (the model preset), and for chapters `content-src/book/BOOK-STYLE.md` and `content-src/book/FACTS.md`. The engine source is `src/core/*.js` (built into `site/js/core.js`) and `src/frontend.js`.

## Hard rules

- Write only your own files: the preset folders, docs or chapters assigned to you. Do not edit `src/`, `site/`, `tools/`, `CONTRACT.md`, `reference.md`, `PLAN.md`, `book.json`, `BOOK-STYLE.md` or anyone else's files. Do not run `tools/build-content.js`, `tools/build-engine.sh` or `tools/build-shell.js`.
- If the engine has a bug or lacks something you need, work around it inside your preset (or choose another example), and report it at the end with a minimal reproduction. Do not patch the engine.
- Every number you write comes from running the engine. Measure with your preset (`node tools/preset-check.js <id>` prints the run) or a scratch script of your own outside `content-src` (for example in `/tmp/<your-name>/`), loading the engine the way `tools/check-common.js` does. Never invent output, IR, op ids or counts.
- IR you show (in notes, docs or chapters) is pasted from the engine's output, not typed.
- In meta.json and every Markdown file: British spelling, no em dashes, none of the flagged words (see `tools/check-common.js`, FLAGGED), units with a space.

## A preset

A folder `content-src/presets/<ID>/` with:

- `main.js`: the body of an async function run with the scope of reference section 2 (`g`, `source`, `files`, `print`, `t`, units). It returns a Program, a RunResult, a LawReport (`g.laws([...])`), Results (`g.search.grid(...)`, `g.table(rows)`), or an object `{ program, laws, results }`. Comment the file for a reader: what it builds and what to change. Keep it short (5 to 40 lines). It must finish in under 3 s in Node: keep law sample counts and search spaces small (`samples: 200`, a handful of design points).
- `program.js` (JavaScript source) and/or `program.ir` (core IR text), read with `source('program.js')`. Other files as the preset needs (`broken.ir`, `variant.js`). A file the notes link to with `lab:open` must exist.
- `notes.md`: the guide shown in the Notes view (house style below).
- `meta.json`, written last:

```json
{ "id": "T-02", "title": "Dead code that is not dead", "group": "Transforms",
  "about": "One sentence for the preset menu.",
  "tries": ["A question for the agent", "Another", "A third"],
  "view": { "fn": "main", "level": "L1", "tab": "ir", "overlays": ["safepoints"], "mode": "spec", "gc": "off" },
  "chapters": [10], "docs": ["rewriting"],
  "expect": { "compile": "ok" } }
```

`group` is fixed by the id's letter (B Basics, S Semantics, I IR, C Contracts, A Analysis, T Transforms, L Lowering, W Backends, E Engine, X Experiments, M Method, J JavaScript scenarios). `view` sets the starting function, level (`L0 L1 L1.cells L2 L3 LLVM WAT`), bottom tab (`ir facts plan machine events laws experiments`), Stage overlays (`live safepoints types roots path exceptional stale iteration`), and run mode and GC for the header. `expect` declares what the preset demonstrates on purpose: `compile: 'errors'` (the program must not compile), `outcome: 'throw' | 'error' | 'diverge'`, `stale: true` (plan mode must hit a stale use), `lawsFail: true` (a failing law is the point). `chapters` and `docs` list where the preset is discussed.

Check it: `node tools/preset-check.js <ID>` until it reports no errors and no warnings you cannot justify. It runs `main.js` against the real engine, runs the program in `view.mode`/`view.gc`, checks the notes' links (op ids and functions against the program), the figures and the style.

## Notes (notes.md)

Follow B-01. A `#` title equal to `meta.title`; a lede that says what is on the screen and what the preset is for; a **Try it** as early as possible (a blockquote starting `> **Try it.**` with lab: links that act); then `##` sections, each explaining one mechanism with a short excerpt of code, IR or a formula, a Try it where it can be seen, and an **Exercise** (`> **Exercise.** …`) at the end; a last section "Where next" linking the chapter (`[Chapter 10](lab:book?ch=10)`), a doc and one or two neighbouring presets. 500 to 1,000 words. Assume the workbench is open and link generously:

- `lab:open?file=program.js&line=7` or `&find=text` (a file of this preset), `lab:fn?name=deposit`, `lab:node?id=deposit/endif2/1` (take ids from `program.cfg(fn)`: `fn/block/index`, `fn/block/term`, or a block `fn/block`), `lab:level?l=L3`, `lab:overlay?name=live&on=1`, `lab:run?mode=plan&gc=stress`, `lab:step?n=12`, `lab:analysis?name=liveness&i=2`, `lab:law?name=<a law name your main.js returns>`, `lab:show?view=plan`, `lab:build`, `lab:ask?q=…` (URL-encoded), `lab:preset?id=…`, `lab:book?ch=…`, `lab:doc?id=…`.
- A link to a preset or doc in PLAN.md that is not written yet is allowed; everything else must resolve now.
- Show the reader what to change: an Exercise usually edits `main.js` or `program.js` and reruns.

## Shelf docs

`content-src/docs/<nn>-<slug>.md`, `nn` the doc's position in PLAN.md (01 to 20):

```markdown
---
id: ssa
title: SSA with block parameters
group: Representation
about: One sentence for the Docs list.
order: 3
---
# SSA with block parameters
```

A doc covers one topic in 900 to 1,800 words: it opens by saying what it covers and where the workbench uses it, develops it in five to eight `##` sections with the engine's own IR and numbers, links the presets that show it and the chapter that goes deeper (`[Chapter 3](lab:book?ch=3)`), and often ends with its limits ("What this model leaves out"). Figures and maths follow BOOK-STYLE. Check docs with `node tools/book-check.js --docs` (errors must be zero; chapter-only warnings do not apply).

## Looking at what you made

`node tools/render-page.js <file.md> /tmp/<you>/page.png` renders Markdown with the workbench's stylesheets; `--figures` writes one PNG per figure. Look at every figure you draw.

## Report when you finish

1. Files written (one line per preset, doc or chapter, with its check line).
2. Engine problems found, each with a minimal reproduction and what you did instead.
3. Deviations from PLAN.md (a title polished, a preset that shows something slightly different).
