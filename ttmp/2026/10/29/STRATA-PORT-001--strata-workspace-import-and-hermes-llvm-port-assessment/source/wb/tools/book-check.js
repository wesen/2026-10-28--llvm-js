#!/usr/bin/env node
/* Check chapters of "Compilers from First Principles" against the book's rules
   (content-src/book/BOOK-STYLE.md and the workbench guide "Writing a book section").
   usage: node tools/book-check.js [n | file | all] [--quiet]
   e.g.   node tools/book-check.js 7      node tools/book-check.js 07-permissions.md      node tools/book-check.js
   Errors fail the chapter; warnings should be fixed unless there is a reason. Also checks shelf docs with --docs. */
'use strict';
const path = require('path');
const C = require('./check-common.js');
const { checkSVG } = require('./preset-check.js');

const PROGRAM_PARTS = new Set(['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX']);
const QUOTABLE = { 'core.js': 'site/js/core.js', 'frontend.js': 'site/js/frontend.js', 'markdown.js': 'site/js/markdown.js', 'stage.js': 'site/js/stage.js', 'agent.js': 'site/js/agent.js', 'app.js': 'site/js/app.js' };

async function main() {
  const args = process.argv.slice(2), flags = new Set(args.filter(a => a.startsWith('--'))), wanted = args.filter(a => !a.startsWith('--'));
  C.loadEngine(); const md = C.loadRenderer();
  const plan = C.bookPlan();
  const chapters = new Map((plan.chapters || []).map(c => [String(c.n), c]));
  const docs = C.docIds();
  const presets = new Set(C.presetDirs());
  const bookDir = path.join(C.SRC, 'book');
  const chapterText = ch => (ch && ch.file && C.exists(path.join(bookDir, ch.file)) ? C.read(path.join(bookDir, ch.file)) : null);
  const headings = n => { const t = chapterText(chapters.get(String(n))); return t ? C.headingSlugs(t, md.slug) : null; };
  const docHeadings = id => { const d = docs.get(id); return d ? C.headingSlugs(d.body, md.slug) : null; };
  let list;
  if (flags.has('--docs')) list = [...docs.values()].map(d => ({ doc: true, n: d.meta.id, title: d.meta.title, file: d.file, text: C.read(path.join(C.SRC, 'docs', d.file)) }));
  else list = [...chapters.values()].filter(c => c.file && C.exists(path.join(bookDir, c.file)))
    .filter(c => !wanted.length || wanted.includes('all') || wanted.some(w => String(c.n) === w || c.file === w || (!/^\d+$/.test(w) && c.file.startsWith(w))))
    .map(c => ({ ...c, text: chapterText(c) }));
  let errors = 0, warnings = 0;
  for (const ch of list) {
    const issues = [];
    const err = m => issues.push({ level: 'error', message: m }), warn = m => issues.push({ level: 'warning', message: m });
    const text = ch.doc ? C.frontmatter(ch.text).body : ch.text;
    const lines = text.split('\n');
    // title
    if (!/^# \S/.test(lines[0])) err('line 1 is not "# Title"');
    else if (lines[0].slice(2).trim() !== String(ch.title).trim()) warn(`title "${lines[0].slice(2).trim()}" differs from the plan's "${ch.title}"`);
    // fences
    const fences = lines.filter(l => /^(```|~~~)/.test(l)).length;
    if (fences % 2) err('an unclosed code fence');
    // render
    let html = '';
    try { html = md.render(text, {}); } catch (e) { err('the renderer throws: ' + e.message); }
    if (/class="[^"]*katex-error/.test(html) || /\bParseError\b/.test(html)) err('maths that KaTeX cannot parse');
    const plain = html.replace(/<(script|style|svg)[\s\S]*?<\/\1>/g, '').replace(/<math[\s\S]*?<\/math>/g, '').replace(/<span class="katex[\s\S]*?<\/span>\s*<\/span>\s*<\/span>/g, '').replace(/<pre[\s\S]*?<\/pre>/g, '').replace(/<code[\s\S]*?<\/code>/g, '').replace(/<[^>]+>/g, '');
    if (/(^|[^\\])\$/.test(plain.replace(/\\\$/g, ''))) warn('a stray $ in the rendered text');
    // sections
    const isChapter = !ch.doc && /^\d+$/.test(String(ch.n));
    if (isChapter) {
      const secs = [...text.matchAll(/^## (\d+)\.(\d+) (.*)$/gm)];
      if (secs.length < 3) warn(`${secs.length} numbered sections (four to eight, then Exercises)`);
      secs.forEach((m, i) => { if (m[1] !== String(ch.n) || Number(m[2]) !== i + 1) warn(`section "${m[0].slice(3)}" should be ${ch.n}.${i + 1}`); });
      if (!/^## Exercises\s*$/m.test(text)) warn('no "## Exercises" section');
      if (!secs.some(m => /^Key points/.test(m[3]))) warn('no "N.m Key points" section');
      if (!secs.some(m => /^The running example/.test(m[3]))) warn('no "N.k The running example: …" section');
    }
    // words
    const n = C.words(text);
    if (isChapter && n < 1300) warn(`${n} words of prose (1,500 to 2,500)`);
    if (isChapter && n > 3200) warn(`${n} words of prose (1,500 to 2,500)`);
    // figures
    const figs = [...text.matchAll(/^```svg\n([\s\S]*?)^```\s*$/gm)];
    figs.forEach((f, i) => {
      for (const m of checkSVG(f[1])) err(`figure ${i + 1}: ${m}`);
      const after = text.slice(f.index + f[0].length).replace(/^\s+/, '');
      const cap = /^\*\*Figure ([\w]+)\.(\d+)\.\*\*/.exec(after);
      if (!cap) warn(`figure ${i + 1} has no caption "**Figure N.k.**" right after it`);
      else if (!ch.doc && (cap[1] !== String(ch.n) || Number(cap[2]) !== i + 1)) warn(`figure ${i + 1} is captioned ${cap[1]}.${cap[2]}, expected ${ch.n}.${i + 1}`);
    });
    if (isChapter && figs.length < 2) warn(`${figs.length} figures (at least two)`);
    // quotations
    let quotes = 0;
    for (const q of text.matchAll(/^```js\n\/\/ ([\w./-]+)\s*\n([\s\S]*?)^```\s*$/gm)) {
      const name = q[1];
      let file = QUOTABLE[name];
      const presetFile = /^([A-Z]-\d\d)\/(.+)$/.exec(name);
      let src = null;
      if (file) src = C.read(path.join(C.ROOT, file));
      else if (presetFile && presets.has(presetFile[1])) { const p = C.loadPreset(presetFile[1]); src = p.files[presetFile[2]]; if (src === undefined) { err(`quotation of ${name}: no such file in ${presetFile[1]}`); continue; } }
      else { err(`quotation of ${name}: not a quotable file (core.js, frontend.js, or <preset>/<file>)`); continue; }
      quotes++;
      const norm = s => s.replace(/\s+/g, '');
      const hay = new Set(src.split('\n').map(norm));
      const body = q[2].split('\n').filter(l => l.trim() && l.trim() !== '// …' && l.trim() !== '// ...');
      for (const l of body) if (!hay.has(norm(l))) { err(`quotation of ${name}: this line is not in the file: ${l.trim().slice(0, 90)}`); break; }
      if (body.length > 34) warn(`quotation of ${name} is ${body.length} lines (5 to 30)`);
    }
    const part = ch.part;
    if (isChapter && PROGRAM_PARTS.has(part) && !quotes) warn('no quotation of real code (a js block starting with // core.js or // frontend.js)');
    // links
    const scopePresets = ch.doc ? [] : (ch.presets || []);
    const runs = [];
    for (const id of scopePresets) if (presets.has(id)) runs.push(await C.runPreset(id));
    const linked = new Set();
    for (const l of C.linksOf(text)) {
      const pm = /^lab:preset\?id=([\w-]+)/.exec(l.href); if (pm) linked.add(pm[1]);
      // links to presets not in the chapter's list also bring that preset into scope
      if (pm && presets.has(pm[1]) && !runs.some(r => r.preset.id === pm[1])) runs.push(await C.runPreset(pm[1]));
    }
    const ctx = { presets, chapters, docs, runs, headings, docHeadings };
    // lab:open, lab:fn and lab:node refer to the preset loaded most recently before them in the text, if any.
    let loaded = null;
    for (const l of C.linksOf(text)) {
      const pm = /^lab:preset\?id=([\w-]+)/.exec(l.href);
      if (pm) { loaded = runs.find(r => r.preset.id === pm[1]) || null; }
      const scoped = loaded && /^lab:(open|fn|node)\?/.test(l.href) ? { ...ctx, runs: [loaded] } : ctx;
      let m = C.checkLink(l.href, scoped);
      if (m && scoped !== ctx && !C.checkLink(l.href, ctx)) m += ` (it resolves in another preset, but ${loaded.preset.id} was loaded last)`;
      if (m) err(`link [${l.text}](${l.href}): ${m}`);
    }
    for (const id of scopePresets) {
      if (!presets.has(id)) warn(`preset ${id} of this chapter does not exist yet`);
      else if (!linked.has(id)) warn(`preset ${id} of this chapter is never linked`);
    }
    if (isChapter && !/\*\*Try it\.\*\*/.test(text)) warn('no **Try it.** callout');
    for (const i of C.styleIssues(text, 'prose')) issues.push(i);
    const ne = issues.filter(i => i.level === 'error').length, nw = issues.length - ne;
    errors += ne; warnings += nw;
    console.log(`${ne ? '✗' : nw ? '~' : '✓'} ${ch.doc ? 'doc ' + ch.n : 'chapter ' + ch.n} ${ch.title} · ${n} words · ${figs.length} figures · ${quotes} quotations`);
    if (!flags.has('--quiet') || ne) for (const i of issues) console.log(`    ${i.level}: ${i.message}`);
  }
  console.log(`${list.length} checked · ${errors} errors · ${warnings} warnings`);
  process.exitCode = errors ? 1 : 0;
}
main().catch(e => { console.error(e.stack); process.exitCode = 2; });
