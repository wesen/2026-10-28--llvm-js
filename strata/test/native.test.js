'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const {build}=require('../tools/strata-native');
const out=process.argv[2]||'/tmp/strata-native-tests';fs.mkdirSync(out,{recursive:true});
const files=fs.readdirSync(path.join(__dirname,'fixtures')).filter(f=>f.endsWith('.js')).sort();
const rows=[];
for(const name of files){
 const input=path.join(__dirname,'fixtures',name);
 const oracle=spawnSync(process.execPath,['-e',"globalThis.print=(...xs)=>console.log(xs.map(String).join(' '));require(process.argv[1]);",input],{encoding:'utf8',timeout:30000});
 assert.equal(oracle.status,0,oracle.stderr);
 for(const optimization of ['0','2']){
  try{
   const {output,manifest}=build(input,{output:path.join(out,name+'-O'+optimization),optimization});
   const actual=spawnSync(output,[],{encoding:'utf8',timeout:30000});
   assert.equal(actual.status,0,actual.stderr);assert.equal(actual.stdout,oracle.stdout);
   rows.push({name,optimization,ok:true,output:actual.stdout,roots:manifest.functions.map(f=>({name:f.name,roots:f.rootSlots}))});
   console.log('PASS',name,'O'+optimization);
  }catch(e){rows.push({name,optimization,ok:false,error:e.message});console.error('FAIL',name,'O'+optimization,e.message);}
 }
}
fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(rows,null,2)+'\n');
console.log(`${rows.filter(r=>r.ok).length}/${rows.length} passed`);process.exitCode=rows.some(r=>!r.ok)?1:0;
