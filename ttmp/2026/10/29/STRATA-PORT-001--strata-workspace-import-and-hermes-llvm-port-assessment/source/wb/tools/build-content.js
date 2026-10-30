#!/usr/bin/env node
/* content-src → site/content/{presets,book,docs,reference}.js
   usage: node tools/build-content.js [content-src dir] [output dir]
   (defaults: /home/claude/wb/content-src and site/content next to this tool). Node only, no dependencies.
   Tolerant: a broken piece is reported and skipped, the rest is still written. Exit code 1 only when
   the source folder is missing or nothing could be written. */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.resolve(process.argv[2] || '/home/claude/wb/content-src');
const OUT = path.resolve(process.argv[3] || path.join(ROOT, 'site', 'content'));
const GROUPS = { B: 'Basics', S: 'Semantics', I: 'IR', C: 'Contracts', A: 'Analysis', T: 'Transforms', L: 'Lowering', W: 'Backends', E: 'Engine', X: 'Experiments', M: 'Method', J: 'JavaScript scenarios', U: 'Your own' };
const GROUP_ORDER = 'BSICATLWEXMJU';
const warnings = [];
const warn = (where, msg) => warnings.push(`${where}: ${msg}`);

const exists = p => { try { fs.accessSync(p); return true; } catch (e) { return false; } };
const isDir = p => { try { return fs.statSync(p).isDirectory(); } catch (e) { return false; } };
const read = p => fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n');
const rel = p => path.relative(SRC, p) || '.';
function readJSON(p) {
  try { return JSON.parse(read(p)); }
  catch (e) { warn(rel(p), 'not valid JSON (' + e.message + ')'); return null; }
}

/* ---- frontmatter: --- key: value --- ; values: numbers, true/false, [a, b], "quoted" or bare text ---- */
function scalar(v) {
  v = v.trim();
  if (v === '') return '';
  if (/^-?\d+(\.\d+)?$/.test(v)) return +v;
  if (v === 'true' || v === 'false') return v === 'true';
  if (v === 'null' || v === '~') return null;
  if (/^\[.*\]$/.test(v)) {
    const inner = v.slice(1, -1).trim();
    if (!inner) return [];
    try { return JSON.parse(v); } catch (e) { /* bare list */ }
    return inner.split(',').map(s => scalar(s));
  }
  if (/^"(.*)"$/.test(v)) { try { return JSON.parse(v); } catch (e) { return v.slice(1, -1); } }
  if (/^'(.*)'$/.test(v)) return v.slice(1, -1).replace(/''/g, "'");
  return v;
}
function frontmatter(text) {
  const m = /^---[ \t]*\n([\s\S]*?)\n---[ \t]*(\n|$)/.exec(text);
  if (!m) return { meta: {}, body: text };
  const meta = {};
  let lastKey = null;
  for (const line of m[1].split('\n')) {
    if (!line.trim() || /^\s*#/.test(line)) continue;
    const kv = /^([A-Za-z_][\w-]*)\s*:\s*(.*)$/.exec(line);
    if (kv) { lastKey = kv[1]; meta[lastKey] = scalar(kv[2]); continue; }
    const item = /^\s+-\s+(.*)$/.exec(line);
    if (item && lastKey) { if (!Array.isArray(meta[lastKey])) meta[lastKey] = meta[lastKey] === '' ? [] : [meta[lastKey]]; meta[lastKey].push(scalar(item[1])); continue; }
    if (lastKey && /^\s+\S/.test(line) && typeof meta[lastKey] === 'string') { meta[lastKey] += ' ' + line.trim(); continue; }
  }
  return { meta, body: text.slice(m[0].length) };
}
const firstHeading = md => { const m = /^#\s+(.+)$/m.exec(md || ''); return m ? m[1].trim() : null; };

/* ---- files of a preset folder (recursive, forward slashes) ---- */
function walk(dir, base = dir, out = []) {
  for (const name of fs.readdirSync(dir).sort()) {
    if (name.startsWith('.')) continue;
    const p = path.join(dir, name);
    if (isDir(p)) walk(p, base, out);
    else out.push(path.relative(base, p).split(path.sep).join('/'));
  }
  return out;
}

/* ---- presets ---- */
function buildPresets() {
  const dir = path.join(SRC, 'presets');
  if (!isDir(dir)) { warn('presets', 'folder missing: no presets'); return []; }
  const list = [];
  const seen = new Set();
  for (const name of fs.readdirSync(dir).sort()) {
    const pdir = path.join(dir, name);
    if (name.startsWith('.') || !isDir(pdir)) continue;
    const where = 'presets/' + name;
    const meta = exists(path.join(pdir, 'meta.json')) ? (readJSON(path.join(pdir, 'meta.json')) || {}) : (warn(where, 'meta.json missing; using the folder name'), {});
    const id = String(meta.id || name);
    if (meta.id && meta.id !== name) warn(where, `meta.json id ${meta.id} differs from the folder name; using ${id}`);
    if (seen.has(id)) { warn(where, `duplicate id ${id}; skipped`); continue; }
    if (!/^[A-Z]-\d{2,3}$/.test(id)) warn(where, `id ${id} is not of the form X-01`);
    const files = {};
    for (const f of walk(pdir)) {
      if (f === 'meta.json' || f === 'notes.md') continue;
      try { files[f] = read(path.join(pdir, f)); } catch (e) { warn(where, `cannot read ${f} (${e.message})`); }
    }
    if (files['main.js'] == null) { warn(where, 'main.js missing; skipped'); continue; }
    let notes = '';
    if (exists(path.join(pdir, 'notes.md'))) notes = read(path.join(pdir, 'notes.md'));
    else warn(where, 'notes.md missing');
    const letter = id[0];
    const p = {
      id,
      title: String(meta.title || firstHeading(notes) || id),
      group: String(meta.group || GROUPS[letter] || 'Your own'),
      about: String(meta.about || ''),
      tries: Array.isArray(meta.tries) ? meta.tries.map(String) : [],
      files, notes,
      view: meta.view && typeof meta.view === 'object' ? meta.view : {},
      chapters: Array.isArray(meta.chapters) ? meta.chapters : [],
      docs: Array.isArray(meta.docs) ? meta.docs.map(String) : [],
    };
    if (!meta.title) warn(where, 'no title in meta.json');
    if (!GROUPS[letter]) warn(where, `unknown group letter ${letter}`);
    seen.add(id);
    list.push(p);
  }
  list.sort((a, b) => (GROUP_ORDER.indexOf(a.id[0]) + 1 || 99) - (GROUP_ORDER.indexOf(b.id[0]) + 1 || 99) || a.id.localeCompare(b.id, 'en', { numeric: true }));
  return list;
}

/* ---- book ---- */
function buildBook() {
  const dir = path.join(SRC, 'book');
  if (!isDir(dir)) { warn('book', 'folder missing: no book'); return null; }
  const jf = path.join(dir, 'book.json');
  const B = exists(jf) ? readJSON(jf) : (warn('book', 'book.json missing'), null);
  if (!B) return null;
  const mdFiles = fs.readdirSync(dir).filter(f => f.endsWith('.md'));
  const chapters = [];
  for (const c of Array.isArray(B.chapters) ? B.chapters : []) {
    if (!c || c.n == null) { warn('book/book.json', 'a chapter without n; skipped'); continue; }
    const where = `book chapter ${c.n}`;
    let file = c.file;
    if (!file && c.slug) file = mdFiles.find(f => f === c.slug + '.md' || f.replace(/^\d+[-_]/, '') === c.slug + '.md');
    let md = '';
    if (file && exists(path.join(dir, file))) {
      const fm = frontmatter(read(path.join(dir, file)));
      md = fm.body;
    } else if (file) warn(where, `file ${file} missing; the chapter shows as not written`);
    else warn(where, 'no file; the chapter shows as not written');
    chapters.push(Object.assign({}, c, { n: typeof c.n === 'number' ? c.n : String(c.n), title: String(c.title || firstHeading(md) || 'Chapter ' + c.n), presets: Array.isArray(c.presets) ? c.presets : [], docs: Array.isArray(c.docs) ? c.docs : [], md }));
  }
  return { title: String(B.title || 'Compilers from First Principles'), subtitle: B.subtitle ? String(B.subtitle) : '', parts: Array.isArray(B.parts) ? B.parts : [], chapters };
}

/* ---- docs ---- */
function buildDocs() {
  const dir = path.join(SRC, 'docs');
  if (!isDir(dir)) { warn('docs', 'folder missing: no docs'); return []; }
  const list = [];
  const seen = new Set();
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.md')).sort()) {
    const where = 'docs/' + f;
    let text;
    try { text = read(path.join(dir, f)); } catch (e) { warn(where, e.message); continue; }
    const { meta, body } = frontmatter(text);
    const slug = f.replace(/\.md$/, '').replace(/^\d+[-_]/, '');
    const id = String(meta.id || slug);
    if (seen.has(id)) { warn(where, `duplicate doc id ${id}; skipped`); continue; }
    seen.add(id);
    const nn = /^(\d+)/.exec(f);
    if (!meta.id) warn(where, 'no id in frontmatter; using the file name');
    list.push({ id, title: String(meta.title || firstHeading(body) || id), group: String(meta.group || 'Topics'), about: String(meta.about || ''), order: typeof meta.order === 'number' ? meta.order : (nn ? +nn[1] : 999), md: body });
  }
  list.sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
  return list;
}

/* ---- reference ---- */
function buildReference() {
  const p = path.join(SRC, 'reference.md');
  if (!exists(p)) { warn('reference.md', 'missing: the Reference view and the agent get none'); return ''; }
  return frontmatter(read(p)).body;
}

/* ---- write ---- */
if (!isDir(SRC)) { console.error(`build-content: no content source folder at ${SRC}`); process.exit(1); }
fs.mkdirSync(OUT, { recursive: true });
const emit = (key, value) => {
  const js = `/* generated by tools/build-content.js from ${path.basename(SRC)}/; do not edit */\n` +
    'window.STRATA_CONTENT = window.STRATA_CONTENT || {};\n' +
    `window.STRATA_CONTENT.${key} = ${JSON.stringify(value, null, 0).replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029')};\n`;
  fs.writeFileSync(path.join(OUT, key + '.js'), js);
  return Buffer.byteLength(js);
};
let wrote = 0;
const report = [];
const steps = [
  ['presets', buildPresets, v => `${v.length} presets`],
  ['book', buildBook, v => v ? `${v.chapters.length} chapters (${v.chapters.filter(c => c.md.trim()).length} written)` : 'no book'],
  ['docs', buildDocs, v => `${v.length} docs`],
  ['reference', buildReference, v => `${v.split('\n').length} lines`],
];
for (const [key, fn, say] of steps) {
  let v;
  try { v = fn(); } catch (e) { warn(key, 'failed: ' + (e && e.stack || e)); v = key === 'book' ? null : key === 'reference' ? '' : []; }
  const bytes = emit(key, v);
  wrote++;
  report.push(`${key}: ${say(v)}, ${(bytes / 1024).toFixed(1)} KiB`);
}
console.log(`build-content: ${rel(SRC) === '.' ? SRC : SRC} → ${path.relative(process.cwd(), OUT) || OUT}`);
for (const r of report) console.log('  ' + r);
if (warnings.length) { console.log(`${warnings.length} warning${warnings.length === 1 ? '' : 's'}:`); for (const w of warnings) console.log('  ' + w); }
process.exit(wrote ? 0 : 1);
