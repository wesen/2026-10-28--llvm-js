#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const parts = fs.readdirSync(path.join(root, 'src/core')).filter(n => n.endsWith('.js')).sort();
fs.mkdirSync(path.join(root, 'lib'), {recursive:true});
fs.writeFileSync(path.join(root, 'lib/core.js'), parts.map(n => fs.readFileSync(path.join(root,'src/core',n),'utf8')).join('\n'));
fs.copyFileSync(path.join(root,'src/frontend.js'), path.join(root,'lib/frontend.js'));
