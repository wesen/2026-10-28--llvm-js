"""Direct-IR correctness, ABI and C-oracle regression checks.

These tests execute the resulting RV32 instructions in the existing simulator;
LLVM verification alone would not establish the source/runtime correspondence.
"""
import json
from pathlib import Path
import random
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'compiler'))
from compile import compile_js


class DirectLLVMTests(unittest.TestCase):
    def build_run(self, source, scenario, backend='llvm', opt='2', fuel=50000):
        with tempfile.TemporaryDirectory(prefix='pico-direct-') as d:
            out = Path(d) / 'world.elf'
            meta = compile_js(source, out, 0x100000, opt, backend=backend)
            proc = subprocess.run([str(ROOT/'build/pico-sim'), '--module', str(out),
                                   '--cap', 'emit', '--fuel', str(fuel)],
                                  input=scenario, text=True, capture_output=True)
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            records = [json.loads(s) for s in proc.stdout.splitlines() if s]
            return records, meta

    def compare(self, body, scenarios, opt='2'):
        source = 'export const schema = 1; export function step(state,event,arg){' + body + 'return 0;}'
        llvm, _ = self.build_run(source, scenarios, 'llvm', opt)
        c, _ = self.build_run(source, scenarios, 'c', opt)
        # Machine-instruction counts differ legitimately between backends.
        semantic = lambda rows: [{k: v for k, v in row.items() if k != 'steps'} for row in rows]
        self.assertEqual(semantic(llvm), semantic(c))
        return llvm

    def test_default_emits_verifiable_llvm_and_no_generated_c(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)/'world.elf'
            meta = compile_js((ROOT/'worlds/counter_v1.js').read_text(), out, 0x100000)
            self.assertEqual(meta['backend'], 'direct-llvm')
            ir = out.with_suffix('.generated.ll')
            self.assertTrue(ir.exists())
            self.assertFalse(out.with_suffix('.generated.c').exists())
            text = ir.read_text()
            self.assertIn('define i32 @pico_world_step', text)
            self.assertIn('asm sideeffect "ecall"', text)
            self.assertNotIn(' nsw ', text)
            self.assertNotIn(' nuw ', text)
            for tool in ('llvm-as', 'opt'):
                self.assertIsNotNone(shutil.which(tool), f'{tool} required for direct backend validation')
            bc = Path(d)/'world.bc'
            subprocess.run(['llvm-as', str(ir), '-o', str(bc)], check=True, capture_output=True)
            subprocess.run(['opt', '-passes=verify', '-disable-output', str(bc)], check=True, capture_output=True)

    def test_short_circuit_nested_phi_and_side_effects(self):
        rows = self.compare('''
            let x = 0;
            0 && cap.abort(8);
            1 || cap.abort(9);
            x = (arg && (event || (state.flags = 55)));
            state.score = x;
            cap.emit(x);
            ''', 'dispatch 0 0\ndispatch 0 2\ndispatch 1 2\n', opt='0')
        self.assertEqual([r['effects'] for r in rows], [[0], [1], [1]])
        self.assertEqual(rows[1]['flags'], 55)

    def test_loop_locals_control_flow_and_assignments(self):
        body = '''
            let i = 0; let total = 0;
            while (i < arg) {
                if (i & 1) { total += i; } else { total -= i; }
                i += 1;
            }
            state.score = total;
            state.ticks = i;
            cap.emit(total);
            '''
        scenarios = ''.join(f'dispatch 1 {n}\n' for n in range(20))
        for opt in ('0', '2', 's'):
            with self.subTest(opt=opt): self.compare(body, scenarios, opt)

    def test_integer_boundaries_unsigned_and_wrap(self):
        body = '''
            state.score = (arg * 17 + 2147483647) | 0;
            state.flags = (event < -1) + (state.schema > arg) * 2;
            state.ticks = ~(arg ^ event);
            cap.emit(state.score);
            '''
        values = [-2147483648, -2147483647, -1, 0, 1, 2147483646, 2147483647]
        scenarios = ''.join(f'dispatch {e} {a}\n' for e in [0, 1, 2147483647] for a in values)
        self.compare(body, scenarios)

    def test_seeded_c_oracle_state_and_effects(self):
        random.seed(73103)
        scenarios = ''.join(f'dispatch {random.choice([1, 2, 4])} {random.randint(-100,100)}\n' for _ in range(100))
        for name in ('counter_v1', 'counter_v2'):
            with self.subTest(world=name):
                source = (ROOT/'worlds'/f'{name}.js').read_text()
                llvm, _ = self.build_run(source, scenarios, 'llvm')
                c, _ = self.build_run(source, scenarios, 'c')
                semantic = lambda rows: [{k:v for k,v in r.items() if k != 'steps'} for r in rows]
                self.assertEqual(semantic(llvm), semantic(c))

    def test_backend_failure_preserves_previous_elf(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)/'world.elf'
            compile_js((ROOT/'worlds/counter_v1.js').read_text(), out, 0x100000)
            old = out.read_bytes()
            with self.assertRaises(subprocess.CalledProcessError):
                compile_js('const schema = 1; function step(state,event,arg){return ()=>arg;}', out, 0x100000)
            self.assertEqual(out.read_bytes(), old)

    def test_unsupported_or_invalid_source_rejected_before_ir_output(self):
        bodies = ['return eval("123");', 'state.__proto__ = arg;', 'return Math.random();',
                  'const o = {x:1};', 'const f = x => x;', 'return 0; eval("bad");',
                  'let x = x + 1;', 'if (arg) {let x = 1;} state.score = x;',
                  'event = 3;', 'state = 1;', 'return version;', 'arg / 2;',
                  'let a = 1; {let a = 2;}', 'state?.score;', 'cap?.emit(1);']
        for body in bodies:
            with self.subTest(body=body):
                code = 'const schema = 1; function step(state,event,arg){' + body + '}'
                p = subprocess.run(['node', str(ROOT/'compiler/js2llvm.js'), '/dev/stdin'],
                                   input=code, capture_output=True, text=True)
                self.assertNotEqual(p.returncode, 0)
                self.assertEqual(p.stdout, '')

    def test_direct_lane_explicit_scope_boundary(self):
        bad = [
            'const schema=1; async function step(state,event,arg){return 0;}',
            'const schema=1; function* step(state,event,arg){return 0;}',
            'const schema=1; function step(state,event,arg=7){return 0;}',
            'const schema=1; function step(state,event,arg){return "string";}',
        ]
        for source in bad:
            p = subprocess.run(['node', str(ROOT/'compiler/js2llvm.js'), '/dev/stdin'],
                               input=source, capture_output=True, text=True)
            self.assertNotEqual(p.returncode, 0, source)
            self.assertEqual(p.stdout, '')


if __name__ == '__main__': unittest.main()
