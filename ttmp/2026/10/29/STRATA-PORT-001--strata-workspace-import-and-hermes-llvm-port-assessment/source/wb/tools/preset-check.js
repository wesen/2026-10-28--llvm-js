#!/usr/bin/env node
/* Check presets: meta.json, main.js runs against the real engine, the returned program behaves as
   the preset says, the notes follow the house style and every lab: link resolves.
   usage: node tools/preset-check.js [ID-or-prefix …] [--quiet] [--json]
   e.g.   node tools/preset-check.js I-03     node tools/preset-check.js C-     node tools/preset-check.js
   meta.json keys: id, title, group, about, tries [..], view { fn, level, tab, overlays, mode, gc }, chapters [n], docs [id],
   and optionally expect { compile: 'ok' | 'errors', outcome: 'normal' | 'throw' | 'error' | 'diverge', stale: true }
   (expect describes what a preset demonstrates on purpose, such as a plan that fails). */
'use strict';
const C = require('./check-common.js');

const GROUPS = { B: 'Basics', S: 'Semantics', I: 'IR', C: 'Contracts', A: 'Analysis', T: 'Transforms', L: 'Lowering', W: 'Backends', E: 'Engine', X: 'Experiments', M: 'Method', J: 'JavaScript scenarios', U: 'Your own' };

async function main() {
  const args = process.argv.slice(2), flags = new Set(args.filter(a => a.startsWith('--'))), wanted = args.filter(a => !a.startsWith('--'));
  const strata = C.loadEngine();
  const md = C.loadRenderer();
  const all = C.presetDirs();
  const ids = wanted.length ? all.filter(id => wanted.some(w => id === w || id.startsWith(w))) : all;
  const plan = C.bookPlan();
  const chapters = new Map((plan.chapters || []).map(c => [String(c.n), c]));
  const docs = C.docIds();
  const presets = new Set(all);
  let errors = 0, warnings = 0;
  const report = [];
  for (const id of ids) {
    const issues = [];
    const err = m => issues.push({ level: 'error', message: m }), warn = m => issues.push({ level: 'warning', message: m });
    let p;
    try { p = C.loadPreset(id); } catch (e) { err('meta.json: ' + e.message); report.push({ id, issues }); errors++; continue; }
    const meta = p.meta;
    if (meta.id !== id) err(`meta.id ${meta.id} differs from the folder name`);
    if (!/^[A-Z]-\d\d$/.test(id)) err('id must be a group letter, a dash and two digits');
    if (GROUPS[id[0]] && meta.group !== GROUPS[id[0]]) err(`group should be "${GROUPS[id[0]]}" for ${id[0]}`);
    for (const k of ['title', 'about']) if (!meta[k] || typeof meta[k] !== 'string') err(`meta.${k} missing`);
    if (meta.about && meta.about.length > 160) warn(`about is ${meta.about.length} characters; keep it to one short sentence`);
    if (!Array.isArray(meta.tries) || meta.tries.length < 2) warn('tries: give two to four questions for the agent');
    for (const ch of meta.chapters || []) if (!chapters.has(String(ch))) warn(`chapter ${ch} is not in book.json`);
    for (const d of meta.docs || []) if (!docs.has(d)) (C.FINAL || !C.PLANNED.docs.has(d) ? err : () => {})(`doc ${d} does not exist${C.PLANNED.docs.has(d) ? ' yet (planned)' : ' and is not planned'}`);
    if (!p.files['main.js']) err('no main.js');
    // run it
    const run = await C.runPreset(id);
    const expect = meta.expect || {};
    let line = '';
    if (!run.res.ok) err(`main.js failed: ${run.res.error.message}${run.res.error.line ? ' (line ' + run.res.error.line + ')' : ''}`);
    else {
      const c = run.classified;
      const kinds = Object.keys(c).filter(k => c[k] !== undefined);
      if (!kinds.some(k => ['program', 'run', 'laws', 'results'].includes(k))) warn('main.js returns nothing the views show (a Program, RunResult, LawReport or Results)');
      if (run.program) {
        const prog = run.program;
        const want = expect.compile || 'ok';
        if (want === 'ok' && !prog.ok) err(`the program has errors: ${prog.diagnostics.filter(d => d.severity === 'error').slice(0, 2).map(d => d.message).join('; ')}`);
        if (want === 'errors' && prog.ok) err('expect.compile is "errors" but the program compiles');
        const v = meta.view || {};
        if (v.fn && !run.functions.has(v.fn)) err(`view.fn ${v.fn} is not a function of the program (${[...run.functions].join(', ')})`);
        if (v.level && !C.LEVELS.includes(v.level)) err(`view.level ${v.level} unknown`);
        if (v.tab && !C.VIEWS.includes(v.tab)) err(`view.tab ${v.tab} unknown`);
        for (const o of v.overlays || []) if (!C.OVERLAYS.includes(o)) err(`overlay ${o} unknown`);
        if (prog.ok || want === 'errors') {
          let r;
          try { r = prog.ok ? prog.run({ mode: v.mode || 'spec', gc: v.gc || 'off' }) : null; } catch (e) { err('run threw: ' + e.message); }
          if (r) {
            const stale = r.events.filter(e => e.type === 'stale').length;
            if (expect.outcome && r.outcome.kind !== expect.outcome) err(`outcome ${r.outcome.kind}, expected ${expect.outcome}${r.error ? ': ' + r.error.message : ''}`);
            if (!expect.outcome && r.outcome.kind === 'error') err(`the run stops with an engine error: ${r.error && r.error.message}`);
            if (stale && !expect.stale) err(`${stale} stale uses in ${v.mode || 'spec'} mode`);
            if (expect.stale && !stale) err('expect.stale but the run has no stale use');
            line = `${prog.functions().length} fn · ${v.mode || 'spec'}${v.gc && v.gc !== 'off' ? '/' + v.gc : ''} ${r.outcome.kind} ${(r.output || []).slice(0, 3).join(' | ').slice(0, 60)}`;
            if (prog.ok && (v.mode || 'spec') !== 'spec') {
              const s = prog.run({ mode: 'spec' });
              if (r.outcome.kind !== 'error' && JSON.stringify(s.output) !== JSON.stringify(r.output)) warn(`spec and ${v.mode} outputs differ`);
            }
          }
        } else line = 'compile errors';
      } else line = kinds.join(', ');
      if (c.laws) {
        const laws = c.laws.laws || [];
        const failing = laws.filter(l => l.ok === false);
        line += ` · laws ${laws.length - failing.length}/${laws.length}`;
        if (failing.length && !expect.lawsFail) warn(`laws failing: ${failing.map(l => l.name).join(', ')} (set expect.lawsFail if that is the point)`);
      }
      if (c.results) line += ` · results ${c.results.rows ? c.results.rows.length : 0} rows`;
    }
    // notes
    if (!p.notes) err('no notes.md');
    else {
      if (!/^# \S/.test(p.notes)) err('notes.md must start with "# Title"');
      const title = (/^# (.*)$/m.exec(p.notes) || [])[1];
      if (title && meta.title && title.trim() !== meta.title.trim()) warn(`notes title "${title}" differs from meta.title "${meta.title}"`);
      const n = C.words(p.notes);
      if (n < 300) warn(`notes are ${n} words; aim for 500 to 1,000`);
      if (n > 1400) warn(`notes are ${n} words; aim for 500 to 1,000`);
      if (!/\*\*Try it\.\*\*/.test(p.notes)) warn('no **Try it.** callout');
      if (!/\*\*Exercise/.test(p.notes)) warn('no **Exercise.**');
      for (const i of C.styleIssues(p.notes, 'notes')) issues.push(i);
      try { md.render(p.notes, {}); } catch (e) { err('the renderer throws on notes.md: ' + e.message); }
      for (const svg of p.notes.match(/^```svg\n[\s\S]*?^```/gm) || []) for (const m of checkSVG(svg.replace(/^```svg\n|```$/g, ''))) issues.push({ level: 'error', message: 'figure: ' + m });
      const ctx = { presets, chapters, docs, runs: [run], headings: null };
      for (const l of C.linksOf(p.notes)) { const m = C.checkLink(l.href, ctx); if (m) err(`link [${l.text}](${l.href}): ${m}`); }
    }
    errors += issues.filter(i => i.level === 'error').length; warnings += issues.filter(i => i.level === 'warning').length;
    report.push({ id, title: meta.title, words: p.notes ? C.words(p.notes) : 0, line, issues });
  }
  if (flags.has('--json')) { console.log(JSON.stringify(report, null, 1)); return; }
  for (const r of report) {
    const bad = r.issues.some(i => i.level === 'error');
    console.log(`${bad ? '✗' : r.issues.length ? '~' : '✓'} ${r.id} ${r.title || ''} · ${r.line || ''} · notes ${r.words} words`);
    if (!flags.has('--quiet') || bad) for (const i of r.issues) console.log(`    ${i.level}: ${i.message}`);
  }
  console.log(`${report.length} presets · ${errors} errors · ${warnings} warnings`);
  process.exitCode = errors ? 1 : 0;
}

// The figure rules shared with the book: well-formed XML, a viewBox, classes not colours.
function checkSVG(src) {
  const out = [];
  const sax = require('/opt/npm-tools/node_modules/sax');
  const parser = sax.parser(true);
  let first = null;
  parser.onerror = e => { out.push('not well-formed XML: ' + e.message.split('\n')[0]); parser.error = null; parser.resume(); };
  parser.onopentag = node => {
    if (!first) first = node;
    if (['style', 'script', 'image', 'foreignObject'].includes(node.name)) out.push(`<${node.name}> is not allowed`);
    for (const [k, v] of Object.entries(node.attributes)) {
      if ((k === 'fill' || k === 'stroke' || k === 'color' || k === 'stop-color') && !['none', 'currentColor', 'url(#arrow)'].includes(v) && !/^url\(#/.test(v)) out.push(`${k}="${v}": use the classes, not a colour`);
      if (k === 'style' && /(fill|stroke|color)\s*:/.test(v)) out.push('a colour in a style attribute');
      if (k === 'font-size' && (Number(v) < 8 || Number(v) > 18)) out.push(`font-size ${v} outside 8 to 18`);
    }
  };
  try { parser.write(src.trim()).close(); } catch (e) { out.push('not well-formed XML: ' + e.message.split('\n')[0]); }
  if (!first || first.name !== 'svg') out.push('the block must start with <svg');
  else {
    const vb = first.attributes.viewBox;
    if (!vb) out.push('no viewBox');
    else { const w = Number(vb.split(/[\s,]+/)[2]); if (w > 760) out.push(`viewBox ${w} wide (at most 720)`); }
  }
  return [...new Set(out)];
}

module.exports = { checkSVG };
if (require.main === module) main().catch(e => { console.error(e.stack); process.exitCode = 2; });
