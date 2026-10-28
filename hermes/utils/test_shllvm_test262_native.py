#!/usr/bin/env python3
"""Native integration probes for Test262 result classification (not suite cases)."""
import argparse
import json
import shutil
from pathlib import Path
import tempfile
from types import SimpleNamespace

import shllvm
from test_shllvm_test262 import execute_variant


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--suite', type=Path, required=True)
    p.add_argument('--build-dir', required=True)
    p.add_argument('--llvm-bin', required=True)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    args.action, args.compiler, args.no_runtime_build = 'build', None, True
    args.hermes_opt, args.llvm_opt = 'O0', '0'
    args.compile_timeout, args.run_timeout = 60, 2
    context = shllvm.prepare(args)
    negative = {'phase': 'runtime', 'type': 'TypeError'}
    cases = [
        ('positive', 'assert.sameValue(2 + 3, 5);', {}, 'pass'),
        ('type-error', 'throw new TypeError("expected");', {'negative': negative}, 'pass'),
        ('wrong-error', 'throw new RangeError("wrong");', {'negative': negative}, 'semantic_failure'),
        ('forged-string', 'throw "TypeError: forged";', {'negative': negative}, 'semantic_failure'),
        ('forged-stack', 'throw {stack: "TypeError: forged"};', {'negative': negative}, 'semantic_failure'),
        ('throwing-constructor', 'throw {get constructor() {throw new TypeError();}};', {'negative': negative}, 'semantic_failure'),
        ('const-runtime', 'const x = 1; x = 2;', {'negative': negative}, 'pass'),
        ('async-missing', 'Promise.resolve(1);', {'flags':['async']}, 'semantic_failure'),
        ('async-complete', 'Promise.resolve().then(function () {$DONE();});', {'flags':['async']}, 'pass'),
        ('async-duplicate', '$DONE(); $DONE();', {'flags':['async']}, 'semantic_failure'),
        ('async-failed', '$DONE(new Error("failed"));', {'flags':['async']}, 'semantic_failure'),
        ('parse-error', 'var = ;', {'negative':{'phase':'parse','type':'SyntaxError'}}, 'pass'),
        ('wrong-phase', 'var = ;', {'negative': negative}, 'unsupported'),
        ('timeout', 'while (true) {}', {}, 'timeout'),
    ]
    results = []
    with tempfile.TemporaryDirectory(prefix='shllvm-native-probes-') as td:
        suite = Path(td)
        # Hostile synthetic probes remain separate from the clean upstream suite.
        shutil.copytree(args.suite.resolve()/'harness', suite/'harness')
        for name, source, meta, expected in cases:
            path = suite/(name+'.js')
            path.write_text(source)
            work = suite/name
            work.mkdir()
            result = execute_variant(path, meta, 'sloppy', suite, args, context, work)
            result.update(probe=name, expected_status=expected, matched=result['status']==expected)
            results.append(result)
            print(name, result['status'], 'OK' if result['matched'] else 'FAIL', flush=True)
    args.output.write_text(json.dumps({'synthetic_probes': results}, indent=2)+'\n')
    return 0 if all(x['matched'] for x in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
