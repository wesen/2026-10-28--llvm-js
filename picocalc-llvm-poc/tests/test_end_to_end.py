import json
import random
import re
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'compiler'))
from compile import compile_js,check_elf

class PicoHostTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='pico-poc-tests-')
        d=Path(cls.tmp.name)
        cls.files={}
        for name,base in [('counter_v1',0x100000),('counter_v2',0x200000),('fault',0x100000),('spin',0x200000),('bad_migrate',0x100000),('native_counter',0x100000),('display_v1',0x100000)]:
            p=d/f'{name}.elf';lang='c' if name=='native_counter' else 'js'
            meta=compile_js((ROOT/'worlds'/f'{name}.{lang}').read_text(),p,base,language=lang)
            cls.files[name]=p
            assert meta['no_libc'] and meta['target']=='riscv32-unknown-elf'
    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()
    def run_guest(self,source='counter_v1',scenario='',cap=True,fuel=15000,schema=1,expected_rc=0):
        cmd=[str(ROOT/'build/pico-sim'),'--module',str(self.files[source]),'--schema',str(schema),'--fuel',str(fuel)]
        if cap:cmd+=['--cap','emit']
        p=subprocess.run(cmd,input=scenario,text=True,capture_output=True,cwd=ROOT)
        self.assertEqual(p.returncode,expected_rc,f'stdout={p.stdout} stderr={p.stderr}')
        return [json.loads(x) for x in p.stdout.splitlines() if x],p
    def test_freestanding_elf_code_slots_and_no_libc(self):
        for name,p in self.files.items():
            data=p.read_bytes()
            self.assertEqual(data[:4],b'\x7fELF')
            self.assertEqual(struct.unpack_from('<HH',data,16),(2,243))
            self.assertTrue(check_elf(p,0x200000 if name in ('spin','counter_v2') else 0x100000)['no_libc'])
            dynamic=subprocess.run(['readelf','-d',str(p)],capture_output=True,text=True)
            self.assertNotIn('NEEDED',dynamic.stdout)
            symbols=subprocess.run(['readelf','--wide','-s',str(p)],capture_output=True,text=True).stdout
            self.assertIn('pico_world_step',symbols)
            self.assertIn('pico_world_migrate',symbols)
            self.assertFalse([ln for ln in symbols.splitlines() if re.search(r'\bUND\b',ln) and not re.match(r'\s*0:',ln)])
    def test_llvm_o0_o2_oz_equivalence(self):
        src=(ROOT/'worlds/counter_v1.js').read_text()
        with tempfile.TemporaryDirectory() as d:
            for opt in ('0','2','s'):
                out=Path(d)/f'module_O{opt}.elf'
                compile_js(src,out,0x100000,opt)
                cmd=[str(ROOT/'build/pico-sim'),'--module',str(out),'--cap','emit','--fuel','25000']
                p=subprocess.run(cmd,input='dispatch 1 7\ndispatch 2 0\nexpect score 14\n',capture_output=True,text=True,cwd=ROOT)
                self.assertEqual(p.returncode,0,f'optimizer {opt}: {p.stderr} {p.stdout}')
                rec=[json.loads(x) for x in p.stdout.splitlines()]
                self.assertEqual([r['effects'] for r in rec if r['event']=='dispatch'],[[7],[14]])
    def test_freestanding_c_guest_with_native_calls_and_stack(self):
        rec,_=self.run_guest(source='native_counter',scenario='dispatch 1 4\nexpect score 12\nexpect ticks 1\n')
        self.assertEqual(rec[0]['effects'],[12])
        self.assertEqual(rec[0]['score'],12)
    def test_pixel_effects_commit_only_after_success(self):
        with tempfile.TemporaryDirectory() as d:
            a=Path(d)/'a.ppm';b=Path(d)/'b.ppm'
            cmd=[str(ROOT/'build/pico-sim'),'--module',str(self.files['display_v1']),'--cap','display']
            text=f'dispatch 1 0\ncapture {a}\ndispatch 3 0\ncapture {b}\n'
            run=subprocess.run(cmd,input=text,capture_output=True,text=True,cwd=ROOT,check=True)
            records=[json.loads(x) for x in run.stdout.splitlines()]
            self.assertEqual(records[0]['pixels'],112216)
            self.assertIn('abort 99',records[2]['reason'])
            self.assertEqual(a.read_bytes(),b.read_bytes(),'faulting turn modified committed display')
            data=a.read_bytes();prefix=b'P6\n320 320\n255\n'
            self.assertTrue(data.startswith(prefix))
            self.assertEqual(data[len(prefix):len(prefix)+3],bytes([255,0,0]))
            self.assertEqual(records[2]['discarded_effects'],1)
    def test_display_capability_denied(self):
        rec,_=self.run_guest(source='display_v1',scenario='dispatch 1 0\nexpect ticks 0\n')
        self.assertFalse(rec[0]['ok']);self.assertIn('capability denied: display',rec[0]['reason'])
    def test_compiled_code_executes_with_effects(self):
        records,_=self.run_guest(scenario='dispatch 1 4\ndispatch 2 0\nexpect score 8\nexpect ticks 1\n')
        self.assertEqual([r['effects'] for r in records if r['event']=='dispatch'],[[4],[8]])
        self.assertEqual(records[1]['score'],8)
    def test_reload_schema_migration_and_stale_messages(self):
        scenario=f'dispatch 1 3\nqueue 1 7\nreload {self.files["counter_v2"]} 2\ndrain\ndispatch 1 4\nexpect score 43\nexpect flags 42\nexpect ticks 2\nexpect epoch 2\n'
        records,_=self.run_guest(scenario=scenario)
        reload=next(x for x in records if x['event']=='reload')
        self.assertTrue(reload['ok']);self.assertEqual(reload['schema'],2);self.assertEqual(reload['score'],3)
        self.assertEqual(len([x for x in records if x['event']=='stale']),1)
    def test_failed_migration_keeps_old_code_and_epoch(self):
        scenario=f'dispatch 1 3\nreload {self.files["counter_v2"]} 2\nreload {self.files["bad_migrate"]} 3\ndispatch 1 4\nexpect score 43\nexpect epoch 2\n'
        rec,_=self.run_guest(scenario=scenario)
        self.assertEqual([(r['ok'],r['epoch']) for r in rec if r['event']=='reload'],[(True,2),(False,2)])
        self.assertIn('world abort 33',next(r['reason'] for r in rec if r['event']=='reload' and not r['ok']))
    def test_schema_mismatch_rolls_back_reload(self):
        rec,_=self.run_guest(scenario=f'reload {self.files["counter_v2"]} 99\nexpect epoch 1\n')
        self.assertFalse(rec[0]['ok']);self.assertIn('schema mismatch',rec[0]['reason'])
    def test_guest_fault_rolls_back_state_and_effects(self):
        rec,_=self.run_guest(source='fault',scenario='dispatch 1 5\nexpect score 0\nexpect ticks 0\n')
        self.assertEqual(rec[0]['event'],'fault');self.assertIn('abort 66',rec[0]['reason'])
        self.assertEqual(rec[0]['discarded_effects'],1);self.assertEqual(rec[0]['score'],0)
    def test_capability_is_enforced_at_ecall_boundary(self):
        rec,_=self.run_guest(cap=False,scenario='dispatch 1 8\nexpect score 0\n')
        self.assertFalse(rec[0]['ok']);self.assertIn('capability denied',rec[0]['reason'])
        self.assertEqual(rec[0]['score'],0)
    def test_instruction_fuel_preempts_infinite_loop(self):
        rec,_=self.run_guest(source='spin',scenario='dispatch 1 0\nexpect score 0\n',fuel=300)
        self.assertEqual(rec[0]['steps'],300)
        self.assertIn('fuel exhausted',rec[0]['reason'])
    def test_malformed_elf_rejected(self):
        p=Path(self.tmp.name)/'bad.elf';original=self.files['counter_v1'].read_bytes()
        p.write_bytes(b'not elf')
        _,run=self.run_guest(source='counter_v1',scenario='')
        r=subprocess.run([str(ROOT/'build/pico-sim'),'--module',str(p)],capture_output=True,text=True)
        self.assertNotEqual(r.returncode,0)
        self.assertIn('not ELF',r.stderr)
        bad=bytearray(original);phoff=struct.unpack_from('<I',bad,28)[0]
        struct.pack_into('<I',bad,phoff+24,7) # W+X program segment
        p.write_bytes(bad)
        r=subprocess.run([str(ROOT/'build/pico-sim'),'--module',str(p)],capture_output=True,text=True)
        self.assertNotEqual(r.returncode,0)
        self.assertIn('W+X',r.stderr)
    def test_differential_against_node_for_supported_js_subset(self):
        random.seed(5813)
        for name in ('counter_v1','counter_v2'):
            events=[(random.choice((1,2,4)),random.randint(-8,8)) for _ in range(80)]
            scenario='\n'.join(f'dispatch {ev} {arg}' for ev,arg in events)+'\n'
            records,_=self.run_guest(source=name,scenario=scenario,schema=1 if name=='counter_v1' else 2)
            self.assertEqual(len(records),80)
            js=(ROOT/'worlds'/f'{name}.js').read_text()
            node_code='''const vm=require('vm');
const src=JSON.parse(process.argv[1]); const events=JSON.parse(process.argv[2]);
const history=[];let effects=[];const context={cap:{emit:(x)=>{effects.push(x);return 0},abort:(x)=>{throw Error('abort '+x)}}};
vm.runInNewContext(src.replace(/\\bexport\\s+/g,''),context);
const state={schema:1,score:0,ticks:0,flags:0};
if(context.migrate) context.migrate(state,1);else state.schema=JSON.parse(process.argv[3]);
for(const [event,arg] of events){ effects=[];context.step(state,event,arg);history.push({score:state.score|0,ticks:state.ticks|0,effects}) }
console.log(JSON.stringify(history));'''
            # Call migrate for v2 for comparable state; we compare score/ticks/effects only.
            proc=subprocess.run(['node','-e',node_code,json.dumps(js),json.dumps(events),str(1 if name=='counter_v1' else 2)],capture_output=True,text=True,check=True)
            expected=json.loads(proc.stdout)
            for i,(actual,want) in enumerate(zip(records,expected)):
                self.assertTrue(actual['ok'],f'case {name}/{i} {actual}')
                self.assertEqual({k:actual[k] for k in ('score','ticks','effects')},want,f'case {name}/{i}')
    def test_transpiler_rejects_dynamic_javascript(self):
        for code in [
          'export const schema = 1; export function step(state,event,arg){ return eval("123"); }',
          'export const schema = 1; export function step(state,event,arg){ state.__proto__ = arg; }',
          'export const schema = 1; export function step(state,event,arg){ return Math.random(); }',
        ]:
            p=subprocess.run(['node',str(ROOT/'compiler/js2c.js'),'/dev/stdin'],input=code,capture_output=True,text=True)
            self.assertNotEqual(p.returncode,0)

if __name__=='__main__':unittest.main()
