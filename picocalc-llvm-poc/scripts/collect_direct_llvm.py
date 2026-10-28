#!/usr/bin/env python3
"""Collect inspectable native artifacts and a transactional hot-reload trace.

The full test suite is a separate gate. This collector does not manufacture
test results or rerun historical benchmarks from the original C release.
"""
from pathlib import Path
import datetime
import hashlib
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'compiler'))
from compile import compile_js

out = ROOT/'artifacts/direct-llvm'
out.mkdir(parents=True, exist_ok=True)
logs = ROOT/'logs'
records = {}
for name, base in [('counter_v1', 0x100000), ('counter_v2', 0x200000),
                   ('bad_migrate', 0x100000), ('display_v1', 0x100000),
                   ('fault', 0x100000), ('spin', 0x200000)]:
    elf = out/f'{name}.elf'
    records[name] = compile_js((ROOT/'worlds'/f'{name}.js').read_text(), elf, base)
    ir = elf.with_suffix('.generated.ll')
    subprocess.run(['llvm-as', str(ir), '-o', str(out/f'{name}.bc')], check=True)
    subprocess.run(['opt', '-passes=verify', '-disable-output', str(out/f'{name}.bc')], check=True)

scenario = f'''dispatch 1 3
queue 1 7
reload {out/'counter_v2.elf'} 2
drain
dispatch 1 4
reload {out/'bad_migrate.elf'} 3
dispatch 2 0
expect score 129
expect ticks 2
expect flags 42
expect epoch 2
'''
proc = subprocess.run([str(ROOT/'build/pico-sim'), '--module', str(out/'counter_v1.elf'), '--cap', 'emit'],
                      input=scenario, text=True, capture_output=True, check=True)
(logs/'direct-llvm-demo.jsonl').write_text(proc.stdout)
(logs/'direct-llvm-demo-input.txt').write_text(scenario)
for command, dest in [(['llvm-objdump', '-d', str(out/'counter_v1.elf')], 'direct-llvm-disassembly.txt'),
                      (['readelf', '-h', '-l', '-d', '-s', str(out/'counter_v1.elf')], 'direct-llvm-elf-audit.txt')]:
    result = subprocess.run(command, text=True, capture_output=True, check=True)
    (logs/dest).write_text(result.stdout)
info = {'collected_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'compiler': subprocess.check_output([os.environ.get('CLANG', 'clang'), '--version'], text=True).splitlines()[0],
        'node': subprocess.check_output(['node', '--version'], text=True).strip(),
        'modules': records,
        'trace': [json.loads(line) for line in proc.stdout.splitlines()],
        'source_hashes': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in [ROOT/'compiler/js2llvm.js', ROOT/'compiler/compile.py',
                                    ROOT/'compiler/jitd.py', ROOT/'kernel/pico_sim.cpp',
                                    ROOT/'include/pico_abi.h']}}
(logs/'direct-llvm-evidence.json').write_text(json.dumps(info, indent=2)+'\n')
print(json.dumps({'modules_verified': len(records), 'trace_records': len(info['trace']),
                  'evidence': str(logs/'direct-llvm-evidence.json')}, indent=2))
