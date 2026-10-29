import {strToU8,strFromU8,gzipSync,gunzipSync,zipSync,unzipSync,Gzip,Gunzip} from '../node_modules/fflate/esm/browser.js';
const documents = globalThis.APP_INPUT.documents;
const files = Object.create(null);
let inputBytes = 0;
for (const document of documents) {
  const bytes = strToU8(document.text);
  inputBytes += bytes.length;
  files[document.name] = [bytes,{mtime:new Date('2020-01-01T00:00:00Z')}];
  const compressed = gzipSync(bytes,{level:6,mtime:0});
  if (strFromU8(gunzipSync(compressed)) !== document.text) throw Error('gzip roundtrip');
}
const archive = zipSync(files,{level:6});
const restored = unzipSync(archive);
const names = Object.keys(restored).sort();
for (const document of documents)
  if (strFromU8(restored[document.name]) !== document.text) throw Error('zip roundtrip');
// Streaming compression/decompression exercises callbacks and retained state.
const chunks = [];
const gzip = new Gzip({mtime:0}, (chunk, final) => chunks.push(chunk));
for (let i=0;i<documents.length;i++) gzip.push(strToU8(documents[i].text), i===documents.length-1);
const decoded = [];
const gunzip = new Gunzip((chunk, final) => decoded.push(chunk));
for (let i=0;i<chunks.length;i++) gunzip.push(chunks[i],i===chunks.length-1);
let length=0;for(const chunk of decoded)length+=chunk.length;
const all=new Uint8Array(length);let offset=0;
for(const chunk of decoded){all.set(chunk,offset);offset+=chunk.length;}
if(strFromU8(all)!==documents.map(x=>x.text).join(''))throw Error('stream roundtrip');
let rejected=false;try{unzipSync(new Uint8Array([1,2,3]));}catch(error){rejected=true;}
if(!rejected)throw Error('corrupt archive accepted');
let checksum=0;for(const byte of archive)checksum=(Math.imul(checksum,31)+byte)>>>0;
print(JSON.stringify({application:'archive-library',version:'fflate@0.8.2',files:names,
  inputBytes,archiveBytes:archive.length,checksum,streamBytes:length,corruptRejected:rejected,zipBytes:Array.from(archive),
  gzipBytes:Array.from(gzipSync(strToU8(documents.map(x=>x.text).join('')),{mtime:0}))}));
