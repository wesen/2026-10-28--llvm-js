from pathlib import Path
import json,hashlib,gzip,shutil
p=Path('ttmp/2026/10/29/STRATA-PORT-001--strata-workspace-import-and-hermes-llvm-port-assessment/reference/evidence')
identity=None
summary={}
for kind in ['normal','stress']:
 src=Path('/tmp/strata-final-'+kind+'/results.json');rows=json.loads(src.read_text());assert len(rows)==76 and all(r['ok'] for r in rows)
 for row in rows:
  if identity is None:identity=row['compilerInputs']
  assert identity==row['compilerInputs'], 'Compiler fingerprint changed during qualification'
  assert hashlib.sha256(Path('strata/test/fixtures',row['name']).read_bytes()).hexdigest()==row['sourceSHA256']
 for name,digest in identity.items():assert hashlib.sha256(Path('strata',name).read_bytes()).hexdigest()==digest,name
 (p/('final-native-'+kind+'.json.gz')).write_bytes(gzip.compress(src.read_bytes(),mtime=0))
 summary[kind]={'checks':len(rows),'normal_executions':sum(r['outcome']=='normal' for r in rows),'expected_language_errors':sum(r['outcome']!='normal' for r in rows),'runtimeLibraries':rows[0]['runtimeLibraries']}
wide=json.load(open('/tmp/strata-roots-results.json'))
summary['wide']={k:v for k,v in wide['wide'].items() if k!='homes'}
summary['compilerInputs']=identity
summary['boundaries']={'unsupported_contexts':8,'parse_errors':1}
summary['root_assignment_negative']='colliding assignment rejected'
summary['driver_checks']='failed compile preserves all five artifacts; source collision and invalid optimization rejected'
summary['gc_negative']=json.load(open('/tmp/strata-gc-negative/result.json'))
summary['gc_negative']['diagnostic']='AddressSanitizer SEGV/invalid read in JSObject::defineOwnPropertyInternal; not labeled heap-use-after-free'
(p/'native-qualification-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
shutil.copyfile('/tmp/strata-gc-negative/mutant.stderr.txt',p/'gc-negative.stderr.txt')
print({k:v for k,v in summary.items() if k in ['wide','boundaries']})
print('All 152 checks passed with identical compiler fingerprints; source hashes match final fixtures')
