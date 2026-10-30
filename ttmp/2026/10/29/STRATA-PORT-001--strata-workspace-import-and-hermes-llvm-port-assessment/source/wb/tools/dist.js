#!/usr/bin/env node
/* Copy site/ to dist/ for publishing: fonts inlined into stage.css as data: URIs (the page's
   font policy allows data: fonts), everything else as it is. Prints the file list for publish_files.
   usage: node tools/dist.js */
'use strict';
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..');
const SITE = path.join(ROOT, 'site'), DIST = path.join(ROOT, 'dist');
fs.rmSync(DIST, { recursive: true, force: true });
const files = [];
function copy(dir) {
  for (const e of fs.readdirSync(path.join(SITE, dir), { withFileTypes: true })) {
    const rel = path.join(dir, e.name);
    if (e.isDirectory()) { if (rel === 'fonts') continue; copy(rel); continue; }
    const src = path.join(SITE, rel), dst = path.join(DIST, rel);
    fs.mkdirSync(path.dirname(dst), { recursive: true });
    if (rel.startsWith(path.join('js', 'vendor'))) continue;   // served from jsDelivr instead (see index.html below)
    if (rel === 'index.html') {
      // The vendored libraries are npm's own files; the published page loads the same versions from jsDelivr.
      const html = fs.readFileSync(src, 'utf8')
        .replace('<script src="js/vendor/acorn.js"></script>', '<script src="https://cdn.jsdelivr.net/npm/acorn@8.18.0/dist/acorn.js"></script>')
        .replace('<script src="js/vendor/katex.min.js"></script>', '<script src="https://cdn.jsdelivr.net/npm/katex@0.16.47/dist/katex.min.js"></script>');
      if (/js\/vendor\//.test(html)) throw new Error('index.html still loads a vendored file');
      fs.mkdirSync(path.dirname(dst), { recursive: true }); fs.writeFileSync(dst, html); files.push(rel); continue;
    }
    if (rel === path.join('css', 'stage.css')) {
      const css = fs.readFileSync(src, 'utf8').replace(/url\("\.\.\/fonts\/([\w.-]+\.woff2)"\)/g, (m, f) =>
        `url("data:font/woff2;base64,${fs.readFileSync(path.join(SITE, 'fonts', f)).toString('base64')}")`);
      fs.writeFileSync(dst, css);
    } else fs.copyFileSync(src, dst);
    files.push(rel.split(path.sep).join('/'));
  }
}
copy('');
const total = files.reduce((n, f) => n + fs.statSync(path.join(DIST, f)).size, 0);
console.log(JSON.stringify(files.map(f => ({ as: f, path: path.join(DIST, f) }))));
console.error(`${files.length} files, ${(total / 1024).toFixed(0)} KiB in dist/`);
