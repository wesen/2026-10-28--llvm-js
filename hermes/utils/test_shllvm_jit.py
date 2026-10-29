#!/usr/bin/env python3
"""Qualify the persistent engine, module bundles, and explicit completion states."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'build-llvm')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    binary = args.build_dir.resolve() / 'bin/shllvm-jit'
    engine_test = args.build_dir.resolve() / 'bin/shllvm-jit-test'
    compiler = ROOT / 'utils/module-host/compiler.cjs'
    files = [binary, engine_test, compiler, ROOT / 'utils/module-host/runtime.js', Path(__file__)]
    files += list((ROOT / 'test/LLVMModules').rglob('*.mjs'))
    files += list((ROOT / 'test/LLVMModules').rglob('oracle.json'))
    files += list((ROOT / 'lib/LLVMJIT').glob('*.cpp'))
    files += [ROOT/'lib/VM/StaticHUnit.cpp', ROOT/'include/hermes/VM/sh_runtime.h',
              ROOT/'tools/shermes/JITHost.cpp', ROOT/'test/LLVMJIT/engine.cpp',
              args.build_dir.resolve()/'lib/libhermesvm.so',
              args.build_dir.resolve()/'tools/shermes/libshermes_console.so',
              args.build_dir.resolve()/'lib/libshllvm_runtime.so']
    source_cases = [ROOT/'test/LLVMNativeExtensions'/name for name in [
        'features_bigint.js', 'features_private_fields.js', 'features_regexp.js',
        'features_typed_arrays.js', 'eval_lexical_bindings.js',
        'async_generators.js', 'generator_protocol.js', 'async_basic.js']]
    files += source_cases
    before = {str(p): digest(p) for p in files}
    results = []
    def run(command):
        start = time.monotonic()
        try:
            p = subprocess.run([str(x) for x in command], text=True, capture_output=True, timeout=120)
            return dict(command=[str(x) for x in command], exit=p.returncode,
                        stdout=p.stdout, stderr=p.stderr, seconds=time.monotonic()-start)
        except subprocess.TimeoutExpired:
            return dict(command=[str(x) for x in command], exit=None, stdout='', stderr='timeout', seconds=time.monotonic()-start)
    def record(name, result, expected='', exit_code=0):
        result.update(case=name, passed=result['exit']==exit_code and result['stdout']==expected)
        results.append(result)
        print(('PASS ' if result['passed'] else 'FAIL ')+name, flush=True)
    record('engine-lifecycle', run([engine_test]), 'engine-lifecycle-ok\n')
    for entry in source_cases:
        oracle=run(['node','-e', 'globalThis.print=console.log;require("vm").runInThisContext(require("fs").readFileSync(process.argv[1],"utf8"));', entry])
        if oracle['exit'] != 0:
            record(entry.stem+'-oracle',oracle,'');continue
        for optimize in (False,True):
            output=run([binary,*(['-O'] if optimize else []),'--async-generators','--stats',entry])
            output['oracle']=oracle
            record(entry.stem+('-O' if optimize else '-O0'),output,oracle['stdout'])
    with tempfile.TemporaryDirectory(prefix='shllvm-jit-') as temporary:
        temp = Path(temporary)
        for entry in sorted((ROOT/'test/LLVMModules').glob('*/main.mjs')):
            case = entry.parent.name
            oracle_file=entry.parent/'oracle.json'
            oracle=None
            if oracle_file.exists():
                qualification=json.loads(oracle_file.read_text())
                expected=qualification['expected_stdout']
            else:
                qualification=None
                oracle=run(['node','--input-type=module','-e',
                            'globalThis.print=console.log; await import('+json.dumps(entry.as_uri())+');'])
                if oracle['exit'] != 0:
                    record(case+'-oracle',oracle,'');continue
                expected=oracle['stdout']
            bundle=temp/(case+'.js')
            command=['node',compiler,entry,'--output',bundle,'--manifest',temp/(case+'.json'),'--host-completion']
            if case=='errors':
                for target in sorted(entry.parent.glob('*.mjs')):
                    command += ['--include',target]
            built=run(command)
            if built['exit'] != 0:
                record(case+'-bundle',built,'');continue
            for optimize in (False,True):
                output=run([binary,*(['-O'] if optimize else []),'--gc-between','--stats',bundle])
                output['oracle_qualification']=qualification
                output['oracle']=oracle
                record(case+('-O' if optimize else '-O0'),output,expected)
        for name,source,code in [
            ('pending','await new Promise(()=>{});',2),
            ('fulfilled','await new Promise(r=>setTimeout(r,1));print("done");',0),
            ('rejected','await Promise.reject(new Error("expected-rejection"));',1)]:
            entry=temp/(name+'.mjs');entry.write_text(source)
            bundle=temp/(name+'.js')
            build=run(['node',compiler,entry,'--output',bundle,'--manifest',temp/(name+'.json'),'--host-completion'])
            if build['exit'] != 0:record(name+'-bundle',build,'');continue
            record(name,run([binary,bundle]),'done\n' if name=='fulfilled' else '',code)
    changed=[name for name,sha in before.items() if digest(Path(name))!=sha]
    report=dict(complete=True, scope='In-process baseline JIT targeted qualification; not full conformance',
                passed=sum(r['passed'] for r in results), failed=sum(not r['passed'] for r in results),
                changed_inputs=changed, fingerprints=before, results=results)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    return 1 if report['failed'] or changed else 0
if __name__=='__main__':
    raise SystemExit(main())
