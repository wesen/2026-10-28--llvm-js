/* Shared by tools/preset-check.js and tools/book-check.js: loading the engine in Node,
   running presets, the house style (flagged words, em dashes) and lab: link resolution. */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'content-src');

function loadEngine() {
  if (global.strata && global.strata.frontend) return global.strata;
  global.acorn = require('/opt/npm-tools/node_modules/acorn');
  const strata = require(path.join(ROOT, 'site/js/core.js'));
  require(path.join(ROOT, 'site/js/frontend.js'));
  return strata;
}
function loadRenderer() {
  if (!global.katex) { try { global.katex = require(path.join(ROOT, 'site/js/vendor/katex.min.js')); } catch (e) { global.katex = null; } }
  require(path.join(ROOT, 'site/js/markdown.js'));
  return global.StrataMarkdown;
}

const read = p => fs.readFileSync(p, 'utf8').replace(/\r\n?/g, '\n');
const exists = p => { try { fs.accessSync(p); return true; } catch (e) { return false; } };

function frontmatter(text) {
  const m = /^---\n([\s\S]*?)\n---\n?/.exec(text);
  if (!m) return { meta: {}, body: text };
  const meta = {};
  for (const line of m[1].split('\n')) { const k = /^([\w-]+):\s*(.*)$/.exec(line); if (k) meta[k[1]] = k[2].trim(); }
  return { meta, body: text.slice(m[0].length) };
}

// ---- the corpus: presets, chapters, docs
function presetDirs() {
  const dir = path.join(SRC, 'presets');
  if (!exists(dir)) return [];
  return fs.readdirSync(dir).filter(d => exists(path.join(dir, d, 'meta.json'))).sort();
}
function loadPreset(id) {
  const dir = path.join(SRC, 'presets', id);
  const meta = JSON.parse(read(path.join(dir, 'meta.json')));
  const files = {};
  for (const f of walkFiles(dir)) {
    const rel = path.relative(dir, f);
    if (rel === 'meta.json' || rel === 'notes.md') continue;
    files[rel] = read(f);
  }
  const notes = exists(path.join(dir, 'notes.md')) ? read(path.join(dir, 'notes.md')) : '';
  return { id, dir, meta, files, notes };
}
function walkFiles(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walkFiles(p)); else out.push(p);
  }
  return out;
}
function bookPlan() {
  const p = path.join(SRC, 'book', 'book.json');
  return exists(p) ? JSON.parse(read(p)) : { chapters: [], parts: [] };
}
function docIds() {
  const dir = path.join(SRC, 'docs');
  if (!exists(dir)) return new Map();
  const out = new Map();
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.md'))) {
    const { meta, body } = frontmatter(read(path.join(dir, f)));
    if (meta.id) out.set(meta.id, { file: f, meta, body });
  }
  return out;
}

// ---- running a preset's main.js against the engine, in Node
const runCache = new Map();
async function runPreset(id) {
  if (runCache.has(id)) return runCache.get(id);
  const strata = loadEngine();
  const p = loadPreset(id);
  const logs = [];
  const scope = strata.presetScope(p.files, { log: (...xs) => logs.push(xs.join(' ')) });
  const res = await strata.runScript(p.files['main.js'] || '', scope, { timeoutMs: 25000 });
  const out = { preset: p, res, logs, classified: res.ok ? strata.classify(res.value) : null };
  const prog = out.classified && out.classified.program;
  out.program = prog && prog.kind === 'program' ? prog : null;
  out.functions = new Set(), out.nodes = new Set();
  if (out.program && out.program.module) {
    for (const fn of out.program.functions()) {
      out.functions.add(fn);
      const cfg = out.program.cfg(fn);
      for (const b of cfg.blocks) { out.nodes.add(`${fn}/${b.name}`); for (const o of b.ops) out.nodes.add(o.id); out.nodes.add(`${fn}/${b.name}/term`); }
    }
  }
  const laws = out.classified && out.classified.laws;
  out.lawNames = new Set(laws && laws.laws ? laws.laws.map(l => l.name) : []);
  runCache.set(id, out);
  return out;
}

// ---- house style
const FLAGGED = ['delve', "it's worth noting", 'it is worth noting', 'of course', 'clearly', 'obviously', 'it goes without saying', 'in this chapter we will',
  'landscape', 'tapestry', 'crucial', 'seamless', 'robust', 'leverage', 'as you can see', "it's important to note", 'imagine', 'think of it', 'think of this', 'think of the',
  'like a', 'just like', 'magic', 'nuanced', 'paramount', 'embark', 'journey', 'simply', 'basically', 'essentially', 'in essence', "here's the thing", "let's dive", 'unlock'];
// American spellings that have British forms in this book's vocabulary.
const AMERICAN = { optimize: 'optimise', optimization: 'optimisation', optimizer: 'optimiser', behavior: 'behaviour', analyze: 'analyse', analyzed: 'analysed', analyzing: 'analysing',
  synchronize: 'synchronise', synchronized: 'synchronised', normalize: 'normalise', minimize: 'minimise (in prose)', maximize: 'maximise (in prose)', specialize: 'specialise', specialized: 'specialised',
  materialize: 'materialise', serialize: 'serialise', initialize: 'initialise', initialized: 'initialised', color: 'colour', modeling: 'modelling', labeled: 'labelled', canceled: 'cancelled', favor: 'favour', center: 'centre' };

// Prose only: drop fenced blocks, inline code, maths and link targets.
function proseOf(md) {
  return md.replace(/^(```|~~~)[\s\S]*?^\1\s*$/gm, ' ').replace(/^\$\$[\s\S]*?^\$\$\s*$/gm, ' ')
    .replace(/`[^`\n]*`/g, ' ').replace(/\$[^$\n]+\$/g, ' ').replace(/\]\([^)]*\)/g, ']').replace(/<[^>]+>/g, ' ');
}
function styleIssues(md, where) {
  const issues = [], prose = proseOf(md), lower = prose.toLowerCase();
  if (prose.includes('—')) issues.push({ level: 'warning', where, message: 'an em dash (use a colon, a comma, parentheses or a new sentence)' });
  for (const w of FLAGGED) {
    const re = new RegExp(`(^|[^a-z])${w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}([^a-z]|$)`, 'i');
    if (re.test(lower)) issues.push({ level: 'warning', where, message: `flagged phrase "${w}"` });
  }
  for (const [us, uk] of Object.entries(AMERICAN)) if (new RegExp(`\\b${us}\\b`, 'i').test(prose)) issues.push({ level: 'warning', where, message: `American spelling "${us}" (${uk})` });
  return issues;
}
const words = md => (proseOf(md).replace(/^#.*$/gm, ' ').match(/[A-Za-z0-9][\w'’.-]*/g) || []).length;

// ---- lab: links
const VIEWS = ['notes', 'code', 'agent', 'docs', 'book', 'reference', 'stage', 'ir', 'facts', 'plan', 'machine', 'events', 'laws', 'experiments'];
const OVERLAYS = ['live', 'safepoints', 'types', 'roots', 'path', 'exceptional', 'stale', 'iteration'];
const LEVELS = ['L0', 'L1', 'L1.cells', 'L2', 'L3', 'LLVM', 'WAT'];
function linksOf(md) {
  const out = [];
  const re = /\[([^\]]*)\]\((lab:[^)\s]+)\)/g; let m;
  const text = md.replace(/^(```|~~~)[\s\S]*?^\1\s*$/gm, '');
  while ((m = re.exec(text))) out.push({ text: m[1], href: m[2] });
  return out;
}
/* ctx: { presets:Set, chapters:Map(n→{title, file}), docs:Map, runs:[run outputs of the presets in scope], headings:(ch)→Set } */
// Ids planned in content-src/PLAN.md: a link to one that is not written yet is a warning
// (prefixed "planned:"), unless the check runs with --final.
function plannedIds() {
  const p = path.join(SRC, 'PLAN.md');
  if (!exists(p)) return { presets: new Set(), docs: new Set() };
  const text = read(p);
  const presets = new Set([...text.matchAll(/^\| ([A-Z]-\d\d) \|/gm)].map(m => m[1]));
  const docsPart = text.split('## Shelf docs')[1] || '';
  const docs = new Set([...docsPart.matchAll(/^\| ([a-z][\w-]*) \|/gm)].map(m => m[1]).filter(x => x !== 'id'));
  return { presets, docs };
}
const PLANNED = plannedIds();
const FINAL = process.argv.includes('--final');
function checkLink(href, ctx) {
  const m0 = /^lab:(preset|doc)\?id=([\w-]+)/.exec(href);
  if (m0 && !FINAL) {
    const [, kind, id] = m0;
    if (kind === 'preset' && !ctx.presets.has(id) && PLANNED.presets.has(id)) return null;
    if (kind === 'doc' && !ctx.docs.has(id) && PLANNED.docs.has(id)) return null;
  }
  return checkLinkInner(href, ctx);
}
function checkLinkInner(href, ctx) {
  const m = /^lab:([a-z]+)\??(.*)$/.exec(href);
  if (!m) return `malformed link ${href}`;
  const kind = m[1], q = new URLSearchParams(m[2]);
  const anyRun = pred => ctx.runs.some(pred);
  switch (kind) {
    case 'preset': return ctx.presets.has(q.get('id')) ? null : `no preset ${q.get('id')}`;
    case 'book': {
      const ch = q.get('ch');
      if (!ctx.chapters.has(String(ch))) return `no chapter ${ch}`;
      const at = q.get('at');
      if (at && ctx.headings) { const hs = ctx.headings(String(ch)); if (hs && !hs.has(at)) return `chapter ${ch} has no heading ${at}`; }
      return null;
    }
    case 'doc': {
      const d = ctx.docs.get(q.get('id'));
      if (!d) return `no doc ${q.get('id')}`;
      const at = q.get('at');
      if (at && ctx.docHeadings) { const hs = ctx.docHeadings(q.get('id')); if (hs && !hs.has(at)) return `doc ${q.get('id')} has no heading ${at}`; }
      return null;
    }
    case 'open': {
      const f = q.get('file');
      const hit = ctx.runs.find(r => r.preset.files[f] !== undefined);
      if (!hit) return `no file ${f} in ${ctx.runs.map(r => r.preset.id).join(', ') || 'any preset in scope'}`;
      const line = q.get('line'), find = q.get('find');
      if (line && Number(line) > hit.preset.files[f].split('\n').length) return `${f} has fewer than ${line} lines`;
      if (find && !hit.preset.files[f].includes(find)) return `${f} does not contain "${find}"`;
      return null;
    }
    case 'fn': return anyRun(r => r.functions.has(q.get('name'))) ? null : `no function ${q.get('name')} in the programs in scope`;
    case 'node': return anyRun(r => r.nodes.has(q.get('id'))) ? null : `no operation or block ${q.get('id')} in the programs in scope`;
    case 'level': return LEVELS.includes(q.get('l')) ? null : `unknown level ${q.get('l')}`;
    case 'overlay': return OVERLAYS.includes(q.get('name')) ? null : `unknown overlay ${q.get('name')}`;
    case 'run': {
      if (q.get('mode') && !['spec', 'plan', 'wasm'].includes(q.get('mode'))) return `unknown mode ${q.get('mode')}`;
      if (q.get('gc') && !['off', 'alloc', 'stress'].includes(q.get('gc'))) return `unknown gc ${q.get('gc')}`;
      return null;
    }
    case 'step': return /^\d+$/.test(q.get('n') || '') ? null : 'step needs n';
    case 'analysis': return ['liveness', 'types'].includes(q.get('name')) ? null : `unknown analysis ${q.get('name')} (liveness or types)`;
    case 'law': return anyRun(r => r.lawNames.has(q.get('name'))) ? null : `no law named "${q.get('name')}" in the presets in scope`;
    case 'show': return VIEWS.includes(q.get('view')) ? null : `unknown view ${q.get('view')}`;
    case 'build': case 'ask': return null;
    default: return `unknown link kind ${kind}`;
  }
}

function headingSlugs(md, slug) {
  const out = new Set();
  const text = md.replace(/^(```|~~~)[\s\S]*?^\1\s*$/gm, '');
  for (const m of text.matchAll(/^#{1,6}\s+(.+)$/gm)) out.add(slug(m[1].trim()));
  return out;
}

module.exports = { PLANNED, FINAL, ROOT, SRC, loadEngine, loadRenderer, read, exists, frontmatter, presetDirs, loadPreset, bookPlan, docIds, runPreset, styleIssues, words, proseOf, linksOf, checkLink, headingSlugs, VIEWS, OVERLAYS, LEVELS, FLAGGED };
