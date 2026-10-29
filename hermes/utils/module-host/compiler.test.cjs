'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const {compileGraph} = require('./compiler.cjs');
function fixture(t, files) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'module-compiler-'));
  t.after(() => fs.rmSync(directory, {recursive:true, force:true}));
  for(const [name, source] of Object.entries(files)) {
    const file=path.join(directory,name);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,source);
  }
  return directory;
}
test('linking never executes source bodies and repeated compilation is deterministic', t => {
  const dir=fixture(t, {'main.mjs':"import {x} from './dep.mjs'; throw Error('body executed');",'dep.mjs':'export const x=1;'});
  const a=compileGraph(path.join(dir,'main.mjs')),b=compileGraph(path.join(dir,'main.mjs'));
  assert.deepEqual(a.check(),{phase:'ready'});assert.equal(a.source,b.source);assert.deepEqual(a.manifest,b.manifest);
});
test('missing exports are linking failures before any body executes',t=>{
  const dir=fixture(t,{'main.mjs':"import {missing} from './dep.mjs';",'dep.mjs':"throw Error('body');"});
  assert.equal(compileGraph(path.join(dir,'main.mjs')).check().phase,'resolution');
});
test('entry parsing and dependency parsing have distinct external phases',t=>{
  const dir=fixture(t,{'main.mjs':"import './bad.mjs';",'bad.mjs':'export const =;'});
  assert.equal(compileGraph(path.join(dir,'bad.mjs')).check().phase,'parse');
  assert.equal(compileGraph(path.join(dir,'main.mjs')).check().phase,'resolution');
});
test('deferred invalid sources do not fail initial linking',t=>{
  const dir=fixture(t,{'main.mjs':"import('./bad.mjs');",'bad.mjs':'export const =;'});
  const graph=compileGraph(path.join(dir,'main.mjs'));assert.equal(graph.check().phase,'ready');
  assert.equal(graph.manifest.modules.find(m=>m.id==='bad.mjs').error.phase,'parse');
});
test('root escape and bare package imports are explicit resolution errors',t=>{
  const dir=fixture(t,{'main.mjs':"import '../outside.mjs';",'bare.mjs':"import 'package';"});
  for(const name of ['main.mjs','bare.mjs']) assert.equal(compileGraph(path.join(dir,name)).check().phase,'resolution');
});
test('symlink aliases identify one record and graph includes use explicit roots',t=>{
  const dir=fixture(t,{'main.mjs':"import './alias.mjs';import './dep.mjs';",'dep.mjs':'export const x=1;','dynamic.mjs':'export const y=2;'});
  fs.symlinkSync('dep.mjs',path.join(dir,'alias.mjs'));
  const graph=compileGraph(path.join(dir,'main.mjs'),{include:[path.join(dir,'dynamic.mjs')]});
  assert.equal(graph.manifest.modules.length,3);assert.equal(graph.manifest.aliases['alias.mjs'],'dep.mjs');
});
test('compiler output cannot overwrite any source through a hardlink',t=>{
  const dir=fixture(t,{'main.mjs':"import './dep.mjs';",'dep.mjs':'export const x=1;'});
  const target=path.join(dir,'output.js');fs.linkSync(path.join(dir,'dep.mjs'),target);
  const result=spawnSync(process.execPath,[path.join(__dirname,'compiler.cjs'),path.join(dir,'main.mjs'),'--output',target,'--manifest',path.join(dir,'manifest.json')],{encoding:'utf8'});
  assert.notEqual(result.status,0);assert.match(result.stderr,/must not overwrite/);assert.equal(fs.readFileSync(target,'utf8'),'export const x=1;');
});
test('module syntax boundaries remain explicit instead of pretending to parse ordinary source',t=>{
  const dir=fixture(t,{'main.mjs':"eval('1');",'phase.mjs':"import source x from './dep.mjs';",'dep.mjs':'export const x=1;'});
  for(const name of ['main.mjs','phase.mjs']) assert.equal(compileGraph(path.join(dir,name)).check().phase,'unsupported');
});
