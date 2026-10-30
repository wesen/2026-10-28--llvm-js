#!/usr/bin/env node
/* Render a Markdown file (a chapter, a doc or preset notes) with the workbench's renderer and
   stylesheets, and screenshot it, so figures and tables can be looked at.
   usage: node tools/render-page.js <file.md> <out.png> [--dark] [--width=760] [--figures]
   --figures writes one PNG per figure instead (<out>-fig1.png, …). */
'use strict';
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const C = require('./check-common.js');

(async () => {
  const args = process.argv.slice(2);
  const [file, out] = args.filter(a => !a.startsWith('--'));
  if (!file || !out) { console.error('usage: node tools/render-page.js <file.md> <out.png> [--dark] [--width=760] [--figures]'); process.exit(2); }
  const dark = args.includes('--dark'), figures = args.includes('--figures');
  const width = Number((args.find(a => a.startsWith('--width=')) || '--width=760').split('=')[1]);
  const md = C.loadRenderer();
  const text = C.frontmatter(C.read(path.resolve(file))).body;
  const body = md.render(text, { prefix: 'p-', toc: false });
  const css = ['kiln.css', 'strata.css'].map(f => `<link rel="stylesheet" href="file://${path.join(C.ROOT, 'site/css', f)}">`).join('');
  const html = `<!DOCTYPE html><html lang="en-GB" data-theme="${dark ? 'dark' : 'light'}"><head><meta charset="utf-8">${css}
    <style>body{margin:0;background:var(--bg,#fff)} .wrap{max-width:${width}px;margin:0 auto;padding:24px}</style></head>
    <body><div class="wrap"><div class="doc">${body}</div></div></body></html>`;
  const tmp = path.join(require('os').tmpdir(), `render-${process.pid}.html`);
  fs.writeFileSync(tmp, html);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: width + 48, height: 900 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + tmp);
  if (figures) {
    const figs = await page.$$('.fig');
    for (let i = 0; i < figs.length; i++) await figs[i].screenshot({ path: out.replace(/\.png$/, '') + `-fig${i + 1}.png` });
    console.log(`${figs.length} figures written next to ${out}`);
  } else {
    await page.screenshot({ path: out, fullPage: true });
    console.log(`wrote ${out}`);
  }
  if (errors.length) console.log('page errors:', errors.join('; '));
  await browser.close();
  fs.unlinkSync(tmp);
})();
