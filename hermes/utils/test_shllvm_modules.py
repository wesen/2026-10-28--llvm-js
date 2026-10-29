#!/usr/bin/env python3
"""Compare closed module graphs with Node ESM, native LLVM, and real lli."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
CASES = ROOT / 'test/LLVMModules'


def invoke(command, timeout=120):
    started = time.monotonic()
    try:
        result = subprocess.run([str(x) for x in command], capture_output=True, text=True, timeout=timeout)
        return dict(command=[str(x) for x in command], exit=result.returncode,
                    stdout=result.stdout, stderr=result.stderr, seconds=time.monotonic()-started)
    except subprocess.TimeoutExpired as error:
        return dict(command=[str(x) for x in command], exit=None, stdout='', stderr=str(error), timeout=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'build-llvm')
    parser.add_argument('--llvm-bin', type=Path, default=Path('/usr/lib/llvm-18/bin'))
    parser.add_argument('--case', action='append', default=[])
    parser.add_argument('--quick', action='store_true')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sources = sorted(CASES.glob('*/main.mjs'))
    if args.case:
        sources = [p for p in sources if p.parent.name in args.case]
    if not sources:
        parser.error('no selected module graphs')
    fingerprint_paths = [*CASES.rglob('*.mjs'), ROOT / 'utils/shllvm.py', Path(__file__).resolve(),
        * (ROOT / 'utils/module-host').glob('*.js'), * (ROOT / 'utils/module-host').glob('*.cjs'),
        ROOT / 'utils/module-host/pnpm-lock.yaml', args.build_dir / 'bin/shermes',
        args.build_dir / 'lib/libshllvm_runtime.a', args.build_dir / 'lib/libshllvm_runtime.so',
        args.build_dir / 'lib/libhermesvm.so']
    def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
    fingerprints = {str(p.resolve()): digest(p) for p in fingerprint_paths}
    results = []
    with tempfile.TemporaryDirectory(prefix='shllvm-modules-') as temporary:
        for source in sources:
            case = source.parent.name
            includes = sorted(source.parent.glob('*.mjs')) if case == 'errors' else []
            node = invoke(['node', '--input-type=module', '-e',
                          'globalThis.print=console.log; await import(' + json.dumps(source.as_uri()) + ');'])
            item = {'case': case, 'oracle': node, 'runs': []}
            item['passed'] = node['exit'] == 0 and bool(node['stdout'])
            profiles = [('O', '2')] if args.quick else [('O0','0'), ('O0','2'), ('O','0'), ('O','2')]
            for action, hermes, llvm in [('run', h, l) for h,l in profiles] + [('jit','O','2')]:
                command = [sys.executable, ROOT / 'utils/shllvm.py', action, '--module',
                           '--build-dir', args.build_dir, '--llvm-bin', args.llvm_bin,
                           '--no-runtime-build', '--hermes-opt', hermes, '--llvm-opt', llvm]
                for include in includes:
                    command += ['--module-include', include]
                command += [source, '-o', Path(temporary) / (case + '-' + action + '-' + hermes + '-' + llvm)]
                result = invoke(command)
                result.update(action=action, hermes=hermes, llvm=llvm)
                result['passed'] = result['exit'] == 0 and result['stdout'] == node['stdout']
                item['passed'] = item['passed'] and result['passed']
                item['runs'].append(result)
            results.append(item)
            print(('PASS' if item['passed'] else 'FAIL'), case, flush=True)
    changed = [name for name, before in fingerprints.items() if digest(Path(name)) != before]
    report = dict(complete=not changed, cases=len(results), passed=sum(r['passed'] for r in results),
                  failed=sum(not r['passed'] for r in results), quick=args.quick,
                  fingerprints=fingerprints, changed_inputs=changed, results=results,
                  scope='targeted source-text module graph contracts; not full module conformance')
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    return 0 if report['complete'] and report['failed'] == 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
