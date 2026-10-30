#!/usr/bin/env node
/* Load every built-in preset in the real page (Chromium), wait for its build, and report what the
   header would show; screenshot a few views. Catches problems that only show in the browser.
   usage: node tools/tour.js [--out=/tmp/tour] [--only=B-01,M-07] [--shots] */
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const ROOT = path.resolve(__dirname, '..'), SITE = path.join(ROOT, 'site');
const args = Object.fromEntries(process.argv.slice(2).map(a => { const m = /^--([\w-]+)(?:=(.*))?$/.exec(a); return m ? [m[1], m[2] == null ? true : m[2]] : [a, true]; }));
const OUT = path.resolve(args.out || '/tmp/tour');
fs.mkdirSync(OUT, { recursive: true });
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.woff2': 'font/woff2' };
const server = http.createServer((req, res) => {
  const p = decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html';
  const f = path.join(SITE, p);
  if (!f.startsWith(SITE) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
});

(async () => {
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(`pageerror: ${e.message}`));
  page.on('console', m => { if (m.type() === 'error') errors.push(`console.error: ${m.text()}`); });
  await page.goto(base);
  await page.waitForFunction(() => window.StrataShell && window.StrataShell.host && window.STRATA_CONTENT, null, { timeout: 15000 });
  const ids = await page.evaluate(() => window.STRATA_CONTENT.presets.map(p => p.id));
  const only = args.only ? new Set(String(args.only).split(',')) : null;
  const rows = [];
  for (const id of ids) {
    if (only && !only.has(id)) continue;
    const before = errors.length;
    const t0 = Date.now();
    const r = await page.evaluate(async id => {
      const h = window.StrataShell.host;
      h.loadPreset(id);
      for (let i = 0; i < 200 && (h.busy || !h.buildInfo || h.preset.id !== id); i++) await new Promise(r => setTimeout(r, 50));
      await new Promise(r => setTimeout(r, 100));
      const bi = h.buildInfo || {};
      return { ok: !!bi.ok, kind: bi.kind || null, message: bi.message || null, program: h.program ? h.program.ok : null,
        run: h.run && h.run.outcome ? h.run.outcome.kind : null, out: h.run && h.run.output ? h.run.output.slice(0, 2).join(' | ') : '',
        laws: h.laws && h.laws.laws ? h.laws.laws.length : 0, results: h.results && h.results.rows ? h.results.rows.length : 0,
        fails: [...document.querySelectorAll('.fail')].length };
    }, id);
    r.ms = Date.now() - t0; r.id = id; r.errors = errors.slice(before);
    rows.push(r);
    console.log(`${r.ok && !r.errors.length ? '✓' : '✗'} ${id} ${r.ms} ms · ${r.kind || ''} ${r.program === false ? '(program has errors)' : ''} ${r.run || ''} ${r.out.slice(0, 50)}${r.laws ? ' · laws ' + r.laws : ''}${r.results ? ' · rows ' + r.results : ''}${r.message ? ' · ' + r.message : ''}${r.errors.length ? '\n    ' + r.errors.join('\n    ') : ''}`);
  }
  if (args.shots) {
    const shoot = async (name, steps) => { for (const s of steps) { await page.evaluate(h => window.StrataShell.host.link(h), s); await page.waitForTimeout(500); } await page.screenshot({ path: path.join(OUT, name + '.png') }); };
    await shoot('book-ch13', ['lab:preset?id=L-03', 'lab:book?ch=13']);
    await shoot('docs-ssa', ['lab:doc?id=ssa']);
    await shoot('m07-laws', ['lab:preset?id=M-07', 'lab:show?view=laws']);
    await shoot('x03-experiments', ['lab:preset?id=X-03', 'lab:show?view=experiments']);
    await shoot('w01-wat', ['lab:preset?id=W-01', 'lab:level?l=WAT', 'lab:show?view=ir']);
    await shoot('a02-facts', ['lab:preset?id=A-02', 'lab:analysis?name=liveness&i=3']);
    await shoot('l05-stale', ['lab:preset?id=L-05', 'lab:show?view=machine']);
    await shoot('e06-laws', ['lab:preset?id=E-06', 'lab:show?view=laws']);
  }
  const bad = rows.filter(r => !r.ok || r.errors.length);
  console.log(`${rows.length} presets loaded in the page · ${bad.length} with problems · ${errors.length} page errors in all`);
  await browser.close(); server.close();
  process.exitCode = bad.length ? 1 : 0;
})().catch(e => { console.error(e); server.close(); process.exit(2); });
