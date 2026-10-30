#!/usr/bin/env node
/* Screenshots of the workbench, light and dark, wide and narrow, plus a few scenarios.
   usage: node tools/shot.js [--real] [--content=<dir>] [--out=<dir>] [--only=<name,…>]
   Serves site/ over a local http server. By default js/core.js is replaced by test-content/core-stub.js,
   js/frontend.js by an empty script and content/*.js by test-content/out/*.js (build them with
   node tools/build-content.js test-content/src test-content/out). --real serves site/ as it is.
   A fake window.claude (sample + no db) is injected for the agent scenario. Prints console errors. */
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const SITE = path.join(ROOT, 'site');
const args = Object.fromEntries(process.argv.slice(2).map(a => { const m = /^--([\w-]+)(?:=(.*))?$/.exec(a); return m ? [m[1], m[2] == null ? true : m[2]] : [a, true]; }));
const REAL = !!args.real;
const CONTENT = args.content ? path.resolve(args.content) : (REAL ? null : path.join(ROOT, 'test-content', 'out'));
const OUT = path.resolve(args.out || path.join(ROOT, 'test-content', 'shots'));
const ONLY = args.only ? new Set(String(args.only).split(',')) : null;
fs.mkdirSync(OUT, { recursive: true });

const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.woff2': 'font/woff2', '.json': 'application/json', '.svg': 'image/svg+xml' };
function resolve(urlPath) {
  const p = decodeURIComponent(urlPath.split('?')[0]).replace(/^\/+/, '') || 'index.html';
  if (!REAL && p === 'js/core.js') return path.join(ROOT, 'test-content', 'core-stub.js');
  if (!REAL && p === 'js/frontend.js') return null; // empty
  if (CONTENT && /^content\/[\w-]+\.js$/.test(p)) return path.join(CONTENT, path.basename(p));
  const full = path.join(SITE, p);
  return full.startsWith(SITE) ? full : undefined;
}
const server = http.createServer((req, res) => {
  const f = resolve(req.url);
  if (f === null) { res.writeHead(200, { 'content-type': TYPES['.js'] }); res.end('/* stubbed out by tools/shot.js */'); return; }
  if (!f || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end('not found'); return; }
  res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream', 'cache-control': 'no-store' });
  fs.createReadStream(f).pipe(res);
});

/* a fake sample(): one eval step, then an answer that streams */
const FAKE_CLAUDE = `
window.claude = { use: async name => {
  if (name !== 'sample') return null;
  return async (turns, opts) => {
    const tool = opts.tools && opts.tools[0];
    window.__lastTurns = turns;
    let r1 = '';
    if (tool) r1 = await tool.execute({ code: "const f = facts('total');\\nreturn { live: f.live.across['total/body/3'], types: f.types.v6 };" }, { signal: opts.signal });
    if (tool) await tool.execute({ code: "return files.edit('program.js', 'const spare = { v: i + 1 };', '');" }, { signal: opts.signal });
    const text = 'At [total/body/3](lab:node?id=total/body/3) the values **n**, **v5** and **v6** are live, and $v_6$ is an object, so the plan needs a root for it.\\n\\n| value | type |\\n|---|---|\\n| v6 | object |\\n\\nI removed the spare allocation in program.js; [rerun](lab:build) to see the plan shrink.';
    for (let i = 20; i < text.length; i += 40) { opts.onText && opts.onText({ text: text.slice(0, i) }); await new Promise(r => setTimeout(r, 5)); }
    return { text, truncated: false };
  };
} };`;

async function main() {
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/`;
  const browser = await chromium.launch();
  const problems = [];
  const shots = [];
  async function open(name, { width, height, theme, claude, setup }) {
    if (ONLY && !ONLY.has(name)) return null;
    const ctx = await browser.newContext({ viewport: { width, height }, colorScheme: theme === 'dark' ? 'dark' : 'light', deviceScaleFactor: 1 });
    if (claude) await ctx.addInitScript(FAKE_CLAUDE);
    const page = await ctx.newPage();
    page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push(`[${name}] console.${m.type()}: ${m.text()}`); });
    page.on('pageerror', e => problems.push(`[${name}] pageerror: ${e.message}\n${(e.stack || '').split('\n').slice(1, 4).join('\n')}`));
    page.on('requestfailed', r => problems.push(`[${name}] request failed: ${r.url()}`));
    page.on('response', r => { if (r.status() >= 400) problems.push(`[${name}] HTTP ${r.status()}: ${r.url()}`); });
    await page.goto(base + 'index.html');
    await page.waitForTimeout(400);
    if (setup) { try { await setup(page); } catch (e) { problems.push(`[${name}] setup: ${e.message}`); } }
    await page.waitForTimeout(250);
    const file = path.join(OUT, name + '.png');
    await page.screenshot({ path: file });
    const blank = await page.evaluate(() => !document.querySelector('#app') || document.querySelector('#app').innerText.trim().length < 20);
    if (blank) problems.push(`[${name}] the page looks blank`);
    const fails = await page.evaluate(() => [...document.querySelectorAll('.fail')].map(e => e.innerText.slice(0, 160)));
    for (const f of fails) problems.push(`[${name}] .fail row: ${f}`);
    shots.push(file);
    await ctx.close();
    return file;
  }
  const L = name => async page => { await page.evaluate(n => window.StrataShell.Dock.apply(n), name); await page.waitForTimeout(200); };
  const seq = (...fns) => async page => { for (const f of fns) await f(page); };
  const theme = t => async page => { await page.evaluate(t => { window.StrataShell.store.set('theme', t); window.StrataShell.host.ui.theme = t; document.documentElement.setAttribute('data-theme', t); window.StrataShell.host.emit('theme'); }, t); };
  const link = href => async page => { await page.evaluate(h => window.StrataShell.host.link(h), href); await page.waitForTimeout(200); };

  await open('wide-light', { width: 1440, height: 900, theme: 'light' });
  await open('wide-dark', { width: 1440, height: 900, theme: 'dark', setup: theme('dark') });
  await open('narrow-light', { width: 420, height: 860, theme: 'light' });
  await open('narrow-dark', { width: 420, height: 860, theme: 'dark', setup: theme('dark') });
  await open('medium-light', { width: 980, height: 760, theme: 'light' });
  await open('layout-program', { width: 1440, height: 900, theme: 'light', setup: L('The program: IR and stage') });
  await open('layout-reading', { width: 1440, height: 900, theme: 'light', setup: seq(L('Reading the book'), link('lab:book?ch=1')) });
  await open('layout-everything', { width: 1440, height: 900, theme: 'dark', setup: seq(theme('dark'), L('Everything in one tile')) });
  await open('stage-select', { width: 1440, height: 900, theme: 'light', setup: seq(L('Code beside the stage'), link('lab:node?id=total/body/3'), link('lab:overlay?name=types&on=1'), link('lab:overlay?name=roots&on=1')) });
  await open('plan-stress', { width: 1440, height: 900, theme: 'light', setup: seq(link('lab:preset?id=L-01'), async p => p.waitForTimeout(300), link('lab:run?mode=plan&gc=stress'), link('lab:show?view=plan')) });
  await open('laws-dark', { width: 1440, height: 900, theme: 'dark', setup: seq(theme('dark'), link('lab:preset?id=L-01'), async p => p.waitForTimeout(300), link('lab:show?view=laws')) });
  await open('experiments', { width: 1440, height: 900, theme: 'light', setup: seq(link('lab:preset?id=L-01'), async p => p.waitForTimeout(300), link('lab:show?view=experiments')) });
  await open('facts-iteration', { width: 1440, height: 900, theme: 'light', setup: seq(link('lab:fn?name=total'), link('lab:analysis?name=liveness&i=2')) });
  await open('machine', { width: 1440, height: 900, theme: 'light', setup: seq(link('lab:run?mode=spec'), link('lab:step?n=20')) });
  await open('events', { width: 1440, height: 900, theme: 'dark', setup: seq(theme('dark'), link('lab:show?view=events')) });
  await open('ir-l3', { width: 1440, height: 900, theme: 'light', setup: seq(link('lab:level?l=L3'), link('lab:show?view=ir')) });
  await open('code-open', { width: 1440, height: 900, theme: 'light', setup: link('lab:open?file=program.js&line=4') });
  await open('docs', { width: 1440, height: 900, theme: 'light', setup: link('lab:doc?id=fixture-doc&at=lattices') });
  await open('reference', { width: 1440, height: 900, theme: 'light', setup: link('lab:show?view=reference') });
  await open('agent-off', { width: 1440, height: 900, theme: 'light', setup: link('lab:show?view=agent') });
  await open('agent-run', { width: 1440, height: 900, theme: 'light', claude: true, setup: async page => {
    await link('lab:ask?q=Why is v6 rooted?')(page);
    await page.waitForTimeout(300);
    await page.click('.composer [data-act="send"]');
    await page.waitForTimeout(1500);
    const turns = await page.evaluate(() => window.__lastTurns && window.__lastTurns.map(t => ({ role: t.role, len: t.content.length, head: t.content.slice(0, 60), ctx: t.content.includes('[context]') })));
    console.log('agent turns:', JSON.stringify(turns));
  } });
  await open('agent-dark-narrow', { width: 420, height: 860, theme: 'dark', claude: true, setup: seq(theme('dark'), link('lab:show?view=agent')) });
  await open('menus-layout', { width: 1440, height: 900, theme: 'light', setup: async page => { const b = await page.$('[data-act="menu"][data-arg="layout"]'); if (b) await b.click(); else throw new Error('no layout menu button'); } });
  await open('menus-preset', { width: 1440, height: 900, theme: 'light', setup: async page => { const b = await page.$('[data-act="menu"][data-arg="presets"]'); if (b) await b.click(); else throw new Error('no preset menu button'); } });
  await open('build-error', { width: 1440, height: 900, theme: 'light', setup: async page => {
    await page.evaluate(() => { const h = window.StrataShell.host; h.setFile('main.js', 'const x = 1;\nnull.boom;\nreturn x;'); return h.build(); });
    await link('lab:show?view=events')(page);
  } });

  await browser.close();
  server.close();
  console.log(`shot: ${shots.length} screenshots in ${path.relative(process.cwd(), OUT) || OUT}${REAL ? ' (real engine)' : ' (stub engine)'}`);
  if (problems.length) { console.log(`${problems.length} problems:`); for (const p of problems) console.log('  ' + p); }
  else console.log('no console errors, page errors or failed requests');
}
main().catch(e => { console.error(e); server.close(); process.exit(1); });
